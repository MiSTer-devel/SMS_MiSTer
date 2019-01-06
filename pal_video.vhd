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
				if hcount=487 then
					vcount <= vcount + 1;
					-- VCounter: 0-242, 442-511 = 313 steps
					if vcount = 242 then
						vcount <= conv_std_logic_vector(442,9);
					elsif vcount = 458 then
						vsync <= '1';
					elsif vcount = 461 then
						vsync <= '0';
					end if;
				end if;

				hcount <= hcount + 1;
				-- HCounter: 0-295, 466-511 = 342 steps
				if hcount = 295 then
					hcount <= conv_std_logic_vector(466,9);
				end if;
				if hcount = 280 then
					hsync <= '1';
				elsif hcount = 474 then
					hsync <= '0';
				end if;
			end if;
		end if;
	end process;

	x	<= hcount;
	y	<= vcount;

	process (clk)
	begin
		if rising_edge(clk) then
			if ce_pix = '1' then
--				if ((hcount>=72 and hcount<232) or (gg='0' and (hcount>=24 and hcount<280))) then
				if (hcount=499) then
					hblank <= '0';
				elsif (hcount=270) then
					hblank<='1';
				end if;
				
--				if ((vcount>=24 and vcount<168) or (gg='0' and (vcount>=0 and vcount<192))) then
				if (vcount=488) then
					vblank <= '0';
				elsif (vcount=215) then
					vblank <= '1';
				end if;
			end if;
		end if;
	end process;
	
end Behavioral;

