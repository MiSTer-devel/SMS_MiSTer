library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL; 

entity gg_sio_pio is
Port(
	clock:	in  STD_LOGIC;
	ce_RD_n:	in  STD_LOGIC;
	ce_WR_n:	in  STD_LOGIC;
	A:			in  STD_LOGIC_VECTOR (2 downto 0);
	D_in:		in  STD_LOGIC_VECTOR (7 downto 0);
	D_out:	out STD_LOGIC_VECTOR (7 downto 0)
);
end gg_sio_pio;

architecture Behavioral of gg_sio_pio is
   signal wideclock : boolean := false ;
	signal shift0	: std_logic_vector (7 downto 0) := (others=>'0');

begin

	process (clock)	begin
		if rising_edge(clock) then
			if ce_WR_n= '0' then
				case A(2 downto 0) is
					when "101" 	=> null ;
					when others	=> null ;
				end case;
			end if;
		end if;
	end process;

   process (ce_RD_n) begin
		if ce_RD_n = '0' then
			case A(2 downto 0) is
				when "101" 	=> D_out <= "00111000" ;
				when others	=> D_out <= "00000000" ;
			end case;
		end if;
	end process;
end Behavioral;

	