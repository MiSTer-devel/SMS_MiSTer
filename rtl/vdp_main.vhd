library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL; 

entity vdp_main is
	generic (
		MAX_SPPL : integer := 7
	);
	port (
		clk_sys:				in  STD_LOGIC;
		ce_vdp:				in  STD_LOGIC;
		ce_pix:				in  STD_LOGIC;
		ce_sp:				in  STD_LOGIC;
		gg:					in  std_logic;			
		sp64:					in  std_logic;			
		vram_A:				out std_logic_vector(13 downto 0);
		vram_D:				in  std_logic_vector(7 downto 0);
		cram_A:				out std_logic_vector(4 downto 0);
		cram_D:				in  std_logic_vector(11 downto 0);
			
		x:						in  std_logic_vector(8 downto 0);
		y:						in  std_logic_vector(8 downto 0);
			
		color:				out std_logic_vector (11 downto 0);
		y1:               out std_logic;
					
		display_on:			in  std_logic;
		mask_column0:		in  std_logic;
		black_column:			in  std_logic;
		smode_M1:			in  std_logic;
		smode_M3:			in  std_logic;
		smode_M4:			in  std_logic;
		overscan:			in  std_logic_vector (3 downto 0);

		bg_address:			in  std_logic_vector (3 downto 0);
		m2mg_address:		in  std_logic_vector (2 downto 0);
		m2ct_address:		in  std_logic_vector (7 downto 0);
		bg_scroll_x:		in  std_logic_vector(7 downto 0);
		bg_scroll_y:		in  std_logic_vector(7 downto 0);
		disable_hscroll:	in  std_logic;
		disable_vscroll:    in  std_logic;

		spr_address:		in  std_logic_vector (6 downto 0);
		spr_high_bits:		in  std_logic_vector(2 downto 0);
		spr_shift:			in  std_logic;	
		spr_tall:			in  std_logic;
		spr_wide:			in  std_logic;
		spr_collide:		out std_logic;
		spr_overflow:		out std_logic);	
end vdp_main;

architecture Behavioral of vdp_main is
	
	signal bg_y:			std_logic_vector(7 downto 0);
	signal bg_vram_A:		std_logic_vector(13 downto 0);
	signal bg_color:		std_logic_vector(4 downto 0);
	signal bg_priority:	std_logic;
	signal out_color: 	std_logic_vector(3 downto 0) ;	
	signal spr_vram_A:	std_logic_vector(13 downto 0);
	signal spr_color:		std_logic_vector(3 downto 0);
	
	signal line_reset:	std_logic;
 	
	
begin

	process (x,y,bg_scroll_y,disable_vscroll,smode_M1,smode_M3)
		variable sum: std_logic_vector(8 downto 0);
	begin
		if disable_vscroll = '0' or x+16 < 25*8 then
			sum := y+('0'&bg_scroll_y);
			if smode_M1='0' and smode_M3='0' then
				if (sum>=224) then sum := sum-224;
				end if;
			-- else
			--	sum(8):='0';
			end if;
			bg_y <= sum(7 downto 0);
		else
			bg_y <= y(7 downto 0);
		end if;
	end process;
	
	-- see vdp_background comment around line 53
	line_reset <= '1' when x=512-24 else '0'; -- offset should be 25 to please VDPTEST
		
	vdp_bg_inst: entity work.vdp_background
	port map (
		clk_sys			=> clk_sys,
		ce_pix			=> ce_pix,
		table_address	=> bg_address,
		pt_address		=> m2mg_address,
		ct_address		=> m2ct_address,
		reset				=> line_reset,
		disable_hscroll=> disable_hscroll,
		scroll_x 		=> bg_scroll_x,
		y					=> bg_y,
		screen_y			=> y,
		
		vram_A			=> bg_vram_A,
		vram_D			=> vram_D,		
		color				=> bg_color,
		smode_M1			=> smode_M1,
		smode_M3			=> smode_M3,
		smode_M4			=> smode_M4,
		
		priority			=> bg_priority);
		
	vdp_spr_inst: entity work.vdp_sprites
	generic map(
		MAX_SPPL => MAX_SPPL
	)
	port map (
		clk_sys			=> clk_sys,
		ce_vdp			=> ce_vdp,
		ce_pix			=> ce_pix,
		ce_sp				=> ce_sp,
		sp64				=> sp64,
		table_address	=> spr_address,
		char_high_bits	=> spr_high_bits,
		tall				=> spr_tall,
		wide				=> spr_wide,
		shift				=> spr_shift,
		x					=> x,
		y					=> y,
		collide			=> spr_collide,
		overflow			=> spr_overflow,
		smode_M1			=> smode_M1,
		smode_M3			=> smode_M3,
		smode_M4			=> smode_M4,
		vram_A			=> spr_vram_A,
		vram_D			=> vram_D,		
		color				=> spr_color);

	process (x, y, mask_column0, bg_priority, spr_color, bg_color, overscan, display_on, gg, smode_M1, smode_M3)
		variable spr_active	: boolean;
		variable bg_active	: boolean;
	begin
		y1 <= '1';
		if ((x>48 and x<=208) or (gg='0' and x<=256 and x>0)) and -- thank you slingshot
 			(mask_column0='0' or x>=9) and display_on='1' then
			if (((y>=24 and y<168) and smode_M1='0')
				or ((y>=40 and y<184) and smode_M1='1')
				or (gg='0' and y<192) 
				or (smode_M1='1' and y<224 and gg='0') 
				or (smode_M3='1' and y<240 and gg='0') ) then
				
				spr_active	:= not (spr_color="0000");
				bg_active	:= not (bg_color(3 downto 0)="0000");
				if not spr_active and not bg_active then
					out_color <= overscan ;
					cram_A <= bg_color(4)&"0000";
					y1 <= '0';
				elsif (bg_priority='0' and spr_active) or (bg_priority='1' and not bg_active) then
					out_color <= spr_color ;
					cram_A <= "1"&spr_color;
				else
					cram_A <= bg_color;
					if bg_color(3 downto 0)="0000" then
						out_color <= overscan ;
					else
						out_color <= bg_color(3 downto 0) ;
					end if;
				end if;
			else
				cram_A <= "1"&overscan;
				out_color <= overscan ;
			end if ;
		else
			cram_A <= "1"&overscan;
			out_color <= overscan ;
		end if;		
	end process;
	
	vram_A <= spr_vram_A when x>=256 and x<496 else bg_vram_A;  -- Does bg only need x<504 only?
	color <= "000000000000" when black_column='1' and mask_column0='1' and x>0 and x<9 else
			cram_D when smode_M4='1' else 
			"000000000000" when out_color="0000" else 
			"000000000000" when out_color="0001" else 
			"010010100010" when out_color="0010" else 
			"011111100110" when out_color="0011" else 
			"111101010101" when out_color="0100" else 
			"111110001000" when out_color="0101" else 
			"010101011101" when out_color="0110" else 
			"111111110100" when out_color="0111" else 
			"010101011111" when out_color="1000" else 
			"100010001111" when out_color="1001" else 
			"010111011101" when out_color="1010" else 
			"100011011110" when out_color="1011" else 
			"010010110010" when out_color="1100" else 
			"101001101011" when out_color="1101" else 
			"101110111011" when out_color="1110" else 
			"111111111111";
end Behavioral;
