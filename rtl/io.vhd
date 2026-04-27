library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity io is
    Port(
		clk:		in	 STD_LOGIC;
		WR_n:		in	 STD_LOGIC;
		RD_n:		in	 STD_LOGIC;
		A:			in	 STD_LOGIC_VECTOR (7 downto 0);
		D_in:		in	 STD_LOGIC_VECTOR (7 downto 0);
		D_out:	out STD_LOGIC_VECTOR (7 downto 0);
		HL_out:	out STD_LOGIC;
		vdp1_bank:out STD_LOGIC;
		vdp2_bank:out STD_LOGIC;
		vdp_cpu_bank:out STD_LOGIC;
		rom_bank:out STD_LOGIC_VECTOR (3 downto 0);
		J1_tr_out: out  STD_LOGIC;
		J1_th_out: out  STD_LOGIC;
		J2_tr_out: out  STD_LOGIC;
		J2_th_out: out  STD_LOGIC;
		J1_up:	in  STD_LOGIC;
		J1_down:	in  STD_LOGIC;
		J1_left:	in  STD_LOGIC;
		J1_right:in  STD_LOGIC;
		J1_tl:	in  STD_LOGIC;
		J1_tr:	in  STD_LOGIC;
		J1_th:	in  STD_LOGIC;
		j1_start:in  STD_LOGIC;
		j1_coin:	in  STD_LOGIC;
		j1_a3:	in  STD_LOGIC;
		J2_up:	in  STD_LOGIC;
		J2_down:	in  STD_LOGIC;
		J2_left:	in  STD_LOGIC;
		J2_right:in  STD_LOGIC;
		J2_tl:	in  STD_LOGIC;
		J2_tr:	in  STD_LOGIC;
		J2_th:	in  STD_LOGIC;
		j2_start:in  STD_LOGIC;
		j2_coin:	in  STD_LOGIC;
		j2_a3:	in  STD_LOGIC;
		Pause:	in  STD_LOGIC;
		soft_reset: in STD_LOGIC;
		E0Type:	in  STD_LOGIC_VECTOR(1 downto 0);
		E1Use:	in	 STD_LOGIC;
		E2Use:	in	 STD_LOGIC;
		E0:		in  STD_LOGIC_VECTOR(7 downto 0);
		F2:		in  STD_LOGIC_VECTOR(7 downto 0);
		F3:		in  STD_LOGIC_VECTOR(7 downto 0);
		has_paddle:in STD_LOGIC;
		has_pedal:in STD_LOGIC;
		paddle:	in  STD_LOGIC_VECTOR(7 downto 0);
		paddle2:	in  STD_LOGIC_VECTOR(7 downto 0);
		pedal:	in  STD_LOGIC_VECTOR(7 downto 0);
		palettemode:in STD_LOGIC;
		sc3000_en:in STD_LOGIC;
		sc_multicart_en:in STD_LOGIC;
		sc_megacart_en:in STD_LOGIC;
		sk1100_en:in STD_LOGIC;
		sc_multicart_page:out STD_LOGIC_VECTOR(6 downto 0);
		sk1100_row_sel:out STD_LOGIC_VECTOR(2 downto 0);
		sk1100_row_data:in STD_LOGIC_VECTOR(11 downto 0);
		pal:		in	 STD_LOGIC;
		gg:		in  STD_LOGIC;
		systeme:	in  STD_LOGIC;
		region:	in	 STD_LOGIC;
		RESET_n:	in  STD_LOGIC);
end io;

architecture rtl of io is

	signal ctrl:	std_logic_vector(7 downto 0) := (others=>'1');
	signal gg_ddr:	std_logic_vector(7 downto 0) := (others=>'1');
	signal gg_txd:	std_logic_vector(7 downto 0) := (others=>'0');
	signal gg_rxd:	std_logic_vector(7 downto 0) := (others=>'1');
	signal gg_pdr:	std_logic_vector(7 downto 0) := (others=>'0');
	signal j1_th_dir: std_logic := '0';
	signal j2_th_dir: std_logic := '0';
	signal sg_mode: std_logic;
	signal sk1100_active: std_logic;
	signal sc_multicart_latch: std_logic_vector(7 downto 0) := (others=>'1');
	signal sk1100_port_c: std_logic_vector(7 downto 0) := (others=>'1');
	signal sk1100_port_a: std_logic_vector(7 downto 0);
	signal sk1100_port_b: std_logic_vector(3 downto 0);
	signal analog_select: std_logic;
	signal analog_player: std_logic;
	signal analog_upper: std_logic;
	-- signal gg_sctrl:	std_logic_vector(7 downto 3) := "00111";

begin

	sg_mode <= '1' when (palettemode='1' or sc3000_en='1' or sk1100_en='1') and gg='0' and systeme='0' else '0';
	sk1100_active <= '1' when (sc3000_en='1' or sk1100_en='1') and sg_mode='1' else '0';
	-- Survivors multicart family:
	-- Mk II uses Q0..Q4 plus Q6 for 64x32KB slots.
	-- The older Megacart extends that to 128x32KB using Q7 as the extra slot bit,
	-- while Q5 remains unused in the menu paging scheme
	sc_multicart_page <= sc_multicart_latch(7) & sc_multicart_latch(6) & sc_multicart_latch(4 downto 0) when sc_megacart_en='1' else
						 '0' & sc_multicart_latch(6) & sc_multicart_latch(4 downto 0);
	sk1100_row_sel <= sk1100_port_c(2 downto 0);
	sk1100_port_a <= sk1100_row_data(7 downto 0);
	sk1100_port_b <= sk1100_row_data(11 downto 8);

	process (clk, RESET_n)
	begin
		if RESET_n = '0' then
			ctrl <= x"FF";
			gg_ddr <= x"FF";
			gg_txd <= x"00" ;
			gg_rxd <= x"FF";
			gg_pdr <= x"00";
			sc_multicart_latch <= x"FF";
			sk1100_port_c <= x"FF";
			analog_select <= '0';
			analog_player <= '0';
			-- gg_sctrl <= "00111" ;
		elsif rising_edge(clk) then
			if gg='1' and A(7 downto 3) = "00000" then
				if WR_n='0' then
					case A(2 downto 0) is
						when "001" => gg_pdr <= D_in ;
						when "010" => gg_ddr <= D_in ;
						when "011" => gg_txd <= D_in ;
						-- when "100" => gg_rxd <= D_in ;
						-- when "101" => gg_sctrl <= D_in(7 downto 3) ; --sio.sctrl = data & 0xF8;
						when others => null ;
					end case;
				end if;
			elsif systeme='1' and A = x"F7" then
				if WR_n='0' then
					vdp1_bank <= D_in(7);
					vdp2_bank <= D_in(6);
					vdp_cpu_bank <= D_in(5);
					rom_bank <= D_in(3 downto 0);
				end if;
			elsif systeme='1' and A = x"FA" then
				if WR_n='0' then
					analog_player <= D_in(3); -- paddle select ridleofp
					analog_upper  <= D_in(2); -- upperbits ridleofp
					analog_select <= D_in(0); -- analog select(paddle, pedal) hangonjr
				end if;
			elsif sc_multicart_en='1' and A(7 downto 5)="111" then
				if WR_n='0' then
					sc_multicart_latch <= D_in;
				end if;
			elsif sg_mode='1' and sk1100_active='1' and A(7 downto 5)="110" then
				if WR_n='0' then
					case A(1 downto 0) is
						when "10" =>
							sk1100_port_c <= D_in;
						when "11" =>
							if D_in(7)='0' then
								sk1100_port_c(to_integer(unsigned(D_in(3 downto 1)))) <= D_in(0);
							end if;
						when others =>
							null;
					end case;
				end if;
			elsif sg_mode='1' and sk1100_active='0' and (A = x"DE" or A = x"DF") then
				-- Plain SG-1000 carts don't have the SC-3000/SK-1100 PPI attached.
				-- Ignore these writes so they don't accidentally hit the SMS control port.
				null;
			elsif A(0)='1' then
--				if WR_n='0' and ((A(7 downto 4)/="0000") or (A(3 downto 0)="0000")) then
				if WR_n='0' then
					ctrl <= D_in;
				end if ;
			end if;
		end if;
	end process;

--	J1_tr <= ctrl(4) when ctrl(0)='0' else 'Z';
--	J2_tr <= ctrl(6) when ctrl(2)='0' else 'Z';
-- $00-$06 : GG specific registers. Initial state is 'C0 7F FF 00 FF 00 FF'

	process (clk)
	begin
		if rising_edge(clk) then
			if RD_n='0' then
				if A(7)='0' then -- implies gg='1'
					case A(2 downto 0) is
						when "000" =>
							D_out(7) <= Pause;
							if (region='0') then
								D_out(6) <= '1'; -- 1=Export (USA/Europe)/0=Japan
								D_out(5) <= not pal ;
								D_out(4 downto 0) <= "11111";
							else
								D_out(6 downto 0) <= "0000000";
							end if;
						-- when "001" => D_out <= gg_pdr(7)&(gg_ddr(6 downto 0) or gg_pdr(6 downto 0)) ;
						when "001" => D_out <= gg_pdr(7)&(not gg_ddr(6 downto 0) and gg_pdr(6 downto 0)) ;
						when "010" => D_out <= gg_ddr ; -- bit7 controls NMI ?
						when "011" => D_out <= gg_txd ;
						when "100" => D_out <= gg_rxd ;
						when "101" => D_out <= "00111000"; -- gg_sctrl & "000" ;
						when "110" => D_out <= (others => '1');
						when others => null ;
					end case;
				elsif systeme='1' and A(7 downto 0)=x"e0" then
					D_out(7) <= not j2_start or E0Type(1) or E0Type(0);
					D_out(6) <= not j1_start or E0Type(1);
					D_out(5) <= '1'; -- not used?
					D_out(4) <= not j1_start or not E0Type(0);
					D_out(3) <= E0(3); -- service
					D_out(2) <= E0(2); -- service no toggle (usually)
					D_out(1) <= not j2_coin;
					D_out(0) <= not j1_coin;
				elsif systeme='1' and A(7 downto 0)=x"e1" then
					if (E1Use='1') then
						D_out(7) <= '1';
						D_out(6) <= '1';
						D_out(5) <= J1_tr;
						D_out(4) <= J1_tl;
						D_out(3) <= J1_right;
						D_out(2) <= J1_left;
						D_out(1) <= J1_down;
						D_out(0) <= J1_up;
					else
						D_out <= x"FF";
					end if;
				elsif systeme='1' and A(7 downto 0)=x"e2" then
					if (E2Use='1') then
						D_out(7) <= '1';
						D_out(6) <= '1';
						D_out(5) <= J2_tr;
						D_out(4) <= J2_tl;
						D_out(3) <= J2_right;
						D_out(2) <= J2_left;
						D_out(1) <= J2_down;
						D_out(0) <= J2_up;
					else
						D_out <= x"FF";
					end if;
				elsif systeme='1' and A(7 downto 0)=x"f2" then
					D_out <= F2; -- free play or 1coin/credit
				elsif systeme='1' and A(7 downto 0)=x"f3" then
					D_out <= F3; -- dip switch options
				elsif systeme='1' and A(7 downto 0)=x"f8" then  -- analog (paddle, pedal)
					if (has_pedal='0' and has_paddle='0') then
						D_out <= x"FF";
					elsif has_pedal='1' then
						if analog_select='0' then
							D_out <= paddle;
						else
							D_out <= pedal;
						end if;
					elsif analog_upper='1' then
						if analog_player='0' then
							D_out(7) <= J1_tl or J1_tr or J1_a3;
							D_out(6) <= J1_tl;
							D_out(5) <= J1_tr;
							D_out(4) <= J1_a3;--j1_middle;
							D_out(3 downto 0) <= paddle(7 downto 4);
						else
							D_out(7) <= J1_tl or J1_tr or J1_a3;
							D_out(6) <= J2_tl;
							D_out(5) <= J2_tr;
							D_out(4) <= J2_a3;--j1_middle;
							D_out(3 downto 0) <= paddle2(7 downto 4);
						end if;
					else
						if analog_player='0' then
							D_out(3 downto 0) <= paddle(7 downto 4);
							D_out(7 downto 4) <= paddle(3 downto 0);
						else
							D_out(3 downto 0) <= paddle2(7 downto 4);
							D_out(7 downto 4) <= paddle2(3 downto 0);
						end if;
					end if;
				elsif systeme='1' and A(7 downto 0)=x"f9" then
					D_out <= x"FF"; -- analog (paddle, pedal, dial)
				elsif systeme='1' and A(7 downto 0)=x"fa" then
					D_out <= x"00"; -- analog (paddle, pedal, dial)
				elsif systeme='1' and A(7 downto 0)=x"fb" then
					D_out <= x"FF"; -- analog (paddle, pedal, dial)
				elsif sg_mode='1' and sk1100_active='1' and A(7 downto 5)="110" then
					case A(1 downto 0) is
						when "00" =>
							D_out <= sk1100_port_a;
						when "01" =>
							D_out(7 downto 4) <= "0111";
							D_out(3 downto 0) <= sk1100_port_b;
						when "10" =>
							D_out <= sk1100_port_c;
						when others =>
							D_out <= x"FF";
					end case;
				elsif sg_mode='1' and sk1100_active='0' and (A = x"DE" or A = x"DF") then
					D_out <= x"FF";
				elsif A(0)='0' then
					D_out(7) <= J2_down;
					D_out(6) <= J2_up;
					-- 5=j1_tr
					if ctrl(0)='0' and region='0' and gg='0' then
						D_out(5) <= ctrl(4);
					else
						D_out(5) <= J1_tr;
					end if;
					D_out(4) <= J1_tl;
					D_out(3) <= J1_right;
					D_out(2) <= J1_left;
					D_out(1) <= J1_down;
					D_out(0) <= J1_up;
				else
					-- 7=j2_th
					if ctrl(3)='0' and region='0' and gg='0' then
						D_out(7) <= ctrl(7);
					else
						D_out(7) <= J2_th;
					end if;
					-- 6=j1_th
					if ctrl(1)='0' and region='0' and gg='0' then
						D_out(6) <= ctrl(5);
					else
						D_out(6) <= J1_th;
					end if;
					D_out(5) <= '1';
					-- Bit 4 = Reset button (active-low). On export SMS hardware this
					-- is port $DD bit 4. On Japanese SMS, Mark III and Game Gear the
					-- physical reset is wired differently, but we expose it here in
					-- all modes so soft reset works across all system configurations.
					D_out(4) <= not soft_reset;
					-- 4=j2_tr
					if ctrl(2)='0' and gg='0' then
						D_out(3) <= ctrl(6);
					else
						D_out(3) <= J2_tr;
					end if;
					D_out(2) <= J2_tl;
					D_out(1) <= J2_right;
					D_out(0) <= J2_left;
				end if;
			end if;

			J1_tr_out <= ctrl(0) or ctrl(4) or region;
			J1_th_out <= ctrl(1) or ctrl(5) or region;
			J2_tr_out <= ctrl(2) or ctrl(6) or region;
			J2_th_out <= ctrl(3) or ctrl(7) or region;
			HL_out <= (not j1_th_dir and ctrl(1)) or (ctrl(1) and not J1_th) or
				(not j2_th_dir and ctrl(3)) or (ctrl(3) and not J2_th);
			j1_th_dir <= ctrl(1);
			j2_th_dir <= ctrl(3);

		end if;
	end process;
	
end rtl;

