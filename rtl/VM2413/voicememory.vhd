--
-- VoiceMemory.vhd
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
entity VoiceMemory is
  port (
    clk    : in std_logic;
    reset  : in std_logic;

    idata  : in VOICE_TYPE;
    wr     : in std_logic;
    rwaddr : in VOICE_ID_TYPE; -- read/write address
    roaddr : in VOICE_ID_TYPE; -- read only address
    odata  : buffer VOICE_TYPE;
    rodata : buffer VOICE_TYPE
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
end VoiceMemory;

architecture RTL of VoiceMemory is

  -- The following array is mapped into a Single-Clock Synchronous RAM with two-read
  -- addresses by Altera's QuartusII compiler.
  type VOICE_ARRAY_TYPE is array (VOICE_ID_TYPE'range) of VOICE_VECTOR_TYPE;
  signal voices : VOICE_ARRAY_TYPE;

  component VoiceRom port (
    clk   : in std_logic;
    addr  : in VOICE_ID_TYPE;
    data  : buffer VOICE_TYPE
  );
  end component;

  signal rom_addr : VOICE_ID_TYPE;
  signal rom_data : VOICE_TYPE;
  signal rstate : integer range 0 to 2;

    signal ss_local_data : std_logic_vector(31 downto 0) := (others=>'0');
    signal ss_mem_active : std_logic;
    signal ss_mem_index : integer range 0 to 37;
    signal ss_mem_ready : std_logic := '0';
    signal ss_voice_low : std_logic_vector(31 downto 0);
    signal ss_mem_vector : std_logic_vector(35 downto 0);

begin

  ROM2413 : VoiceRom port map(clk, rom_addr, rom_data);

  process(clk, reset)

    variable init_id  : integer range 0 to VOICE_ID_TYPE'high+1;

  begin

    if reset = '1' then
ss_mem_ready <= '0';

      init_id := 0;
      rstate <= 0;

    elsif rising_edge(clk) then

      ss_mem_ready <= '0'; if init_id=38 then ss_mem_ready <= '1'; end if;
if ss_hold='0' then
if init_id /= VOICE_ID_TYPE'high+1 then

        case rstate is
        when 0 =>
          rom_addr <= init_id;
          rstate <= 1;
        when 1 =>
          rstate <= 2;
        when 2 =>
          voices(init_id) <= CONV_VOICE_VECTOR(rom_data);
          rstate <= 0;
          init_id := init_id + 1;
        end case;

      elsif wr = '1' then
        voices(rwaddr) <= CONV_VOICE_VECTOR(idata);
      end if;


elsif ss_write='1' and ss_mem_active='1' then
if ss_addr(0)='1' then ss_voice_low<=ss_wdata; else voices(ss_mem_index)<=ss_wdata(3 downto 0) & ss_voice_low; end if;
end if;
if ss_mem_active='1' then odata <= CONV_VOICE(voices(ss_mem_index)); else odata <= CONV_VOICE(voices(rwaddr)); end if;
      rodata <= CONV_VOICE(voices(roaddr));

    end if;

  end process;
ss_mem_active <= '1' when ss_hold='1' and conv_integer(ss_addr)>=9 and conv_integer(ss_addr)<=12 else '0';
ss_mem_index <= (conv_integer(ss_addr)-9)/2 when conv_integer(ss_addr)>=9 and conv_integer(ss_addr)<=12 else 0;
ss_mem_vector <= CONV_VOICE_VECTOR(odata);
ss_local_data <= ss_mem_vector(31 downto 0) when ss_mem_active='1' and ss_addr(0)='1' else (27 downto 0 => '0') & ss_mem_vector(35 downto 32) when ss_mem_active='1' else (others=>'0');


ss_rdata <= ss_local_data;
ss_initialized <= ss_mem_ready;

end rtl;
