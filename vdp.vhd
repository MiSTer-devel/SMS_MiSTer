library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vdp is
	generic (
		MAX_SPPL : integer := 7
	);
	port (
		clk_sys:			in  STD_LOGIC;
		ce_vdp:			in  STD_LOGIC;
		ce_pix:			in  STD_LOGIC;
		ce_sp:			in  STD_LOGIC;
		sp64:				in  STD_LOGIC;
		RD_n:				in  STD_LOGIC;
		WR_n:				in  STD_LOGIC;
		IRQ_n:			out STD_LOGIC;
		A:					in  STD_LOGIC_VECTOR (7 downto 0);
		D_in:				in  STD_LOGIC_VECTOR (7 downto 0);
		D_out:			out STD_LOGIC_VECTOR (7 downto 0);
		x:					unsigned(8 downto 0);
		y:					unsigned(7 downto 0);
		color:			out std_logic_vector (5 downto 0);
		reset_n:       in  STD_LOGIC);
end vdp;

architecture Behavioral of vdp is
	
	signal old_RD_n:			STD_LOGIC;
	signal old_WR_n:			STD_LOGIC;

	-- helper bits
	signal data_write:		std_logic;
	signal address_ff:		std_logic := '0';
	signal to_cram:			boolean := false;
	signal spr_collide:		std_logic;
	signal spr_overflow:		std_logic;
	
	-- vram and cram lines for the cpu interface
	signal xram_cpu_A:		std_logic_vector(13 downto 0);
	signal vram_cpu_WE:		std_logic;
	signal cram_cpu_WE:		std_logic;
	signal vram_cpu_D_out:	std_logic_vector(7 downto 0);	
	signal vram_cpu_D_outl:	std_logic_vector(7 downto 0);	
	signal xram_cpu_A_incr:	std_logic := '0';
	signal xram_cpu_read:	std_logic := '0';
	
	-- vram and cram lines for the video interface
	signal vram_vdp_A:		std_logic_vector(13 downto 0);
	signal vram_vdp_D:		std_logic_vector(7 downto 0);	
	signal cram_vdp_A:		std_logic_vector(4 downto 0);
	signal cram_vdp_D:		std_logic_vector(5 downto 0);
			
	-- control bits
	signal display_on:		std_logic := '1';
	signal disable_hscroll:	std_logic := '0';
	signal mask_column0:		std_logic := '0';
	signal overscan:			std_logic_vector (3 downto 0) := "0000";	
	signal irq_frame_en:		std_logic := '0';
	signal irq_line_en:		std_logic := '0';
	signal irq_line_count:	unsigned(7 downto 0) := (others=>'1');	
	signal bg_address:		std_logic_vector (2 downto 0) := (others=>'0');
	signal bg_scroll_x:		unsigned(7 downto 0) := (others=>'0');
	signal bg_scroll_y:		unsigned(7 downto 0) := (others=>'0');
	signal spr_address:		std_logic_vector (5 downto 0) := (others=>'0');
	signal spr_shift:			std_logic := '0';
	signal spr_tall:			std_logic := '0';
	signal spr_high_bit:		std_logic := '0';

	-- various counters
	signal last_y0:			std_logic := '0';
	signal vbi_done:			std_logic := '0';
	signal virq_flag:			std_logic := '0';
	signal reset_flags:		boolean := false;
	signal collide_flag:		std_logic := '0';
	signal overflow_flag:	std_logic := '0';
	signal irq_counter:		unsigned(6 downto 0) := (others=>'0');
	signal hbl_counter:		unsigned(7 downto 0) := (others=>'0');
	signal vbl_irq:			std_logic;
	signal hbl_irq:			std_logic;
	
begin
		
	vdp_main_inst: entity work.vdp_main
	generic map(
		MAX_SPPL => MAX_SPPL
	)
	port map(
		clk_sys			=> clk_sys,
		ce_vdp			=> ce_vdp,
		ce_pix			=> ce_pix,
		ce_sp				=> ce_sp,
		sp64				=> sp64,
		vram_A			=> vram_vdp_A,
		vram_D			=> vram_vdp_D,
		cram_A			=> cram_vdp_A,
		cram_D			=> cram_vdp_D,
				
		x					=> x,
		y					=> y,
		color				=> color,
						
		display_on		=> display_on,
		mask_column0	=> mask_column0,
		overscan			=> overscan,

		bg_address		=> bg_address,
		bg_scroll_x		=> bg_scroll_x,
		bg_scroll_y		=> bg_scroll_y,
		disable_hscroll=>disable_hscroll,
				
		spr_address		=> spr_address,
		spr_high_bit	=> spr_high_bit,
		spr_shift		=> spr_shift,
		spr_tall			=> spr_tall,
		spr_collide		=> spr_collide,
		spr_overflow	=> spr_overflow);

    
  vdp_vram_inst : entity work.dpram
    generic map
    (
      widthad_a		=> 14
    )
    port map
    (
      clock_a			=> clk_sys,
      address_a		=> xram_cpu_A(13 downto 0),
      wren_a			=> vram_cpu_WE,
      data_a			=> D_in,
      q_a				=> vram_cpu_D_out,

      clock_b			=> clk_sys,
      address_b		=> vram_vdp_A,
      wren_b			=> '0',
      data_b			=> (others => '0'),
      q_b				=> vram_vdp_D
    );

	vdp_cram_inst: entity work.vdp_cram
	port map (
		cpu_clk			=> clk_sys,
		cpu_WE			=> cram_cpu_WE,
		cpu_A 			=> xram_cpu_A(4 downto 0),
		cpu_D				=> D_in(5 downto 0),
		vdp_clk			=> clk_sys,
		vdp_A				=> cram_vdp_A,
		vdp_D				=> cram_vdp_D
	);
		
	cram_cpu_WE <= data_write when to_cram else '0';
	vram_cpu_WE <= data_write when not to_cram else '0';

	process (clk_sys, reset_n)
	begin
		if reset_n='0' then
			disable_hscroll<= '0';--36
			mask_column0	<= '1';--
			irq_line_en		<= '1';--
			spr_shift		<= '0';--
			display_on		<= '0';--80
			irq_frame_en	<= '0';--
			spr_tall			<= '0';--
			bg_address		<= "111";--FF
			spr_address		<= "111111";--FF
			spr_high_bit	<= '0';--FB
			overscan			<= "0000";--00
			bg_scroll_x		<= to_unsigned(0, bg_scroll_x'length);--00
			bg_scroll_y		<= to_unsigned(0, bg_scroll_y'length);--00
			irq_line_count	<= to_unsigned(255, irq_line_count'length);--FF
			reset_flags		<= true;
			address_ff		<= '0';
			xram_cpu_read	<= '0';
		elsif rising_edge(clk_sys) then
			old_WR_n <= WR_n;
			old_RD_n <= RD_n;
			data_write <= '0';

			if old_WR_n = '1' and WR_n='0' then
				if A(0)='0' then
					data_write <= '1';
					xram_cpu_A_incr <= '1';
					address_ff		<= '0';
					vram_cpu_D_outl <= D_in;
				else
					if address_ff='0' then
						xram_cpu_A(7 downto 0) <= D_in;
					else
						xram_cpu_A(13 downto 8) <= D_in(5 downto 0);
						to_cram <= D_in(7 downto 6)="11";
						if D_in(7 downto 6)="00" then
							xram_cpu_read <= '1';
						end if;
						case D_in is
						when "10000000" =>
							disable_hscroll<= xram_cpu_A(6);
							mask_column0	<= xram_cpu_A(5);
							irq_line_en		<= xram_cpu_A(4);
							spr_shift		<= xram_cpu_A(3);
						when "10000001" =>
							display_on		<= xram_cpu_A(6);
							irq_frame_en	<= xram_cpu_A(5);
							spr_tall			<= xram_cpu_A(1);
						when "10000010" =>
							bg_address		<= xram_cpu_A(3 downto 1);
						when "10000101" =>
							spr_address		<= xram_cpu_A(6 downto 1);
						when "10000110" =>
							spr_high_bit	<= xram_cpu_A(2);
						when "10000111" =>
							overscan			<= xram_cpu_A(3 downto 0);
						when "10001000" =>
							bg_scroll_x		<= unsigned(xram_cpu_A(7 downto 0));
						when "10001001" =>
							bg_scroll_y		<= unsigned(xram_cpu_A(7 downto 0));
						when "10001010" =>
							irq_line_count	<= unsigned(xram_cpu_A(7 downto 0));
						when others =>
						end case;
					end if;
					address_ff <= not address_ff;
				end if;
				
			elsif old_RD_n = '1' and RD_n='0' then
				address_ff		<= '0';
				case A(7 downto 6)&A(0) is
				when "010" =>
					D_out <= std_logic_vector(y);
				when "011" =>
					D_out <= std_logic_vector(x(7 downto 0));
				when "100" =>
					--D_out <= vram_cpu_D_out;
					D_out <= vram_cpu_D_outl;
					xram_cpu_A_incr <= '1';
					xram_cpu_read <= '1';
				when "101" =>
					D_out(7) <= virq_flag;
					D_out(6) <= overflow_flag;
					D_out(5) <= collide_flag;
					D_out(4 downto 0) <= (others=>'0');
					reset_flags <= true;
				when others =>
				end case;
				
			elsif xram_cpu_A_incr='1' then
				xram_cpu_A <= std_logic_vector(unsigned(xram_cpu_A) + 1);
				xram_cpu_A_incr <= '0';
				if xram_cpu_read='1' then
					vram_cpu_D_outl <= vram_cpu_D_out;
				end if;
				xram_cpu_read <= '0';

			elsif xram_cpu_read='1' then
				xram_cpu_A_incr <= '1';

			else
				reset_flags <= false;
			end if;
		end if;
	end process;

	process (clk_sys)
	begin
		if rising_edge(clk_sys) then
			if ce_vdp = '1' then
				-- we need to make sure we only send one vbi per image since the 
				-- y counter repeats within the image and the value 192 occurs twice
				if y=0 then
					vbi_done <= '0';
				end if;
				
				if x=256 and y=192 and not (last_y0=std_logic(y(0))) then
					if(vbi_done='0') then
						vbl_irq <= '1';
						vbi_done <= '1';
					end if;
				else
					vbl_irq <= '0';
				end if;
			end if;
		end if;
	end process;
	
	process (clk_sys)
	begin
		if rising_edge(clk_sys) then
			if ce_vdp = '1' then
				if x=256 and not (last_y0=std_logic(y(0))) then
					last_y0 <= std_logic(y(0));
					if y<192 then
						if hbl_counter=0 then
							hbl_irq <= irq_line_en;
							hbl_counter <= irq_line_count;
						else
							hbl_counter <= hbl_counter-1;
						end if;
					else
						hbl_counter <= irq_line_count;
					end if;
				else
					hbl_irq <= '0';
				end if;
			end if;
		end if;
	end process;
	
	process (clk_sys)
	begin
		if rising_edge(clk_sys) then
			if ce_vdp = '1' then
				if vbl_irq='1' then
					virq_flag <= '1';
				elsif reset_flags then
					virq_flag <= '0';
				end if;

				if spr_collide='1' then
					collide_flag <= '1';
				elsif reset_flags then
					collide_flag <= '0';
				end if;

				if spr_overflow='1' then
					overflow_flag <= '1';
				elsif reset_flags then
					overflow_flag <= '0';
				end if;

				if (vbl_irq='1' and irq_frame_en='1') or hbl_irq='1' then
					irq_counter <= (others=>'1');
				elsif irq_counter>0 then
					irq_counter <= irq_counter-1;
				end if;
			end if;
		end if;
	end process;
	IRQ_n <= '0' when irq_counter>0 else '1';

	
end Behavioral;
