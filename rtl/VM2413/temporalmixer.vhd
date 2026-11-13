--
-- TemporalMixer.vhd
--
-- Copyright (c) 2006 Mitsutaka Okazaki (brezza@pokipoki.org)
-- All rights reserved.
--
-- Redistribution and use of this source code or any derivative works, are
-- permitted provided that the following conditions are met:
--
-- 1. Redistributions of source code must retain the above copyright notice,
--    this list of conditions and the following disclaimer.
-- 2. Redistributions in binary form must reproduce the above copyright
--    notice, this list of conditions and the following disclaimer in the
--    documentation and/or other materials provided with the distribution.
-- 3. Redistributions may not be sold, nor may they be used in a commercial
--    product or activity without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
-- "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
-- TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
-- CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
-- EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
-- PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
-- OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
-- WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
-- OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
-- ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.std_logic_arith.all;
use WORK.VM2413.ALL;

use ieee.std_logic_arith.conv_std_logic_vector;
entity TemporalMixer is
  port (
    clk    : in std_logic;
    reset  : in std_logic;
    clkena : in std_logic;

    slot   : in SLOT_TYPE;
    stage  : in STAGE_TYPE;

    rhythm : in std_logic;

    maddr : buffer SLOT_TYPE;
    mdata : in SIGNED_LI_TYPE;

    mixout : buffer std_logic_vector(13 downto 0)
  ;
        -- FM savestate access: fixed-latency 32-bit interface; no emulated clock enables.
        ss_hold : in std_logic := '0';
        ss_addr : in std_logic_vector(7 downto 0) := (others=>'0');
        ss_read : in std_logic := '0';
        ss_write : in std_logic := '0';
        ss_wdata : in std_logic_vector(31 downto 0) := (others=>'0');
        ss_rdata : out std_logic_vector(31 downto 0);
        ss_initialized : out std_logic
);
end TemporalMixer;

architecture RTL of TemporalMixer is

  signal mute : std_logic;
  signal mix  : std_logic_vector(13 downto 0);

    signal ss_local_data : std_logic_vector(31 downto 0) := (others=>'0');

begin

  process(clk,reset)


begin
if reset='1' then
ss_local_data <= (others=>'0');


      maddr  <= (others => '0');
      mute   <= '1';
		mix    <= (others =>'0');
		mixout <= (others =>'0');


elsif rising_edge(clk) then

ss_local_data <= (others=>'0');

if ss_hold='0' then
 if clkena='1' then

      if stage = 0 then

        if rhythm = '0' then

          case slot is
            when "00000" => maddr <= "00001"; mute <='0';
            when "00001" => maddr <= "00011"; mute <='0';
            when "00010" => maddr <= "00101"; mute <='0';
            when "00011" => mute <= '1';
            when "00100" => mute <= '1';
            when "00101" => mute <= '1';
            when "00110" => maddr <= "00111"; mute<='0';
            when "00111" => maddr <= "01001"; mute<='0';
            when "01000" => maddr <= "01011"; mute<='0';
            when "01001" => mute <= '1';
            when "01010" => mute <= '1';
            when "01011" => mute <= '1';
            when "01100" => maddr <= "01101"; mute<='0';
            when "01101" => maddr <= "01111"; mute<='0';
            when "01110" => maddr <= "10001"; mute<='0';
            when "01111" => mute <= '1';
            when "10000" => mute <= '1';
            when "10001" => mute <= '1';
            when others  => mute <= '1';
          end case;

        else

          case slot is
            when "00000" => maddr <= "00001"; mute <='0';
            when "00001" => maddr <= "00011"; mute <='0';
            when "00010" => maddr <= "00101"; mute <='0';
            when "00011" => maddr <= "01111"; mute <='0';
            when "00100" => maddr <= "10001"; mute <='0';
            when "00101" =>                   mute <='1';
            when "00110" => maddr <= "00111"; mute <='0';
            when "00111" => maddr <= "01001"; mute <='0';
            when "01000" => maddr <= "01011"; mute <='0';
            when "01001" => maddr <= "01110"; mute <='0';
            when "01010" => maddr <= "10000"; mute <='0';
            when "01011" => maddr <= "01101"; mute <='0';
            when "01100" => maddr <= "01111"; mute <='0';
            when "01101" => maddr <= "10001"; mute <='0';
            when "01110" => maddr <= "01110"; mute <='0';
            when "01111" => maddr <= "10000"; mute <='0';
            when "10000" => maddr <= "01101"; mute <='0';
            when "10001" =>                   mute <='1';
            when others  =>                   mute <='1';
          end case;

        end if;

      else
			if stage = 2 then
				if slot = "10001" then
					mixout <= mix;
					mix <= (others =>'0');
				else 
					if mute = '0' then
						 if mdata.sign = '0' then
							mix <= mix + mdata.value;
						 else
							mix <= mix - mdata.value;
						 end if;
					end if;
				end if;
			end if;

      end if;

    end if;

end if;
end if;
end process;


ss_rdata <= ss_local_data;
ss_initialized <= '1';

end rtl;
