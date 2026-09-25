library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Combinational cartridge/BIOS ownership and physical ROM address decode.
entity memory_decode is
	port (
		gg : in std_logic;
		gg_bios_en : in std_logic;
		bios_en : in std_logic;
		ext_bios_sel : in std_logic;
		ext_bios_loaded : in std_logic;
		dbr : in std_logic;
		bootloader_n : in std_logic;
		ext_gg_bios_loaded : in std_logic;
		mapper_dahjee_a : in std_logic;
		use_zem : in std_logic;
		mapper_4pak : in std_logic;
		mapper_codies : in std_logic;
		systeme : in std_logic;
		sc3000_en : in std_logic;
		sc_multicart_en : in std_logic;
		mapper_linear : in std_logic;
		mapper_janggun : in std_logic;
		A : in std_logic_vector(15 downto 0);
		media_control : in std_logic_vector(7 downto 5);
		bank0 : in std_logic_vector(7 downto 0);
		bank1 : in std_logic_vector(7 downto 0);
		bank2 : in std_logic_vector(7 downto 0);
		bank3 : in std_logic_vector(7 downto 0);
		nem_bank0 : in std_logic_vector(7 downto 0);
		rom_bank : in std_logic_vector(3 downto 0);
		sc_multicart_page : in std_logic_vector(6 downto 0);
		jang_bank1 : in std_logic_vector(5 downto 0);
		jang_bank2 : in std_logic_vector(5 downto 0);
		jang_bank3 : in std_logic_vector(5 downto 0);
		jang_bank4 : in std_logic_vector(5 downto 0);
		cart_precedence_out : out std_logic;
		cart_memory_selected_out : out std_logic;
		dahjee_cart_access_out : out std_logic;
		rom_a_i_out : out std_logic_vector(21 downto 0)
	);
end entity;

architecture rtl of memory_decode is
	signal cart_precedence : std_logic;
	signal cart_memory_selected : std_logic;
	signal dahjee_cart_access : std_logic;
	signal rom_a_i : std_logic_vector(21 downto 0);
begin
	cart_precedence_out <= cart_precedence;
	cart_memory_selected_out <= cart_memory_selected;
	dahjee_cart_access_out <= dahjee_cart_access;
	rom_a_i_out <= rom_a_i;

	-- Original Master System hardware gives cartridge data precedence when
	-- the BIOS and cartridge are enabled simultaneously. The core models
	-- this SMS1 behavior for external SMS BIOS operation.
	cart_precedence <= '1' when (gg='0' and gg_bios_en='0' and bios_en='1'
	                               and ext_bios_sel='1' and ext_bios_loaded='1' and dbr='1'
	                               and bootloader_n='0' and media_control(6)='0') else '0';

	-- Source selection shared by the ROM mux and cartridge-only DahJee effects.
	-- A full external SMS BIOS also owns banking writes at $FFFC-$FFFF:
	-- do not restrict that ownership to CPU ROM addresses below $C000.
	-- Internal/GG BIOSes only cover the first 16KB; retain their existing decode.
	cart_memory_selected <= '0' when bootloader_n='0' and
	                           ((gg_bios_en='1' and ext_gg_bios_loaded='1' and A(15 downto 14)="00") or
	                            (gg_bios_en='0' and cart_precedence='0' and
	                             (A(15 downto 14)="00" or (ext_bios_sel='1' and ext_bios_loaded='1')))) else
	                        '0' when bootloader_n='1' and
	                           (dbr='0' or (bios_en='1' and gg='0' and gg_bios_en='0' and
	                            ext_bios_sel='1' and ext_bios_loaded='1' and media_control(6)='1')) else
	                        '1';
	dahjee_cart_access <= mapper_dahjee_a and cart_memory_selected;


	rom_a_i(12 downto 0) <= A(12 downto 0);
	process (A,bank0,bank1,bank2,bank3,use_zem,nem_bank0,mapper_4pak,mapper_codies,systeme,sc3000_en,sc_multicart_en,sc_multicart_page,rom_bank,bootloader_n,mapper_linear,dahjee_cart_access,
	         mapper_janggun,jang_bank1,jang_bank2,jang_bank3,jang_bank4)
	begin
		if systeme = '1' then
			case A(15 downto 14) is
			when "10" =>	
				rom_a_i(21 downto 13) <= "0000" & rom_bank & A(13);
			when others =>
				rom_a_i(21 downto 13) <= "000100" & A(15 downto 13);
			end case;
		elsif sc_multicart_en = '1' then
			rom_a_i(21 downto 15) <= sc_multicart_page;
			rom_a_i(14 downto 13) <= A(14 downto 13);
		elsif sc3000_en = '1' or mapper_linear = '1' or dahjee_cart_access = '1' then
			-- SC-3000, no-mapper (MEKA type 11), and Dahjee Type A cartridges: linear, unbanked.
			-- Keep the full CPU address so ROM pages don't mirror.
			rom_a_i(21 downto 16) <= (others=>'0');
			rom_a_i(15 downto 13) <= A(15 downto 13);
		elsif mapper_janggun = '1' and bootloader_n = '1' then
			case A(15 downto 13) is
			when "000" | "001" =>
				-- $0000-$3FFF fixed: first 16KB / pages 0 and 1
				rom_a_i(21 downto 13) <= "000000" & A(15 downto 13);
			when "010" => -- $4000-$5FFF
				rom_a_i(21 downto 13) <= "000" & jang_bank1;
			when "011" => -- $6000-$7FFF
				rom_a_i(21 downto 13) <= "000" & jang_bank2;
			when "100" => -- $8000-$9FFF
				rom_a_i(21 downto 13) <= "000" & jang_bank3;
			when "101" => -- $A000-$BFFF
				rom_a_i(21 downto 13) <= "000" & jang_bank4;
			when others =>
				rom_a_i(21 downto 13) <= "000000" & A(15 downto 13);
			end case;
		-- Zemina/Nemesis mapper is suppressed while the BIOS is running (bootloader_n='0').
		-- This allows large banked BIOSes (e.g. Korean 64KB) to bank-switch their own
		-- pages via the standard Sega mapper, without nem_bank0 corrupting $0000-$1FFF.
		elsif use_zem = '1' and bootloader_n = '1' then
			case A(15 downto 13) is
			when "000" =>
				-- $0000-$1FFF: fixed page (Nemesis I uses last page via nem_bank0).
				rom_a_i(21 downto 13) <= '0' & nem_bank0;
			when "001" =>
				-- $2000-$3FFF: always page 1 (never remapped in Zemina/Nemesis)
				rom_a_i(21 downto 13) <= "000000001";
			when "010" =>	
				rom_a_i(21 downto 13) <= '0' & bank0;
			when "011" =>
				rom_a_i(21 downto 13) <= '0' & bank1;
			when "100" =>
				rom_a_i(21 downto 13) <= '0' & bank2;
			when "101" =>
				rom_a_i(21 downto 13) <= '0' & bank3;
			when others =>
				rom_a_i(21 downto 13) <= "000000" & A(15 downto 13);
			end case;
		elsif mapper_4pak = '1' then
			-- 4-PAK All Action: full 16KB banking for all three slots.
			-- NO "first 1KB always from bank 0" exception here: the sub-games
			-- have their own interrupt vectors (NMI at $0066, IM1 at $0038) in
			-- their first bank (bank_base), NOT in physical bank 0 (the menu).
			rom_a_i(13) <= A(13);
			case A(15 downto 14) is
			when "00"   => rom_a_i(21 downto 14) <= bank0;
			when "01"   => rom_a_i(21 downto 14) <= bank1;
			when others => rom_a_i(21 downto 14) <= bank2;
			end case;
		else
			rom_a_i(13) <= A(13);
			case A(15 downto 14) is
			when "00" =>
				-- first kilobyte is always from bank 0
				if A(13 downto 10)="0000" and mapper_codies='0' then
					rom_a_i(21 downto 14) <= (others=>'0');
				else
					rom_a_i(21 downto 14) <= bank0;
				end if;

			when "01" =>
				rom_a_i(21 downto 14) <= bank1;
			
			when others =>
				rom_a_i(21 downto 14) <= bank2;

			end case;
		end if;
	end process;
end architecture;
