library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; 
--use IEEE.STD_LOGIC_ARITH.ALL;
-- use IEEE.STD_LOGIC_UNSIGNED.ALL; 
use work.jt89.all;

entity system is
	generic (
		MAX_SPPL : integer := 7;
		BASE_DIR : string := ""
	);
	port (
		clk_sys:		in	 STD_LOGIC;
		ce_cpu:		in	 STD_LOGIC;
		ce_vdp:		in	 STD_LOGIC;
		ce_pix:		in	 STD_LOGIC; 
		ce_sp:		in	 STD_LOGIC;
		turbo:		in	 STD_LOGIC;
		gg:			in	 STD_LOGIC;
		ggres:			in STD_LOGIC;
		systeme:		in  STD_LOGIC;
		-- sg:			in	 STD_LOGIC;		-- sg1000
		bios_en:	in	 STD_LOGIC;
		ext_bios_sel:    in STD_LOGIC;
		ext_bios_loaded: in STD_LOGIC;
		gg_bios_en:      in STD_LOGIC;
		ext_gg_bios_loaded: in STD_LOGIC;
		GG_BIOSWEN:      in STD_LOGIC;

		GG_EN		: in std_logic; -- Game Genie not game gear
		GG_CODE		: in std_logic_vector(128 downto 0); -- game genie code
		GG_RESET	: in std_logic;
		GG_AVAIL	: out std_logic;
		gg_link_en	: in  STD_LOGIC;
		gg_link_in	: in  STD_LOGIC_VECTOR(6 downto 0);
		gg_link_out	: out STD_LOGIC_VECTOR(6 downto 0);

		RESET_n:		in	 STD_LOGIC;

		rom_rd:  	out STD_LOGIC;
		rom_a:		out STD_LOGIC_VECTOR(23 downto 0);
		rom_do:		in	 STD_LOGIC_VECTOR(7 downto 0);

		j1_up:		in	 STD_LOGIC;
		j1_down:		in	 STD_LOGIC;
		j1_left:		in	 STD_LOGIC;
		j1_right:	in	 STD_LOGIC;
		j1_tl:		in	 STD_LOGIC;
		j1_tr:		in	 STD_LOGIC;
		j1_th:		in  STD_LOGIC;
		j1_start:	in  STD_LOGIC;
		j1_coin:		in  STD_LOGIC;
		j1_a3:		in  STD_LOGIC;
		j2_up:		in	 STD_LOGIC;
		j2_down:		in	 STD_LOGIC;
		j2_left:		in	 STD_LOGIC;
		j2_right:	in	 STD_LOGIC;
		j2_tl:		in	 STD_LOGIC;
		j2_tr:		in	 STD_LOGIC;
		j2_th:		in  STD_LOGIC;
		j2_start:	in  STD_LOGIC;
		j2_coin:		in  STD_LOGIC;
		j2_a3:		in  STD_LOGIC;
		pause:		in	 STD_LOGIC;
		soft_reset:	in	 STD_LOGIC;
		
		E0Type:	in  STD_LOGIC_VECTOR(1 downto 0);
		E1Use:	in	 STD_LOGIC;
		E2Use:	in	 STD_LOGIC;
		E0:		in  STD_LOGIC_VECTOR(7 downto 0);
		F2:		in  STD_LOGIC_VECTOR(7 downto 0);
		F3:		in  STD_LOGIC_VECTOR(7 downto 0);

		has_paddle:	in  STD_LOGIC;
		has_pedal:	in  STD_LOGIC;
		paddle:		in  STD_LOGIC_VECTOR(7 downto 0);
		paddle2:		in  STD_LOGIC_VECTOR(7 downto 0);
		pedal:		in  STD_LOGIC_VECTOR(7 downto 0);
		sc3000_en:	in  STD_LOGIC;
		sc_multicart_en:	in  STD_LOGIC;
		sc_megacart_en:	in  STD_LOGIC;
		sc_cart_ram:	in  STD_LOGIC_VECTOR(1 downto 0);
		sk1100_en:	in  STD_LOGIC;
		sk1100_row_sel:	out STD_LOGIC_VECTOR(2 downto 0);
		sk1100_row_data:	in  STD_LOGIC_VECTOR(11 downto 0);

		j1_tr_out:	out STD_LOGIC;
		j1_th_out:	out STD_LOGIC;
		j2_tr_out:	out STD_LOGIC;
		j2_th_out:	out STD_LOGIC;

		x:				in	 STD_LOGIC_VECTOR(8 downto 0);
		y:				in	 STD_LOGIC_VECTOR(8 downto 0);
		vcounter_cpu:	in	 STD_LOGIC_VECTOR(7 downto 0);
		color:		out STD_LOGIC_VECTOR(11 downto 0);
		palettemode:	in	STD_LOGIC;
		mask_column:out STD_LOGIC;
		black_column:		in STD_LOGIC;
		smode_M1:		out STD_LOGIC;
		smode_M2:		out STD_LOGIC;
		smode_M3:		out STD_LOGIC;
		smode_M4:		out STD_LOGIC;
		ysj_quirk:		in	STD_LOGIC;
		pal:				in STD_LOGIC;
		region:			in	STD_LOGIC;
		mapper_lock:	in STD_LOGIC;
		mapper_codies_force : in STD_LOGIC;
		mapper_dahjee_a_force : in STD_LOGIC;
		mapper_linear_force : in STD_LOGIC;
		mapper_zemina_force : in STD_LOGIC;   -- Force Zemina mapper (OSD override)
		mapper_evolution_force : in STD_LOGIC;
		evolution_gg_active : out STD_LOGIC;
		evolution_active : out STD_LOGIC;
		mapper_eeprom_out   : out STD_LOGIC;  -- Active high when EEPROM game detected
		vdp_enables:	in STD_LOGIC_VECTOR(1 downto 0);
		psg_enables:	in STD_LOGIC_VECTOR(1 downto 0);

		audioL:		out STD_LOGIC_VECTOR(15 downto 0);
		audioR:		out STD_LOGIC_VECTOR(15 downto 0);
		fm_ena:	   in  STD_LOGIC;

		dbr:			in  STD_LOGIC;
		sp64:			in  STD_LOGIC;

		-- Work RAM
		ram_a:      out STD_LOGIC_VECTOR(13 downto 0);
		ram_d:      out STD_LOGIC_VECTOR( 7 downto 0);
		ram_we:     out STD_LOGIC;
		ram_q:      in  STD_LOGIC_VECTOR( 7 downto 0);
		
		-- Backup RAM
		nvram_a:    out STD_LOGIC_VECTOR(14 downto 0);
		nvram_d:    out STD_LOGIC_VECTOR( 7 downto 0);
		nvram_we:   out STD_LOGIC;
		nvram_q:    in  STD_LOGIC_VECTOR( 7 downto 0);

		-- MC8123 decryption
		encrypt:		in  STD_LOGIC_VECTOR(1 downto 0);
		key_a : 		out STD_LOGIC_VECTOR(12 downto 0);
		key_d : 		in  STD_LOGIC_VECTOR(7 downto 0);
		
		ROMCL  : IN  STD_LOGIC;
		ROMAD  : IN STD_LOGIC_VECTOR(24 downto 0);
		ROMDT  : IN STD_LOGIC_VECTOR(7 downto 0);
		ROMEN  : IN  STD_LOGIC;
		BIOSWEN: IN  STD_LOGIC;

		-- Save-state interface
		z80_reg_out  : out STD_LOGIC_VECTOR(229 downto 0);
		z80_dir      : in  STD_LOGIC_VECTOR(229 downto 0) := (others => '0');
		z80_set      : in  STD_LOGIC := '0';
		vdp_regs_out : out STD_LOGIC_VECTOR(127 downto 0);
		vdp_regs_in  : in  STD_LOGIC_VECTOR(127 downto 0) := (others => '0');
		vdp_regs_set : in  STD_LOGIC := '0';
		vdp_cram_out : out STD_LOGIC_VECTOR(383 downto 0);
		ss_cram_wr   : in  STD_LOGIC := '0';
		ss_cram_A    : in  STD_LOGIC_VECTOR(4 downto 0)  := (others => '0');
		ss_cram_D    : in  STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
		ss_vram_en   : in  STD_LOGIC := '0';
		ss_vram_A    : in  STD_LOGIC_VECTOR(14 downto 0) := (others => '0');
		ss_vram_D    : out STD_LOGIC_VECTOR(7 downto 0);
		ss_vram_WE   : in  STD_LOGIC := '0';
		ss_vram_WA   : in  STD_LOGIC_VECTOR(14 downto 0) := (others => '0');
		ss_vram_WD   : in  STD_LOGIC_VECTOR(7 downto 0)  := (others => '0');
		psg_out      : out STD_LOGIC_VECTOR(55 downto 0);
		psg_in       : in  STD_LOGIC_VECTOR(55 downto 0) := (others => '0');
		psg_set      : in  STD_LOGIC := '0';
		mapper_out   : out STD_LOGIC_VECTOR(63 downto 0);
		mapper_in    : in  STD_LOGIC_VECTOR(63 downto 0) := (others => '0');
		mapper_set   : in  STD_LOGIC := '0';
		evolution_ss_out : out STD_LOGIC_VECTOR(95 downto 0);
		evolution_ss_in  : in  STD_LOGIC_VECTOR(95 downto 0) := (others => '0');
		evolution_ss_set : in  STD_LOGIC := '0';
		eeprom_ss_out : out STD_LOGIC_VECTOR(63 downto 0);
		eeprom_ss_in  : in  STD_LOGIC_VECTOR(63 downto 0) := (others => '0');
		eeprom_ss_set : in  STD_LOGIC := '0';
		-- Z80 instruction boundary detection (M1 cycle = opcode fetch)
		z80_m1_n     : out STD_LOGIC;
		-- MREQ_n: low = normal opcode fetch, high = interrupt acknowledge
		z80_mreq_n   : out STD_LOGIC;
		-- ISet: "00" = no prefix active (clean instruction boundary)
		z80_iset     : out STD_LOGIC_VECTOR(1 downto 0);
		-- Save-state interface for VDP2 (System E second VDP)
		vdp2_regs_out : out STD_LOGIC_VECTOR(127 downto 0);
		vdp2_regs_in  : in  STD_LOGIC_VECTOR(127 downto 0) := (others => '0');
		vdp2_regs_set : in  STD_LOGIC := '0';
		vdp2_cram_out : out STD_LOGIC_VECTOR(383 downto 0);
		ss_cram2_wr   : in  STD_LOGIC := '0';
		ss_cram2_A    : in  STD_LOGIC_VECTOR(4 downto 0)  := (others => '0');
		ss_cram2_D    : in  STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
		ss_vram2_en   : in  STD_LOGIC := '0';
		ss_vram2_A    : in  STD_LOGIC_VECTOR(14 downto 0) := (others => '0');
		ss_vram2_D    : out STD_LOGIC_VECTOR(7 downto 0);
		ss_vram2_WE   : in  STD_LOGIC := '0';
		ss_vram2_WA   : in  STD_LOGIC_VECTOR(14 downto 0) := (others => '0');
		ss_vram2_WD   : in  STD_LOGIC_VECTOR(7 downto 0)  := (others => '0');
		-- Save-state interface for PSG2 (System E second PSG)
		psg2_out      : out STD_LOGIC_VECTOR(55 downto 0);
		psg2_in       : in  STD_LOGIC_VECTOR(55 downto 0) := (others => '0');
		psg2_set      : in  STD_LOGIC := '0';
		-- Save-state interface for IO registers
		io_state_out  : out STD_LOGIC_VECTOR(31 downto 0);
		io_state_in   : in  STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
		io_state_set  : in  STD_LOGIC := '0';
		-- System E hardware pause: gates Z80 clock independently of ce_pix
		-- (ce_pix keeps running so VDP scanout and sync are unaffected)
		se_pause      : in  STD_LOGIC := '0';
		ss_freeze     : in  STD_LOGIC := '0'
	);
end system;

architecture Behavioral of system is
	
	signal RD_n:				std_logic;
	signal WR_n:				std_logic;
	signal IRQ_n:				std_logic;
	signal IORQ_n:				std_logic;
	signal M1_n:				std_logic;
	signal MREQ_n:				std_logic;
	signal z80_iset_int:		std_logic_vector(1 downto 0);
	signal A:					std_logic_vector(15 downto 0);
	signal D_in:				std_logic_vector(7 downto 0);
	signal D_out:				std_logic_vector(7 downto 0);
	signal ce_z80:				std_logic;
	
	signal vdp_RD_n:			std_logic;
	signal vdp_WR_n:			std_logic;
	signal vdp_D_out:			std_logic_vector(7 downto 0);
	signal vdp_IRQ_n:			std_logic;
	signal vdp_color:			std_logic_vector(11 downto 0);
--	signal vdp_y1:				std_logic;
	signal vdp2_RD_n:			std_logic;
	signal vdp2_WR_n:			std_logic;
	signal vdp2_D_out:		std_logic_vector(7 downto 0);
	signal vdp2_IRQ_n:		std_logic;
	signal vdp2_color:		std_logic_vector(11 downto 0);
	signal vdp2_y1:			std_logic;

	signal ctl_WR_n:			std_logic;
	
	signal io_RD_n:			std_logic;
	signal io_WR_n:			std_logic;
	signal io_D_out:			std_logic_vector(7 downto 0);
	
	signal ram_WR:				std_logic;
	signal ram_D_out:			std_logic_vector(7 downto 0);

	signal vram_WR:			std_logic;
	signal vram2_WR:			std_logic;

	signal boot_rom_D_out:	std_logic_vector(7 downto 0);
	signal ext_bios_D_out:	std_logic_vector(7 downto 0);
	signal active_bios_D_out: std_logic_vector(7 downto 0);
	signal ext_bios_addr:   std_logic_vector(17 downto 0);
	signal ext_bios_wren:   std_logic;
	signal ext_gg_bios_D_out: std_logic_vector(7 downto 0);
	signal ext_gg_bios_addr:  std_logic_vector(13 downto 0);
	signal ext_gg_bios_wren:  std_logic;
	signal rom_a_i:         std_logic_vector(21 downto 0);

	-- Master System Evolution / Noza mapper state.
	signal evolution_bank61 : std_logic_vector(7 downto 0);
	signal evolution_bank62 : std_logic_vector(7 downto 0);
	signal evolution_game_bank61, evolution_game_bank62 : std_logic_vector(7 downto 0);
	signal evolution_prev_game_bank61, evolution_prev_game_bank62 : std_logic_vector(7 downto 0);
	signal evolution_game_select : std_logic_vector(15 downto 0);
	signal evolution_effective_game_select : std_logic_vector(15 downto 0);
	signal evolution_selector_page : std_logic_vector(15 downto 0);
	signal evolution_game_page   : std_logic_vector(15 downto 0);
	signal evolution_3ffe   : std_logic_vector(7 downto 0);
	signal evolution_8c     : std_logic_vector(7 downto 0);
	signal evolution_cd     : std_logic_vector(7 downto 0);
	signal evolution_63, evolution_88 : std_logic_vector(7 downto 0);
	signal evolution_8d, evolution_8e, evolution_8f : std_logic_vector(7 downto 0);
	signal evolution_game_launch : std_logic;
	signal evolution_menu_mode   : std_logic;
	signal evolution_gg_mode     : std_logic;
	signal effective_vdp_gg      : std_logic;
	signal effective_gg          : std_logic;
	signal evolution_launch_trace : std_logic_vector(63 downto 0);
	signal evolution_launch_fetch_addr : std_logic_vector(15 downto 0);
	signal mapper_evolution : std_logic;

	-- The menu's 16-byte launch records follow the physical order of the
	-- MS132X1E flash dump.  Using that stable record index avoids ambiguous
	-- $61/$62 selectors, several of which are shared by two different games.
	function evolution_record_page(
		record_addr : std_logic_vector(15 downto 0);
		fallback    : std_logic_vector(15 downto 0)
	) return std_logic_vector is
	begin
		case record_addr is
			when x"1FD8" => return x"0180"; when x"1FE8" => return x"01C0";
			when x"1FF8" => return x"05C0"; when x"2008" => return x"09C0";
			when x"2018" => return x"0DC0"; when x"2028" => return x"0FC0";
			when x"2038" => return x"1040"; when x"2048" => return x"1440";
			when x"2058" => return x"1640"; when x"2068" => return x"1840";
			when x"2078" => return x"1C40"; when x"2088" => return x"2000";
			when x"2098" => return x"2400"; when x"20A8" => return x"2800";
			when x"20B8" => return x"2C00"; when x"20C8" => return x"2E00";
			when x"20D8" => return x"3200"; when x"20E8" => return x"3400";
			when x"20F8" => return x"3800"; when x"2108" => return x"3C00";
			when x"2118" => return x"4000"; when x"2128" => return x"4200";
			when x"2138" => return x"4600"; when x"2148" => return x"4800";
			when x"2158" => return x"4C00"; when x"2168" => return x"4E00";
			when x"2178" => return x"5000"; when x"2188" => return x"5200";
			when x"2198" => return x"5600"; when x"21A8" => return x"5800";
			when x"21B8" => return x"6000"; when x"21C8" => return x"6200";
			when x"21D8" => return x"6400"; when x"21E8" => return x"6600";
			when x"21F8" => return x"6A00"; when x"2208" => return x"6A80";
			when x"2218" => return x"6E80"; when x"2228" => return x"7280";
			when x"2238" => return x"7300"; when x"2248" => return x"7700";
			when x"2258" => return x"7900"; when x"2268" => return x"7D00";
			when x"2278" => return x"7F00"; when x"2288" => return x"7F80";
			when x"2298" => return x"8000"; when x"22A8" => return x"8200";
			when x"22B8" => return x"8400"; when x"22C8" => return x"8600";
			when x"22D8" => return x"8A00"; when x"22E8" => return x"8E00";
			when x"22F8" => return x"9200"; when x"2308" => return x"9600";
			when x"2318" => return x"9800"; when x"2328" => return x"A000";
			when x"2338" => return x"A080"; when x"2348" => return x"A480";
			when x"2358" => return x"A880"; when x"2368" => return x"AC80";
			when x"2378" => return x"AD00"; when x"2388" => return x"B100";
			when x"2398" => return x"B300"; when x"23A8" => return x"B700";
			when x"23B8" => return x"B780"; when x"23C8" => return x"B980";
			when x"23D8" => return x"BA00"; when x"23E8" => return x"BAC0";
			when x"23F8" => return x"BCC0"; when x"2408" => return x"BF00";
			when x"2418" => return x"C000"; when x"2428" => return x"CF00";
			when x"2438" => return x"CF80"; when x"2448" => return x"D080";
			when x"2458" => return x"D140"; when x"2468" => return x"D240";
			when x"2478" => return x"D440"; when x"2488" => return x"D540";
			when x"2498" => return x"D640"; when x"24A8" => return x"D740";
			when x"24B8" => return x"D880"; when x"24C8" => return x"DA00";
			when x"24D8" => return x"DAC0"; when x"24E8" => return x"DBC0";
			when x"24F8" => return x"DCC0"; when x"2508" => return x"DE00";
			when x"2518" => return x"DF00"; when x"2528" => return x"E000";
			when x"2538" => return x"E100"; when x"2548" => return x"E200";
			when x"2558" => return x"E2C0"; when x"2568" => return x"E3C0";
			when x"2578" => return x"E480"; when x"2588" => return x"E540";
			when x"2598" => return x"E640"; when x"25A8" => return x"E880";
			when x"25B8" => return x"E980"; when x"25C8" => return x"EA40";
			-- Icepost Rescue occupies $EA4000-$EDBFFF but has only one menu
			-- record ($25C8).  State captures show that $25D8 is Junte 4;
			-- the old synthetic $EC4000 entry shifted every following title.
			when x"25D8" => return x"EDC0"; when x"25E8" => return x"EE80";
			when x"25F8" => return x"EF80"; when x"2608" => return x"F0C0";
			when x"2618" => return x"F180"; when x"2628" => return x"F2C0";
			when x"2638" => return x"F3C0"; when x"2648" => return x"FBC0";
			when x"2658" => return x"FBC0";
			when others  => return fallback;
		end case;
	end function;

	signal bootloader_n:	std_logic := '0';
	signal media_control:   std_logic_vector(7 downto 5) := "101";
	signal cart_precedence: std_logic;
	signal io_state_out_i:  std_logic_vector(31 downto 0);
	signal active_bios:     std_logic;
	signal irom_D_out:		std_logic_vector(7 downto 0);
	signal irom_RD_n:			std_logic := '1';

	signal bank0:				std_logic_vector(7 downto 0);
	signal bank1:				std_logic_vector(7 downto 0);
	signal bank2:				std_logic_vector(7 downto 0);
	signal bank3:				std_logic_vector(7 downto 0);
  
	signal vdp_se_bank:		std_logic := '0';
	signal vdp2_se_bank:		std_logic := '0';
	signal vdp_cpu_bank:		std_logic := '0';

	-- VDP2 save-state internal wires (System E)
	signal vdp2_regs_out_i   : std_logic_vector(127 downto 0);
	signal vdp2_cram_out_i   : std_logic_vector(383 downto 0);
	signal vdp2_vram_D_i     : std_logic_vector(7 downto 0);
	-- PSG2 save-state internal wire
	signal psg2_out_i        : std_logic_vector(55 downto 0);
	signal rom_bank:			std_logic_vector(3 downto 0) := "0000";

	signal PSG_disable:		std_logic;
	signal PSG_outL:			std_logic_vector(10 downto 0);
	signal PSG_outR:			std_logic_vector(10 downto 0);
	signal PSG_mux:			std_logic_vector(7 downto 0);
	signal psg_WR_n:			std_logic;
	signal bal_WR_n:			std_logic;
	signal PSG2_outL:			std_logic_vector(10 downto 0);
	signal PSG2_outR:			std_logic_vector(10 downto 0);
	signal psg2_WR_n:			std_logic;
	signal bal2_WR_n:			std_logic;

	signal FM_out:				std_logic_vector(13 downto 0);
	signal FM_gated:			std_logic_vector(12 downto 0);
	alias FM_sign:				std_logic is FM_out(13);
	alias FM_adj:				std_logic is FM_out(12);
	signal fm_a:            std_logic;
	signal fm_d:            std_logic_vector(7 downto 0);
	signal fm_WR_n:	   	std_logic;

	signal mix_inL:			std_logic_vector(12 downto 0);
	signal mix_inR:			std_logic_vector(12 downto 0);
	signal mix2_inL:			std_logic_vector(12 downto 0);
	signal mix2_inR:			std_logic_vector(12 downto 0);
	
	signal det_D:		   	std_logic_vector(2 downto 0);
	signal det_WR_n:	   	std_logic;

	signal HL:					std_logic;
	signal TH_Ain:				std_logic;
	signal TH_Bin:				std_logic;
	signal sc_multicart_page:	std_logic_vector(6 downto 0);
	signal io_cycle:			std_logic;
	signal evolution_io_port:	std_logic;
	signal io_upper_port:		std_logic;
	signal io_sms_port:			std_logic;
	signal io_gg_port:			std_logic;
	signal io_gg_data_port:		std_logic;
	signal io_systeme_port:		std_logic;
	signal io_sc_mode:			std_logic;
	signal io_sc_ppi_port:		std_logic;
	signal io_sc_legacy_port:	std_logic;
	signal io_sc_mc_port:		std_logic;
	signal sc_cart_ram_32k:		std_logic;
	signal sc_cart_ram_low:		std_logic;
	signal sc_cart_ram_high:	std_logic;
	signal sc_cart_ram_rd:		std_logic;
	signal sc_multicart_upper:	std_logic;
	signal sc_multicart_open:	std_logic;

	signal nvram_WR:		   std_logic;
	signal nvram_e:         std_logic;
	signal nvram_ex:        std_logic;
	signal nvram_p:         std_logic;
	signal nvram_cme:       std_logic; -- codemasters ram extension
	signal nvram_D_out:     std_logic_vector(7 downto 0);
	
	signal lock_mapper_B:	std_logic;
	signal mapper_codies:	std_logic; -- Ernie Els Golf mapper
	signal mapper_codies_lock:	std_logic;
	
	signal mapper_msx_check0 : boolean := false ;
	signal mapper_msx_check1 : boolean := false ;
	signal mapper_msx_lock0 :  boolean := false ;
	signal mapper_msx_lock :   boolean := false ;
	signal mapper_msx :		   std_logic := '0' ;

	-- 4-PAK All Action mapper signals (HES 4 PAK All Action)
	-- References: MAME sega8_4pak_device (src/devices/bus/sega8/rom.cpp)
	signal mapper_4pak :		std_logic;
	signal pak4_reg2 :		std_logic_vector(7 downto 0); -- written at $BFFF

	-- Zemina/Nemesis mapper family (MAME: sega8_zemina_device / sega8_nemesis_device)
	-- Zemina:    8KB banking via writes to $0000-$0003; $0000-$1FFF starts from page 0.
	-- Nemesis I: same as Zemina but $0000-$1FFF initially reads from the LAST 8KB page.
	-- Nemesis II+/plain Zemina: $0000-$1FFF starts from page 0.
	-- Auto-detection is restricted to CRC/header signatures.
	-- Results from mapper_detect; detector-private state lives in that entity.
	signal mapper_manual_force : std_logic;
	signal sega_mapper_write_seen : std_logic;
	signal rom_size_pages : std_logic_vector(7 downto 0);
	signal rom_crc32 : std_logic_vector(31 downto 0);
	signal detect_zemina_static : std_logic;
	signal detect_codies_static : std_logic;
	signal detect_castle : std_logic;
	signal detect_dahjee_a : std_logic;
	signal detect_linear : std_logic;
	signal detect_wonderkid : std_logic;
	signal detect_sega_locked : std_logic;
	signal mapper_janggun : std_logic;
	signal mapper_castle : std_logic;
	signal mapper_nemesis_auto : std_logic;
	signal mapper_wonderkid : std_logic;
	signal mapper_linear : std_logic;
	signal mapper_sega_locked : std_logic;
	signal mapper_dahjee_a : std_logic;
	signal mapper_eeprom : std_logic;
	signal use_zem : std_logic;
	signal nem_bank0          : std_logic_vector(7 downto 0);  -- $0000-$1FFF bank

	-- GG EEPROM mapper (Pro Yakyuu GG League, Majors Pro Baseball,
	-- World Series Baseball v0/v1, World Series Baseball '95)
	-- Detected by CRC32 of full ROM.
	signal eeprom_enabled       : std_logic := '0';
	signal eeprom_D_out         : std_logic_vector(7 downto 0);
	signal eeprom_nvram_a       : std_logic_vector(6 downto 0);
	signal eeprom_nvram_di      : std_logic_vector(7 downto 0);
	signal eeprom_nvram_we      : std_logic;
	signal eeprom_bus_active    : std_logic;
	signal eeprom_soft_reset    : std_logic;
	signal eeprom_ss_out_i      : std_logic_vector(63 downto 0);


	signal mc8123_D_out    : std_logic_vector(7 downto 0);
	signal segadect2_D_out : std_logic_vector(7 downto 0);

	signal GENIE		: boolean;
	signal GENIE_DO	: std_logic_vector(7 downto 0);
	signal GENIE_DI   : std_logic_vector(7 downto 0);
	signal gg_link_nmi_n: std_logic;

	function reverse8(x : std_logic_vector(7 downto 0)) return std_logic_vector is
	begin
		return x(0) & x(1) & x(2) & x(3) & x(4) & x(5) & x(6) & x(7);
	end function;

	-- Janggun mapper (Janggun-ui Adeul): CRC32-based auto-detection
	signal jang_bank1, jang_bank2 : std_logic_vector(5 downto 0); -- $4000 (page 2), $6000 (page 3)
	signal jang_bank3, jang_bank4 : std_logic_vector(5 downto 0); -- $8000 (page 4), $A000 (page 5)
	signal jang_rev1, jang_rev2   : std_logic;
	signal jang_rev3, jang_rev4   : std_logic;
	signal janggun_reverse_active : std_logic := '0';

	component CODES is
		generic(
			ADDR_WIDTH  : in integer := 16;
			DATA_WIDTH  : in integer := 8
		);
		port(
			clk         : in  std_logic;
			reset       : in  std_logic;
			enable      : in  std_logic;
			addr_in     : in  std_logic_vector(15 downto 0);
			data_in     : in  std_logic_vector(7 downto 0);
			code        : in  std_logic_vector(128 downto 0);
			available   : out std_logic;
			genie_ovr   : out boolean;
			genie_data  : out std_logic_vector(7 downto 0)
		);
	end component;
	
	COMPONENT MC8123_rom_decrypt IS
	PORT (
		clk    : IN  STD_LOGIC;
		m1     : IN  STD_LOGIC;
		a      : IN  STD_LOGIC_VECTOR(15 downto 0);
		d      : OUT STD_LOGIC_VECTOR(7 downto 0);
		prog_d : IN STD_LOGIC_VECTOR(7 downto 0);
		key_a  : OUT STD_LOGIC_VECTOR(12 downto 0);
		key_d  : IN STD_LOGIC_VECTOR(7 downto 0)
	);
	END COMPONENT;

	COMPONENT SEGASYS1_DECT2 IS
	PORT (
		clk    : IN  STD_LOGIC;
		mrom_m1: IN  STD_LOGIC;
		mrom_ad: IN  STD_LOGIC_VECTOR(14 downto 0);
		mrom_dt: OUT STD_LOGIC_VECTOR(7 downto 0);
		rad    : OUT STD_LOGIC_VECTOR(14 downto 0);
		rdt    : IN STD_LOGIC_VECTOR(7 downto 0);
		ROMCL  : IN  STD_LOGIC;
		ROMAD  : IN STD_LOGIC_VECTOR(24 downto 0);
		ROMDT  : IN STD_LOGIC_VECTOR(7 downto 0);
		ROMEN  : IN  STD_LOGIC
	);
	END COMPONENT;

begin

	mapper_detect_inst : entity work.mapper_detect
		port map (
			clk_sys => clk_sys,
			ROMCL => ROMCL,
			ROMAD => ROMAD,
			ROMDT => ROMDT,
			ROMEN => ROMEN,
			RESET_n => RESET_n,
			ss_freeze => ss_freeze,
			bootloader_n => bootloader_n,
			gg => gg,
			A => A,
			WR_n => WR_n,
			MREQ_n => MREQ_n,
			mapper_lock => mapper_lock,
			mapper_codies_force => mapper_codies_force,
			mapper_dahjee_a_force => mapper_dahjee_a_force,
			mapper_linear_force => mapper_linear_force,
			mapper_zemina_force => mapper_zemina_force,
			mapper_evolution => mapper_evolution,
			mapper_msx => mapper_msx,
			mapper_4pak => mapper_4pak,
			mapper_codies => mapper_codies,
			mapper_set => mapper_set,
			mapper_in => mapper_in,
			evolution_ss_in => evolution_ss_in,
			mapper_manual_force_o => mapper_manual_force,
			sega_mapper_write_seen_o => sega_mapper_write_seen,
			rom_size_pages_o => rom_size_pages,
			rom_crc32_o => rom_crc32,
			detect_zemina_static_o => detect_zemina_static,
			detect_codies_static_o => detect_codies_static,
			detect_castle_o => detect_castle,
			detect_dahjee_a_o => detect_dahjee_a,
			detect_linear_o => detect_linear,
			detect_wonderkid_o => detect_wonderkid,
			detect_sega_locked_o => detect_sega_locked,
			mapper_janggun_o => mapper_janggun,
			mapper_castle_o => mapper_castle,
			mapper_nemesis_auto_o => mapper_nemesis_auto,
			mapper_wonderkid_o => mapper_wonderkid,
			mapper_linear_o => mapper_linear,
			mapper_sega_locked_o => mapper_sega_locked,
			mapper_dahjee_a_o => mapper_dahjee_a,
			mapper_eeprom_o => mapper_eeprom,
			use_zem_o => use_zem
		);


	-- The two known 16 MiB Evolution dumps differ in only 17 bytes. Detect
	-- their exact full-image CRCs after download; this avoids false positives
	-- and removes the need for a user-visible mapper override.
	mapper_evolution <= '1' when mapper_evolution_force = '1' or
	                   ((mapper_lock or mapper_codies_force or
	                     mapper_dahjee_a_force or mapper_linear_force or
	                     mapper_zemina_force) = '0' and
	                    ((rom_crc32 xor x"FFFFFFFF") = x"0C90A6CA" or
	                     (rom_crc32 xor x"FFFFFFFF") = x"CBD7FF82")) else '0';
	evolution_active <= mapper_evolution;

	-- Master System Evolution mapper register interface.
	-- $61/$62 select the game flash base; the observed $3FFE commands
	-- select the selected-game view ($87) or menu view ($85).
	evolution_mapper_inst : entity work.evolution_mapper
	port map (
		clk        => clk_sys,
		reset_n    => RESET_n,
		enable     => mapper_evolution,
		cpu_a      => A,
		mreq_n     => MREQ_n,
		iorq_n     => IORQ_n,
		rd_n       => RD_n,
		wr_n       => WR_n,
		d_in       => D_in,
		m1_n       => M1_n,
		bank61     => evolution_bank61,
		bank62     => evolution_bank62,
		game_bank61 => evolution_game_bank61,
		game_bank62 => evolution_game_bank62,
		prev_game_bank61 => evolution_prev_game_bank61,
		prev_game_bank62 => evolution_prev_game_bank62,
		reg3ffe    => evolution_3ffe,
		reg8c      => evolution_8c,
		regcd      => evolution_cd,
		reg63      => evolution_63,
		reg88      => evolution_88,
		reg8d      => evolution_8d,
		reg8e      => evolution_8e,
		reg8f      => evolution_8f,
		launch_trace => evolution_launch_trace,
		launch_fetch_addr => evolution_launch_fetch_addr,
		game_launch => evolution_game_launch,
		ss_out      => evolution_ss_out,
		ss_in       => evolution_ss_in,
		ss_mapper_in=> mapper_in,
		ss_set      => evolution_ss_set
	);

	-- Game Genie
	GAMEGENIE : component CODES
	generic map(
		ADDR_WIDTH => 16,
		DATA_WIDTH => 8
	)
	port map(
		clk => clk_sys,
		reset => GG_RESET,
		enable => not GG_EN,
		addr_in => A,
		data_in => D_out,
		code => GG_CODE,
		available => GG_AVAIL,
		genie_ovr => GENIE,
		genie_data => GENIE_DO
	);
	
	GENIE_DI <= GENIE_DO when GENIE else D_out;

	z80_inst: entity work.T80s
	generic map(
		T2Write => 0
	)
	port map
	(
		RESET_n	=> RESET_n,
		CLK		=> clk_sys,
		CEN		=> ce_z80,
		INT_n		=> IRQ_n,
		NMI_n		=> (pause or effective_gg) and gg_link_nmi_n,
		MREQ_n	=> MREQ_n,
		IORQ_n	=> IORQ_n,
		M1_n		=> M1_n,
		RD_n		=> RD_n,
		WR_n		=> WR_n,
		A			=> A,
		DI			=> GENIE_DI,
		DO			=> D_in,
		REG    => z80_reg_out,
		DIRSet => z80_set,
		DIR    => z80_dir,
		ISet_out => z80_iset_int
	);

	vdp_inst: entity work.vdp
	generic map(
		MAX_SPPL => MAX_SPPL
	)
	port map
	(
		clk_sys	=> clk_sys,
		ce_vdp	=> ce_vdp,
		ce_pix	=> ce_pix,
		ce_sp		=> ce_sp,
		-- Later TecToy VDP implementations used by Evolution do not enforce
		-- the original eight-sprites-per-line display limit.  Several bundled
		-- titles rely on this even when the global compatibility option is off.
		sp64		=> sp64 or mapper_evolution,
		HL			=> HL,
		-- The Evolution menu sets R10=$C0 while enabling both HINT and VINT.
		-- This timing model otherwise delivers a line-191 IRQ and a separate
		-- line-192 frame IRQ. The menu treats both as frame ticks and may resume
		-- VRAM writes before VBlank. Selected games retain normal line IRQs.
		mask_line_irq => evolution_menu_mode,
		capture_cpu_edges => evolution_menu_mode,
		-- Evolution's clone keeps the ordinary R2 name-table addressing
		-- while displaying 224 lines. Its educational ROMs populate $3800;
		-- SMS2 addressing would incorrectly render pattern data from $3700.
		legacy_ext_nt => mapper_evolution,
		gg			=> effective_vdp_gg,
		ggres			=> ggres,
		-- Bsg			=> sg,		-- sg1000
		se_bank	=> vdp_se_bank,
		RD_n		=> vdp_RD_n,
		WR_n		=> vdp_WR_n,
		IRQ_n		=> vdp_IRQ_n,
		WR_direct => vram_WR,
		A_direct	=> A(13 downto 8),
		A			=> A(7 downto 0),
		D_in		=> D_in,
		D_out		=> vdp_D_out,
		x			=> x,
		y			=> y,
		vcounter_cpu=> vcounter_cpu,
		color		=> vdp_color,
		palettemode	=> palettemode,
		y1			=> open,
		mask_column => mask_column,
		black_column => black_column,
		smode_M1	=> smode_M1,
		smode_M2	=> smode_M2,
		smode_M3	=> smode_M3,
		smode_M4	=> smode_M4,
		ysj_quirk	=> ysj_quirk,
		reset_n  => RESET_n,
		ss_regs_out => vdp_regs_out,
		ss_regs_in  => vdp_regs_in,
		ss_regs_set => vdp_regs_set,
		ss_cram_out => vdp_cram_out,
		ss_cram_wr  => ss_cram_wr,
		ss_cram_A   => ss_cram_A,
		ss_cram_D   => ss_cram_D,
		ss_vram_en  => ss_vram_en,
		ss_vram_A   => ss_vram_A,
		ss_vram_D   => ss_vram_D,
		ss_vram_WE  => ss_vram_WE,
		ss_vram_WA  => ss_vram_WA,
		ss_vram_WD  => ss_vram_WD
	);

	vdp2_inst: entity work.vdp
	generic map(
		MAX_SPPL => MAX_SPPL
	)
	port map
	(
		clk_sys	=> clk_sys,
		ce_vdp	=> ce_vdp,
		ce_pix	=> ce_pix,
		ce_sp		=> ce_sp,
		sp64		=> sp64,
		HL			=> HL,
		mask_line_irq => '0',
		capture_cpu_edges => '0',
		legacy_ext_nt => '0',
		gg			=> effective_vdp_gg,
		ggres			=> ggres,
		-- Bsg			=> sg,		-- sg1000
		se_bank	=> vdp2_se_bank,
		RD_n		=> vdp2_RD_n,
		WR_n		=> vdp2_WR_n,
		IRQ_n		=> vdp2_IRQ_n,
		WR_direct => vram2_WR,
		A_direct	=> A(13 downto 8),
		A			=> A(7 downto 0),
		D_in		=> D_in,
		D_out		=> vdp2_D_out,
		x			=> x,
		y			=> y,
		vcounter_cpu=> vcounter_cpu,
		color		=> vdp2_color,
		palettemode	=> palettemode,
		y1			=> vdp2_y1,
		mask_column => open,
		black_column => black_column,
		smode_M1	=> open,
		smode_M2	=> open,
		smode_M3	=> open,
		smode_M4	=> open,
		ysj_quirk	=> ysj_quirk,
		reset_n  => RESET_n,
		ss_regs_out => vdp2_regs_out_i,
		ss_regs_in  => vdp2_regs_in,
		ss_regs_set => vdp2_regs_set,
		ss_cram_out => vdp2_cram_out_i,
		ss_cram_wr  => ss_cram2_wr,
		ss_cram_A   => ss_cram2_A,
		ss_cram_D   => ss_cram2_D,
		ss_vram_en  => ss_vram2_en,
		ss_vram_A   => ss_vram2_A,
		ss_vram_D   => vdp2_vram_D_i,
		ss_vram_WE  => ss_vram2_WE,
		ss_vram_WA  => ss_vram2_WA,
		ss_vram_WD  => ss_vram2_WD
	);

	psg_inst: jt89
	port map
	(
		clk		=> clk_sys,
		clk_en   => ce_cpu,
		wr_n		=> psg_WR_n,
		din		=> D_in,
		
		mux		=> PSG_mux,
		soundL	=> PSG_outL,
		soundR	=> PSG_outR,

		rst		=> not RESET_n,
		ss_out => psg_out,
		ss_set => psg_set,
		ss_in  => psg_in
	);
	
	psg2_inst: jt89
	port map
	(
		clk		=> clk_sys,
		clk_en   => ce_cpu,
		wr_n		=> psg2_WR_n,
		din		=> D_in,
		
		mux		=> PSG_mux,
		soundL	=> PSG2_outL,
		soundR	=> PSG2_outR,

		rst		=> not RESET_n,
		ss_out => psg2_out_i,
		ss_set => psg2_set,
		ss_in  => psg2_in
	);
	
	fm: work.opll
	port map
	(
		xin		=> clk_sys,
		xena		=> ce_cpu,
		d        => fm_d,
		a        => fm_a,
		cs_n     => '0',
		we_n		=> '0',
		ic_n		=> RESET_n,
		mixout   => FM_out
	);
	
	process (clk_sys)
	begin
		if rising_edge(clk_sys) then
			if RESET_n='0' then
				fm_d <= (others => '0');
				fm_a <= '0';
			elsif ss_freeze = '0' and fm_WR_n='0' then
				fm_d <= D_in;
				fm_a <= A(0);
			end if;
		end if;
	end process;
	
	
-- AMR - Clamped volume boosting - if the top two bits match, truncate the topmost bit.
-- If the top two bits don't match, duplicate the second bit across the output.

FM_gated <= (others=>'0') when fm_ena='0' or mapper_evolution='1' or det_D(0)='0' else  -- All zero if FM is disabled
				FM_out(FM_out'high-1 downto 0) when FM_sign=FM_adj else -- Pass through
				(FM_gated'high=>FM_sign,others=>FM_adj); -- Clamp

PSG_disable <= '1' when (systeme='0' and gg='0' and fm_ena='1' and mapper_evolution='0' and (not det_D(1)=det_D(0))) else '0';
				 
mix_inL <= (others=>'0') when psg_enables(0)='1' or PSG_disable='1' else (PSG_outL(10) & PSG_outL & '0');
mix_inR <= (others=>'0') when psg_enables(0)='1' or PSG_disable='1' else (PSG_outR(10) & PSG_outR & '0');
mix2_inL <= (others=>'0') when psg_enables(1)='1' else (PSG2_outL(10) & PSG2_outL & '0') when systeme='1' else FM_gated;
mix2_inR <= (others=>'0') when psg_enables(1)='1' else (PSG2_outR(10) & PSG2_outR & '0') when systeme='1' else FM_gated;
				
-- The old code shifts FM right by one place and PSG right by three places.
-- This version shift FM left one place and PSG right by one place, so the volume
-- is four times higher.  I haven't yet found a game in which this clips.

mix : entity work.AudioMix
port map(
	clk => clk_sys,
	reset_n => RESET_n,
	audio_in_l1 => signed(mix_inL & "000"),
	audio_in_l2 => signed(mix2_inL & "000"),
	audio_in_r1 => signed(mix_inR & "000"),
	audio_in_r2 => signed(mix2_inR & "000"),
	std_logic_vector(audio_l) => audioL,
	std_logic_vector(audio_r) => audioR
);

--	audioL <= (PSG_outL(10) & PSG_outL(10) & PSG_outL(10) & PSG_outL & "00") + (FM_out(13) & FM_out & "0") when fm_ena = '1'
--	     else (PSG_outL(10) & PSG_outL(10) & PSG_outL(10) & PSG_outL & "00");
--	audioR <= (PSG_outR(10) & PSG_outR(10) & PSG_outR(10) & PSG_outR & "00") + (FM_out(13) & FM_out & "0") when fm_ena = '1'
--	     else (PSG_outR(10) & PSG_outR(10) & PSG_outR(10) & PSG_outL & "00");

	io_inst: entity work.io
	port map
	(
		clk		=> clk_sys,
		ce_cpu	=> ce_cpu,
		WR_n		=> io_WR_n,
		RD_n		=> io_RD_n,
		A			=> A(7 downto 0),
		D_in		=> D_in,
		D_out		=> io_D_out,
		HL_out	=> HL,
		vdp1_bank => vdp_se_bank,
		vdp2_bank => vdp2_se_bank,
		vdp_cpu_bank => vdp_cpu_bank,
		rom_bank => rom_bank,
		J1_tr_out => j1_tr_out,
		J1_th_out => j1_th_out,
		J2_tr_out => j2_tr_out,
		J2_th_out => j2_th_out,
		J1_up		=> j1_up,
		J1_down	=> j1_down,
		J1_left	=> j1_left,
		J1_right	=> j1_right,
		J1_tl		=> j1_tl,
		J1_tr		=> j1_tr,
		J1_th		=> j1_th,
		J1_start	=> j1_start,
		J1_coin	=> j1_coin,
		J1_a3		=> j1_a3,
		J2_up		=> j2_up,
		J2_down	=> j2_down,
		J2_left	=> j2_left,
		J2_right	=> j2_right,
		J2_tl		=> j2_tl,
		J2_tr		=> j2_tr,
		J2_th		=> j2_th,
		J2_start	=> j2_start,
		J2_coin	=> j2_coin,
		J2_a3		=> j2_a3,
		Pause		=> pause,
		soft_reset	=> soft_reset,
		E0Type	=> E0Type,
		E1Use		=> E1Use,
		E2Use		=> E2Use,
		E0			=> E0,
		F2			=> F2,
		F3			=> F3,
		has_paddle=> has_paddle,
		has_pedal=> has_pedal,
		paddle	=> paddle,
		paddle2	=> paddle2,
		pedal		=> pedal,
		palettemode => palettemode,
		sc3000_en => sc3000_en,
		sc_multicart_en => sc_multicart_en,
		sc_megacart_en => sc_megacart_en,
		sk1100_en => sk1100_en,
		sc_multicart_page => sc_multicart_page,
		sk1100_row_sel => sk1100_row_sel,
		sk1100_row_data => sk1100_row_data,
		pal		=> pal,
		gg			=> effective_gg,
		gg_link_en => gg_link_en,
		gg_link_in => gg_link_in,
		gg_link_out => gg_link_out,
		gg_link_nmi_n => gg_link_nmi_n,
		systeme	=> systeme,
		region	=> region,
		vdp_enables   => vdp_enables,
		psg_enables   => psg_enables,
		se_mapper_in  => mapper_in(7 downto 0),
		se_mapper_set => mapper_set,
		io_state_out  => io_state_out_i,
		io_state_in   => io_state_in,
		io_state_set  => io_state_set,
		mapper_evolution_force => mapper_evolution,
		evolution_menu_io => evolution_io_port,
		evolution_bank61 => evolution_bank61,
		evolution_bank62 => evolution_bank62,
		evolution_reg8c => evolution_8c,
		evolution_regcd => evolution_cd,
		evolution_reg63 => evolution_63,
		evolution_reg88 => evolution_88,
		evolution_reg8d => evolution_8d,
		evolution_reg8e => evolution_8e,
		evolution_reg8f => evolution_8f,
		ss_freeze     => ss_freeze,
		RESET_n	=> RESET_n
	);
	
	ce_z80 <= '0' when se_pause='1' else
	          ce_pix when (systeme = '1' or turbo='1') else ce_cpu;
	io_cycle <= '1' when IORQ_n='0' and M1_n='1' else '0';
	-- Only ports demonstrated by the menu ROM and implemented by the
	-- Evolution mapper are exclusive. $A0 remains a mirrored VDP data port.
	-- The menu also writes $06 once to $89 as board configuration; suppress
	-- that write at the VDP below, but do not expose an invented readable
	-- Evolution register (the ROM never reads $89).
	evolution_io_port <= '1' when evolution_menu_mode='1' and
		(A(7 downto 0)=x"61" or A(7 downto 0)=x"62" or A(7 downto 0)=x"63" or
		 A(7 downto 0)=x"88" or A(7 downto 0)=x"8C" or
		 A(7 downto 0)=x"8D" or A(7 downto 0)=x"8E" or
		 A(7 downto 0)=x"8F" or A(7 downto 0)=x"CD") else '0';
	z80_m1_n   <= M1_n;
	z80_mreq_n <= MREQ_n;
	z80_iset   <= z80_iset_int;
	-- VDP2 / PSG2 SS output port connections
	vdp2_regs_out <= vdp2_regs_out_i;
	vdp2_cram_out <= vdp2_cram_out_i;
	ss_vram2_D    <= vdp2_vram_D_i;
	psg2_out      <= psg2_out_i;
	io_upper_port <= '1' when A(7 downto 6)="11" else '0';
	io_sms_port <= '1' when A(7 downto 6)="00" and (A(0)='1' or (effective_gg='1' and A(5 downto 3)="000")) else '0';
	io_gg_port <= '1' when effective_gg='1' and A(7 downto 3)="00000" and A(2 downto 1)/="11" else '0';
	io_gg_data_port <= '1' when effective_gg='1' and A(7 downto 3)="00000" and A(2 downto 0)/="111" else '0';
	io_systeme_port <= '1' when io_upper_port='1' and systeme='1' else '0';
	io_sc_mode <= '1' when gg='0' and systeme='0' and (sc3000_en='1' or sk1100_en='1') else '0';
	io_sc_ppi_port <= '1' when A(7 downto 5)="110" and io_sc_mode='1' else '0';
	io_sc_legacy_port <= '1' when (A(7 downto 0)=x"DE" or A(7 downto 0)=x"DF") and palettemode='1' and gg='0' and systeme='0' else '0';
	io_sc_mc_port <= '1' when A(7 downto 5)="111" and sc_multicart_en='1' and gg='0' and systeme='0' else '0';

	sc_cart_ram_32k <= '1' when (sc3000_en='1' and sc_cart_ram="11") or mapper_castle='1' else '0';
	sc_cart_ram_low <= '1' when ((sc3000_en='1' and sc_cart_ram/="00") or mapper_castle='1') and A(15 downto 14)="10" else '0';
	sc_cart_ram_high <= '1' when sc_cart_ram_32k='1' and A(15 downto 14)="11" else '0';
	sc_cart_ram_rd <= sc_cart_ram_low or sc_cart_ram_high;
	sc_multicart_upper <= '1' when sc_multicart_en='1' and A(15)='1' else '0';
	sc_multicart_open <= '1' when sc_multicart_en='1' and A(15 downto 14)="10" and sc_cart_ram="00" else '0';

	ram_a <= "000" & A(10 downto 0) when sc3000_en = '1' else
	         A(13 downto 0) when systeme = '1' else
	         '0' & A(12 downto 0);
	ram_we <= ram_WR;
	ram_d <= D_in;
	ram_D_out <= ram_q;

	eeprom_enabled <= mapper_eeprom;

	-- SC-3000 selector values are exposed to the user as total main RAM:
	-- 00=2KB base machine, 01=4KB total (2KB cart), 10=18KB total (16KB cart),
	-- 11=32KB total (32KB cart overlaying the internal 2KB window).
	nvram_a <= ("00000000" & eeprom_nvram_a)
                   when eeprom_enabled = '1' else
               "0000" & A(10 downto 0) when sc3000_en = '1' and sc_cart_ram = "01" else
               '0' & A(13 downto 0)    when sc3000_en = '1' and sc_cart_ram = "10" else
               A(14 downto 0)          when (sc3000_en = '1' and sc_cart_ram = "11") or mapper_castle = '1' else
               "00" & A(12 downto 0)   when mapper_dahjee_a = '1' else
               (nvram_p and not A(14)) & A(13 downto 0);

	nvram_we <= eeprom_nvram_we          when eeprom_enabled = '1' else nvram_WR;
	nvram_d  <= eeprom_nvram_di          when eeprom_enabled = '1' else D_in;
	nvram_D_out <= nvram_q;

	boot_rom_inst : entity work.sprom
	generic map
	(
		init_file=> BASE_DIR & "rtl/mboot.mif",
		widthad_a=> 14
	)
	port map
	(
		clock		=> clk_sys,
		address	=> A(13 downto 0),
		q			=> boot_rom_D_out
	);

	-- Temporary diagnostic aliases confirmed by the physical dump/savestates.
	-- These are not intended to become a permanent per-game database: once
	-- all outer Flash address/control lines are understood, replace this table
	-- with the equivalent mapper equation.
	evolution_game_select <= evolution_game_bank62 & evolution_game_bank61;
	evolution_menu_mode <= '1' when mapper_evolution = '1' and
	                                evolution_3ffe /= x"87" and
	                                evolution_3ffe /= x"97" and
	                                evolution_3ffe /= x"C7" else '0';
	-- Record $2638 (Sonic Drift 2) is the sole game record in the flash image
	-- that programs this board configuration.  It selects the clone's Game
	-- Gear-compatible CRAM and I/O behavior while retaining TV-sized output.
	evolution_gg_mode <= '1' when mapper_evolution = '1' and
	                              evolution_menu_mode = '0' and
	                              evolution_8d = x"47" and
	                              evolution_8e = x"00" and
	                              evolution_8f = x"36" and
	                              evolution_63 = x"18" else '0';
	-- Menu/service space also uses the clone VDP's 12-bit CRAM, but retains
	-- Evolution/SMS controller I/O. Keep the two hardware modes independent.
	effective_vdp_gg <= gg or evolution_gg_mode or
	                    (mapper_evolution and not evolution_3ffe(1));
	effective_gg <= gg or evolution_gg_mode;
	evolution_gg_active <= evolution_gg_mode;
	-- Some patched interrupt handlers restore a selector with A21 asserted.
	-- Resolve confirmed selector collisions while leaving standalone launches
	-- of the corresponding upper pages intact.
	evolution_effective_game_select <=
		x"2800" when evolution_game_select = x"4800" and evolution_3ffe = x"97" else
		-- The menu records are 16 bytes and follow physical-ROM order.  Use
		-- their read address only where two games share the same final selector.
		x"2C00" when evolution_game_select = x"4C00" and
		                 evolution_launch_fetch_addr = x"20B8" else
		x"2E00" when evolution_game_select = x"4E00" and
		                 evolution_launch_fetch_addr = x"20C8" else
		x"3200" when evolution_game_select = x"5200" and
		                 evolution_launch_fetch_addr = x"20D8" else
		x"A880" when evolution_game_select = x"6800" and
		                 evolution_launch_fetch_addr = x"2358" else
		x"2800" when evolution_game_select = x"4800" and
		                 (evolution_prev_game_bank62 & evolution_prev_game_bank61) = x"2800" else
		evolution_game_select;
	with evolution_effective_game_select select evolution_selector_page <=
		x"0180" when x"2180", -- timeout demo cycle: Color and Switch Test
		x"01C0" when x"21C0", -- timeout demo cycle: Sonic
		x"1040" when x"3040", -- Bonanza Bros.
		x"1640" when x"5640", -- Alex Kidd in Miracle World
		x"1C40" when x"5C40", -- Action Fighter
		x"2000" when x"4000", -- Aerial Assault
		x"2400" when x"2400", -- Alex Kidd: The Lost Stars
		x"2800" when x"2800", -- Alex Kidd in Shinobi World
		x"2C00" when x"2C00", -- Alex Kidd High Tech World
		x"3200" when x"3200", -- Aztec Adventure
		x"3400" when x"5400", -- Baku Baku Animal
		x"3800" when x"5800", -- Battle Out Run
		x"4200" when x"4200", -- Bubble Bobble
		x"4600" when x"4600", -- Taito Chase H.Q.
		x"4800" when x"4800", -- Cyber Shinobi
		x"4800" when x"6800", -- Cyber Shinobi launch selector
		x"4C00" when x"4C00", -- Dragon Crystal
		x"4E00" when x"4E00", -- Double Target
		x"5000" when x"5000", -- Enduro Racer
		x"5200" when x"5200", -- ESWAT
		x"0DC0" when x"4DC0", -- Columns
		x"CF80" when x"8F80", -- Dr. Limpeza
		x"B980" when x"9980", -- Bank Panic
		x"D440" when x"9440", -- Aquaduto
		x"D540" when x"9540", -- Bombeiros
		x"DCC0" when x"BCC0", -- Bolas e Cores
		x"DE00" when x"BE00", -- Acerte o Alvo
		x"E100" when x"A100", -- Arqueiro
		x"E000" when x"A000", -- Domine o Territorio
		x"E540" when x"A540", -- Cava Cava
		x"A000" when x"6000", -- Satellite 7
		x"E200" when x"A200", -- Ataque dos Vermes
		(evolution_game_bank62(7) &
		 not (evolution_game_bank61(7) xor evolution_game_bank62(6)) &
		 (evolution_game_bank61(6) xor evolution_game_bank61(7) xor
		  evolution_game_bank62(0) xor evolution_game_bank62(5) xor
		  evolution_game_bank62(6) xor evolution_game_bank62(7)) &
		 evolution_game_bank62(4 downto 0) & evolution_game_bank61) when others;

	-- Normal menu launches use the authoritative record-index table.  Keep the
	-- reverse-engineered selector path as a fallback for service transitions or
	-- malformed/unrecognised records.
	evolution_game_page <= evolution_record_page(
		evolution_launch_fetch_addr, evolution_selector_page);

	-- Drive the captured game base plus the cartridge-relative Sega address.
	rom_a <= std_logic_vector(
		unsigned(evolution_game_page & x"00") +
		-- Individual cartridges in the image decode at most six Sega bank
		-- bits (1 MB).  Bits 7:6 written by games are not physical ROM lines.
		resize(unsigned(rom_a_i(19 downto 0)), 24))
		when mapper_evolution = '1' and
		     (evolution_3ffe = x"87" or evolution_3ffe = x"97" or
		      evolution_3ffe = x"C7") else
		std_logic_vector(resize(unsigned(rom_a_i), 24));

	-- External BIOS RAM: up to 256KB, written only during BIOS file download (BIOSWEN)
	-- Read address uses rom_a_i (mapper-translated) so banking works correctly.
	-- The Zemina mapper is gated off during BIOS execution (see rom_a_i process),
	-- so large banked BIOSes (e.g. Korean) use the standard Sega mapper here.
	ext_bios_wren <= BIOSWEN;
	ext_bios_addr <= ROMAD(17 downto 0) when BIOSWEN='1' else rom_a_i(17 downto 0);

	ext_bios_inst : entity work.spram
	generic map
	(
		widthad_a=> 18
	)
	port map
	(
		clock		=> clk_sys,
		address	=> ext_bios_addr,
		wren		=> ext_bios_wren,
		data		=> ROMDT,
		q			=> ext_bios_D_out
	);	

	ext_gg_bios_wren <= GG_BIOSWEN;
	ext_gg_bios_addr <= ROMAD(13 downto 0) when GG_BIOSWEN='1' else A(13 downto 0);


	ext_gg_bios_inst : entity work.spram
	generic map
	(
		widthad_a => 14
	)
	port map
	(
		clock   => clk_sys,
		address => ext_gg_bios_addr,
		wren    => ext_gg_bios_wren,
		data    => ROMDT,
		q       => ext_gg_bios_D_out
	);
	mc8123_inst : component MC8123_rom_decrypt
	port map
	(
		clk		=> clk_sys,
		m1			=> not M1_n,
		a			=> A,
		d			=> mc8123_D_out,
		prog_d	=> rom_do,
		key_a		=> key_a,
		key_d		=> key_d
	);
	
	segadect2_inst : component SEGASYS1_DECT2
	port map
	(
		clk		=> clk_sys,
		mrom_m1	=> not M1_n,
		mrom_ad	=> A(14 downto 0),
		mrom_dt	=> segadect2_D_out,
--		rad      =>,
		rdt		=> rom_do,
		ROMCL		=> ROMCL,
		ROMAD		=> ROMAD,
		ROMDT		=> ROMDT,
		ROMEN		=> ROMEN
	);
	
	-- -----------------------------------------------------------------------
	-- GG EEPROM cartridge mapper instance
	-- -----------------------------------------------------------------------
	cart_eeprom_inst : entity work.cart_eeprom
		port map (
			clk_sys    => clk_sys,
			ce_cpu     => ce_cpu,
			reset_n    => RESET_n,
			soft_reset => eeprom_soft_reset,
			A          => A,
			D_in       => D_in,
			D_out      => eeprom_D_out,
			WR_n       => WR_n,
			RD_n       => RD_n,
			MREQ_n     => MREQ_n,
			M1_n       => M1_n,
			enabled    => eeprom_enabled,
			mapper_eeprom => mapper_eeprom,
			bus_active => eeprom_bus_active,
			nvram_a    => eeprom_nvram_a,
			nvram_di   => eeprom_nvram_di,
			nvram_do   => nvram_q,
			nvram_we   => eeprom_nvram_we,
			ss_out     => eeprom_ss_out_i,
			ss_in      => eeprom_ss_in,
			ss_set     => eeprom_ss_set
		);

	eeprom_ss_out <= eeprom_ss_out_i;
	mapper_eeprom_out <= mapper_eeprom;

	-- glue logic
	bal_WR_n <= WR_n when IORQ_n='0' and M1_n='1' and A(7 downto 0)="00000110" and effective_gg='1' else '1';
	vdp_WR_n <= WR_n when IORQ_n='0' and M1_n='1' and evolution_io_port='0' and
	                         not (evolution_menu_mode='1' and A(7 downto 0)=x"89") and
	                         A(7 downto 6)="10" and (A(2)='0' or systeme='0') else '1';
	vdp2_WR_n <= WR_n when IORQ_n='0' and M1_n='1' and A(7 downto 6)="10" and (A(2)='1' and systeme='1')  else '1';
	vdp_RD_n <= RD_n when IORQ_n='0' and M1_n='1' and evolution_io_port='0' and (A(7 downto 6)="01" or A(7 downto 6)="10") and (A(2)='0' or systeme='0') else '1';
	vdp2_RD_n <= RD_n when IORQ_n='0' and M1_n='1' and (A(7 downto 6)="01" or A(7 downto 6)="10") and (A(2)='1' and systeme='1') else '1';
	psg_WR_n <= WR_n when IORQ_n='0' and M1_n='1' and evolution_io_port='0' and A(7 downto 6)="01" and (A(2)='0' or systeme='0') else '1';
	psg2_WR_n <= WR_n when IORQ_n='0' and M1_n='1' and A(7 downto 6)="01" and (A(2)='1' and systeme='1') else '1';
	ctl_WR_n <=	WR_n when IORQ_n='0' and M1_n='1' and A(7 downto 6)="00" and A(0)='0' else '1';
	io_WR_n  <=	WR_n when io_cycle='1' and
		(
			io_sms_port='1' or
			io_systeme_port='1' or
			io_sc_mc_port='1' or
			io_sc_ppi_port='1' or
			io_sc_legacy_port='1'
		)
	else '1';
	io_RD_n  <=	RD_n when io_cycle='1' and
		(
			(io_upper_port='1' and io_sc_mode='0') or
			io_sc_ppi_port='1' or
			io_gg_port='1' or
			evolution_io_port='1'
		)
	else '1';
	fm_WR_n  <= WR_n when IORQ_n='0' and M1_n='1' and A(7 downto 1)="1111000" and mapper_evolution='0' else '1';
	det_WR_n <= WR_n when IORQ_n='0' and M1_n='1' and A(7 downto 0)=x"F2" and mapper_evolution='0' else '1';
	IRQ_n <= vdp_IRQ_n when systeme='0' else vdp2_IRQ_n;
					
	ram_WR   <= not WR_n when ss_freeze = '0' and MREQ_n='0' and A(15 downto 14)="11" and sc_cart_ram_32k='0' else '0';
	vram_WR  <= not WR_n when ss_freeze = '0' and MREQ_n='0' and A(15 downto 14)="10" and vdp_cpu_bank='1' and systeme='1' else '0';
	vram2_WR  <= not WR_n when ss_freeze = '0' and MREQ_n='0' and A(15 downto 14)="10" and vdp_cpu_bank='0' and systeme='1' else '0';
	nvram_WR <= not WR_n when ss_freeze = '0' and MREQ_n='0' and mapper_eeprom = '0' and (((A(15 downto 14)="10" and nvram_e = '1')
						or (A(15 downto 14)="11" and nvram_ex = '1') 
						or (A(15 downto 13)="101" and nvram_cme = '1'))
						or sc_cart_ram_low='1'
						or sc_cart_ram_high='1'
						or (mapper_dahjee_a='1' and A(15 downto 13)="001")) else '0';
	rom_RD   <= not RD_n when MREQ_n='0' and A(15 downto 14)/="11" and sc_multicart_upper='0'
	                     and not (mapper_castle='1' and A(15)='1')
	                     and not (mapper_dahjee_a='1' and A(15 downto 13)="001") else '0';
	color    <= vdp2_color when (vdp2_y1='1' and systeme='1' and vdp_enables(1)='0') else vdp_color when vdp_enables(0)='0' else x"000";

	active_bios <= '1' when (bios_en = '1' and (ext_bios_sel = '0' or ext_bios_loaded = '1')) or (gg_bios_en = '1' and ext_gg_bios_loaded = '1') else '0';

	-- Only cartridge visibility currently affects emulation. Preserve it in the
	-- spare IO state bit; older states stored zero here (cartridge enabled).
	io_state_out <= media_control(6) & io_state_out_i(30 downto 0);
	process (clk_sys)
	begin
		if rising_edge(clk_sys) then
			if RESET_n='0' then
				-- Cartridge precedence must not bypass the BIOS at reset.
				if bios_en='1' and gg='0' and
				   ext_bios_sel='1' and ext_bios_loaded='1' then
					media_control <= "111";
				else
					media_control <= "101";
				end if;
			elsif mapper_set='1' then
				-- Legacy states without IO retain cartridge-enabled behavior.
				media_control <= "101";
			elsif io_state_set='1' then
				-- Card/expansion have no backing media or emulated state yet.
				media_control <= '1' & io_state_in(31) & '1';
			elsif ss_freeze='0' and ctl_WR_n='0' and A(7 downto 0)=x"3E" then
				media_control <= D_in(7 downto 5);
			end if;
		end if;
	end process;

	process (clk_sys)
	begin
		if rising_edge(clk_sys) then
			if RESET_n='0' then 
				bootloader_n <= not active_bios;
			elsif mapper_set='1' then
				-- Save-state restore: recover exact bootloader_n captured at save time.
				-- Without this, restoring a cart game saved while BIOS was active but
				-- disabled (bootloader_n=1) would leave bootloader_n=0 (reset default)
				-- so the Z80 would read BIOS ROM instead of cart ROM → instant crash.
				if mapper_evolution = '1' and
				   evolution_ss_in(31 downto 16) = x"E132" then
					-- Evolution repurposes the mapper word for its launch record.
					-- The flash image is already the active cartridge at restore time.
					bootloader_n <= '1';
				else
					bootloader_n <= mapper_in(54);
				end if;
			elsif ss_freeze = '0' and ctl_WR_n='0' then
				if (ext_bios_sel='1' and ext_bios_loaded='1') or
				   (gg_bios_en='1' and ext_gg_bios_loaded='1') then
					-- For external BIOS: honour port $3E bit 3 ONLY when the CPU
					-- actually writes to port $3E (Memory Control).
					-- ctl_WR_n fires for ALL even-addressed I/O in $00-$3F range,
					-- including port $02 (GG serial DDR). The GG BIOS writes $FA
					-- ($FA bit3=1) to port $02 during SMS/GG mode detection, which
					-- would incorrectly set bootloader_n=1 and corrupt BIOS execution.
					if A(7 downto 0) = x"3E" then
						bootloader_n <= D_in(3);
					end if;
				elsif bootloader_n='0' then
					-- Internal BIOS (mboot.mif): any write disables BIOS, original behaviour
					bootloader_n <= '1';
				end if;
			end if;
		end if;
	end process;

	-- Reset the mapper to default state whenever the BIOS hands control to the
	-- cartridge (bootloader_n goes 0->1 via port $3E). Merged into the mapper
	-- process below to avoid multiple drivers on the bank registers.

	-- When ext BIOS is active and BIOS ROM is enabled (bootloader_n=0):
	-- serve all ROM banks (0, 1, 2) from SPRAM so the full 256KB BIOS can run.
	-- When BIOS ROM is disabled (bootloader_n=1, triggered by port $3E bit3=1):
	-- serve SDRAM only when the cartridge is selected; card/expansion probes
	-- see an empty slot. The BIOS then re-enables itself (bit3=0) if no
	-- valid cart is found, causing bootloader_n to go back to 0, and JP $0000
	-- will fall back into the SPRAM BIOS - giving the correct no-cart loop.
	active_bios_D_out <= ext_bios_D_out when (ext_bios_sel='1' and ext_bios_loaded='1') else boot_rom_D_out;

	janggun_reverse_active <=
		jang_rev1 when mapper_janggun = '1' and bootloader_n = '1' and A(15 downto 13) = "010" else
		jang_rev2 when mapper_janggun = '1' and bootloader_n = '1' and A(15 downto 13) = "011" else
		jang_rev3 when mapper_janggun = '1' and bootloader_n = '1' and A(15 downto 13) = "100" else
		jang_rev4 when mapper_janggun = '1' and bootloader_n = '1' and A(15 downto 13) = "101" else
		'0';

	-- Original Master System hardware gives cartridge data precedence when
	-- the BIOS and cartridge are enabled simultaneously. The core models
	-- this SMS1 behavior for external SMS BIOS operation.
	cart_precedence <= '1' when (gg='0' and gg_bios_en='0' and bios_en='1'
	                               and ext_bios_sel='1' and ext_bios_loaded='1' and dbr='1'
	                               and bootloader_n='0' and media_control(6)='0') else '0';

	irom_D_out <=	ext_gg_bios_D_out when (bootloader_n='0' and gg_bios_en='1' and ext_gg_bios_loaded='1' and A(15 downto 14)="00")
	               else active_bios_D_out when (bootloader_n='0' and gg_bios_en='0' and cart_precedence='0' and A(15 downto 14)="00")
	               else ext_bios_D_out when (bootloader_n='0' and gg_bios_en='0' and ext_bios_sel='1' and ext_bios_loaded='1' and cart_precedence='0' and A(15 downto 14)/="11")
	               -- External SMS BIOS media probes: port $3E bit 6 is active low.
	               else x"FF" when (bootloader_n='1' and bios_en='1' and gg='0' and gg_bios_en='0'
	                               and ext_bios_sel='1' and ext_bios_loaded='1' and media_control(6)='1')
	               -- Empty cartridge slot: data lines float high on real hardware.
	               -- Without this, SDRAM returns stale data from the last loaded ROM,
	               -- causing BIOSes that check for non-0xFF bytes (Korea) to
	               -- incorrectly detect a cartridge when none is present.
	               else x"FF" when (bootloader_n='1' and dbr='0')
	               else segadect2_D_out when (encrypt(1 downto 0)="10" and A(15)='0')
						else mc8123_D_out when (encrypt(0)='1' and A(15)='0') or (encrypt(1 downto 0)="11" and A(14)='0')
						else reverse8(rom_do) when (mapper_janggun = '1' and bootloader_n = '1' and janggun_reverse_active = '1')
						else rom_do;
	
	process (clk_sys)
	begin
		if rising_edge(clk_sys) then
			if RESET_n='0' then 
				det_D <= "111";
				PSG_mux <= x"FF";
			elsif ss_freeze = '0' and det_WR_n='0' then
				det_D <= D_in(2 downto 0);
			elsif ss_freeze = '0' and bal_WR_n='0' then
				PSG_mux <= D_in;
			end if;
		end if;
	end process;
	
		process (IORQ_n,A,vdp_D_out,vdp2_D_out,io_D_out,irom_D_out,ram_D_out,nvram_D_out,
					nvram_ex,nvram_e,nvram_cme,gg,det_D,fm_ena,bootloader_n,systeme,io_upper_port,io_gg_data_port,
					sc_cart_ram_rd,sc_multicart_open,mapper_dahjee_a,
					mapper_eeprom,eeprom_enabled,eeprom_D_out,eeprom_bus_active,MREQ_n,evolution_io_port)
	begin
		if IORQ_n='0' then
			if A(7 downto 0)=x"F2" and fm_ena = '1' and systeme='0' and mapper_evolution='0' then
				D_out <= "11111"&det_D;
			elsif evolution_io_port='1' then
				D_out <= io_D_out;
			elsif io_upper_port='1' or io_gg_data_port='1' then
				D_out(6 downto 0) <= io_D_out(6 downto 0);
				-- during bootload, we trick the io ports so bit 7 indicates gg or sms game
				if (bootloader_n='0') then
					D_out(7) <= gg;
				else
					D_out(7) <= io_D_out(7);
				end if;
			elsif (A(2)='1' and systeme='1') then
				D_out <= vdp2_D_out;
			else
				D_out <= vdp_D_out;
			end if;
		else
			if eeprom_bus_active = '1' then
				D_out <= eeprom_D_out;
			elsif sc_cart_ram_rd='1' then
				D_out <= nvram_D_out;
			elsif sc_multicart_open='1' then
				D_out <= x"FF";
			elsif A(15 downto 14)="11" and nvram_ex = '1' then
				D_out <= nvram_D_out;
			elsif A(15 downto 14)="11" and nvram_ex = '0' then
				D_out <= ram_D_out;
			elsif A(15 downto 13)="101" and nvram_cme  = '1' then
				D_out <= nvram_D_out;
			elsif A(15 downto 14)="10" and nvram_e  = '1' then
				D_out <= nvram_D_out;
			elsif mapper_dahjee_a = '1' and A(15 downto 13) = "001" then
				-- Dahjee Type A: RAM at 0x2000-0x3FFF reads from nvram block
				D_out <= nvram_D_out;
			else
				D_out <= irom_D_out;
			end if;
		end if;
	end process;

	-- detect MSX mapper : we check the two first bytes of the rom, must be 41:42
	process (RESET_n, clk_sys)
	begin
		if RESET_n='0' then
			mapper_msx_check0 <= false ;
			mapper_msx_check1 <= false ;
			mapper_msx_lock0 <= false ;
			mapper_msx_lock <= false ;
			mapper_msx <= '0' ;
		else
			if rising_edge(clk_sys) then
				if mapper_set = '1' then
					if mapper_evolution = '1' and
					   evolution_ss_in(31 downto 16) = x"E132" then
						-- Evolution's record address occupies the generic mapper flag
						-- bits; never interpret it as an MSX mapper selection.
						mapper_msx <= '0';
						mapper_msx_lock <= false;
						mapper_msx_lock0 <= false;
						mapper_msx_check0 <= false;
						mapper_msx_check1 <= false;
					elsif mapper_in(56) = '1' then
						mapper_msx <= '1';
						mapper_msx_lock <= true;
						mapper_msx_lock0 <= true;
					else
						mapper_msx <= '0';
						mapper_msx_lock <= false;
						mapper_msx_lock0 <= false;
						mapper_msx_check0 <= false;
						mapper_msx_check1 <= false;
					end if;
				elsif ss_freeze = '0' and bootloader_n='1' and sc3000_en='0' and mapper_wonderkid='0' and not mapper_msx_lock then
					if MREQ_n='0' then 
					-- in this state, A is stable but not D_out
						if A=x"0000" then
							mapper_msx_check0 <= (D_out=x"41") ;
						elsif A=x"0001" then
							mapper_msx_check1 <= (D_out=x"42") ;
							mapper_msx_lock0 <= true ;
						end if;
					else
					-- this state is similar to old_MREQ_n
					-- now we can lock values depending on D_out
						if mapper_msx_check0 and mapper_msx_check1 then
							mapper_msx <= '1'; -- if 4142 lock msx mapper on
						end if;
						-- be paranoid : give only 1 chance to the mapper to lock on
						mapper_msx_lock <= mapper_msx_lock0 ; 
					end if;
				end if;
			end if;
		end if;
	end process;
	
	mapper_banking : entity work.mapper_ctrl
		port map (
			RESET_n => RESET_n,
			clk_sys => clk_sys,
			evolution_game_launch => evolution_game_launch,
			mapper_set => mapper_set,
			mapper_evolution => mapper_evolution,
			evolution_ss_in => evolution_ss_in,
			mapper_in => mapper_in,
			mapper_janggun => mapper_janggun,
			systeme => systeme,
			bootloader_n => bootloader_n,
			mapper_wonderkid => mapper_wonderkid,
			mapper_lock => mapper_lock,
			detect_codies_static => detect_codies_static,
			mapper_codies_force => mapper_codies_force,
			mapper_eeprom => mapper_eeprom,
			mapper_zemina_force => mapper_zemina_force,
			mapper_nemesis_auto => mapper_nemesis_auto,
			rom_size_pages => rom_size_pages,
			ce_z80 => ce_z80,
			WR_n => WR_n,
			MREQ_n => MREQ_n,
			A => A,
			ss_freeze => ss_freeze,
			D_in => D_in,
			sc3000_en => sc3000_en,
			mapper_castle => mapper_castle,
			mapper_linear => mapper_linear,
			mapper_dahjee_a => mapper_dahjee_a,
			mapper_sega_locked => mapper_sega_locked,
			use_zem => use_zem,
			mapper_manual_force => mapper_manual_force,
			sega_mapper_write_seen => sega_mapper_write_seen,
			bank0_out => bank0,
			bank1_out => bank1,
			bank2_out => bank2,
			bank3_out => bank3,
			jang_bank1_out => jang_bank1,
			jang_bank2_out => jang_bank2,
			jang_bank3_out => jang_bank3,
			jang_bank4_out => jang_bank4,
			jang_rev1_out => jang_rev1,
			jang_rev2_out => jang_rev2,
			jang_rev3_out => jang_rev3,
			jang_rev4_out => jang_rev4,
			nvram_e_out => nvram_e,
			nvram_ex_out => nvram_ex,
			nvram_p_out => nvram_p,
			nvram_cme_out => nvram_cme,
			lock_mapper_B_out => lock_mapper_B,
			mapper_codies_out => mapper_codies,
			mapper_codies_lock_out => mapper_codies_lock,
			mapper_4pak_out => mapper_4pak,
			pak4_reg2_out => pak4_reg2,
			nem_bank0_out => nem_bank0,
			eeprom_soft_reset_out => eeprom_soft_reset
		);

	-- 4-PAK auto-detection is write-based only ($3FFE first-write pattern).

	-- Save-state: pack all mapper state into one 64-bit word.
	-- [63]detect_linear [62]detect_wonderkid [61]detect_castle [60]mapper_codies_lock
	-- [59]lock_mapper_B [58]mapper_codies [57]mapper_4pak [56]spare
	-- [55]detect_zemina_static [54]bootloader_n [53]nvram_cme [52]nvram_p [51]nvram_ex [50]nvram_e
	-- [49]detect_sega_locked [48]detect_dahjee_a [47:40]nem_bank0 [39:32]pak4_reg2
	-- [31:24]bank3 [23:16]bank2 [15:8]bank1 [7:0]bank0
	-- Note: when systeme='1', bits [7:0] mirror IO port 0xF7:
	--   [7]=vdp_se_bank [6]=vdp2_se_bank [5]=vdp_cpu_bank [3:0]=rom_bank
	-- Evolution operational layout: [63:48] menu record address,
	-- [47:40] bank0, [39:32] bank1, [31:24] bank2, [23:16] bank3,
	-- [15:8] active $3FFE mode, [7:0] current $61 latch.
	-- Remaining board latches are stored in the dedicated extra header fields.
	mapper_out(63 downto 8) <=
	              evolution_launch_fetch_addr & bank0 & bank1 & bank2 & bank3 & evolution_3ffe
	              when mapper_evolution = '1' else
	              detect_linear & detect_wonderkid & detect_castle & mapper_codies_lock &
	              lock_mapper_B & mapper_codies & mapper_4pak & mapper_msx &
	              detect_zemina_static & bootloader_n & nvram_cme & nvram_p & nvram_ex & nvram_e &
	              detect_sega_locked & detect_dahjee_a &
	              x"0000" &
	              jang_rev4 & "0" & jang_bank4 &
	              jang_rev3 & "0" & jang_bank3 &
	              jang_rev2 & "0" & jang_bank2 when mapper_janggun = '1' else
	              detect_linear & detect_wonderkid & detect_castle & mapper_codies_lock &
	              lock_mapper_B & mapper_codies & mapper_4pak & mapper_msx &
	              detect_zemina_static & bootloader_n & nvram_cme & nvram_p & nvram_ex & nvram_e &
	              detect_sega_locked & detect_dahjee_a &
	              nem_bank0 & pak4_reg2 & bank3 & bank2 & bank1;

	mapper_out(7 downto 0) <= evolution_bank61 when mapper_evolution = '1' else
	                          vdp_se_bank & vdp2_se_bank & vdp_cpu_bank & '0' & rom_bank when systeme='1' else
	                          jang_rev1 & "0" & jang_bank1 when mapper_janggun = '1' else
	                          bank0;


	rom_a_i(12 downto 0) <= A(12 downto 0);
	process (A,bank0,bank1,bank2,bank3,use_zem,nem_bank0,mapper_4pak,mapper_codies,systeme,sc3000_en,sc_multicart_en,sc_multicart_page,rom_bank,bootloader_n,mapper_linear,mapper_dahjee_a,
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
		elsif sc3000_en = '1' or mapper_linear = '1' or mapper_dahjee_a = '1' then
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

end Behavioral;
