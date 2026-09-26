library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity evolution_rom_address is
	port (
		evolution_game_bank61 : in std_logic_vector(7 downto 0);
		evolution_game_bank62 : in std_logic_vector(7 downto 0);
		evolution_prev_game_bank61 : in std_logic_vector(7 downto 0);
		evolution_prev_game_bank62 : in std_logic_vector(7 downto 0);
		evolution_launch_fetch_addr : in std_logic_vector(15 downto 0);
		evolution_3ffe : in std_logic_vector(7 downto 0);
		mapper_evolution : in std_logic;
		rom_a_i : in std_logic_vector(21 downto 0);
		rom_a : out std_logic_vector(23 downto 0)
	);
end entity;

architecture rtl of evolution_rom_address is
	signal evolution_game_select : std_logic_vector(15 downto 0);
	signal evolution_effective_game_select : std_logic_vector(15 downto 0);
	signal evolution_selector_page : std_logic_vector(15 downto 0);
	signal evolution_game_page   : std_logic_vector(15 downto 0);

	-- The menu's 16-byte launch records follow the physical order of the
	-- MS132X1E flash dump.  Using that stable record index avoids ambiguous
	-- $61/$62 selectors, several of which are shared by two different games.
	function evolution_record_page(
		record_addr : std_logic_vector(15 downto 0);
		fallback    : std_logic_vector(15 downto 0)
	) return std_logic_vector is
	begin
		case record_addr is
			when x"1FD8" => return x"0180"; when x"1FE8" => return x"01C0";
			when x"1FF8" => return x"05C0"; when x"2008" => return x"09C0";
			when x"2018" => return x"0DC0"; when x"2028" => return x"0FC0";
			when x"2038" => return x"1040"; when x"2048" => return x"1440";
			when x"2058" => return x"1640"; when x"2068" => return x"1840";
			when x"2078" => return x"1C40"; when x"2088" => return x"2000";
			when x"2098" => return x"2400"; when x"20A8" => return x"2800";
			when x"20B8" => return x"2C00"; when x"20C8" => return x"2E00";
			when x"20D8" => return x"3200"; when x"20E8" => return x"3400";
			when x"20F8" => return x"3800"; when x"2108" => return x"3C00";
			when x"2118" => return x"4000"; when x"2128" => return x"4200";
			when x"2138" => return x"4600"; when x"2148" => return x"4800";
			when x"2158" => return x"4C00"; when x"2168" => return x"4E00";
			when x"2178" => return x"5000"; when x"2188" => return x"5200";
			when x"2198" => return x"5600"; when x"21A8" => return x"5800";
			when x"21B8" => return x"6000"; when x"21C8" => return x"6200";
			when x"21D8" => return x"6400"; when x"21E8" => return x"6600";
			when x"21F8" => return x"6A00"; when x"2208" => return x"6A80";
			when x"2218" => return x"6E80"; when x"2228" => return x"7280";
			when x"2238" => return x"7300"; when x"2248" => return x"7700";
			when x"2258" => return x"7900"; when x"2268" => return x"7D00";
			when x"2278" => return x"7F00"; when x"2288" => return x"7F80";
			when x"2298" => return x"8000"; when x"22A8" => return x"8200";
			when x"22B8" => return x"8400"; when x"22C8" => return x"8600";
			when x"22D8" => return x"8A00"; when x"22E8" => return x"8E00";
			when x"22F8" => return x"9200"; when x"2308" => return x"9600";
			when x"2318" => return x"9800"; when x"2328" => return x"A000";
			when x"2338" => return x"A080"; when x"2348" => return x"A480";
			when x"2358" => return x"A880"; when x"2368" => return x"AC80";
			when x"2378" => return x"AD00"; when x"2388" => return x"B100";
			when x"2398" => return x"B300"; when x"23A8" => return x"B700";
			when x"23B8" => return x"B780"; when x"23C8" => return x"B980";
			when x"23D8" => return x"BA00"; when x"23E8" => return x"BAC0";
			when x"23F8" => return x"BCC0"; when x"2408" => return x"BF00";
			when x"2418" => return x"C000"; when x"2428" => return x"CF00";
			when x"2438" => return x"CF80"; when x"2448" => return x"D080";
			when x"2458" => return x"D140"; when x"2468" => return x"D240";
			when x"2478" => return x"D440"; when x"2488" => return x"D540";
			when x"2498" => return x"D640"; when x"24A8" => return x"D740";
			when x"24B8" => return x"D880"; when x"24C8" => return x"DA00";
			when x"24D8" => return x"DAC0"; when x"24E8" => return x"DBC0";
			when x"24F8" => return x"DCC0"; when x"2508" => return x"DE00";
			when x"2518" => return x"DF00"; when x"2528" => return x"E000";
			when x"2538" => return x"E100"; when x"2548" => return x"E200";
			when x"2558" => return x"E2C0"; when x"2568" => return x"E3C0";
			when x"2578" => return x"E480"; when x"2588" => return x"E540";
			when x"2598" => return x"E640"; when x"25A8" => return x"E880";
			when x"25B8" => return x"E980"; when x"25C8" => return x"EA40";
			-- Icepost Rescue occupies $EA4000-$EDBFFF but has only one menu
			-- record ($25C8).  State captures show that $25D8 is Junte 4;
			-- the old synthetic $EC4000 entry shifted every following title.
			when x"25D8" => return x"EDC0"; when x"25E8" => return x"EE80";
			when x"25F8" => return x"EF80"; when x"2608" => return x"F0C0";
			when x"2618" => return x"F180"; when x"2628" => return x"F2C0";
			when x"2638" => return x"F3C0"; when x"2648" => return x"FBC0";
			when x"2658" => return x"FBC0";
			when others  => return fallback;
		end case;
	end function;

begin
	-- Temporary diagnostic aliases confirmed by the physical dump/savestates.
	-- These are not intended to become a permanent per-game database: once
	-- all outer Flash address/control lines are understood, replace this table
	-- with the equivalent mapper equation.
	evolution_game_select <= evolution_game_bank62 & evolution_game_bank61;

	-- Some patched interrupt handlers restore a selector with A21 asserted.
	-- Resolve confirmed selector collisions while leaving standalone launches
	-- of the corresponding upper pages intact.
	evolution_effective_game_select <=
		x"2800" when evolution_game_select = x"4800" and evolution_3ffe = x"97" else
		-- The menu records are 16 bytes and follow physical-ROM order.  Use
		-- their read address only where two games share the same final selector.
		x"2C00" when evolution_game_select = x"4C00" and
		                 evolution_launch_fetch_addr = x"20B8" else
		x"2E00" when evolution_game_select = x"4E00" and
		                 evolution_launch_fetch_addr = x"20C8" else
		x"3200" when evolution_game_select = x"5200" and
		                 evolution_launch_fetch_addr = x"20D8" else
		x"A880" when evolution_game_select = x"6800" and
		                 evolution_launch_fetch_addr = x"2358" else
		x"2800" when evolution_game_select = x"4800" and
		                 (evolution_prev_game_bank62 & evolution_prev_game_bank61) = x"2800" else
		evolution_game_select;
	with evolution_effective_game_select select evolution_selector_page <=
		x"0180" when x"2180", -- timeout demo cycle: Color and Switch Test
		x"01C0" when x"21C0", -- timeout demo cycle: Sonic
		x"1040" when x"3040", -- Bonanza Bros.
		x"1640" when x"5640", -- Alex Kidd in Miracle World
		x"1C40" when x"5C40", -- Action Fighter
		x"2000" when x"4000", -- Aerial Assault
		x"2400" when x"2400", -- Alex Kidd: The Lost Stars
		x"2800" when x"2800", -- Alex Kidd in Shinobi World
		x"2C00" when x"2C00", -- Alex Kidd High Tech World
		x"3200" when x"3200", -- Aztec Adventure
		x"3400" when x"5400", -- Baku Baku Animal
		x"3800" when x"5800", -- Battle Out Run
		x"4200" when x"4200", -- Bubble Bobble
		x"4600" when x"4600", -- Taito Chase H.Q.
		x"4800" when x"4800", -- Cyber Shinobi
		x"4800" when x"6800", -- Cyber Shinobi launch selector
		x"4C00" when x"4C00", -- Dragon Crystal
		x"4E00" when x"4E00", -- Double Target
		x"5000" when x"5000", -- Enduro Racer
		x"5200" when x"5200", -- ESWAT
		x"0DC0" when x"4DC0", -- Columns
		x"CF80" when x"8F80", -- Dr. Limpeza
		x"B980" when x"9980", -- Bank Panic
		x"D440" when x"9440", -- Aquaduto
		x"D540" when x"9540", -- Bombeiros
		x"DCC0" when x"BCC0", -- Bolas e Cores
		x"DE00" when x"BE00", -- Acerte o Alvo
		x"E100" when x"A100", -- Arqueiro
		x"E000" when x"A000", -- Domine o Territorio
		x"E540" when x"A540", -- Cava Cava
		x"A000" when x"6000", -- Satellite 7
		x"E200" when x"A200", -- Ataque dos Vermes
		(evolution_game_bank62(7) &
		 not (evolution_game_bank61(7) xor evolution_game_bank62(6)) &
		 (evolution_game_bank61(6) xor evolution_game_bank61(7) xor
		  evolution_game_bank62(0) xor evolution_game_bank62(5) xor
		  evolution_game_bank62(6) xor evolution_game_bank62(7)) &
		 evolution_game_bank62(4 downto 0) & evolution_game_bank61) when others;

	-- Normal menu launches use the authoritative record-index table.  Keep the
	-- reverse-engineered selector path as a fallback for service transitions or
	-- malformed/unrecognised records.
	evolution_game_page <= evolution_record_page(
		evolution_launch_fetch_addr, evolution_selector_page);

	-- Drive the captured game base plus the cartridge-relative Sega address.
	rom_a <= std_logic_vector(
		unsigned(evolution_game_page & x"00") +
		-- Individual cartridges in the image decode at most six Sega bank
		-- bits (1 MB).  Bits 7:6 written by games are not physical ROM lines.
		resize(unsigned(rom_a_i(19 downto 0)), 24))
		when mapper_evolution = '1' and
		     (evolution_3ffe = x"87" or evolution_3ffe = x"97" or
		      evolution_3ffe = x"C7") else
		std_logic_vector(resize(unsigned(rom_a_i), 24));

end architecture;
