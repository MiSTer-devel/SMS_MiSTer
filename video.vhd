library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL; 

entity video is
	Port (
		clk:				in  std_logic;
		ce_pix:			in  std_logic;
		pal:				in  std_logic;
		gg:				in  std_logic;
		border:        in  std_logic := '1';
		x: 				out std_logic_vector(8 downto 0);
		y:					out std_logic_vector(8 downto 0);
		hsync:			out std_logic;
		vsync:			out std_logic;
		hblank:			out std_logic;
		vblank:			out std_logic);
end video;

architecture Behavioral of video is

	signal ntsc_x:			std_logic_vector(8 downto 0);
	signal ntsc_y:			std_logic_vector(8 downto 0);
	signal ntsc_hsync:	std_logic;
	signal ntsc_vsync:	std_logic;
	signal ntsc_de:	   std_logic;

	signal pal_x:			std_logic_vector(8 downto 0);
	signal pal_y:			std_logic_vector(8 downto 0);
	signal pal_hsync:		std_logic;
	signal pal_vsync:		std_logic;
	signal pal_hblank:   std_logic;
	signal pal_vblank:   std_logic;
	signal ntsc_hblank:  std_logic;
	signal ntsc_vblank:  std_logic;

begin

	x <= pal_x when pal='1' else ntsc_x;
	y <= pal_y when pal='1' else ntsc_y;
	
	hsync <= pal_hsync  when pal='1' else ntsc_hsync;
	vsync <= pal_vsync  when pal='1' else ntsc_vsync;
	hblank<= pal_hblank when pal='1' else ntsc_hblank;
	vblank<= pal_vblank when pal='1' else ntsc_vblank;

	ntsc_inst: entity work.ntsc_video
	port map (
		clk	 => clk,
		ce_pix => ce_pix,
		gg		 => gg,
		border => border,
		x	 	 => ntsc_x,
		y		 => ntsc_y,
		hsync	 => ntsc_hsync,
		vsync	 => ntsc_vsync,
		hblank => ntsc_hblank,
		vblank => ntsc_vblank
	);

	pal_inst: entity work.pal_video
	port map (
		clk	 => clk,
		ce_pix => ce_pix,
		gg		 => gg,
		border => border,
		x	 	 => pal_x,
		y		 => pal_y,
		hsync	 => pal_hsync,
		vsync	 => pal_vsync,
		hblank => pal_hblank,
		vblank => pal_vblank
	);

end Behavioral;
