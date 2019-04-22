library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL; 
use work.jt89.all;

entity system is
	generic (
		MAX_SPPL : integer := 7
	);
	port (
		clk_sys:		in	 STD_LOGIC;
		ce_cpu:		in	 STD_LOGIC;
		ce_vdp:		in	 STD_LOGIC;
		ce_pix:		in	 STD_LOGIC;
		ce_sp:		in	 STD_LOGIC;
		gg:			in	 STD_LOGIC;
		bios_en:	in	 STD_LOGIC;

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
		j1_th:      out STD_LOGIC;
		j2_up:		in	 STD_LOGIC;
		j2_down:		in	 STD_LOGIC;
		j2_left:		in	 STD_LOGIC;
		j2_right:	in	 STD_LOGIC;
		j2_tl:		in	 STD_LOGIC;
		j2_tr:		in	 STD_LOGIC;
		j2_th:      out STD_LOGIC;
		pause:		in	 STD_LOGIC;

		x:				in	 STD_LOGIC_VECTOR(8 downto 0);
		y:				in	 STD_LOGIC_VECTOR(8 downto 0);
		color:		out STD_LOGIC_VECTOR(11 downto 0);
		mask_column:out STD_LOGIC;
		smode_M1:		out STD_LOGIC;
		smode_M3:		out STD_LOGIC;
		pal:				in STD_LOGIC;

		audioL:		out STD_LOGIC_VECTOR(15 downto 0);
		audioR:		out STD_LOGIC_VECTOR(15 downto 0);
		fm_ena:	   in  STD_LOGIC;

		dbr:			in  STD_LOGIC;
		sp64:			in  STD_LOGIC;

		-- Work RAM
		ram_a:      out STD_LOGIC_VECTOR(12 downto 0);
		ram_d:      out STD_LOGIC_VECTOR( 7 downto 0);
		ram_we:     out STD_LOGIC;
		ram_q:      in  STD_LOGIC_VECTOR( 7 downto 0);
		
		-- Backup RAM
		nvram_a:    out STD_LOGIC_VECTOR(14 downto 0);
		nvram_d:    out STD_LOGIC_VECTOR( 7 downto 0);
		nvram_we:   out STD_LOGIC;
		nvram_q:    in  STD_LOGIC_VECTOR( 7 downto 0)
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
	
	signal vdp_RD_n:			std_logic;
	signal vdp_WR_n:			std_logic;
	signal vdp_D_out:			std_logic_vector(7 downto 0);
	
	signal ctl_WR_n:			std_logic;
	
	signal io_RD_n:			std_logic;
	signal io_WR_n:			std_logic;
	signal io_D_out:			std_logic_vector(7 downto 0);
	
	signal ram_WR:				std_logic;
	signal ram_D_out:			std_logic_vector(7 downto 0);
	
	signal boot_rom_D_out:	std_logic_vector(7 downto 0);
	
	signal bootloader_n:	std_logic := '0';
	signal irom_D_out:		std_logic_vector(7 downto 0);
	signal irom_RD_n:			std_logic := '1';

	signal bank0:				std_logic_vector(7 downto 0) := "00000000";
	signal bank1:				std_logic_vector(7 downto 0) := "00000001";
	signal bank2:				std_logic_vector(7 downto 0) := "00000010";
  
	signal PSG_outL:			std_logic_vector(10 downto 0);
	signal PSG_outR:			std_logic_vector(10 downto 0);
	signal PSG_mux:			std_logic_vector(7 downto 0);
	signal psg_WR_n:			std_logic;
	signal bal_WR_n:			std_logic;

	signal FM_out:				std_logic_vector(13 downto 0);
	signal fm_WR_n:	   	std_logic;
	
	signal det_D:		   	std_logic_vector(2 downto 0);
	signal det_WR_n:	   	std_logic;

	signal TH_A:			std_logic;
	signal TH_B:			std_logic;

	signal nvram_WR:		   std_logic;
	signal nvram_e:         std_logic := '0';
	signal nvram_ex:        std_logic := '0';
	signal nvram_p:         std_logic := '0';
	signal nvram_D_out:     std_logic_vector(7 downto 0);
	
	signal lock_mapper_A:	std_logic := '0';
	signal lock_mapper_B:	std_logic := '0';

begin

	z80_inst: entity work.T80s
	generic map(
		T2Write => 0
	)
	port map
	(
		RESET_n	=> RESET_n,
		CLK		=> clk_sys,
		CEN		=> ce_cpu,
		INT_n		=> IRQ_n,
		NMI_n		=> pause or gg,
		MREQ_n	=> MREQ_n,
		IORQ_n	=> IORQ_n,
		M1_n		=> M1_n,
		RD_n		=> RD_n,
		WR_n		=> WR_n,
		A			=> A,
		DI			=> D_out,
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
		TH_A		=> TH_A,
		TH_B		=> TH_B,
		gg			=> gg,
		RD_n		=> vdp_RD_n,
		WR_n		=> vdp_WR_n,
		IRQ_n		=> IRQ_n,
		A			=> A(7 downto 0),
		D_in		=> D_in,
		D_out		=> vdp_D_out,
		x			=> x,
		y			=> y,
		color		=> color,
		smode_M1  => smode_M1,
		smode_M3  => smode_M3,
		mask_column => mask_column,
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
	
	fm: work.opll
   port map
	(
		xin		=> clk_sys,
		xena		=> ce_cpu,
		d        => D_in,
		a        => A(0),
		cs_n     => '0',
		we_n		=> fm_WR_n,
		ic_n		=> RESET_n,
		mixout   => FM_out
	);

	audioL <= (PSG_outL(10) & PSG_outL(10) & PSG_outL(10) & PSG_outL & "00") + (FM_out(13) & FM_out & "0") when fm_ena = '1'
	     else (PSG_outL(10) & PSG_outL(10) & PSG_outL(10) & PSG_outL & "00");
	audioR <= (PSG_outR(10) & PSG_outR(10) & PSG_outR(10) & PSG_outR & "00") + (FM_out(13) & FM_out & "0") when fm_ena = '1'
	     else (PSG_outR(10) & PSG_outR(10) & PSG_outR(10) & PSG_outL & "00");

	io_inst: entity work.io
	port map
	(
		clk		=> clk_sys,
		WR_n		=> io_WR_n,
		RD_n		=> io_RD_n,
		A			=> A(7 downto 0),
		D_in		=> D_in,
		D_out		=> io_D_out,
		TH_A		=> TH_A,
		TH_B		=> TH_B,
		J1_up		=> j1_up,
		J1_down	=> j1_down,
		J1_left	=> j1_left,
		J1_right	=> j1_right,
		J1_tl		=> j1_tl,
		J1_tr		=> j1_tr,
		J2_up		=> j2_up,
		J2_down	=> j2_down,
		J2_left	=> j2_left,
		J2_right	=> j2_right,
		J2_tl		=> j2_tl,
		J2_tr		=> j2_tr,
		Pause		=> pause,
		pal		=> pal,
		gg			=> gg,
		RESET_n	=> RESET_n
	);
	
	j1_th <= TH_A;
	j2_th <= TH_B;

	ram_a <= A(12 downto 0);
	ram_we <= ram_WR;
	ram_d <= D_in;
	ram_D_out <= ram_q;

	nvram_a <= (nvram_p and not A(14)) & A(13 downto 0);
	nvram_we <= nvram_WR;
	nvram_d <= D_in;
	nvram_D_out <= nvram_q;

	boot_rom_inst : entity work.sprom
	generic map
	(
		init_file=> "mboot.mif",
		widthad_a=> 14
	)
	port map
	(
		clock		=> clk_sys,
		address	=> A(13 downto 0),
		q			=> boot_rom_D_out
	);
		
	-- glue logic
	bal_WR_n <= WR_n when IORQ_n='0' and M1_n='1' and A(7 downto 0)="00000110" and gg='1' else '1';
	vdp_WR_n <= WR_n when IORQ_n='0' and M1_n='1' and A(7 downto 6)="10" else '1';
	vdp_RD_n <= RD_n when IORQ_n='0' and M1_n='1' and (A(7 downto 6)="01" or A(7 downto 6)="10") else '1';
	psg_WR_n <= WR_n when IORQ_n='0' and M1_n='1' and A(7 downto 6)="01" else '1';
	ctl_WR_n <=	WR_n when IORQ_n='0' and M1_n='1' and A(7 downto 6)="00" and A(0)='0' else '1';
	io_WR_n  <=	WR_n when IORQ_n='0' and M1_n='1' and A(7 downto 6)="00" and (A(0)='1' or (gg='1' and A(5 downto 3)="000")) else '1';
	io_RD_n  <=	RD_n when IORQ_n='0' and M1_n='1' and (A(7 downto 6)="11" or (gg='1' and A(7 downto 3)="00000" and A(2 downto 1)/="11")) else '1';
	fm_WR_n  <= WR_n when IORQ_n='0' and M1_n='1' and A(7 downto 1)="1111000" else '1';
	det_WR_n <= WR_n when IORQ_n='0' and M1_n='1' and A(7 downto 0)=x"F2" else '1';
					
	ram_WR   <= not WR_n when MREQ_n='0' and A(15 downto 14)="11" else '0';
	nvram_WR <= not WR_n when MREQ_n='0' and ((A(15 downto 14)="10" and nvram_e = '1') or (A(15 downto 14)="11" and nvram_ex = '1')) else '0';
	rom_RD   <= not RD_n when MREQ_n='0' and A(15 downto 14)/="11" else '0';

	process (clk_sys)
	begin
		if rising_edge(clk_sys) then
			if RESET_n='0' then 
				bootloader_n <= gg or not bios_en;
			elsif ctl_WR_n='0' and bootloader_n='0' then
				bootloader_n <= '1';
			end if;
		end if;
	end process;
	
	irom_D_out <=	boot_rom_D_out when bootloader_n='0' and A(15 downto 14)="00" else rom_do;
	
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
	
	process (IORQ_n,A,vdp_D_out,io_D_out,irom_D_out,ram_D_out,nvram_D_out,nvram_ex,nvram_e,gg,det_D,fm_ena)
	begin
		if IORQ_n='0' then
			if A(7 downto 0)=x"F2" and fm_ena = '1' then
				D_out <= "11111"&det_D;
			elsif (A(7 downto 6)="11" or (gg='1' and A(7 downto 3)="00000" and A(2 downto 0)/="111")) then
				D_out <= io_D_out;
			else
				D_out <= vdp_D_out;
			end if;
		else
			if    A(15 downto 14)="11" and nvram_ex = '1' then
				D_out <= nvram_D_out;
			elsif A(15 downto 14)="11" and nvram_ex = '0' then
				D_out <= ram_D_out;
			elsif A(15 downto 14)="10" and nvram_e  = '1' then
				D_out <= nvram_D_out;
			else
				D_out <= irom_D_out;
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
			nvram_e  <= '0';
			nvram_ex <= '0';
			nvram_p  <= '0';
			lock_mapper_A <= '0' ;
			lock_mapper_B <= '0' ;
		else
			if rising_edge(clk_sys) then
				if WR_n='0' and A(15 downto 2)="11111111111111" then
					if lock_mapper_B='0' then
						lock_mapper_A <= '1' ;
						case A(1 downto 0) is
							when "00" => 
								nvram_ex <= D_in(4);
								nvram_e  <= D_in(3);
								nvram_p  <= D_in(2);
							when "01" => bank0 <= D_in;
							when "10" => bank1 <= D_in;
							when "11" => bank2 <= D_in;
						end case;
					end if;
				end if;
				if WR_n='0' and lock_mapper_A='0' then
					case A(15 downto 0) is
				-- Codemasters
						when x"0000" => bank0 <= D_in ;  lock_mapper_B <= '1' ;
						when x"4000" => bank1 <= D_in ;  lock_mapper_B <= '1' ;
						when x"8000" => bank2 <= D_in ;  lock_mapper_B <= '1' ;
				-- Korean mapper (Sangokushi 3, Dodgeball King)
				-- should be safe to enable unconditionally, A000 is ROM area
						when x"A000" => bank2 <= D_in ;  lock_mapper_B <= '1' ;
						when others => null ;
					end case ;
				end if;
			end if;
		end if;
	end process;

	rom_a(13 downto 0) <= A(13 downto 0);
	process (A,bank0,bank1,bank2)
	begin
		case A(15 downto 14) is
		when "00" =>
			-- first kilobyte is always from bank 0
			if A(13 downto 10)="0000" then
				rom_a(21 downto 14) <= (others=>'0');
			else
				rom_a(21 downto 14) <= bank0;
			end if;

		when "01" =>
			rom_a(21 downto 14) <= bank1;
			
		when others =>
			rom_a(21 downto 14) <= bank2;

		end case;
	end process;

end Behavioral;
