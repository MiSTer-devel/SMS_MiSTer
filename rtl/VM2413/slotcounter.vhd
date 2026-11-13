--
-- SlotCounter.vhd
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

--
--  modified by t.hara
--

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;

use ieee.std_logic_arith.conv_std_logic_vector;
entity SlotCounter is
    generic (
        delay   : integer
    );
    port (
        clk     : in    std_logic;
        reset   : in    std_logic;
        clkena  : in    std_logic;

        slot    : buffer   std_logic_vector( 4 downto 0 );
        stage   : buffer   std_logic_vector( 1 downto 0 )
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
end SlotCounter;

architecture rtl of SlotCounter is
    signal ff_count     : std_logic_vector( 6 downto 0 );
    signal ss_local_data : std_logic_vector(31 downto 0) := (others=>'0');

begin

    process(clk,reset)


variable ss_v_ff_count : std_logic_vector(6 downto 0);
variable ss_response : std_logic_vector(31 downto 0);
begin
if reset='1' then
ss_local_data <= (others=>'0');

            ff_count <= "1000111" - delay;

elsif rising_edge(clk) then

ss_response := (others=>'0');
if ss_hold='1' and (ss_read='1' or ss_write='1') then
ss_v_ff_count := ff_count;

if ss_read='1' then
case conv_integer(ss_addr) is
when 78 => if delay=0 then ss_response(6 downto 0):=ff_count; end if;
when others => null; end case;
end if;
if ss_write='1' then
case conv_integer(ss_addr) is
when 78 => if conv_integer(ss_wdata(6 downto 0)) >= delay then ff_count <= conv_std_logic_vector(conv_integer(ss_wdata(6 downto 0))-delay,7); else ff_count <= conv_std_logic_vector(conv_integer(ss_wdata(6 downto 0))+72-delay,7); end if;
when others => null; end case;
end if;
end if;
ss_local_data <= ss_response;

if ss_hold='0' then

            if( clkena ='1' )then
                if( ff_count = "1000111" )then
                    ff_count <= (others => '0');
                else
                    ff_count <= ff_count + 1;
                end if;
            end if;


end if;
end if;
end process;


    stage   <= ff_count( 1 downto 0 );      --  0`3 ‚ÅzŠÂ
    slot    <= ff_count( 6 downto 2 );      --  0`17 ‚ÅzŠÂ
ss_rdata <= ss_local_data;
ss_initialized <= '1';

end rtl;
