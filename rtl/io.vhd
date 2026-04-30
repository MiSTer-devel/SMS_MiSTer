library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity io is
    Port(
		clk:		in	 STD_LOGIC;
		ce_cpu:	in	 STD_LOGIC;
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
		gg_link_en:	in  STD_LOGIC;
		gg_link_in:	in  STD_LOGIC_VECTOR(6 downto 0);
		gg_link_out:	out STD_LOGIC_VECTOR(6 downto 0);
		gg_link_nmi_n:	out STD_LOGIC;
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
	signal gg_sctrl:	std_logic_vector(7 downto 3) := (others=>'0');
	signal gg_pc_in_mux:	std_logic_vector(6 downto 0);
	signal gg_pc_drive_en:	std_logic_vector(6 downto 0);
	signal gg_pc_drive_val:	std_logic_vector(6 downto 0);
	signal gg_pc_read:	std_logic_vector(6 downto 0);
	signal gg_tx_line:	std_logic := '1';
	signal gg_tx_busy:	std_logic := '0';
	signal gg_tx_shift:	std_logic_vector(9 downto 0) := (others=>'1');
	signal gg_tx_cnt:	unsigned(13 downto 0) := (others=>'0');
	signal gg_tx_bits:	unsigned(3 downto 0) := (others=>'0');
	signal gg_rx_sync:	std_logic_vector(2 downto 0) := (others=>'1');
	signal gg_pc6_sync:	std_logic_vector(2 downto 0) := (others=>'1');
	signal gg_pc6_prev:	std_logic := '1';
	signal gg_rx_state:	unsigned(1 downto 0) := (others=>'0');
	signal gg_rx_cnt:	unsigned(13 downto 0) := (others=>'0');
	signal gg_rx_bits:	unsigned(2 downto 0) := (others=>'0');
	signal gg_rx_shift:	std_logic_vector(7 downto 0) := (others=>'1');
	signal gg_rx_ready:	std_logic := '0';
	signal gg_rx_frame_err:	std_logic := '0';
	signal gg_nmi_serial:	std_logic := '0';
	signal gg_nmi_pc6:	std_logic := '0';
	signal gg_baud_div:	unsigned(13 downto 0);
	signal gg_baud_half:	unsigned(13 downto 0);
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

begin

	gg_pc_in_mux <= gg_link_in when gg_link_en='1' else "1111111";

	with gg_sctrl(7 downto 6) select gg_baud_div <=
		to_unsigned(745,  14) when "00", -- 4800 bps at the GG CPU clock
		to_unsigned(1491, 14) when "01", -- 2400 bps
		to_unsigned(2982, 14) when "10", -- 1200 bps
		to_unsigned(11931,14) when others; -- 300 bps

	with gg_sctrl(7 downto 6) select gg_baud_half <=
		to_unsigned(372,  14) when "00",
		to_unsigned(745,  14) when "01",
		to_unsigned(1491, 14) when "10",
		to_unsigned(5965, 14) when others;

	process (gg_ddr, gg_pdr, gg_sctrl, gg_tx_line)
	begin
		gg_pc_drive_en <= not gg_ddr(6 downto 0);
		gg_pc_drive_val <= gg_pdr(6 downto 0);

		if gg_sctrl(4)='1' then
			gg_pc_drive_en(4) <= '1';
			gg_pc_drive_val(4) <= gg_tx_line;
		end if;

		if gg_sctrl(5)='1' then
			gg_pc_drive_en(5) <= '0';
		end if;
	end process;

	process (gg_pc_in_mux, gg_pc_drive_en, gg_pc_drive_val)
	begin
		for i in 0 to 6 loop
			if gg_pc_drive_en(i)='1' and gg_pc_drive_val(i)='0' then
				gg_pc_read(i) <= '0';
			else
				gg_pc_read(i) <= gg_pc_in_mux(i);
			end if;
		end loop;
	end process;
	gg_link_nmi_n <= '0' when gg='1' and gg_link_en='1' and (gg_nmi_serial='1' or gg_nmi_pc6='1') else '1';

	pc_out: for i in 0 to 6 generate
		gg_link_out(i) <= '0' when gg='1' and gg_link_en='1' and gg_pc_drive_en(i)='1' and gg_pc_drive_val(i)='0' else '1';
	end generate;

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
			gg_pdr <= x"7F";
			gg_sctrl <= (others=>'0');
			gg_tx_line <= '1';
			gg_tx_busy <= '0';
			gg_tx_shift <= (others=>'1');
			gg_tx_cnt <= (others=>'0');
			gg_tx_bits <= (others=>'0');
			gg_rx_sync <= (others=>'1');
			gg_pc6_sync <= (others=>'1');
			gg_pc6_prev <= '1';
			gg_rx_state <= (others=>'0');
			gg_rx_cnt <= (others=>'0');
			gg_rx_bits <= (others=>'0');
			gg_rx_shift <= (others=>'1');
			gg_rx_ready <= '0';
			gg_rx_frame_err <= '0';
			gg_nmi_serial <= '0';
			gg_nmi_pc6 <= '0';
			sc_multicart_latch <= x"FF";
			sk1100_port_c <= x"FF";
			analog_select <= '0';
			analog_player <= '0';
			analog_upper <= '0';
		elsif rising_edge(clk) then
			if gg='0' or gg_link_en='0' then
				gg_tx_line <= '1';
				gg_tx_busy <= '0';
				gg_rx_state <= (others=>'0');
				gg_rx_ready <= '0';
				gg_rx_frame_err <= '0';
				gg_nmi_serial <= '0';
				gg_nmi_pc6 <= '0';
				gg_rx_sync <= (others=>'1');
				gg_pc6_sync <= (others=>'1');
				gg_pc6_prev <= '1';
			elsif ce_cpu='1' then
				gg_rx_sync <= gg_rx_sync(1 downto 0) & gg_pc_in_mux(5);
				gg_pc6_sync <= gg_pc6_sync(1 downto 0) & gg_pc_in_mux(6);

				if gg_tx_busy='1' then
					if gg_tx_cnt=to_unsigned(0, gg_tx_cnt'length) then
						if gg_tx_bits=to_unsigned(0, gg_tx_bits'length) then
							gg_tx_busy <= '0';
							gg_tx_line <= '1';
						else
							gg_tx_line <= gg_tx_shift(1);
							gg_tx_shift <= '1' & gg_tx_shift(9 downto 1);
							gg_tx_bits <= gg_tx_bits - 1;
							gg_tx_cnt <= gg_baud_div;
						end if;
					else
						gg_tx_cnt <= gg_tx_cnt - 1;
					end if;
				end if;

				if gg_sctrl(5)='0' then
					gg_rx_state <= (others=>'0');
				else
					case gg_rx_state is
						when "00" =>
							if gg_rx_sync(2)='1' and gg_rx_sync(1)='0' then
								gg_rx_state <= "01";
								gg_rx_cnt <= gg_baud_half;
							end if;
						when "01" =>
							if gg_rx_cnt=to_unsigned(0, gg_rx_cnt'length) then
								if gg_rx_sync(2)='0' then
									gg_rx_state <= "10";
									gg_rx_bits <= (others=>'0');
									gg_rx_cnt <= gg_baud_div;
								else
									gg_rx_state <= "00";
								end if;
							else
								gg_rx_cnt <= gg_rx_cnt - 1;
							end if;
						when "10" =>
							if gg_rx_cnt=to_unsigned(0, gg_rx_cnt'length) then
								gg_rx_shift <= gg_rx_sync(2) & gg_rx_shift(7 downto 1);
								gg_rx_cnt <= gg_baud_div;
								if gg_rx_bits="111" then
									gg_rx_state <= "11";
								else
									gg_rx_bits <= gg_rx_bits + 1;
								end if;
							else
								gg_rx_cnt <= gg_rx_cnt - 1;
							end if;
						when others =>
							if gg_rx_cnt=to_unsigned(0, gg_rx_cnt'length) then
								if gg_rx_sync(2)='1' then
									gg_rxd <= gg_rx_shift;
									gg_rx_ready <= '1';
									gg_rx_frame_err <= '0';
								else
									gg_rx_frame_err <= '1';
								end if;
								if gg_sctrl(3)='1' then
									gg_nmi_serial <= '1';
								end if;
								gg_rx_state <= "00";
							else
								gg_rx_cnt <= gg_rx_cnt - 1;
							end if;
					end case;
				end if;

				if gg_ddr(7)='0' and gg_ddr(6)='1' and gg_pc6_prev='1' and gg_pc6_sync(2)='0' then
					gg_nmi_pc6 <= '1';
				end if;
				gg_pc6_prev <= gg_pc6_sync(2);
			end if;

			if gg='1' and A(7 downto 3)="00000" and RD_n='0' and A(2 downto 0)="100" then
				gg_rx_ready <= '0';
				gg_rx_frame_err <= '0';
				gg_nmi_serial <= '0';
			end if;

			if gg='1' and A(7 downto 3) = "00000" then
				if WR_n='0' then
					case A(2 downto 0) is
						when "001" => gg_pdr <= D_in ;
						when "010" =>
							gg_ddr <= D_in ;
							if D_in(7)='1' then
								gg_nmi_pc6 <= '0';
							end if;
						when "011" =>
							gg_txd <= D_in ;
							if gg_link_en='1' and gg_sctrl(4)='1' and gg_tx_busy='0' then
								gg_tx_shift <= '1' & D_in & '0';
								gg_tx_line <= '0';
								gg_tx_bits <= to_unsigned(9, gg_tx_bits'length);
								gg_tx_cnt <= gg_baud_div;
								gg_tx_busy <= '1';
							end if;
						-- when "100" => gg_rxd <= D_in ;
						when "101" =>
							gg_sctrl <= D_in(7 downto 3);
							if D_in(3)='0' then
								gg_nmi_serial <= '0';
							end if;
							if D_in(4)='0' then
								gg_tx_line <= '1';
								gg_tx_busy <= '0';
							end if;
							if D_in(5)='0' then
								gg_rx_state <= (others=>'0');
								gg_rx_ready <= '0';
								gg_rx_frame_err <= '0';
								gg_nmi_serial <= '0';
							end if;
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
						when "001" => D_out <= gg_pdr(7)&gg_pc_read ;
						when "010" => D_out <= gg_ddr ; -- bit7 controls NMI ?
						when "011" => D_out <= gg_txd ;
						when "100" => D_out <= gg_rxd ;
						when "101" =>
							if gg_link_en='1' then
								D_out <= gg_sctrl & gg_rx_frame_err & gg_rx_ready & gg_tx_busy;
							else
								D_out <= "00111000";
							end if;
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

