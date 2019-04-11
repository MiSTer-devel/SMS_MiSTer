library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL; 

entity vdp_sprites is
	generic (
		MAX_SPPL : integer := 7
	);
port (
	clk_sys			: in  STD_LOGIC;
	ce_vdp			: in  STD_LOGIC;
	ce_pix			: in  STD_LOGIC;
	ce_sp				: in  STD_LOGIC;
	sp64				: in  std_logic;
	table_address	: in  STD_LOGIC_VECTOR (13 downto 8);
	char_high_bit	: in  std_logic;
	tall				: in  std_logic;
	shift				: in  std_logic;
	smode_M1			: in	std_logic ;
	smode_M3			: in	std_logic ;
	vram_A			: out STD_LOGIC_VECTOR (13 downto 0);
	vram_D			: in  STD_LOGIC_VECTOR (7 downto 0);
	x					: in  STD_LOGIC_VECTOR (8 downto 0);
	y					: in  STD_LOGIC_VECTOR (8 downto 0);
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
	signal count:		integer range 0 to 64;
	signal index:		std_logic_vector(5 downto 0);
	signal data_address: std_logic_vector(13 downto 2);
	signal ce_spload:	std_logic;

	type tenable	is array (0 to MAX_SPPL) of boolean;
	type tx			is array (0 to MAX_SPPL) of std_logic_vector(7 downto 0);
	type tdata		is array (0 to MAX_SPPL) of std_logic_vector(7 downto 0);
	signal enable:	tenable;
	signal spr_x:	tx;
	signal spr_d0:	tdata;
	signal spr_d1:	tdata;
	signal spr_d2:	tdata;
	signal spr_d3:	tdata;

	type tcolor is array (0 to MAX_SPPL) of std_logic_vector(3 downto 0);
	signal spr_color:	tcolor;
	signal active:		std_logic_vector(MAX_SPPL downto 0);
	
begin
	shifters:
	for i in 0 to MAX_SPPL generate
	begin
		shifter: entity work.vpd_sprite_shifter
		port map(
			clk_sys=> clk_sys,
			ce_pix=> ce_pix,
			x		=> x(7 downto 0),
			spr_x	=> spr_x(i),
			shift	=> shift,
			-- as we pass only 8 bits for the x address, we need to make the difference
			-- between x=255 and x=511 in some way inside the shifters, or we'll have spurious
			-- signals difficult to filter outside them. The compare operators are kept
			-- outside the module to avoid to have them duplicated 64 times.
			load  => x<256, --load range
			x248  => x<248 or x>=504, --load range for shifted sprites
			spr_d0=> spr_d0(i),
			spr_d1=> spr_d1(i),
			spr_d2=> spr_d2(i),
			spr_d3=> spr_d3(i),
			color => spr_color(i),
			active=> active(i)
		);
	end generate;

	with state select
	vram_a <=	table_address&"00"&index		when COMPARE,
					table_address&"1"&index&"1"	when LOAD_N,
					table_address&"1"&index&"0"	when LOAD_X,
					data_address&"00"					when LOAD_0,
					data_address&"01"					when LOAD_1,
					data_address&"10"					when LOAD_2,
					data_address&"11"					when LOAD_3,
					(others=>'0') when others;

	ce_spload <= ce_vdp when (MAX_SPPL<8 or sp64='0') else ce_sp;
	
	process (clk_sys)
		variable y9 	: std_logic_vector(8 downto 0);
		variable d9		: std_logic_vector(8 downto 0);
		variable delta : std_logic_vector(8 downto 0);
	begin
		if rising_edge(clk_sys) then
			if ce_spload='1' then
			
				if x=255 then  -- 
					count <= 0;
					enable <= (others=>false);
					state <= COMPARE;
					index <= (others=>'0');
					overflow <= '0';
				
				elsif x=496 then  --match vdp_main.vhd (384)
					state <= WAITING;
					
				else
					y9 := y;
					d9 := "0"&vram_D;
					if d9>=240 then
						d9 := d9-256;
					end if;
					delta := y9-d9;
					--overflow <= '0';
					
					case state is
					when COMPARE =>
						if d9=208 and smode_M1='0' and smode_M3='0' then  -- hD0 stops only in 192 mode
							state <= WAITING; -- stop
						elsif (delta(8 downto 3)="00000" and tall='0') or (delta(8 downto 4)="0000" and tall='1') then
							data_address(5 downto 2) <= delta(3 downto 0);
							if (count>=8 and ( y<192 or (y<224 and smode_M1='1') or (y<240 and smode_M3='1') ) ) then
								overflow <= '1';
							end if;
							if ((count<MAX_SPPL+1) and (count<8 or sp64='1')) then
								state <= LOAD_N;
							else
								state <= WAITING;
							end if;
						else
							if index<MAX_SPPL then
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
						spr_x(count)	<= vram_d;
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
						enable(count)	<= true;
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
		variable collision 	: std_logic_vector(7 downto 0);
	begin
		if rising_edge(clk_sys) then
			if ce_vdp='1' then 
				color <= (others=>'0');
				collision := (others=>'0');
				for i in MAX_SPPL downto 8 loop
					if enable(i) and active(i)='1' and not (spr_color(i)="0000") then
						color <= spr_color(i);
					end if;
				end loop;
				for i in 7 downto 0 loop
					if enable(i) and active(i)='1' and not (spr_color(i)="0000") then
						collision(i) := '1';
						color <= spr_color(i);
					end if;
				end loop;
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

