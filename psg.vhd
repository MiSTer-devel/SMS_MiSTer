-- Modified from SMS version in MiST:
-- DAC removed
-- Added clock enable
-- Jose Tejada, 26 Feb 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity psg is
	port (
		clk	 : in  STD_LOGIC;
		clken	 : in  STD_LOGIC := '1';
		reset	 : in  STD_LOGIC;
		WR_n	 : in  STD_LOGIC;
		WR_Bal : in  STD_LOGIC;
		D_in	 : in  STD_LOGIC_VECTOR(7 downto 0);
		outputL: out STD_LOGIC_VECTOR(5 downto 0);
		outputR: out STD_LOGIC_VECTOR(5 downto 0)
	);
end entity;

architecture rtl of psg is

	signal en         : std_logic;
	signal clk_divide	: unsigned(3 downto 0) := "0000";
	signal regn			: std_logic_vector(2 downto 0);
	signal tone0		: std_logic_vector(9 downto 0):="0000100000";
	signal tone1		: std_logic_vector(9 downto 0):="0000100000";
	signal tone2		: std_logic_vector(9 downto 0):="0000100000";
	signal ctrl3		: std_logic_vector(2 downto 0):="100";
	signal volume0		: std_logic_vector(3 downto 0):="1111";
	signal volume1		: std_logic_vector(3 downto 0):="1111";
	signal volume2		: std_logic_vector(3 downto 0):="1111";
	signal volume3		: std_logic_vector(3 downto 0):="1111";
	signal output0		: std_logic_vector(3 downto 0);
	signal output1		: std_logic_vector(3 downto 0);
	signal output2		: std_logic_vector(3 downto 0);
	signal output3		: std_logic_vector(3 downto 0);
	signal old_WR_n   : std_logic;
	signal Balance		: std_logic_vector(7 downto 0);
	signal output0L	: std_logic_vector(3 downto 0);
	signal output1L	: std_logic_vector(3 downto 0);
	signal output2L	: std_logic_vector(3 downto 0);
	signal output3L	: std_logic_vector(3 downto 0);
	signal output0R	: std_logic_vector(3 downto 0);
	signal output1R	: std_logic_vector(3 downto 0);
	signal output2R	: std_logic_vector(3 downto 0);
	signal output3R	: std_logic_vector(3 downto 0);
	
begin

	t0: work.psg_tone
	port map (
		clk		=> clk,
		clk_en	=> en,
		tone		=> tone0,
		volume	=> volume0,
		output	=> output0);
		
	t1: work.psg_tone
	port map (
		clk		=> clk,
		clk_en	=> en,
		tone		=> tone1,
		volume	=> volume1,
		output	=> output1);
		
	t2: work.psg_tone
	port map (
		clk		=> clk,
		clk_en	=> en,
		tone		=> tone2,
		volume	=> volume2,
		output	=> output2);

	t3: work.psg_noise
	port map (
		clk		=> clk,
		clk_en	=> en,
		style		=> ctrl3,
		tone		=> tone2,
		volume	=> volume3,
		output	=> output3);
		
	process (clk)
	begin
		if rising_edge(clk) then
			en <= '0';
			if clken='1' then
				clk_divide <= clk_divide+1;
				if clk_divide = 0 then
					en <= '1';
				end if;
			end if;
		end if;
	end process;

	process (clk)
	begin
		if rising_edge(clk) then

			old_WR_n <= WR_n;

			if reset = '1' then
				volume0 <= (others => '1');
				volume1 <= (others => '1');
				volume2 <= (others => '1');
				volume3 <= (others => '1');
				tone0 <= (others => '0');
				tone1 <= (others => '0');
				tone2 <= (others => '0');
				ctrl3 <= (others => '0');
				Balance <= (others => '1');

			elsif old_WR_n = '1' and WR_n='0' then
				if WR_Bal='1' then
					Balance <= D_in;
				elsif D_in(7)='1' then
					case D_in(6 downto 4) is
						when "000" => tone0(3 downto 0) <= D_in(3 downto 0);
						when "010" => tone1(3 downto 0) <= D_in(3 downto 0);
						when "100" => tone2(3 downto 0) <= D_in(3 downto 0);
						when "110" => ctrl3 <= D_in(2 downto 0);
						when "001" => volume0 <= D_in(3 downto 0);
						when "011" => volume1 <= D_in(3 downto 0);
						when "101" => volume2 <= D_in(3 downto 0);
						when "111" => volume3 <= D_in(3 downto 0);
						when others =>
					end case;
					regn <= D_in(6 downto 4);
				else
					case regn is
						when "000" => tone0(9 downto 4) <= D_in(5 downto 0);
						when "010" => tone1(9 downto 4) <= D_in(5 downto 0);
						when "100" => tone2(9 downto 4) <= D_in(5 downto 0);
						when "110" => 
						when "001" => volume0 <= D_in(3 downto 0);
						when "011" => volume1 <= D_in(3 downto 0);
						when "101" => volume2 <= D_in(3 downto 0);
						when "111" => volume3 <= D_in(3 downto 0);
						when others =>
					end case;
				end if;
			end if;
		end if;
	end process;
	
	output0R <= output0 when Balance(0)='1' else "0000";
	output1R <= output1 when Balance(1)='1' else "0000";
	output2R <= output2 when Balance(2)='1' else "0000";
	output3R <= output3 when Balance(3)='1' else "0000";
	output0L <= output0 when Balance(4)='1' else "0000";
	output1L <= output1 when Balance(5)='1' else "0000";
	output2L <= output2 when Balance(6)='1' else "0000";
	output3L <= output3 when Balance(7)='1' else "0000";
	outputR <= std_logic_vector(
		  unsigned("00"&output0R)
		+ unsigned("00"&output1R)
		+ unsigned("00"&output2R)
		+ unsigned("00"&output3R)
	);
	outputL <= std_logic_vector(
		  unsigned("00"&output0L)
		+ unsigned("00"&output1L)
		+ unsigned("00"&output2L)
		+ unsigned("00"&output3L)
	);

end rtl;
