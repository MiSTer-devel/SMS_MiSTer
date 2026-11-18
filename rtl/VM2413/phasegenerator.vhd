--
-- PhaseGenerator.vhd
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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use WORK.VM2413.ALL;

use ieee.std_logic_arith.conv_std_logic_vector;
entity PhaseGenerator is port (
  clk      : in std_logic;
  reset    : in std_logic;
  clkena   : in std_logic;

  slot     : in SLOT_TYPE;
  stage    : in STAGE_TYPE;

  rhythm : in std_logic;
  pm     : in PM_TYPE;
  ml     : in ML_TYPE;
  blk    : in BLK_TYPE;
  fnum   : in FNUM_TYPE;
  key    : in std_logic;

  noise  : buffer std_logic;
  pgout  : buffer std_logic_vector( 17 downto 0 )
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
end PhaseGenerator;

architecture RTL of PhaseGenerator is

  component PhaseMemory is port (
    clk     : in std_logic;
    reset   : in std_logic;

    slot    : in SLOT_TYPE;
    memwr   : in std_logic;

    memout  : buffer PHASE_TYPE;
    memin   : in  PHASE_TYPE
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
  end component;

  type ML_TABLE is array (0 to 15) of std_logic_vector(4 downto 0);

  constant mltbl : ML_TABLE := (
    "00001","00010","00100","00110","01000","01010","01100","01110",
    "10000","10010","10100","10100","11000","11000","11110","11110"
  );

  constant noise14_tbl : std_logic_vector(63 downto 0) :=
    "1000100010001000100010001000100100010001000100010001000100010000";
  constant noise17_tbl : std_logic_vector(7 downto 0) :=
    "00001010";

  -- Signals connected to the phase memory.
  signal memwr : std_logic;
  signal memout, memin : PHASE_TYPE;

  -- Counter for pitch modulation;
  signal pmcount : std_logic_vector(12 downto 0);

    signal ss_local_data : std_logic_vector(31 downto 0) := (others=>'0');
    signal ss_MEM_data : std_logic_vector(31 downto 0);
    signal ss_MEM_ready : std_logic;

begin

    process(clk,reset)

        variable lastkey : std_logic_vector(18-1 downto 0);
        variable dphase : PHASE_TYPE;
        variable noise14 : std_logic;
        variable noise17 : std_logic;
        variable pgout_buf : std_logic_vector( 17 downto 0 );   --  êÆêîïî 9bit, è¨êîïî 9bit

variable ss_v_memwr : std_logic_vector(0 downto 0);
variable ss_v_memin : std_logic_vector(17 downto 0);
variable ss_v_pmcount : std_logic_vector(12 downto 0);
variable ss_v_noise : std_logic_vector(0 downto 0);
variable ss_v_pgout : std_logic_vector(17 downto 0);
variable ss_v_lastkey : std_logic_vector(17 downto 0);
variable ss_v_noise14 : std_logic_vector(0 downto 0);
variable ss_v_noise17 : std_logic_vector(0 downto 0);
variable ss_response : std_logic_vector(31 downto 0);
begin
if reset='1' then
ss_local_data <= (others=>'0');


      pmcount <= (others=>'0');
      memwr <= '0';
      lastkey := (others=>'0');
      dphase  := (others=>'0');
      noise14 := '0';
      noise17 := '0';


elsif rising_edge(clk) then

ss_response := (others=>'0');
if ss_hold='1' and (ss_read='1' or ss_write='1') then
ss_v_memwr := (0 => memwr);
ss_v_memin := memin;
ss_v_pmcount := pmcount;
ss_v_noise := (0 => noise);
ss_v_pgout := pgout;
ss_v_lastkey := lastkey;
ss_v_noise14 := (0 => noise14);
ss_v_noise17 := (0 => noise17);

if ss_read='1' then
case conv_integer(ss_addr) is
when 93 =>
ss_response(0) := memwr;
ss_response(18 downto 1) := memin(17 downto 0);
ss_response(31 downto 19) := pmcount(12 downto 0);
when 94 =>
ss_response(0) := noise;
ss_response(18 downto 1) := pgout(17 downto 0);
when 95 =>
ss_response(17 downto 0) := lastkey(17 downto 0);
ss_response(18) := noise14;
ss_response(19) := noise17;
when others => null; end case;
end if;
if ss_write='1' then
case conv_integer(ss_addr) is
when 93 =>
ss_v_memwr(0) := ss_wdata(0);
memwr <= ss_v_memwr(0);
ss_v_memin(17 downto 0) := ss_wdata(18 downto 1);
memin <= ss_v_memin;
ss_v_pmcount(12 downto 0) := ss_wdata(31 downto 19);
pmcount <= ss_v_pmcount;
when 94 =>
ss_v_noise(0) := ss_wdata(0);
noise <= ss_v_noise(0);
ss_v_pgout(17 downto 0) := ss_wdata(18 downto 1);
pgout <= ss_v_pgout;
when 95 =>
ss_v_lastkey(17 downto 0) := ss_wdata(17 downto 0);
lastkey := ss_v_lastkey;
ss_v_noise14(0) := ss_wdata(18);
noise14 := ss_v_noise14(0);
ss_v_noise17(0) := ss_wdata(19);
noise17 := ss_v_noise17(0);
when others => null; end case;
end if;
end if;
ss_local_data <= ss_response;

if ss_hold='0' then
 if clkena = '1' then

      noise <= noise14 xor noise17;

      if stage = 0 then

        memwr <= '0';

      elsif stage = 1 then



      elsif stage = 2 then


        if slot = 0 then
          pmcount <= pmcount + '1';
        end if;


        dphase := (SHL("00000000"&(fnum*mltbl(CONV_INTEGER(ml))),blk)(19 downto 2));

        if pm ='1' then
           case pmcount(pmcount'high downto pmcount'high-1) is
             when "01" =>
               dphase := dphase + SHR(dphase,"111");
             when "11" =>
               dphase := dphase - SHR(dphase,"111");
             when others => null;
           end case;
        end if;


        if lastkey(conv_integer(slot)) = '0' and key = '1' and (rhythm = '0' or (slot /= "01110" and slot /= "10001")) then
          memin <= (others=>'0');
        else
          memin <= memout + dphase;
        end if;
        lastkey(conv_integer(slot)) := key;


        if slot = "01110" then
          noise14 := noise14_tbl(CONV_INTEGER(memout(15 downto 10)));
        elsif slot = "10001" then
          noise17 := noise17_tbl(CONV_INTEGER(memout(13 downto 11)));
        end if;

        pgout_buf := memout;
        pgout <= pgout_buf;
        memwr <= '1';

      elsif stage = 3 then

        memwr <= '0';

      end if;

    end if;

end if;
end if;
end process;


  MEM : PhaseMemory port map(clk,reset,slot,memwr,memout,memin,
ss_hold,ss_addr,ss_read,ss_write,ss_wdata,ss_MEM_data,ss_MEM_ready);

ss_rdata <= ss_local_data or ss_MEM_data;
ss_initialized <= '1' and ss_MEM_ready;

end rtl;
