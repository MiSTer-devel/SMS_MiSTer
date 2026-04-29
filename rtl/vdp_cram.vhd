library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vdp_cram is
	port (
		cpu_clk:	in  STD_LOGIC;
		cpu_WE:	in  STD_LOGIC;
		cpu_A:	in  STD_LOGIC_VECTOR (4 downto 0);
		cpu_D:	in  STD_LOGIC_VECTOR (11 downto 0);
		vdp_clk:	in  STD_LOGIC;
		vdp_A:	in  STD_LOGIC_VECTOR (4 downto 0);
		vdp_D:	out STD_LOGIC_VECTOR (11 downto 0);
		-- Save-state snapshot: all 32 entries read in one cycle (combinational)
		ss_D:		out STD_LOGIC_VECTOR (11*32+31 downto 0);  -- 32 × 12 bits = 384 bits
		-- Save-state restore: write one entry per cycle
		ss_wr:	in  STD_LOGIC := '0';
		ss_A:		in  STD_LOGIC_VECTOR (4 downto 0) := (others => '0');
		ss_wD:	in  STD_LOGIC_VECTOR (11 downto 0) := (others => '0')
	);
end vdp_cram;

architecture Behavioral of vdp_cram is

	type t_ram is array (0 to 31) of std_logic_vector(11 downto 0);
	signal ram : t_ram := (others => "111111111111");
	
begin

	process (cpu_clk)
		variable i : integer range 0 to 31;
	begin
		if rising_edge(cpu_clk) then
			if ss_wr = '1' then
				i := to_integer(unsigned(ss_A));
				ram(i) <= ss_wD;
			elsif cpu_WE='1' then
				i := to_integer(unsigned(cpu_A));
				ram(i) <= cpu_D;
			end if;
		end if;
	end process;

	-- Snapshot: all 32 entries read combinationally for save-state DMA
	gen_ss: for idx in 0 to 31 generate
		ss_D(idx*12+11 downto idx*12) <= ram(idx);
	end generate;

	process (vdp_clk)
		variable i : integer range 0 to 31;
	begin
		if rising_edge(vdp_clk) then
			i := to_integer(unsigned(vdp_A));
			vdp_D <= ram(i);
		end if;
	end process;

end Behavioral;

