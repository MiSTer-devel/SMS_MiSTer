--
-- FeedbackMemory.vhd
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

--
-- This module represents a store for feedback data of all OPLL channels. The feedback
-- data is written by the OutputGenerator module. Then the value written is
-- read from the Operator module.
--
use ieee.std_logic_arith.conv_std_logic_vector;
entity FeedbackMemory is port (
  clk    : in std_logic;
  reset  : in std_logic;
  wr     : in std_logic;
  waddr  : in CH_TYPE;
  wdata  : in SIGNED_LI_TYPE;
  raddr  : in CH_TYPE;
  rdata  : buffer SIGNED_LI_TYPE
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
end FeedbackMemory;

architecture RTL of FeedbackMemory is

  type SIGNED_LI_ARRAY_TYPE is array (0 to 9-1) of SIGNED_LI_VECTOR_TYPE;
  signal data_array : SIGNED_LI_ARRAY_TYPE;
  attribute ramstyle : string;
  attribute ramstyle of data_array : signal is "logic";

    signal ss_local_data : std_logic_vector(31 downto 0) := (others=>'0');
    signal ss_mem_active : std_logic;
    signal ss_mem_index : integer range 0 to 8;
    signal ss_mem_ready : std_logic := '0';
    signal ss_mem_vector : std_logic_vector(9 downto 0);

begin

  process(clk, reset)

    variable init_ch : integer range 0 to 9;

  begin

    if reset = '1' then
ss_mem_ready <= '0';

      init_ch := 0;

    elsif rising_edge(clk) then

      ss_mem_ready <= '0'; if init_ch=9 then ss_mem_ready <= '1'; end if;
if ss_hold='0' then
if init_ch /= 9 then

        data_array(init_ch) <= (others=>'0');
        init_ch := init_ch + 1;

      elsif wr='1' then

        data_array(waddr) <= CONV_SIGNED_LI_VECTOR(wdata);

      end if;


elsif ss_write='1' and ss_mem_active='1' then
data_array(ss_mem_index)<=ss_wdata(9 downto 0);
end if;
if ss_mem_active='1' then rdata <= CONV_SIGNED_LI(data_array(ss_mem_index)); else rdata <= CONV_SIGNED_LI(data_array(raddr)); end if;

    end if;

  end process;
ss_mem_active <= '1' when ss_hold='1' and conv_integer(ss_addr)>=49 and conv_integer(ss_addr)<=57 else '0';
ss_mem_index <= conv_integer(ss_addr)-49 when conv_integer(ss_addr)>=49 and conv_integer(ss_addr)<=57 else 0;
ss_mem_vector <= CONV_SIGNED_LI_VECTOR(rdata);
ss_local_data <= (21 downto 0 => '0') & ss_mem_vector when ss_mem_active='1' else (others=>'0');


ss_rdata <= ss_local_data;
ss_initialized <= ss_mem_ready;

end rtl;
