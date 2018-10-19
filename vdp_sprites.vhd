library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vdp_sprites is
port (
	clk_sys:				in  STD_LOGIC;
	ce_vdp:				in  STD_LOGIC;
	ce_pix:				in  STD_LOGIC;
	table_address	: in  STD_LOGIC_VECTOR (13 downto 8);
	char_high_bit	: in  std_logic;
	tall				: in  std_logic;
	vram_A			: out STD_LOGIC_VECTOR (13 downto 0);
	vram_D			: in  STD_LOGIC_VECTOR (7 downto 0);
	x					: in  unsigned (8 downto 0);
	y					: in  unsigned (7 downto 0);
	collide			: out std_logic;
	overflow			: out std_logic;
	color				: out STD_LOGIC_VECTOR (3 downto 0));
end vdp_sprites;

architecture Behavioral of vdp_sprites is

	constant WAITING:	integer := 0;
	constant COMPARE:	integer := 1;
	constant LOAD_N:	integer := 2;
	constant LOAD_X:	integer := 3;
	constant LOAD_0:	integer := 4;
	constant LOAD_1:	integer := 5;
	constant LOAD_2:	integer := 6;
	constant LOAD_3:	integer := 7;

	signal state:		integer	:= WAITING;
	signal count:		integer range 0 to 8;
	signal index:		unsigned(5 downto 0);
	signal data_address: std_logic_vector(13 downto 2);

	type tenable	is array (0 to 7) of boolean;
	type tx			is array (0 to 7) of unsigned(7 downto 0);
	type tdata		is array (0 to 7) of std_logic_vector(7 downto 0);
	signal enable:	tenable;
	signal spr_x:	tx;
	signal spr_d0:	tdata;
	signal spr_d1:	tdata;
	signal spr_d2:	tdata;
	signal spr_d3:	tdata;

	type tcolor is array (0 to 7) of std_logic_vector(3 downto 0);
	signal spr_color:	tcolor;
	signal active:		std_logic_vector(7 downto 0);
	
begin
	shifters:
	for i in 0 to 7 generate
	begin
		shifter: entity work.vpd_sprite_shifter
		port map(
			clk_sys=> clk_sys,
			ce_pix=> ce_pix,
			x		=> x(7 downto 0),
			spr_x	=> spr_x(i),
			spr_d0=> spr_d0(i),
			spr_d1=> spr_d1(i),
			spr_d2=> spr_d2(i),
			spr_d3=> spr_d3(i),
			color => spr_color(i),
			active=> active(i)
		);
	end generate;

	with state select
	vram_a <=	table_address&"00"&std_logic_vector(index)		when COMPARE,
					table_address&"1"&std_logic_vector(index)&"1"	when LOAD_N,
					table_address&"1"&std_logic_vector(index)&"0"	when LOAD_X,
					data_address&"00"											when LOAD_0,
					data_address&"01"											when LOAD_1,
					data_address&"10"											when LOAD_2,
					data_address&"11"											when LOAD_3,
					(others=>'0') when others;

	process (clk_sys)
		variable y9 	: unsigned(8 downto 0);
		variable d9		: unsigned(8 downto 0);
		variable delta : unsigned(8 downto 0);
	begin
		if rising_edge(clk_sys) then
			if ce_vdp='1' then
			
				if x=255 then
					count <= 0;
					enable <= (others=>false);
					state <= COMPARE;
					index <= (others=>'0');
					
				else
					y9 := "0"&y;
					d9 := "0"&unsigned(vram_D);
					if d9>=240 then
						d9 := d9-256;
					end if;
					delta := y9-d9;
					overflow <= '0';
					
					case state is
					when COMPARE =>
						if d9=208 then
							state <= WAITING; -- stop
						elsif 0<=delta and ((delta<8 and tall='0') or (delta<16 and tall='1')) then
							enable(count) <= true;
							data_address(5 downto 2) <= std_logic_vector(delta(3 downto 0));
							if (count<8) then
								state <= LOAD_N;
							else
								state <= WAITING;
								overflow <= '1';
							end if;
						else
							if index<63 then
								index <= index+1;
							else
								state <= WAITING;
							end if;
						end if;
						
					when LOAD_N =>
						data_address(13) <= char_high_bit;
						data_address(12 downto 6) <= vram_d(7 downto 1);
						if tall='0' then
							data_address(5) <= vram_d(0);
						end if;
						state <= LOAD_X;
						
					when LOAD_X =>
						spr_x(count)	<= unsigned(vram_d);
						state <= LOAD_0;
						
					when LOAD_0 =>
						spr_d0(count)	<= vram_d;
						state	<= LOAD_1;
						
					when LOAD_1 =>
						spr_d1(count)	<= vram_d;
						state	<= LOAD_2;
						
					when LOAD_2 =>
						spr_d2(count)	<= vram_d;
						state	<= LOAD_3;
						
					when LOAD_3 =>
						spr_d3(count)	<= vram_d;
						state	<= COMPARE;
						index	<= index+1;
						count	<= count+1;
						
					when others =>
					end case;
				end if;
			end if;
		end if;
	end process;

	process (clk_sys)
		variable collision 	: unsigned(7 downto 0);
	begin
		if rising_edge(clk_sys) then
			if ce_vdp='1' then
				color <= (others=>'0');
				collision := (others=>'0');
				if enable(7) and active(7)='1' and not (spr_color(7)="0000") then
					collision(7) := '1';
					color <= spr_color(7);
				end if;
				if enable(6) and active(6)='1' and not (spr_color(6)="0000") then
					collision(6) := '1';
					color <= spr_color(6);
				end if;
				if enable(5) and active(5)='1' and not (spr_color(5)="0000") then
					collision(5) := '1';
					color <= spr_color(5);
				end if;
				if enable(4) and active(4)='1' and not (spr_color(4)="0000") then
					collision(4) := '1';
					color <= spr_color(4);
				end if;
				if enable(3) and active(3)='1' and not (spr_color(3)="0000") then
					collision(3) := '1';
					color <= spr_color(3);
				end if;
				if enable(2) and active(2)='1' and not (spr_color(2)="0000") then
					collision(2) := '1';
					color <= spr_color(2);
				end if;
				if enable(1) and active(1)='1' and not (spr_color(1)="0000") then
					collision(1) := '1';
					color <= spr_color(1);
				end if;
				if enable(0) and active(0)='1' and not (spr_color(0)="0000") then
					collision(0) := '1';
					color <= spr_color(0);
				end if;
				case collision is
				when x"00" | x"01" | x"02" | x"04" | x"08" | x"10" | x"20" | x"40" | x"80" =>
					collide <= '0';
				when others =>
					collide <= '1';
				end case;
			end if;
		end if;
	end process;

end Behavioral;

