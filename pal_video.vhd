library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pal_video is
	Port (
		clk8:				in  std_logic;
		x: 				out unsigned(8 downto 0);
		y:					out unsigned(7 downto 0);
		hsync:			out std_logic;
		vsync:			out std_logic;
		de:	  			out std_logic);
end pal_video;

architecture Behavioral of pal_video is

	signal hcount:			unsigned(8 downto 0) := (others => '0');
	signal vcount:			unsigned(8 downto 0) := (others => '0');
	signal y9:				unsigned(8 downto 0);

begin

	process (clk8)
	begin
		if rising_edge(clk8) then
			if hcount=511 then
				hcount <= (others => '0');
				hsync <= '1';
				if vcount=311 then
					vcount <= (others=>'0');
					vsync <= '1';
				else
					vcount <= vcount + 1;
					if vcount = 4 then
						vsync <= '0';
					end if;
				end if;
			else
				hcount <= hcount + 1;
				if hcount = 36 then
					hsync <= '0';
				end if;
			end if;
		end if;
	end process;
	
	x	<= hcount-164;
	y9	<= vcount-64;
	y	<= y9(7 downto 0);

	process (clk8)
	begin
		if rising_edge(clk8) then
			if (hcount>=166 and hcount<422 and vcount>=64 and vcount<256) then
				de <= '1';
			else
				de <= '0';
			end if;
		end if;
	end process;
	
end Behavioral;

