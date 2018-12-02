library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL; 

entity pal_video is
	Port (
		clk:				in  std_logic;
		ce_pix:			in  std_logic;
		gg:				in  std_logic;
		x: 				out std_logic_vector(8 downto 0);
		y:					out std_logic_vector(8 downto 0);
		hsync:			out std_logic;
		vsync:			out std_logic;
		hblank:			out std_logic;
		vblank:			out std_logic);
end pal_video;

architecture Behavioral of pal_video is

	signal hcount:			std_logic_vector(8 downto 0) := (others => '0');
	signal vcount:			std_logic_vector(8 downto 0) := (others => '0');

begin

	process (clk)
	begin
		if rising_edge(clk) then
			if ce_pix = '1' then
				if hcount=511 then
					hcount <= (others => '0');
					hsync <= '0';
					if vcount=511 then
						vcount <= (others=>'0');
					else
						vcount <= vcount + 1;
						if vcount = 242 then
							vcount <= vcount + 201;
						elsif vcount = 476 then
							vsync <= '0';
						elsif vcount = 471 then
							vsync <= '1';
						end if;
					end if;
				else
					hcount <= hcount + 1;
					--if hcount = 488 then
					if hcount = 317 then
						hcount <= hcount + 171;
						hsync <= '1';
					end if;
				end if;
			end if;
		end if;
	end process;
	
	x	<= hcount-24;
	y	<= vcount;

	process (clk)
	begin
		if rising_edge(clk) then
			if ce_pix = '1' then
--				if ((hcount>=72 and hcount<232) or (gg='0' and (hcount>=24 and hcount<280))) then
				if (hcount>=24 and hcount<280) then
					hblank <= '0';
				else
					hblank <= '1';
				end if;
				
--				if ((vcount>=24 and vcount<168) or (gg='0' and (vcount>=0 and vcount<192))) then
				if (vcount>=0 and vcount<192) then
					vblank <= '0';
				else
					vblank <= '1';
				end if;
			end if;
		end if;
	end process;
	
end Behavioral;

