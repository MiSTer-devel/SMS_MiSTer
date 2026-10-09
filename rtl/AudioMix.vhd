-- A simple audio mixer which avoids attenuation by clipping extremities
--
-- Copyright 2020 by Alastair M. Robinson

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity AudioMix is
port
(
	clk : in std_logic;
	audio_in_l1 : in signed(15 downto 0);
	audio_in_l2 : in signed(15 downto 0);
	audio_in_r1 : in signed(15 downto 0);
	audio_in_r2 : in signed(15 downto 0);
	audio_l : out signed(15 downto 0);
	audio_r : out signed(15 downto 0);
	ss_phase_out : out std_logic;
	ss_phase_in : in std_logic := '0';
	ss_phase_set : in std_logic := '0'
);
end entity;

architecture rtl of AudioMix is

signal in1 : signed(16 downto 0);
signal in2 : signed(16 downto 0);
signal sum : signed(16 downto 0);
signal overflow : std_logic;
signal clipped : signed(16 downto 0);
signal toggle : std_logic;
signal phase : std_logic;

begin
ss_phase_out <= toggle;
-- The registered release strobe arrives on the first resumed clock. Use the
-- saved phase for that clock's output selection as well as the next toggle.
phase <= ss_phase_in when ss_phase_set='1' else toggle;

in1(16)<=in1(15);
in2(16)<=in2(15);

in1(15 downto 0)<=audio_in_l1 when phase='0' else audio_in_r1;
in2(15 downto 0)<=audio_in_l2 when phase='0' else audio_in_r2;

sum<=in1+in2;
overflow<=sum(15) xor sum(16);

clipped<=sum when overflow='0' else (others=>sum(16));

process(clk)
begin
	if rising_edge(clk) then
		if phase='0' then
			audio_l<=clipped(15 downto 0);
		else
			audio_r<=clipped(15 downto 0);
		end if;
		toggle<=not phase;
	end if;
end process;


end architecture;
