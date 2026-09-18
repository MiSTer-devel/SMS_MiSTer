library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Mapper banking/register state. Selection and save-state packing remain in system.
entity mapper_ctrl is
	port (
		RESET_n : in std_logic;
		clk_sys : in std_logic;
		evolution_game_launch : in std_logic;
		mapper_set : in std_logic;
		mapper_evolution : in std_logic;
		evolution_ss_in : in std_logic_vector(95 downto 0);
		mapper_in : in std_logic_vector(63 downto 0);
		mapper_janggun : in std_logic;
		systeme : in std_logic;
		bootloader_n : in std_logic;
		mapper_wonderkid : in std_logic;
		mapper_lock : in std_logic;
		detect_codies_static : in std_logic;
		mapper_codies_force : in std_logic;
		mapper_eeprom : in std_logic;
		mapper_zemina_force : in std_logic;
		mapper_nemesis_auto : in std_logic;
		rom_size_pages : in std_logic_vector(7 downto 0);
		ce_z80 : in std_logic;
		WR_n : in std_logic;
		MREQ_n : in std_logic;
		A : in std_logic_vector(15 downto 0);
		ss_freeze : in std_logic;
		D_in : in std_logic_vector(7 downto 0);
		sc3000_en : in std_logic;
		mapper_castle : in std_logic;
		mapper_linear : in std_logic;
		mapper_dahjee_a : in std_logic;
		mapper_sega_locked : in std_logic;
		use_zem : in std_logic;
		mapper_manual_force : in std_logic;
		sega_mapper_write_seen : in std_logic;
		bank0_out : out std_logic_vector(7 downto 0);
		bank1_out : out std_logic_vector(7 downto 0);
		bank2_out : out std_logic_vector(7 downto 0);
		bank3_out : out std_logic_vector(7 downto 0);
		jang_bank1_out : out std_logic_vector(5 downto 0);
		jang_bank2_out : out std_logic_vector(5 downto 0);
		jang_bank3_out : out std_logic_vector(5 downto 0);
		jang_bank4_out : out std_logic_vector(5 downto 0);
		jang_rev1_out : out std_logic;
		jang_rev2_out : out std_logic;
		jang_rev3_out : out std_logic;
		jang_rev4_out : out std_logic;
		nvram_e_out : out std_logic;
		nvram_ex_out : out std_logic;
		nvram_p_out : out std_logic;
		nvram_cme_out : out std_logic;
		lock_mapper_B_out : out std_logic;
		mapper_codies_out : out std_logic;
		mapper_codies_lock_out : out std_logic;
		mapper_4pak_out : out std_logic;
		pak4_reg2_out : out std_logic_vector(7 downto 0);
		nem_bank0_out : out std_logic_vector(7 downto 0);
		eeprom_soft_reset_out : out std_logic
	);
end entity;

architecture rtl of mapper_ctrl is
	signal bank0 : std_logic_vector(7 downto 0) := "00000000";
	signal bank1 : std_logic_vector(7 downto 0) := "00000001";
	signal bank2 : std_logic_vector(7 downto 0) := "00000010";
	signal bank3 : std_logic_vector(7 downto 0) := "00000011";
	signal jang_bank1 : std_logic_vector(5 downto 0) := "000010";
	signal jang_bank2 : std_logic_vector(5 downto 0) := "000010";
	signal jang_bank3 : std_logic_vector(5 downto 0) := "000100";
	signal jang_bank4 : std_logic_vector(5 downto 0) := "000100";
	signal jang_rev1 : std_logic := '0';
	signal jang_rev2 : std_logic := '0';
	signal jang_rev3 : std_logic := '0';
	signal jang_rev4 : std_logic := '0';
	signal nvram_e : std_logic := '0';
	signal nvram_ex : std_logic := '0';
	signal nvram_p : std_logic := '0';
	signal nvram_cme : std_logic := '0';
	signal lock_mapper_B : std_logic := '0';
	signal mapper_codies : std_logic := '0';
	signal mapper_codies_lock : std_logic := '0';
	signal mapper_4pak : std_logic := '0';
	signal pak4_reg0 : std_logic_vector(7 downto 0) := "00000000";
	signal pak4_reg2 : std_logic_vector(7 downto 0) := "00000000";
	signal nem_bank0 : std_logic_vector(7 downto 0) := "00000000";
	signal mapper_wonderkid_prev : std_logic := '0';
	signal reset_n_prev : std_logic := '0';
	signal bootloader_n_prev : std_logic := '0';
	signal eeprom_soft_reset : std_logic := '0';
	signal last_read_addr : std_logic_vector(15 downto 0);
begin
	bank0_out <= bank0;
	bank1_out <= bank1;
	bank2_out <= bank2;
	bank3_out <= bank3;
	jang_bank1_out <= jang_bank1;
	jang_bank2_out <= jang_bank2;
	jang_bank3_out <= jang_bank3;
	jang_bank4_out <= jang_bank4;
	jang_rev1_out <= jang_rev1;
	jang_rev2_out <= jang_rev2;
	jang_rev3_out <= jang_rev3;
	jang_rev4_out <= jang_rev4;
	nvram_e_out <= nvram_e;
	nvram_ex_out <= nvram_ex;
	nvram_p_out <= nvram_p;
	nvram_cme_out <= nvram_cme;
	lock_mapper_B_out <= lock_mapper_B;
	mapper_codies_out <= mapper_codies;
	mapper_codies_lock_out <= mapper_codies_lock;
	mapper_4pak_out <= mapper_4pak;
	pak4_reg2_out <= pak4_reg2;
	nem_bank0_out <= nem_bank0;
	eeprom_soft_reset_out <= eeprom_soft_reset;

	-- external ram control
	process (RESET_n,clk_sys)
	begin
		if RESET_n='0' then
			bank0 <= "00000000";
			bank1 <= "00000001";
			bank2 <= "00000010";
			bank3 <= "00000011";
			jang_bank1 <= "000010";
			jang_bank2 <= "000011";
			jang_bank3 <= "000100";
			jang_bank4 <= "000101";
			jang_rev1 <= '0';
			jang_rev2 <= '0';
			jang_rev3 <= '0';
			jang_rev4 <= '0';
			nvram_e  <= '0';
			nvram_ex <= '0';
			nvram_p  <= '0';
			nvram_cme <= '0';
			lock_mapper_B <= '0' ;
			mapper_codies <= '0' ;
			mapper_codies_lock <= '0' ;
			-- heuristic detectors are initialized in the dedicated detection process
			mapper_4pak <= '0' ;
			pak4_reg0 <= "00000000" ;
			pak4_reg2 <= "00000000" ;
			nem_bank0 <= (others => '0');
			mapper_wonderkid_prev <= '0';
			reset_n_prev <= '0';
			bootloader_n_prev <= '0';

		else
			if rising_edge(clk_sys) then
				eeprom_soft_reset <= '0';
				-- The Evolution launcher stores data in the top bytes of RAM,
				-- which alias the standard SMS mapper registers in this core.
				-- Start each selected game with the normal Sega power-on banks.
				if evolution_game_launch = '1' then
					bank0 <= x"00";
					bank1 <= x"01";
					bank2 <= x"02";
					bank3 <= x"03";
				end if;
				if mapper_set = '1' then
					if mapper_evolution = '1' and
					   evolution_ss_in(31 downto 16) = x"E132" then
						bank0 <= mapper_in(47 downto 40);
						bank1 <= mapper_in(39 downto 32);
						bank2 <= mapper_in(31 downto 24);
						bank3 <= mapper_in(23 downto 16);
						nvram_e <= '0';
						nvram_ex <= '0';
						nvram_p <= '0';
						nvram_cme <= '0';
						lock_mapper_B <= '0';
						mapper_codies <= '0';
						mapper_codies_lock <= '0';
						mapper_4pak <= '0';
					elsif mapper_janggun = '1' then
						jang_bank1 <= mapper_in(5 downto 0);
						jang_rev1  <= mapper_in(7);
						jang_bank2 <= mapper_in(13 downto 8);
						jang_rev2  <= mapper_in(15);
						jang_bank3 <= mapper_in(21 downto 16);
						jang_rev3  <= mapper_in(23);
						jang_bank4 <= mapper_in(29 downto 24);
						jang_rev4  <= mapper_in(31);
					else
						-- For System E, mapper_in(7:0) is IO port 0xF7 state (VDP bank
						-- selects + rom_bank), NOT bank0.  The IO module restores the
						-- SE banking via se_mapper_set, so skip bank0/pak4_reg0 here.
						if systeme = '0' then
							bank0          <= mapper_in(7 downto 0);
						end if;
						bank1              <= mapper_in(15 downto 8);
						bank2              <= mapper_in(23 downto 16);
						bank3              <= mapper_in(31 downto 24);
						if systeme = '0' then
							pak4_reg0      <= mapper_in(7 downto 0);
						end if;
						pak4_reg2          <= mapper_in(39 downto 32);
						nem_bank0          <= mapper_in(47 downto 40);
						nvram_e            <= mapper_in(50);
						nvram_ex           <= mapper_in(51);
						nvram_p            <= mapper_in(52);
						nvram_cme          <= mapper_in(53);
						mapper_4pak        <= mapper_in(57);
						mapper_codies      <= mapper_in(58);
						lock_mapper_B      <= mapper_in(59);
						mapper_codies_lock <= mapper_in(60);
					end if;
					-- Prevent edge detector registers from triggering false transitions
					-- in the next clock cycle after state restoration.
					bootloader_n_prev     <= bootloader_n;
					reset_n_prev          <= RESET_n;
					mapper_wonderkid_prev <= mapper_wonderkid;
				else
				if bootloader_n = '0' and mapper_lock = '0' then
					lock_mapper_B <= '0';
					mapper_codies <= '0';
					mapper_codies_lock <= '0';
				end if;
				-- BIOS handoff: restore standard cartridge startup banks.
				-- BIOS bank writes can leave bank0/1/2 in non-default states, which
				-- breaks static Codemasters detection and forced Codemasters start.
				if bootloader_n = '1' and bootloader_n_prev = '0' then
					bank0 <= "00000000";
					bank1 <= "00000001";
					bank2 <= "00000010";
					bank3 <= "00000011";
					jang_bank1 <= "000010";
					jang_bank2 <= "000011";
					jang_bank3 <= "000100";
					jang_bank4 <= "000101";
					jang_rev1 <= '0';
					jang_rev2 <= '0';
					jang_rev3 <= '0';
					jang_rev4 <= '0';
					nvram_e  <= '0';
					nvram_ex <= '0';
					nvram_p  <= '0';
					nvram_cme <= '0';
					if mapper_wonderkid = '1' then
						bank1 <= "00000000";
						bank2 <= "00000000";
						lock_mapper_B <= '1';
					elsif (detect_codies_static = '1' or mapper_codies_force = '1') and mapper_lock = '0' and mapper_eeprom = '0' then
						lock_mapper_B      <= '1';
						mapper_codies      <= '1';
						mapper_codies_lock <= '1';
						bank2              <= "00000000";
					end if;
				end if;
				-- On the first clock after RESET_n rises, initialise mapper state.
				-- rom_size_pages is stable here because
				-- cart_download holds RESET_n low throughout the entire ROM transfer.
				if RESET_n = '1' and reset_n_prev = '0' then
					if mapper_janggun = '1' then
						jang_bank1 <= "000010";
						jang_bank2 <= "000011";
						jang_bank3 <= "000100";
						jang_bank4 <= "000101";
						jang_rev1 <= '0';
						jang_rev2 <= '0';
						jang_rev3 <= '0';
						jang_rev4 <= '0';
					end if;
					if mapper_zemina_force = '1' then
						nem_bank0 <= (others => '0');
					elsif mapper_nemesis_auto = '1' and unsigned(rom_size_pages) /= 0 then
						-- Nemesis I needs $0000-$1FFF mapped to the last 8KB page on boot.
						nem_bank0 <= std_logic_vector(unsigned(rom_size_pages) - 1);
					else
						nem_bank0 <= (others => '0');
					end if;
					if mapper_wonderkid = '1' then
						-- All slots start at page 0; pre-lock to prevent 4-PAK misdetection
						bank1         <= "00000000";
						bank2         <= "00000000";
						lock_mapper_B <= '1';
					elsif (detect_codies_static = '1' or mapper_codies_force = '1') and mapper_lock = '0' and mapper_eeprom = '0' then
						if bootloader_n = '1' then
							lock_mapper_B      <= '1';
							mapper_codies      <= '1';
							mapper_codies_lock <= '1';
							bank2              <= "00000000";
						end if;
					end if;
					-- Initialize detection window (ticks run while bootloader active)
					-- detection window initialization is handled by the detection process
				end if;
				-- Auto-detected Wonder Kid becomes active after reset; apply init once.
				if mapper_wonderkid = '1' and mapper_wonderkid_prev = '0' then
					bank1         <= "00000000";
					bank2         <= "00000000";
					lock_mapper_B <= '1';
				end if;
				mapper_wonderkid_prev <= mapper_wonderkid;
				reset_n_prev <= RESET_n;
				bootloader_n_prev <= bootloader_n;
				if ce_z80 = '1' then
					if WR_n='1' and MREQ_n='0' then
						last_read_addr <= A; -- gyurco anti-ldir patch
					end if;
				end if;

				if mapper_janggun = '1' and bootloader_n = '1' then
					if ss_freeze = '0' and WR_n = '0' and MREQ_n = '0' then
						case A is
							when x"4000" =>
								jang_bank1 <= D_in(5 downto 0);
								jang_rev1  <= D_in(7);

							when x"6000" =>
								jang_bank2 <= D_in(5 downto 0);
								jang_rev2  <= D_in(7);

							when x"8000" =>
								jang_bank3 <= D_in(5 downto 0);
								jang_rev3  <= D_in(7);

							when x"A000" =>
								jang_bank4 <= D_in(5 downto 0);
								jang_rev4  <= D_in(7);

							when x"FFFE" =>
								jang_bank1 <= D_in(4 downto 0) & '0';
								jang_bank2 <= D_in(4 downto 0) & '1';
								jang_rev1  <= D_in(6) or D_in(7);
								jang_rev2  <= D_in(6) or D_in(7);

							when x"FFFF" =>
								jang_bank3 <= D_in(4 downto 0) & '0';
								jang_bank4 <= D_in(4 downto 0) & '1';
								jang_rev3  <= D_in(6) or D_in(7);
								jang_rev4  <= D_in(6) or D_in(7);

							when others =>
								null;
						end case;
					end if;
				elsif mapper_eeprom = '1' then
					-- EEPROM carts (93C46) always use the plain Sega $FFFC-$FFFF register map.
					-- Must take priority over every other mapper heuristic below (4-PAK $3FFE
					-- write-trigger, Zemina opcode scan, Dahjee/linear/castle/etc.) so a false
					-- positive on one of those heuristics can never steal the $FFFC write.
					if ss_freeze = '0' and WR_n='0' and MREQ_n='0' and A(15 downto 2)="11111111111111" then
						case A(1 downto 0) is
							when "00" =>
								eeprom_soft_reset  <= D_in(7);
							when "01" => bank0 <= D_in;
							when "10" => bank1 <= D_in;
							when "11" => bank2 <= D_in;
						end case;
					end if;
				elsif systeme = '1' or sc3000_en = '1' or mapper_castle = '1' or mapper_linear = '1' or mapper_dahjee_a = '1' or mapper_sega_locked = '1' then
					-- no System E, SC-3000, Castle (32KB RAM), linear, Dahjee Type A, or Sega-locked mappers
				elsif mapper_4pak = '1' then
					-- 4-PAK All Action mapper (per MAME sega8_4pak_device):
					-- $3FFE: reg0=D; bank0=D; bank2=(reg0[5:4]+reg2)
					-- $7FFF: bank1=D (independent)
					-- $BFFF: reg2=D; bank2=(reg0[5:4]+D)
					if ss_freeze = '0' and WR_n='0' and MREQ_n='0' then
						if A=x"3FFE" then
							pak4_reg0 <= D_in;
							bank0 <= D_in;
							bank2 <= std_logic_vector(
								unsigned(D_in(5 downto 4) & "0000") +
								unsigned(pak4_reg2));
						elsif A=x"7FFF" then
							bank1 <= D_in;
						elsif A=x"BFFF" then
							pak4_reg2 <= D_in;
							bank2 <= std_logic_vector(
								unsigned(pak4_reg0(5 downto 4) & "0000") +
								unsigned(D_in));
						end if;
					end if;
				elsif use_zem = '1' and bootloader_n = '1' then
					-- Zemina/Nemesis register map (verified against working nemesis-mapper branch):
					-- $0000 -> bank2 ($8000-$9FFF), $0001 -> bank3 ($A000-$BFFF)
					-- $0002 -> bank0 ($4000-$5FFF), $0003 -> bank1 ($6000-$7FFF)
					-- $0000-$1FFF is nem_bank0 (fixed at reset); $2000-$3FFF is always page 1.
					-- Suppressed while BIOS is running (bootloader_n='0') so the BIOS can
					-- bank-switch its own pages via the standard Sega mapper ($FFFC-$FFFF).
					if ss_freeze = '0' and WR_n='0' and MREQ_n='0' and A(15 downto 2)="00000000000000" then
						case A(1 downto 0) is
							when "00" => bank2 <= D_in;
							when "01" => bank3 <= D_in;
							when "10" => bank0 <= D_in;
							when "11" => bank1 <= D_in;
						end case;
					end if ;
				elsif ss_freeze = '0' and mapper_manual_force = '0' and bootloader_n = '1' and WR_n='0' and MREQ_n='0' and A=x"3FFE" and sega_mapper_write_seen = '0' then
					-- 4-PAK All Action: first write to $3FFE when no mapper active (gated by sega_mapper_write_seen='0').
					mapper_4pak <= '1';
					pak4_reg0 <= D_in;
					pak4_reg2 <= "00000000";
					bank0 <= D_in;
					bank1 <= "00000001";
					bank2 <= std_logic_vector(
						("00" & unsigned(D_in(5 downto 4)) & "0000") +
						to_unsigned(0, 8)); -- reg2=0 initially
				else
					-- No write-triggered Zemina detection here.
					-- Zemina mode is selected by header/CRC/OSD; once active, writes are handled in the use_zem branch above.
					if ss_freeze = '0' and WR_n='0' and MREQ_n='0' and A(15 downto 2)="11111111111111" then
						-- A write to $FFFC-$FFFF is a Sega mapper register; disable Codemasters
						-- detection unless it was already confirmed (mapper_codies_lock='1') or forced.
						if mapper_codies_force = '0' and mapper_codies_lock = '0' and detect_codies_static = '0' then
							mapper_codies <= '0' ;
						end if;
						if (mapper_codies = '0' and (detect_codies_static = '0' or bootloader_n = '0')) or mapper_eeprom = '1' then
							case A(1 downto 0) is
								when "00" => 
									if mapper_eeprom = '0' then
										nvram_ex <= D_in(4);
										nvram_e  <= D_in(3);
										nvram_p  <= D_in(2);
									end if;
								when "01" => bank0 <= D_in;
								when "10" => bank1 <= D_in;
								when "11" => bank2 <= D_in ; 
							end case;
						end if;
					end if;
					if ss_freeze = '0' and WR_n='0' and MREQ_n='0' and nvram_e='0' and mapper_lock='0' then
						case A(15 downto 0) is
							-- Codemasters-style banking; Wonder Kid mapper #41 uses only $8000.
							when x"0000" => 
								if mapper_codies = '1' or detect_codies_static = '1' or mapper_codies_force = '1' then
									bank0 <= D_in ;
								end if;
							when x"4000" => 
								if (mapper_codies = '1' or detect_codies_static = '1' or mapper_codies_force = '1') and mapper_eeprom = '0' then
									bank1(6 downto 0) <= D_in(6 downto 0) ;
									bank1(7) <= '0' ;
									nvram_cme <= D_in(7) ;
								end if ;
							when x"8000" => 
								if (mapper_codies = '1' or detect_codies_static = '1' or mapper_codies_force = '1' or mapper_wonderkid = '1') and mapper_eeprom = '0' then
									bank2 <= D_in ; 
								end if;
							-- Korean mapper (Sangokushi 3, Dodgeball King (Dallyeora Pigu-Wang), Jang Pung II, Jang Pung 3)
							when x"A000" => 
								if last_read_addr /= x"A000" then -- gyurco anti-ldir patch
									if mapper_codies='0' then
										bank2 <= D_in ;
									end if ;
								end if ;
							when others => null ;
						end case ;
					end if;
				end if;
				end if; -- mapper_set
			end if;
		end if;
	end process;

end architecture;
