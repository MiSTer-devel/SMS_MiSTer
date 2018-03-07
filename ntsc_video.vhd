library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ntsc_video is
	Port (
		clk8:				in  std_logic;
		x: 				out unsigned(8 downto 0);
		y:					out unsigned(7 downto 0);
		hsync:			out std_logic;
		vsync:			out std_logic;
		hblank:			out std_logic;
		vblank:			out std_logic);
end ntsc_video;

architecture Behavioral of ntsc_video is

	signal hcount:			unsigned(8 downto 0) := (others => '0');
	signal vcount:			unsigned(8 downto 0) := (others => '0');
	signal y9:				unsigned(8 downto 0);
	
begin

	process (clk8)
	begin
		if rising_edge(clk8) then
			if hcount=507 then
				hcount <= (others => '0');
				hsync <= '1';
				if vcount=261 then
					vcount <= (others=>'0');
					vsync <= '1';
				else
					vcount <= vcount + 1;
					if vcount = 8 then
						vsync <= '0';
					end if;
				end if;
			else
				hcount <= hcount + 1;
				if hcount = 37 then
					hsync <= '0';
				end if;
			end if;
		end if;
	end process;
	
	x	<= hcount-164;
	y9	<= vcount-40;
	y	<= y9(7 downto 0);

	process (clk8)
	begin
		if rising_edge(clk8) then
			if (hcount>=164 and hcount<420) then
				hblank <= '0';
			else
				hblank <= '1';
			end if;
			
			if (vcount>=40 and vcount<232) then
				vblank <= '0';
			else
				vblank <= '1';
			end if;
		end if;
	end process;
	
end Behavioral;

