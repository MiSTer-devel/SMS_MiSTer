--
-- EnvelopeMemory.vhd
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
use WORK.VM2413.ALL;

use ieee.std_logic_arith.conv_std_logic_vector;
entity EnvelopeMemory is port (
  clk     : in std_logic;
  reset   : in std_logic;

  waddr   : in SLOT_TYPE;
  wr      : in std_logic;
  wdata   : in EGDATA_TYPE;
  raddr   : in SLOT_TYPE;
  rdata   : buffer EGDATA_TYPE
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
end EnvelopeMemory;

architecture RTL of EnvelopeMemory is

  type EGDATA_ARRAY is array (0 to 18-1) of EGDATA_VECTOR_TYPE;
  signal egdata_set : EGDATA_ARRAY;

    signal ss_local_data : std_logic_vector(31 downto 0) := (others=>'0');
    signal ss_mem_active : std_logic;
    signal ss_mem_index : integer range 0 to 17;
    signal ss_mem_ready : std_logic := '0';
    signal ss_mem_vector : std_logic_vector(24 downto 0);

begin

  process(clk, reset)

    variable init_slot : integer range 0 to 18;

  begin

   if reset = '1' then
ss_mem_ready <= '0';

     init_slot := 0;

   elsif rising_edge(clk) then

     ss_mem_ready <= '0'; if init_slot=18 then ss_mem_ready <= '1'; end if;
if ss_hold='0' then
if init_slot /= 18 then
       egdata_set(init_slot) <= (others=>'1');
       init_slot := init_slot + 1;
     elsif wr = '1' then
       egdata_set(conv_integer(waddr)) <= CONV_EGDATA_VECTOR(wdata);
     end if;

elsif ss_write='1' and ss_mem_active='1' then
egdata_set(ss_mem_index)<=ss_wdata(24 downto 0);
end if;
if ss_mem_active='1' then rdata <= CONV_EGDATA(egdata_set(ss_mem_index)); else rdata <= CONV_EGDATA(egdata_set(conv_integer(raddr))); end if;

   end if;

end process;
ss_mem_active <= '1' when ss_hold='1' and conv_integer(ss_addr)>=31 and conv_integer(ss_addr)<=48 else '0';
ss_mem_index <= conv_integer(ss_addr)-31 when conv_integer(ss_addr)>=31 and conv_integer(ss_addr)<=48 else 0;
ss_mem_vector <= CONV_EGDATA_VECTOR(rdata);
ss_local_data <= (6 downto 0 => '0') & ss_mem_vector when ss_mem_active='1' else (others=>'0');


ss_rdata <= ss_local_data;
ss_initialized <= ss_mem_ready;

end rtl;
