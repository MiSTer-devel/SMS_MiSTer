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

		GG_EN		: in std_logic; -- Game Genie not game gear
		GG_CODE		: in std_logic_vector(128 downto 0); -- game genie code
		GG_RESET	: in std_logic;
		GG_AVAIL	: out std_logic;

		RESET_n:		in	 STD_LOGIC;

		rom_rd:  	out STD_LOGIC;
		rom_a:		out STD_LOGIC_VECTOR(21 downto 0);
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
		color:		out STD_LOGIC_VECTOR(11 downto 0);
		palettemode:	in	STD_LOGIC;
		mask_column:out STD_LOGIC;
		black_column:		in STD_LOGIC;
		smode_M1:		out STD_LOGIC;
		smode_M2:		out STD_LOGIC;
		smode_M3:		out STD_LOGIC;
		ysj_quirk:		in	STD_LOGIC;
		pal:				in STD_LOGIC;
		region:			in	STD_LOGIC;
		mapper_lock:	in STD_LOGIC;
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
		BIOSWEN: IN  STD_LOGIC

	);
end system;

architecture Behavioral of system is
	
	signal RD_n:				std_logic;
	signal WR_n:				std_logic;
	signal IRQ_n:				std_logic;
	signal IORQ_n:				std_logic;
	signal M1_n:				std_logic;
	signal MREQ_n:				std_logic;
	signal A:					std_logic_vector(15 downto 0);
	signal D_in:				std_logic_vector(7 downto 0);
	signal D_out:				std_logic_vector(7 downto 0);
	signal last_read_addr:  std_logic_vector(15 downto 0);
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
	signal rom_a_i:         std_logic_vector(21 downto 0);

	signal bootloader_n:	std_logic := '0';
	signal irom_D_out:		std_logic_vector(7 downto 0);
	signal irom_RD_n:			std_logic := '1';

	signal bank0:				std_logic_vector(7 downto 0) := "00000000";
	signal bank1:				std_logic_vector(7 downto 0) := "00000001";
	signal bank2:				std_logic_vector(7 downto 0) := "00000010";
	signal bank3:				std_logic_vector(7 downto 0) := "00000011";
  
	signal vdp_se_bank:		std_logic := '0';
	signal vdp2_se_bank:		std_logic := '0';
	signal vdp_cpu_bank:		std_logic := '0';
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
	signal nvram_e:         std_logic := '0';
	signal nvram_ex:        std_logic := '0';
	signal nvram_p:         std_logic := '0';
	signal nvram_cme:       std_logic := '0'; -- codemasters ram extension
	signal nvram_D_out:     std_logic_vector(7 downto 0);
	
	signal lock_mapper_B:	std_logic := '0';
	signal mapper_codies:	std_logic := '0'; -- Ernie Els Golf mapper
	signal mapper_codies_lock:	std_logic := '0'; 
	
	signal mapper_msx_check0 : boolean := false ;
	signal mapper_msx_check1 : boolean := false ;
	signal mapper_msx_lock0 :  boolean := false ;
	signal mapper_msx_lock :   boolean := false ;
	signal mapper_msx :		   std_logic := '0' ;

	signal mc8123_D_out    : std_logic_vector(7 downto 0);
	signal segadect2_D_out : std_logic_vector(7 downto 0);

	signal GENIE		: boolean;
	signal GENIE_DO	: std_logic_vector(7 downto 0);
	signal GENIE_DI   : std_logic_vector(7 downto 0);

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
		NMI_n		=> pause or gg,
		MREQ_n	=> MREQ_n,
		IORQ_n	=> IORQ_n,
		M1_n		=> M1_n,
		RD_n		=> RD_n,
		WR_n		=> WR_n,
		A			=> A,
		DI			=> GENIE_DI,
		DO			=> D_in
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
		sp64		=> sp64,
		HL			=> HL,
		gg			=> gg,
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
		color		=> vdp_color,
		palettemode	=> palettemode,
--		y1       => vdp_y1,
		smode_M1  => smode_M1,
		smode_M2  => smode_M2,
		smode_M3  => smode_M3,
		ysj_quirk	=> ysj_quirk,
		mask_column => mask_column,
		black_column => black_column,
		reset_n  => RESET_n
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
		gg			=> gg,
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
		color		=> vdp2_color,
		palettemode	=> palettemode,
		y1       => vdp2_y1,
--		smode_M1  => smode2_M1,
--		smode_M2  => smode2_M2,
--		smode_M3  => smode2_M3,
		ysj_quirk	=> ysj_quirk,
--		mask_column => mask2_column,
		black_column => black_column,
		reset_n  => RESET_n
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

		rst		=> not RESET_n
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

		rst		=> not RESET_n
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
			elsif fm_WR_n='0' then
				fm_d <= D_in;
				fm_a <= A(0);
			end if;
		end if;
	end process;
	
	
-- AMR - Clamped volume boosting - if the top two bits match, truncate the topmost bit.
-- If the top two bits don't match, duplicate the second bit across the output.

FM_gated <= (others=>'0') when fm_ena='0' or det_D(0)='0' else  -- All zero if FM is disabled
				FM_out(FM_out'high-1 downto 0) when FM_sign=FM_adj else -- Pass through
				(FM_gated'high=>FM_sign,others=>FM_adj); -- Clamp

PSG_disable <= '1' when (systeme='0' and fm_ena='1' and (not det_D(1)=det_D(0))) else '0';
				 
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
		gg			=> gg,
		systeme	=> systeme,
		region	=> region,
		RESET_n	=> RESET_n
	);
	
	ce_z80 <= ce_pix when (systeme = '1' or turbo='1') else ce_cpu;
	io_cycle <= '1' when IORQ_n='0' and M1_n='1' else '0';
	io_upper_port <= '1' when A(7 downto 6)="11" else '0';
	io_sms_port <= '1' when A(7 downto 6)="00" and (A(0)='1' or (gg='1' and A(5 downto 3)="000")) else '0';
	io_gg_port <= '1' when gg='1' and A(7 downto 3)="00000" and A(2 downto 1)/="11" else '0';
	io_gg_data_port <= '1' when gg='1' and A(7 downto 3)="00000" and A(2 downto 0)/="111" else '0';
	io_systeme_port <= '1' when io_upper_port='1' and systeme='1' else '0';
	io_sc_mode <= '1' when gg='0' and systeme='0' and (sc3000_en='1' or sk1100_en='1') else '0';
	io_sc_ppi_port <= '1' when A(7 downto 5)="110" and io_sc_mode='1' else '0';
	io_sc_legacy_port <= '1' when (A(7 downto 0)=x"DE" or A(7 downto 0)=x"DF") and palettemode='1' and gg='0' and systeme='0' else '0';
	io_sc_mc_port <= '1' when A(7 downto 5)="111" and sc_multicart_en='1' and gg='0' and systeme='0' else '0';

	sc_cart_ram_32k <= '1' when sc3000_en='1' and sc_cart_ram="11" else '0';
	sc_cart_ram_low <= '1' when sc3000_en='1' and sc_cart_ram/="00" and A(15 downto 14)="10" else '0';
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

	-- SC-3000 selector values are exposed to the user as total main RAM:
	-- 00=2KB base machine, 01=4KB total (2KB cart), 10=18KB total (16KB cart),
	-- 11=32KB total (32KB cart overlaying the internal 2KB window).
	nvram_a <= "0000" & A(10 downto 0) when sc3000_en = '1' and sc_cart_ram = "01" else
	           '0' & A(13 downto 0) when sc3000_en = '1' and sc_cart_ram = "10" else
	           A(14 downto 0) when sc3000_en = '1' and sc_cart_ram = "11" else
	           (nvram_p and not A(14)) & A(13 downto 0);
	nvram_we <= nvram_WR;
	nvram_d <= D_in;
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

	-- Drive the output port from the internal signal
	rom_a <= rom_a_i;

	-- External BIOS RAM: up to 256KB, written only during BIOS file download (BIOSWEN)
	-- Read address uses rom_a_i (mapper-translated) so banking works correctly
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
	
	-- glue logic
	bal_WR_n <= WR_n when IORQ_n='0' and M1_n='1' and A(7 downto 0)="00000110" and gg='1' else '1';
	vdp_WR_n <= WR_n when IORQ_n='0' and M1_n='1' and A(7 downto 6)="10" and (A(2)='0' or systeme='0') else '1';
	vdp2_WR_n <= WR_n when IORQ_n='0' and M1_n='1' and A(7 downto 6)="10" and (A(2)='1' and systeme='1')  else '1';
	vdp_RD_n <= RD_n when IORQ_n='0' and M1_n='1' and (A(7 downto 6)="01" or A(7 downto 6)="10") and (A(2)='0' or systeme='0') else '1';
	vdp2_RD_n <= RD_n when IORQ_n='0' and M1_n='1' and (A(7 downto 6)="01" or A(7 downto 6)="10") and (A(2)='1' and systeme='1') else '1';
	psg_WR_n <= WR_n when IORQ_n='0' and M1_n='1' and A(7 downto 6)="01" and (A(2)='0' or systeme='0') else '1';
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
			io_gg_port='1'
		)
	else '1';
	fm_WR_n  <= WR_n when IORQ_n='0' and M1_n='1' and A(7 downto 1)="1111000" else '1';
	det_WR_n <= WR_n when IORQ_n='0' and M1_n='1' and A(7 downto 0)=x"F2" else '1';
	IRQ_n <= vdp_IRQ_n when systeme='0' else vdp2_IRQ_n;
					
	ram_WR   <= not WR_n when MREQ_n='0' and A(15 downto 14)="11" and sc_cart_ram_32k='0' else '0';
	vram_WR  <= not WR_n when MREQ_n='0' and A(15 downto 14)="10" and vdp_cpu_bank='1' and systeme='1' else '0';
	vram2_WR  <= not WR_n when MREQ_n='0' and A(15 downto 14)="10" and vdp_cpu_bank='0' and systeme='1' else '0';
	nvram_WR <= not WR_n when MREQ_n='0' and (((A(15 downto 14)="10" and nvram_e = '1')
						or (A(15 downto 14)="11" and nvram_ex = '1') 
						or (A(15 downto 13)="101" and nvram_cme = '1'))
						or sc_cart_ram_low='1'
						or sc_cart_ram_high='1') else '0';
	rom_RD   <= not RD_n when MREQ_n='0' and A(15 downto 14)/="11" and sc_multicart_upper='0' else '0';
	color    <= vdp2_color when (vdp2_y1='1' and systeme='1' and vdp_enables(1)='0') else vdp_color when vdp_enables(0)='0' else x"000";

	process (clk_sys)
	begin
		if rising_edge(clk_sys) then
			if RESET_n='0' then 
				bootloader_n <= not bios_en;
			elsif ctl_WR_n='0' then
				if ext_bios_sel='1' and ext_bios_loaded='1' then
					-- For external BIOS: honour port $3E bit 3 (active low BIOS enable)
					-- bit3=0 -> BIOS ROM enabled -> bootloader_n=0
					-- bit3=1 -> BIOS ROM disabled (cartridge enabled) -> bootloader_n=1
					bootloader_n <= D_in(3);
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
	-- serve SDRAM (cartridge) so the BIOS detection code (running from RAM) can
	-- read the cartridge header. The BIOS then re-enables itself (bit3=0) if no
	-- valid cart is found, causing bootloader_n to go back to 0, and JP $0000
	-- will fall back into the SPRAM BIOS - giving the correct no-cart loop.
	active_bios_D_out <= ext_bios_D_out when (ext_bios_sel='1' and ext_bios_loaded='1') else boot_rom_D_out;

	irom_D_out <=	active_bios_D_out when (bootloader_n='0' and A(15 downto 14)="00")
	               else ext_bios_D_out when (bootloader_n='0' and ext_bios_sel='1' and ext_bios_loaded='1' and A(15 downto 14)/="11")
	               -- Empty cartridge slot: data lines float high on real hardware.
	               -- Without this, SDRAM returns stale data from the last loaded ROM,
	               -- causing BIOSes that check for non-0xFF bytes (Korea) to
	               -- incorrectly detect a cartridge when none is present.
	               else x"FF" when (bootloader_n='1' and dbr='0')
	               else segadect2_D_out when (encrypt(1 downto 0)="10" and A(15)='0')
						else mc8123_D_out when (encrypt(0)='1' and A(15)='0') or (encrypt(1 downto 0)="11" and A(14)='0') else rom_do;
	
	process (clk_sys)
	begin
		if rising_edge(clk_sys) then
			if RESET_n='0' then 
				det_D <= "111";
				PSG_mux <= x"FF";
			elsif det_WR_n='0' then
				det_D <= D_in(2 downto 0);
			elsif bal_WR_n='0' then
				PSG_mux <= D_in;
			end if;
		end if;
	end process;
	
	process (IORQ_n,A,vdp_D_out,vdp2_D_out,io_D_out,irom_D_out,ram_D_out,nvram_D_out,
					nvram_ex,nvram_e,nvram_cme,gg,det_D,fm_ena,bootloader_n,systeme,io_upper_port,io_gg_data_port,
					sc_cart_ram_rd,sc_multicart_open)
	begin
		if IORQ_n='0' then
			if A(7 downto 0)=x"F2" and fm_ena = '1' and systeme='0' then
				D_out <= "11111"&det_D;
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
			if    sc_cart_ram_rd='1' then
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
				if bootloader_n='1' and sc3000_en='0' and not mapper_msx_lock then
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
	
	-- external ram control
	process (RESET_n,clk_sys)
	begin
		if RESET_n='0' then
			bank0 <= "00000000";
			bank1 <= "00000001";
			bank2 <= "00000010";
			bank3 <= "00000011";
			nvram_e  <= '0';
			nvram_ex <= '0';
			nvram_p  <= '0';
			nvram_cme <= '0';
			lock_mapper_B <= '0' ;
			mapper_codies <= '0' ;
			mapper_codies_lock <= '0' ;
		else
			if rising_edge(clk_sys) then
				if WR_n='1' and MREQ_n='0' then
					last_read_addr <= A; -- gyurco anti-ldir patch
				end if;
				if systeme = '1' or sc3000_en = '1' then
					-- no System E or SC-3000 mappers
				elsif mapper_msx = '1' then
					if WR_n='0' and A(15 downto 2)="00000000000000" then
						case A(1 downto 0) is
							when "00" => bank2 <= D_in;
							when "01" => bank3 <= D_in;
							when "10" => bank0 <= D_in;
							when "11" => bank1 <= D_in ; 
						end case;
					end if ;
				else
					if WR_n='0' and A(15 downto 2)="11111111111111" then
						mapper_codies <= '0' ;
						case A(1 downto 0) is
							when "00" => 
								nvram_ex <= D_in(4);
								nvram_e  <= D_in(3);
								nvram_p  <= D_in(2);
							when "01" => bank0 <= D_in;
							when "10" => bank1 <= D_in;
							when "11" => bank2 <= D_in ; 
						end case;
					end if;
					if WR_n='0' and nvram_e='0' and mapper_lock='0' then
						case A(15 downto 0) is
				-- Codemasters
				-- do not accept writing in adr $0000 (canary) unless we are sure that Codemasters mapper is in use
							when x"0000" => 
								if (lock_mapper_B='1') then 
									bank0 <= D_in ;  
								-- we need a strong criteria to set mapper_codies, hopefully only Ernie Els Golf
								-- will have written a zero in $4000 before coming here
									if D_in /= "00000000" and mapper_codies_lock = '0' then
										if bank1 = "00000001" then
											mapper_codies <= '1' ;
										end if;
										mapper_codies_lock <= '1' ;
									end if;
								end if;
							when x"4000" => 
								if last_read_addr /= x"4000" then -- gyurco anti-ldir patch
									bank1(6 downto 0) <= D_in(6 downto 0) ;
									bank1(7) <= '0' ;
								-- mapper_codies <= mapper_codies or D_in(7) ;
									nvram_cme <= D_in(7) ;
									lock_mapper_B <= '1' ;
								end if ;
							when x"8000" => 
								if last_read_addr /= x"8000" then -- gyurco anti-ldir patch
									bank2 <= D_in ; 
									lock_mapper_B <= '1' ;
								end if;
					-- Korean mapper (Sangokushi 3, Dodgeball King)
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
			end if;
		end if;
	end process;

	rom_a_i(12 downto 0) <= A(12 downto 0);
	process (A,bank0,bank1,bank2,bank3,mapper_msx,mapper_codies,systeme,sc3000_en,sc_multicart_en,sc_multicart_page,rom_bank)
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
		elsif sc3000_en = '1' then
			-- SC-3000 cartridges are linear, unbanked images in the $0000-$BFFF space.
			-- Keep the full CPU address so 32K BASIC/Music carts don't mirror every 16K.
			rom_a_i(21 downto 16) <= (others=>'0');
			rom_a_i(15 downto 13) <= A(15 downto 13);
		elsif mapper_msx = '1' then
			case A(15 downto 13) is
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
