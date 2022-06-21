library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.VM2413.ALL;
entity oplldelay is
     port(
        xin         : in  std_logic;
        xout        : out std_logic;
        xena        : in  std_logic;
        delay       : in  std_logic;
        d           : in  std_logic_vector( 7 downto 0 );
        a           : in  std_logic;
        cs_n        : in  std_logic;
        we_n        : in  std_logic;
        ic_n        : in  std_logic;
        mixout      : out std_logic_vector(13 downto 0 )
    );
end oplldelay;

architecture RTL of oplldelay is
	
	signal counter: integer range 0 to 72*6;

	signal AdressBuf : std_logic;
	signal DboBuf	 : std_logic_vector(7 downto 0);
	signal WE_NBuf   : std_logic;


begin
	process(xin)
	begin
		if rising_edge(xin) then
			if counter/=0 then
				counter <= counter-1;
			else
				if we_n='0' then
					if delay='1' then
						if a='0' then
							counter <= 4*6;
						else
							counter <= 72*6;
						end if;
					end if;
					AdressBuf <= a;
					dbobuf <= d;
					WE_NBuf <= we_n;
				end if;
			end if;

		end if;
	end process;
	fm:work.opll
	port map
	(
		xin		=> xin,
		xena		=> xena,
		d        => dbobuf,
		a        => AdressBuf,
		cs_n     => '0',
		we_n		=> WE_NBuf,
		ic_n		=> ic_n,
		mixout   => mixout
	);
end RTL;