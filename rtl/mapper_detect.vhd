library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- ROM metadata and mapper identification only; banking remains in system.vhd.
-- Preserve the existing domains: metadata/Zemina on ROMCL, Codemasters and
-- runtime heuristics on clk_sys. No new sampling stages or CDC paths are added.
-- mapper_in/evolution_ss_in retain the existing savestate interpretation.
-- Static download results (including mapper_out bit 55) are not restored,
-- matching the original detector; only the five runtime flags are restored.
entity mapper_detect is
	port (
		clk_sys : in std_logic;
		ROMCL : in std_logic;
		ROMAD : in std_logic_vector(24 downto 0);
		ROMDT : in std_logic_vector(7 downto 0);
		ROMEN : in std_logic;
		RESET_n : in std_logic;
		ss_freeze : in std_logic;
		bootloader_n : in std_logic;
		gg : in std_logic;
		A : in std_logic_vector(15 downto 0);
		WR_n : in std_logic;
		MREQ_n : in std_logic;
		mapper_lock : in std_logic;
		mapper_codies_force : in std_logic;
		mapper_dahjee_a_force : in std_logic;
		mapper_linear_force : in std_logic;
		mapper_zemina_force : in std_logic;
		mapper_evolution : in std_logic;
		mapper_msx : in std_logic;
		mapper_4pak : in std_logic;
		mapper_codies : in std_logic;
		mapper_set : in std_logic;
		mapper_in : in std_logic_vector(63 downto 0);
		evolution_ss_in : in std_logic_vector(95 downto 0);
		-- Existing guards consumed by the 4-PAK banking process in system.vhd.
		mapper_manual_force_o : out std_logic;
		sega_mapper_write_seen_o : out std_logic;
		rom_size_pages_o : out std_logic_vector(7 downto 0);
		rom_crc32_o : out std_logic_vector(31 downto 0);
		detect_zemina_static_o : out std_logic;
		detect_codies_static_o : out std_logic;
		detect_castle_o : out std_logic;
		detect_dahjee_a_o : out std_logic;
		detect_linear_o : out std_logic;
		detect_wonderkid_o : out std_logic;
		detect_sega_locked_o : out std_logic;
		mapper_janggun_o : out std_logic;
		mapper_castle_o : out std_logic;
		mapper_nemesis_auto_o : out std_logic;
		mapper_wonderkid_o : out std_logic;
		mapper_linear_o : out std_logic;
		mapper_sega_locked_o : out std_logic;
		mapper_dahjee_a_o : out std_logic;
		mapper_eeprom_o : out std_logic;
		use_zem_o : out std_logic
	);
end mapper_detect;

architecture Behavioral of mapper_detect is
	signal rom_size_pages     : std_logic_vector(7 downto 0)  := (others => '0');
	-- CRC16-CCITT (poly 0x1021, init 0xFFFF) of last 8KB block, accumulated during ROM load.
	-- Used to identify Wonder Kid [Proto] (CRC 0x8613) which starts with 0x41/0x42 (MSX header
	-- bytes) but uses Codemasters-style banking -- the CRC is needed because the MSX detector
	-- fires on the first two ROM reads, before any write-based heuristic can fire.
	signal rom_crc16_run      : std_logic_vector(15 downto 0) := x"FFFF";
	-- Static opcode-scan Zemina detection (computed during ROM download, ROMCL domain)
	-- Mirrors MAME's get_cart_type() logic: counts LD (nn),A opcodes targeting
	-- $0002/$0003/$0004 vs $FFFF in the first 32KB of the ROM.
	signal detect_zemina_static : std_logic := '0';
	signal zem_scan_state       : integer range 0 to 2 := 0;  -- 3-byte seq state machine
	signal zem_scan_lo          : std_logic_vector(7 downto 0) := (others => '0');
	signal zem_count_0002       : integer range 0 to 127 := 0;
	signal zem_count_ffff       : integer range 0 to 127 := 0;

	-- Static Codemasters header detection (mirrors MAME get_cart_type)
	-- Checks: ROM[0x7FE0] & 0x0F <= 9, ROM[0x7FE3] in {0x93, 0x94, 0x95}, ROM[0x7FEF] = 0x00
	signal codies_byte_fe0      : std_logic_vector(7 downto 0) := (others => '1');
	signal codies_byte_fe3      : std_logic_vector(7 downto 0) := (others => '1');
	signal detect_codies_static : std_logic := '0';

	-- CRC32 of the full ROM, accumulated during download (ROMCL domain).
	-- Used for CRC-based mapper and cartridge identification.
	signal rom_crc32            : std_logic_vector(31 downto 0) := x"FFFFFFFF";

	-- Heuristic detection signals
	signal detect_castle       : std_logic := '0';
	signal detect_dahjee_a     : std_logic := '0';
	signal detect_linear       : std_logic := '0';
	signal detect_wonderkid    : std_logic := '0';
	signal detect_sega_locked  : std_logic := '0';
	signal wonderkid_write_count: integer range 0 to 3 := 0;
	signal castle_write_count  : integer range 0 to 15 := 0;
	signal bank_write_seen     : std_logic := '0';
	signal sega_mapper_write_seen : std_logic := '0';
	signal mapper_detect_ticks : unsigned(15 downto 0) := (others => '0'); -- detection window timer (16-bit: ~1.2ms at 53.6MHz, needed for external BIOS handoff)
	-- Simple page-0 signature captured during download, used by Wonder Kid heuristic guards.
	signal rom_page0_byte0     : std_logic_vector(7 downto 0) := x"FF";
	signal rom_page0_byte1     : std_logic_vector(7 downto 0) := x"FF";
	signal mapper_nemesis_auto: std_logic;  -- Nemesis I special boot page by CRC
	signal use_zem            : std_logic;  -- active for any Zemina-family mapper
	signal mapper_eeprom        : std_logic := '0';
	signal mapper_manual_force  : std_logic;
	signal mapper_castle        : std_logic := '0'; -- The Castle (Japan): 32KB RAM at 0x8000-0xFFFF
	signal mapper_wonderkid     : std_logic;         -- Wonder Kid [Proto]: Codemasters-style 16KB, all banks init 0
	signal mapper_linear        : std_logic;         -- No mapper, linear ROM up to 48KB (MEKA type 11)
	signal mapper_sega_locked   : std_logic := '0';  -- Sega mapper path + all bank writes blocked (for 48KB dahjee_typeb games)
	signal mapper_dahjee_a      : std_logic;         -- Dahjee Type A: linear ROM + 8KB RAM at 0x2000-0x3FFF
	signal mapper_janggun         : std_logic := '0';

	-- CRC16-CCITT one-byte update: poly=0x1021, init=0xFFFF, MSB-first, no reflection.
	-- Equivalent to Python: binascii.crc_hqx(bytes([byte_in]), crc_in)
	function crc16_ccitt_byte(
		crc_in  : std_logic_vector(15 downto 0);
		byte_in : std_logic_vector(7 downto 0)
	) return std_logic_vector is
		variable crc : std_logic_vector(15 downto 0);
	begin
		crc := crc_in;
		for i in 7 downto 0 loop
			if (crc(15) xor byte_in(i)) = '1' then
				crc := (crc(14 downto 0) & '0') xor x"1021";
			else
				crc := crc(14 downto 0) & '0';
			end if;
		end loop;
		return crc;
	end function;


begin

	mapper_manual_force_o <= mapper_manual_force;
	sega_mapper_write_seen_o <= sega_mapper_write_seen;
	rom_size_pages_o <= rom_size_pages;
	rom_crc32_o <= rom_crc32;
	detect_zemina_static_o <= detect_zemina_static;
	detect_codies_static_o <= detect_codies_static;
	detect_castle_o <= detect_castle;
	detect_dahjee_a_o <= detect_dahjee_a;
	detect_linear_o <= detect_linear;
	detect_wonderkid_o <= detect_wonderkid;
	detect_sega_locked_o <= detect_sega_locked;
	mapper_janggun_o <= mapper_janggun;
	mapper_castle_o <= mapper_castle;
	mapper_nemesis_auto_o <= mapper_nemesis_auto;
	mapper_wonderkid_o <= mapper_wonderkid;
	mapper_linear_o <= mapper_linear;
	mapper_sega_locked_o <= mapper_sega_locked;
	mapper_dahjee_a_o <= mapper_dahjee_a;
	mapper_eeprom_o <= mapper_eeprom;
	use_zem_o <= use_zem;

	mapper_manual_force <= mapper_lock or mapper_codies_force or mapper_dahjee_a_force or
	                       mapper_linear_force or mapper_zemina_force or mapper_evolution;

	-- Janggun mapper (Janggun-ui Adeul): CRC32-based auto-detection.
	-- CRC32 0x192949D5
	mapper_janggun <= '1' when mapper_manual_force = '0' and (rom_crc32 xor x"FFFFFFFF") = x"192949D5" else '0';

	-- Castle mapper heuristic + OSD force.
	mapper_castle <= '1' when mapper_manual_force = '0' and mapper_janggun = '0' and detect_castle = '1' else
	                 '0';

	-- Wonder Kid [Proto] [SMS-GG]: MAPPER_MSX_Generic16_8000
	-- Codemasters-style 16KB banking, register at $8000, all slots init at page 0.
	-- This ROM starts with 0x41 0x42 which would normally trigger the MSX/Zemina
	-- detector on the CPU's very first two reads -- long before any $8000 write
	-- can confirm Wonder Kid via the write-based heuristic.  The CRC of the last
	-- 8KB block (0x8613) provides a load-time identity that's already stable when
	-- the CPU starts, so mapper_wonderkid='1' suppresses MSX detection from the
	-- first clock.  The write-based heuristic (detect_wonderkid) is kept as a
	-- fallback for ROM dumps where the CRC differs.
	-- CRC16-CCITT of last 8KB block: 0x8613

	-- Nemesis I requires a special startup mapping: $0000-$1FFF from the last page.
	mapper_nemesis_auto <= '1' when mapper_manual_force = '0' and mapper_janggun = '0' and
	                                rom_crc16_run = x"EE05" else
	                       '0';

	mapper_wonderkid <= '1' when mapper_manual_force = '0' and mapper_janggun = '0' and
	                             (detect_wonderkid = '1' or rom_crc16_run = x"8613") else
	                    '0';

	-- MEKA mapper type 11: no mapper, linear ROM (MAME dahjee_typeb).
	-- Pure linear ROM with system RAM at 0xC000-0xFFFF, no banking.
	-- mapper_linear uses A[15:13] directly for rom_a_i (bypasses all bank registers).
	-- Works correctly for these 32KB games on the physical FPGA.
	-- 48KB dahjee_typeb games that need bank-write protection but NOT the mapper_linear
	-- rom_a_i branch are handled separately by mapper_sega_locked (see below).
	-- Linear mapper heuristic + OSD force.
	mapper_linear <= '1' when mapper_linear_force = '1' else
	                 '1' when mapper_manual_force = '0' and mapper_janggun = '0' and detect_linear = '1' else
	                 '0';

	-- 48KB dahjee_typeb games: Sega mapper code path (bank registers 0,1,2 never updated)
	-- with ALL mapper register writes blocked to prevent bank corruption.
	-- These must NOT use the mapper_linear branch of rom_a_i: that path (using A[15:13]
	-- directly from the combinational address bus) fails to boot on the physical Cyclone V
	-- FPGA due to different routing/timing vs the Sega mapper's registered-bank path.
	-- Keeping them on the Sega mapper path (same SDRAM addresses for banks 0,1,2 on 48KB)
	-- while blocking all write detection fixes both the boot failure and the logo loop.
	-- Mapper that follows Sega path but locks all bank writes (used for some 48KB linear/dahjee_typeb games)
	mapper_sega_locked <= '1' when mapper_manual_force = '0' and mapper_janggun = '0' and detect_sega_locked = '1' else '0';

	-- Dahjee Type A expansion: linear ROM + 8KB RAM at 0x2000-0x3FFF.
	-- MSX conversions published by DahJee/Jumbo that require the Type A
	-- RAM expansion cart (which adds 9KB total: 8KB at 0x2000-0x3FFF +
	-- 1KB at 0xC000 merged with the system WRAM).
	-- (MAME devices: sega8_dahjee_typea_device)
	-- Dahjee Type A heuristic + OSD force.
	mapper_dahjee_a <= '1' when mapper_dahjee_a_force = '1' else
	                  '1' when mapper_manual_force = '0' and mapper_janggun = '0' and detect_dahjee_a = '1' else
	                  '0';

	-- GG EEPROM mapper: CRC32-based auto-detection. 
	-- The games are uniquely identified by their full-ROM CRC32.
	--   0x056CAE74  Hyper Pro Yakyuu '92 (Japan)
	--   0x2DA8E943  Pro Yakyuu GG League (Japan)
	--   0x36EBCD6D  Majors, The - Pro Baseball (USA)
	--   0x3D8D0DD6  World Series Baseball (USA)
	--   0xBB38CFD7  World Series Baseball (USA) (Rev A)
	--   0x578A8A38  World Series Baseball '95 (USA)
	--   0x496515A6  World Series Baseball '95 (USA) (Beta) (1994-06-29)
	--   0x410F1CA0  World Series Baseball '95 (USA) (Beta) (1994-07-09)
	--   0x5F7CCA5F  World Series Baseball '95 (USA) (Beta) (1994-07-19)
	--   0x6073CD59  World Series Baseball '95 (USA) (Beta) (1994-07-22)
	--   0x4190AD97  World Series Baseball '95 (USA) (Beta) (1994-07-28)
	--   0xF1987DE6  World Series Baseball '95 (USA) (Beta) (1994-07-29)

	mapper_eeprom <= '1' when ((rom_crc32 xor x"FFFFFFFF") = x"056CAE74" or
                                (rom_crc32 xor x"FFFFFFFF") = x"2DA8E943" or
                                (rom_crc32 xor x"FFFFFFFF") = x"A1A19135" or
                                (rom_crc32 xor x"FFFFFFFF") = x"36EBCD6D" or
                                (rom_crc32 xor x"FFFFFFFF") = x"3D8D0DD6" or
                                (rom_crc32 xor x"FFFFFFFF") = x"BB38CFD7" or
                                (rom_crc32 xor x"FFFFFFFF") = x"578A8A38" or
                                (rom_crc32 xor x"FFFFFFFF") = x"496515A6" or
                                (rom_crc32 xor x"FFFFFFFF") = x"410F1CA0" or
                                (rom_crc32 xor x"FFFFFFFF") = x"5F7CCA5F" or
                                (rom_crc32 xor x"FFFFFFFF") = x"6073CD59" or
                                (rom_crc32 xor x"FFFFFFFF") = x"4190AD97" or
                                (rom_crc32 xor x"FFFFFFFF") = x"F1987DE6") else
                     '0';

	-- Active for any Zemina-family mapper.
	-- detect_zemina_static: MAME-equivalent static opcode scan result.
	-- Size guard: Zemina games are all > 64KB (>8 pages of 8KB).
	-- GG guard: no Zemina games exist on Game Gear cartridges.
	use_zem <= '1' when mapper_zemina_force = '1' else
	           '0' when mapper_manual_force = '1' else
	           '0' when mapper_janggun = '1' else
	           '0' when mapper_wonderkid = '1' else
	           '0' when mapper_codies = '1' or detect_codies_static = '1' or mapper_codies_force = '1' else
	           '1' when mapper_nemesis_auto = '1' else
	           '1' when detect_zemina_static = '1'
	                    and unsigned(rom_size_pages) > 8
	                    and gg = '0' else
	           '0';

	-- Heuristic detection process: watch early writes during boot to infer mapper types
	process (clk_sys)
	begin
		if rising_edge(clk_sys) then
			if RESET_n = '0' then
				mapper_detect_ticks <= (others => '0');
				castle_write_count <= 0;
				bank_write_seen <= '0';
				detect_castle <= '0';
				detect_dahjee_a <= '0';
				detect_linear <= '0';
				detect_wonderkid <= '0';
				detect_sega_locked <= '0';
				wonderkid_write_count <= 0;
				sega_mapper_write_seen <= '0';
			elsif mapper_set = '1' then
				if mapper_evolution = '1' and
				   evolution_ss_in(31 downto 16) = x"E132" then
					-- These positions contain the Evolution launch-record address,
					-- not legacy auto-detection flags.
					detect_castle      <= '0';
					detect_wonderkid   <= '0';
					detect_linear      <= '0';
					detect_dahjee_a    <= '0';
					detect_sega_locked <= '0';
				else
					detect_castle      <= mapper_in(61);
					detect_wonderkid   <= mapper_in(62);
					detect_linear      <= mapper_in(63);
					detect_dahjee_a    <= mapper_in(48);
					detect_sega_locked <= mapper_in(49);
				end if;
				mapper_detect_ticks <= to_unsigned(65535, 16);
				castle_write_count <= 0;
				bank_write_seen <= '0';
				sega_mapper_write_seen <= '0';
				wonderkid_write_count <= 0;
			else
				if bootloader_n = '0' then
					mapper_detect_ticks <= (others => '0');
					castle_write_count <= 0;
					bank_write_seen <= '0';
					detect_castle <= '0';
					detect_dahjee_a <= '0';
					detect_linear <= '0';
					detect_wonderkid <= '0';
					detect_sega_locked <= '0';
					wonderkid_write_count <= 0;
					sega_mapper_write_seen <= '0';
				-- run a limited detection window while bootloader is active
				elsif ss_freeze = '0' and mapper_detect_ticks /= to_unsigned(65535, mapper_detect_ticks'length) then
					mapper_detect_ticks <= mapper_detect_ticks + 1;
				end if;

				if ss_freeze = '0' and bootloader_n = '1' and mapper_manual_force = '0' and mapper_detect_ticks < to_unsigned(65535, mapper_detect_ticks'length) then
					if WR_n = '0' and MREQ_n = '0' then
						-- Wonder Kid [Proto]: confirm after two $8000 writes during the detection window.
						if A = x"8000" and mapper_4pak = '0' and mapper_codies = '0' and detect_castle = '0' and detect_dahjee_a = '0' and sega_mapper_write_seen = '0' then
							if wonderkid_write_count < 2 then
								wonderkid_write_count <= wonderkid_write_count + 1;
							end if;
							if wonderkid_write_count = 1 then
								-- $8000 writes rule out MSX/Zemina register maps; require 0x41/0x42 header too.
								if rom_page0_byte0 = x"41" and rom_page0_byte1 = x"42" then
									detect_wonderkid <= '1';
								end if;
							end if;
						end if;

						-- Castle heuristic: repeated non-mapper writes inside 0x8000-0xBFFF.
						-- Excludes common mapper registers to avoid false positives on Sega games.
						if gg = '0' and A(15 downto 14) = "10" and
						   A /= x"8000" and A /= x"A000" and A /= x"BFFF" and A /= x"9FFF" and
						   bank_write_seen = '0' and mapper_msx = '0' and mapper_4pak = '0' and mapper_codies = '0' then
							if castle_write_count < 15 then
								castle_write_count <= castle_write_count + 1;
							end if;
							if castle_write_count >= 12 then
								detect_castle <= '1';
							end if;
						end if;
						-- bank register writes (common Sega banking addresses) disable linear assumption
						if A = x"4000" or A = x"8000" or A = x"A000" or A = x"3FFE" or A = x"7FFF" or A = x"BFFF" or A(15 downto 2) = "11111111111111" then
							bank_write_seen <= '1';
						end if;
						if A(15 downto 2) = "11111111111111" then
							sega_mapper_write_seen <= '1';
						end if;
						-- reset wonderkid write count on any Sega mapper/reg write to avoid false promotion
						if A(15 downto 2) = "11111111111111" or A = x"3FFE" or A = x"7FFF" or A = x"BFFF" then
							wonderkid_write_count <= 0;
						end if;
					end if;
				end if;

				-- Dahjee Type A: watch for writes to $2000-$3FFF at any point during boot.
				-- $2000-$3FFF is ROM space; standard Sega games never write here.
				-- $3FFE is the 4-PAK reg0 address and is explicitly excluded.
				-- Gated by gg='0', sega_mapper_write_seen='0', and MSX header (0x41 0x42) to prevent misdetection.
				if gg = '0' and ss_freeze = '0' and bootloader_n = '1' and mapper_manual_force = '0' and WR_n = '0' and MREQ_n = '0' and sega_mapper_write_seen = '0' then
					if rom_page0_byte0 = x"41" and rom_page0_byte1 = x"42" and A(15 downto 13) = "001" and A /= x"3FFE" then
						detect_dahjee_a <= '1';
					end if;
				end if;

				-- after detection window:
				if mapper_manual_force = '0' and mapper_detect_ticks = to_unsigned(65534, mapper_detect_ticks'length) then
					-- 32KB pure-linear ROMs -> mapper_linear
					if unsigned(rom_size_pages) = 4 and bank_write_seen = '0' then
						detect_linear <= '1';
					end if;

					-- (ROM-signature-only fallback for Wonder Kid removed:
					-- The 0x41/0x42 header is not unique to Wonder Kid and varies across ROM dumps.
					-- Detection now relies solely on the $8000 write heuristic above.)
					-- 48KB linear ROMs: use Sega mapper path but block bank writes
					if unsigned(rom_size_pages) = 6 and bank_write_seen = '0' then
						detect_sega_locked <= '1';
					end if;
				end if;
			end if;
		end if;
	end process;

	-- -----------------------------------------------------------------------
	-- ROM metadata capture (runs on ROM download clock)
	-- Tracks ROM size in 8KB pages and captures the page-0 signature bytes.
	-- -----------------------------------------------------------------------
	process (ROMCL)
		variable crc32_v : std_logic_vector(31 downto 0);
	begin
		if rising_edge(ROMCL) then
			if ROMEN = '1' then
				-- Reset page size counter on address 0 (start of new ROM)
				if unsigned(ROMAD) = 0 then
					rom_size_pages       <= (others => '0');
					rom_page0_byte0      <= x"FF";
					rom_page0_byte1      <= x"FF";
					detect_zemina_static <= '0';
					zem_scan_state       <= 0;
					zem_scan_lo          <= (others => '0');
					zem_count_0002       <= 0;
					zem_count_ffff       <= 0;
				end if;

				-- Update running CRC16-CCITT over the current (last-seen) 8KB block.
				-- Each time a new 8KB block starts (ROMAD(12:0)=0), restart the CRC
				-- so rom_crc16_run always holds the CRC of the highest-index block seen.
				if ROMAD(12 downto 0) = "0000000000000" then
					rom_crc16_run <= crc16_ccitt_byte(x"FFFF", ROMDT);
				else
					rom_crc16_run <= crc16_ccitt_byte(rom_crc16_run, ROMDT);
				end if;
				-- Capture first bytes of ROM page 0.
				if ROMAD(12 downto 0) = "0000000000000" then
					if unsigned(ROMAD(20 downto 13)) = 0 then
						rom_page0_byte0 <= ROMDT;
					end if;
				end if;
				if unsigned(ROMAD(20 downto 13)) = 0 and ROMAD(12 downto 0) = "0000000000001" then
					rom_page0_byte1 <= ROMDT;
				end if;

				-- Track highest 8KB page index seen (= number of pages - 1)
				if (unsigned(ROMAD(20 downto 13)) + 1) > unsigned(rom_size_pages) then
					rom_size_pages <= std_logic_vector(unsigned(ROMAD(20 downto 13)) + 1);
				end if;

				-- ---------------------------------------------------------------
				-- Static Zemina opcode scan (MAME get_cart_type() port)
				-- Scans only the first 32KB (ROMAD < 0x8000), matching MAME exactly.
				-- Detects LD (nn),A (opcode 0x32) sequences targeting $0002/$0003/$0004
				-- vs $FFFF. No opcode-boundary tracking needed: same approach as MAME.
				-- ---------------------------------------------------------------
				if unsigned(ROMAD) < 32768 then  -- first 32KB only
					case zem_scan_state is
						when 0 =>
							-- Waiting for 0x32 (LD (nn),A opcode)
							if ROMDT = x"32" then
								zem_scan_state <= 1;
							end if;
						when 1 =>
							-- Capture low byte of address operand
							zem_scan_lo    <= ROMDT;
							zem_scan_state <= 2;
						when 2 =>
							-- Examine high byte; classify full 16-bit address
							-- $0002, $0003, $0004: Zemina bank registers
							if ROMDT = x"00" and
							   (zem_scan_lo = x"02" or
							    zem_scan_lo = x"03" or
							    zem_scan_lo = x"04") then
								if zem_count_0002 < 127 then
									zem_count_0002 <= zem_count_0002 + 1;
								end if;
							-- $FFFF: Sega mapper register
							elsif ROMDT = x"FF" and zem_scan_lo = x"FF" then
								if zem_count_ffff < 127 then
									zem_count_ffff <= zem_count_ffff + 1;
								end if;
							end if;
							-- After consuming the high byte, check if this byte
							-- is itself a new 0x32 opcode (back-to-back sequences)
							if ROMDT = x"32" then
								zem_scan_state <= 1;
							else
								zem_scan_state <= 0;
							end if;
						when others =>
							zem_scan_state <= 0;
					end case;

					if unsigned(ROMAD) = 32767 then
						if zem_count_0002 > zem_count_ffff + 1 then
							detect_zemina_static <= '1';
						end if;
					end if;
				end if;

				-- CRC32 (IEEE 802.3 / zlib), reflected, poly 0xEDB88320
				if unsigned(ROMAD) = 0 then
					crc32_v := x"FFFFFFFF" xor (x"000000" & ROMDT);
				else
					crc32_v := rom_crc32 xor (x"000000" & ROMDT);
				end if;
				for i in 0 to 7 loop
					if crc32_v(0) = '1' then
						crc32_v := ('0' & crc32_v(31 downto 1)) xor x"EDB88320";
					else
						crc32_v := '0' & crc32_v(31 downto 1);
					end if;
				end loop;
				rom_crc32 <= crc32_v;
			end if;
		end if;
	end process;

	-- Static Codemasters header detection (runs on clk_sys domain with ROMEN write enable)
	process (clk_sys)
	begin
		if rising_edge(clk_sys) then
			if ROMEN = '1' then
				if unsigned(ROMAD) = 0 then
					codies_byte_fe0      <= (others => '1');
					codies_byte_fe3      <= (others => '1');
					detect_codies_static <= '0';
				end if;
				if unsigned(ROMAD) = to_unsigned(16#7FE0#, ROMAD'length) then
					codies_byte_fe0 <= ROMDT;
				end if;
				if unsigned(ROMAD) = to_unsigned(16#7FE3#, ROMAD'length) then
					codies_byte_fe3 <= ROMDT;
				end if;
				if unsigned(ROMAD) = to_unsigned(16#7FEF#, ROMAD'length) then
					if (unsigned(codies_byte_fe0(3 downto 0)) <= 9) and
					   (codies_byte_fe3 = x"93" or codies_byte_fe3 = x"94" or codies_byte_fe3 = x"95") and
					   (ROMDT = x"00") and mapper_eeprom = '0' then
						detect_codies_static <= '1';
					end if;
				end if;
				if mapper_eeprom = '1' then
					detect_codies_static <= '0';
				end if;
			end if;
		end if;
	end process;


end Behavioral;
