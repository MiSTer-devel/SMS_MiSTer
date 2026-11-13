--
-- Controller.vhd
-- The core controller module of VM2413
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
-- [Description]
--
-- The Controller is the beginning module of the OPLL slot calculation.
-- It manages register accesses from I/O and sends proper voice parameters
-- to the succeding PhaseGenerator and EnvelopeGenerator modules.
-- The one cycle of the Controller consists of 4 stages as follows.
--
-- 1st stage:
--   * Prepare to read the register value for the current slot from RegisterMemory.
--   * Prepare to read the voice parameter for the current slot from VoiceMemory.
--   * Prepare to read the user-voice data from VoiceMemory.
--
-- 2nd stage:
--   * Wait for RegisterMemory and VoiceMemory
--
-- 3rd clock stage:
--   * Update register value if wr='1' and addr points the current OPLL channel.
--   * Update voice parameter if wr='1' and addr points the voice parameter area.
--   * Write register value to RegisterMemory.
--   * Write voice parameter to VoiceMemory.
--
-- 4th stage:
--   * Send voice and register parameters to PhaseGenerator and EnvelopeGenerator.
--   * Increment the number of the current slot.
--
-- Each stage is completed in one clock. Thus the Controller traverses all 18 opll
-- slots in 72 clocks.
--

--
--  modified by t.hara
--

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;
    use work.vm2413.all;

use ieee.std_logic_arith.conv_std_logic_vector;
entity controller is port (

    clk     : in    std_logic;
    reset   : in    std_logic;
    clkena  : in    std_logic;

    slot    : in    std_logic_vector( 4 downto 0 );
    stage   : in    std_logic_vector( 1 downto 0 );

    wr      : in    std_logic;
    addr    : in    std_logic_vector( 7 downto 0 );
    data    : in    std_logic_vector( 7 downto 0 );

    -- output parameters for phasegenerator and envelopegenerator
    am      : buffer   am_type;
    pm      : buffer   pm_type;
    wf      : buffer   wf_type;
    ml      : buffer   ml_type;
    tl      : buffer   db_type;
    fb      : buffer   fb_type;
    ar      : buffer   ar_type;
    dr      : buffer   dr_type;
    sl      : buffer   sl_type;
    rr      : buffer   rr_type;

    blk     : buffer   blk_type;
    fnum    : buffer   fnum_type;
    rks     : buffer   rks_type;

    key     : buffer   std_logic;
    rhythm  : buffer   std_logic

    -- slot_out : buffer slot_id
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
end controller;

architecture rtl of controller is

    component registermemory
        port (
            clk     : in    std_logic;
            reset   : in    std_logic;
            addr    : in    std_logic_vector(  3 downto 0 );
            wr      : in    std_logic;
            idata   : in    std_logic_vector( 23 downto 0 );
            odata   : buffer   std_logic_vector( 23 downto 0 )
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

    component voicememory port (
        clk     : in std_logic;
        reset   : in std_logic;
        idata   : in voice_type;
        wr       : in std_logic;
        rwaddr : in voice_id_type;
        roaddr : in voice_id_type;
        odata   : buffer voice_type;
        rodata : buffer voice_type ;
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

    -- the array which caches instrument number of each channel.
    type inst_array is array (ch_type'range) of integer range 0 to 15;
    signal inst_cache : inst_array;

    type kl_array is array (0 to 15) of std_logic_vector(5 downto 0);
    constant kl_table : kl_array := (
        "000000", "011000", "100000", "100101",
        "101000", "101011", "101101", "101111",
        "110000", "110010", "110011", "110100",
        "110101", "110110", "110111", "111000"
    ); -- 0.75db/step, 6db/oct

    -- signals for the read-only access ports of voicememory module.
    signal slot_voice_addr      : voice_id_type;
    signal slot_voice_data      : voice_type;

    -- signals for the read-write access ports of voicememory module.
    signal user_voice_wr        : std_logic;
    signal user_voice_addr      : voice_id_type;
    signal user_voice_rdata     : voice_type;
    signal user_voice_wdata     : voice_type;

    -- signals for the registermemory module.
    signal regs_wr              : std_logic;
    signal regs_addr            : std_logic_vector(  3 downto 0 );
    signal regs_rdata           : std_logic_vector( 23 downto 0 );
    signal regs_wdata           : std_logic_vector( 23 downto 0 );

    signal rflag                : std_logic_vector(  7 downto 0 );
    signal w_channel            : std_logic_vector(  3 downto 0 );
--  signal w_is_carrier         : std_logic;

    signal ss_local_data : std_logic_vector(31 downto 0) := (others=>'0');
    signal ss_u_register_memory_data : std_logic_vector(31 downto 0);
    signal ss_u_register_memory_ready : std_logic;
    signal ss_vmem_data : std_logic_vector(31 downto 0);
    signal ss_vmem_ready : std_logic;

begin   -- rtl

    --  レジスタ設定値を保持するためのメモリ
    u_register_memory : RegisterMemory
    port map (
        clk     => clk,
        reset   => reset,
        addr    => regs_addr,
        wr      => regs_wr,
        idata   => regs_wdata,
        odata   => regs_rdata
    ,
ss_hold=>ss_hold, ss_addr=>ss_addr, ss_read=>ss_read, ss_write=>ss_write, ss_wdata=>ss_wdata, ss_rdata=>ss_u_register_memory_data, ss_initialized=>ss_u_register_memory_ready);

    vmem : voicememory port map (
        clk, reset, user_voice_wdata, user_voice_wr, user_voice_addr, slot_voice_addr,
        user_voice_rdata, slot_voice_data ,
ss_hold,ss_addr,ss_read,ss_write,ss_wdata,ss_vmem_data,ss_vmem_ready);

    --  レジスタアドレスラッチ (第１ステージ)
    process(clk,reset)






        variable kflag : std_logic;
        variable tll : std_logic_vector(db_type'high+1 downto 0);
        variable kll : std_logic_vector(db_type'high+1 downto 0);

        variable regs_tmp       : std_logic_vector(23 downto 0);
        variable user_voice_tmp : voice_type;

        variable fb_buf : fb_type;
        variable wf_buf : wf_type;

        variable extra_mode : std_logic;
        variable vindex : voice_id_type;


variable ss_v_inst_cache : std_logic_vector(35 downto 0);
variable ss_v_regs_addr : std_logic_vector(3 downto 0);
variable ss_v_slot_voice_addr : std_logic_vector(5 downto 0);
variable ss_v_user_voice_addr : std_logic_vector(5 downto 0);
variable ss_v_user_voice_wr : std_logic_vector(0 downto 0);
variable ss_v_user_voice_wdata : std_logic_vector(35 downto 0);
variable ss_v_regs_wr : std_logic_vector(0 downto 0);
variable ss_v_regs_wdata : std_logic_vector(23 downto 0);
variable ss_v_rflag : std_logic_vector(7 downto 0);
variable ss_v_am : std_logic_vector(0 downto 0);
variable ss_v_pm : std_logic_vector(0 downto 0);
variable ss_v_wf : std_logic_vector(0 downto 0);
variable ss_v_ml : std_logic_vector(3 downto 0);
variable ss_v_tl : std_logic_vector(6 downto 0);
variable ss_v_fb : std_logic_vector(2 downto 0);
variable ss_v_ar : std_logic_vector(3 downto 0);
variable ss_v_dr : std_logic_vector(3 downto 0);
variable ss_v_sl : std_logic_vector(3 downto 0);
variable ss_v_rr : std_logic_vector(3 downto 0);
variable ss_v_blk : std_logic_vector(2 downto 0);
variable ss_v_fnum : std_logic_vector(8 downto 0);
variable ss_v_rks : std_logic_vector(3 downto 0);
variable ss_v_key : std_logic_vector(0 downto 0);
variable ss_v_rhythm : std_logic_vector(0 downto 0);
variable ss_v_extra_mode : std_logic_vector(0 downto 0);
variable ss_v_vindex : std_logic_vector(5 downto 0);
variable ss_response : std_logic_vector(31 downto 0);
begin
if reset='1' then
ss_local_data <= (others=>'0');

            regs_addr   <= (others => '0');


            slot_voice_addr <= 0;



            key <= '0';
            rhythm <= '0';
            tll := (others=>'0');
            kll := (others=>'0');
            kflag := '0';
            rflag <= (others=>'0');
            user_voice_wr <= '0';
            user_voice_addr <= 0;
            regs_wr <='0';
            ar  <= (others=>'0');
            dr  <= (others=>'0');
            sl  <= (others=>'0');
            rr  <= (others=>'0');
            tl  <= (others=>'0');
            fb  <= (others=>'0');
            wf  <= '0';
            ml  <= (others=>'0');
            fnum <= (others=>'0');
            blk <= (others=>'0');
            key <= '0';
            rks <= (others=>'0');
            rhythm <= '0';
            extra_mode := '0';
            vindex := 0;


elsif rising_edge(clk) then

ss_response := (others=>'0');
if ss_hold='1' and (ss_read='1' or ss_write='1') then
ss_v_inst_cache(3 downto 0) := conv_std_logic_vector(inst_cache(0),4);
ss_v_inst_cache(7 downto 4) := conv_std_logic_vector(inst_cache(1),4);
ss_v_inst_cache(11 downto 8) := conv_std_logic_vector(inst_cache(2),4);
ss_v_inst_cache(15 downto 12) := conv_std_logic_vector(inst_cache(3),4);
ss_v_inst_cache(19 downto 16) := conv_std_logic_vector(inst_cache(4),4);
ss_v_inst_cache(23 downto 20) := conv_std_logic_vector(inst_cache(5),4);
ss_v_inst_cache(27 downto 24) := conv_std_logic_vector(inst_cache(6),4);
ss_v_inst_cache(31 downto 28) := conv_std_logic_vector(inst_cache(7),4);
ss_v_inst_cache(35 downto 32) := conv_std_logic_vector(inst_cache(8),4);
ss_v_regs_addr := regs_addr;
ss_v_slot_voice_addr := conv_std_logic_vector(slot_voice_addr,6);
ss_v_user_voice_addr := conv_std_logic_vector(user_voice_addr,6);
ss_v_user_voice_wr := (0 => user_voice_wr);
ss_v_user_voice_wdata := CONV_VOICE_VECTOR(user_voice_wdata);
ss_v_regs_wr := (0 => regs_wr);
ss_v_regs_wdata := regs_wdata;
ss_v_rflag := rflag;
ss_v_am := (0 => am);
ss_v_pm := (0 => pm);
ss_v_wf := (0 => wf);
ss_v_ml := ml;
ss_v_tl := tl;
ss_v_fb := fb;
ss_v_ar := ar;
ss_v_dr := dr;
ss_v_sl := sl;
ss_v_rr := rr;
ss_v_blk := blk;
ss_v_fnum := fnum;
ss_v_rks := rks;
ss_v_key := (0 => key);
ss_v_rhythm := (0 => rhythm);
ss_v_extra_mode := (0 => extra_mode);
ss_v_vindex := conv_std_logic_vector(vindex,6);

if ss_read='1' then
case conv_integer(ss_addr) is
when 80 =>
ss_response(31 downto 0) := ss_v_inst_cache(31 downto 0);
when 81 =>
ss_response(3 downto 0) := ss_v_inst_cache(35 downto 32);
ss_response(7 downto 4) := regs_addr(3 downto 0);
ss_response(13 downto 8) := ss_v_slot_voice_addr(5 downto 0);
ss_response(14) := ss_v_user_voice_addr(0);
ss_response(15) := user_voice_wr;
when 82 =>
ss_response(31 downto 0) := ss_v_user_voice_wdata(31 downto 0);
when 83 =>
ss_response(3 downto 0) := ss_v_user_voice_wdata(35 downto 32);
ss_response(4) := regs_wr;
ss_response(26 downto 5) := regs_wdata(23 downto 16) & regs_wdata(13 downto 0);
when 84 =>
ss_response(5 downto 0) := rflag(5 downto 0);
ss_response(6) := am;
ss_response(7) := pm;
ss_response(8) := wf;
ss_response(12 downto 9) := ml(3 downto 0);
ss_response(19 downto 13) := tl(6 downto 0);
ss_response(22 downto 20) := fb(2 downto 0);
ss_response(26 downto 23) := ar(3 downto 0);
ss_response(30 downto 27) := dr(3 downto 0);
when 85 =>
ss_response(3 downto 0) := sl(3 downto 0);
ss_response(7 downto 4) := rr(3 downto 0);
ss_response(10 downto 8) := blk(2 downto 0);
ss_response(19 downto 11) := fnum(8 downto 0);
ss_response(23 downto 20) := rks(3 downto 0);
ss_response(24) := key;
ss_response(25) := rhythm;
ss_response(26) := extra_mode;
ss_response(27) := ss_v_vindex(0);
when others => null; end case;
end if;
if ss_write='1' then
case conv_integer(ss_addr) is
when 80 =>
ss_v_inst_cache(31 downto 0) := ss_wdata(31 downto 0);
inst_cache(0) <= conv_integer(ss_v_inst_cache(3 downto 0));
inst_cache(1) <= conv_integer(ss_v_inst_cache(7 downto 4));
inst_cache(2) <= conv_integer(ss_v_inst_cache(11 downto 8));
inst_cache(3) <= conv_integer(ss_v_inst_cache(15 downto 12));
inst_cache(4) <= conv_integer(ss_v_inst_cache(19 downto 16));
inst_cache(5) <= conv_integer(ss_v_inst_cache(23 downto 20));
inst_cache(6) <= conv_integer(ss_v_inst_cache(27 downto 24));
inst_cache(7) <= conv_integer(ss_v_inst_cache(31 downto 28));
inst_cache(8) <= conv_integer(ss_v_inst_cache(35 downto 32));
when 81 =>
ss_v_inst_cache(35 downto 32) := ss_wdata(3 downto 0);
inst_cache(0) <= conv_integer(ss_v_inst_cache(3 downto 0));
inst_cache(1) <= conv_integer(ss_v_inst_cache(7 downto 4));
inst_cache(2) <= conv_integer(ss_v_inst_cache(11 downto 8));
inst_cache(3) <= conv_integer(ss_v_inst_cache(15 downto 12));
inst_cache(4) <= conv_integer(ss_v_inst_cache(19 downto 16));
inst_cache(5) <= conv_integer(ss_v_inst_cache(23 downto 20));
inst_cache(6) <= conv_integer(ss_v_inst_cache(27 downto 24));
inst_cache(7) <= conv_integer(ss_v_inst_cache(31 downto 28));
inst_cache(8) <= conv_integer(ss_v_inst_cache(35 downto 32));
ss_v_regs_addr(3 downto 0) := ss_wdata(7 downto 4);
regs_addr <= ss_v_regs_addr;
ss_v_slot_voice_addr(5 downto 0) := ss_wdata(13 downto 8);
slot_voice_addr <= conv_integer(ss_v_slot_voice_addr);
ss_v_user_voice_addr(0) := ss_wdata(14);
user_voice_addr <= conv_integer(ss_v_user_voice_addr);
ss_v_user_voice_wr(0) := ss_wdata(15);
user_voice_wr <= ss_v_user_voice_wr(0);
when 82 =>
ss_v_user_voice_wdata(31 downto 0) := ss_wdata(31 downto 0);
user_voice_wdata <= CONV_VOICE(ss_v_user_voice_wdata);
when 83 =>
ss_v_user_voice_wdata(35 downto 32) := ss_wdata(3 downto 0);
user_voice_wdata <= CONV_VOICE(ss_v_user_voice_wdata);
ss_v_regs_wr(0) := ss_wdata(4);
regs_wr <= ss_v_regs_wr(0);
ss_v_regs_wdata(15 downto 14) := "00"; ss_v_regs_wdata(13 downto 0) := ss_wdata(18 downto 5); ss_v_regs_wdata(23 downto 16) := ss_wdata(26 downto 19);
regs_wdata <= ss_v_regs_wdata;
when 84 =>
ss_v_rflag(5 downto 0) := ss_wdata(5 downto 0);
rflag <= ss_v_rflag;
ss_v_am(0) := ss_wdata(6);
am <= ss_v_am(0);
ss_v_pm(0) := ss_wdata(7);
pm <= ss_v_pm(0);
ss_v_wf(0) := ss_wdata(8);
wf <= ss_v_wf(0);
ss_v_ml(3 downto 0) := ss_wdata(12 downto 9);
ml <= ss_v_ml;
ss_v_tl(6 downto 0) := ss_wdata(19 downto 13);
tl <= ss_v_tl;
ss_v_fb(2 downto 0) := ss_wdata(22 downto 20);
fb <= ss_v_fb;
ss_v_ar(3 downto 0) := ss_wdata(26 downto 23);
ar <= ss_v_ar;
ss_v_dr(3 downto 0) := ss_wdata(30 downto 27);
dr <= ss_v_dr;
when 85 =>
ss_v_sl(3 downto 0) := ss_wdata(3 downto 0);
sl <= ss_v_sl;
ss_v_rr(3 downto 0) := ss_wdata(7 downto 4);
rr <= ss_v_rr;
ss_v_blk(2 downto 0) := ss_wdata(10 downto 8);
blk <= ss_v_blk;
ss_v_fnum(8 downto 0) := ss_wdata(19 downto 11);
fnum <= ss_v_fnum;
ss_v_rks(3 downto 0) := ss_wdata(23 downto 20);
rks <= ss_v_rks;
ss_v_key(0) := ss_wdata(24);
key <= ss_v_key(0);
ss_v_rhythm(0) := ss_wdata(25);
rhythm <= ss_v_rhythm(0);
ss_v_extra_mode(0) := ss_wdata(26);
extra_mode := ss_v_extra_mode(0);
ss_v_vindex(0) := ss_wdata(27);
vindex := conv_integer(ss_v_vindex);
when others => null; end case;
end if;
end if;
ss_local_data <= ss_response;

if ss_hold='0' then

            if clkena='1' then
                if( stage = "00" )then
                    regs_addr <= slot( 4 downto 1 );
                else

                end if;
            end if;


            if clkena='1' then
                if( stage = "00" )then
                    if( rflag(5) = '1' and w_channel >= "0110" )then

                        slot_voice_addr <= conv_integer(slot) - 12 + 32;
                    else
                        slot_voice_addr <= inst_cache(conv_integer(slot)/2) * 2 + conv_integer(slot) mod 2;
                    end if;
                else

                end if;
            end if;

 if clkena='1' then

            case stage is



            when "00" =>



                     vindex := conv_integer(slot) mod 2;








                user_voice_addr <= vindex;
                regs_wr <= '0';
                user_voice_wr <='0';




            when "01" =>
                null;




            when "10" =>

                if wr='1' then



                    if( extra_mode = '0' and conv_integer(addr) < 8 )then


                        user_voice_tmp := user_voice_rdata;

                        case addr(2 downto 1) is
                            when "00" =>
                                if conv_integer(addr(0 downto 0)) = (vindex mod 2) then
                                    user_voice_tmp.am := data(7);
                                    user_voice_tmp.pm := data(6);
                                    user_voice_tmp.eg := data(5);
                                    user_voice_tmp.kr := data(4);
                                    user_voice_tmp.ml := data(3 downto 0);
                                    user_voice_wr <= '1';
                                end if;

                            when "01" =>
                                if addr(0)='0' and (vindex mod 2 = 0) then
                                    user_voice_tmp.kl := data(7 downto 6);
                                    user_voice_tmp.tl := data(5 downto 0);
                                    user_voice_wr <= '1';
                                elsif addr(0)='1' and (vindex mod 2 = 0) then
                                    user_voice_tmp.wf := data(3);
                                    user_voice_tmp.fb := data(2 downto 0);
                                    user_voice_wr <= '1';
                                elsif addr(0)='1' and (vindex mod 2 = 1) then
                                    user_voice_tmp.kl := data(7 downto 6);
                                    user_voice_tmp.wf := data(4);
                                    user_voice_wr <= '1';
                                end if;

                            when "10" =>
                                if conv_integer(addr(0 downto 0)) = (vindex mod 2) then
                                    user_voice_tmp.ar := data(7 downto 4);
                                    user_voice_tmp.dr := data(3 downto 0);
                                    user_voice_wr <= '1';
                                end if;

                            when "11" =>
                                if conv_integer(addr(0 downto 0)) = (vindex mod 2) then
                                    user_voice_tmp.sl := data(7 downto 4);
                                    user_voice_tmp.rr := data(3 downto 0);
                                    user_voice_wr <= '1';
                                end if;
                        end case;

                        user_voice_wdata <= user_voice_tmp;

                    elsif conv_integer(addr) = 14 then

                        rflag <= data;

                    elsif conv_integer(addr) < 16 then

                        null;

                    elsif conv_integer(addr) <= 63 then

                        if( conv_integer(addr(3 downto 0) ) = conv_integer(slot) / 2 ) then
                            regs_tmp := regs_rdata;
                            case addr( 5 downto 4 ) is
                                when "01" =>
                                    regs_tmp(7 downto 0) := data;
                                    regs_wr <= '1';
                                when "10" =>
                                    regs_tmp(13) := data(5);
                                    regs_tmp(12) := data(4);
                                    regs_tmp(11 downto 9) := data(3 downto 1);
                                    regs_tmp(8) := data(0);
                                    regs_wr <= '1';
                                when "11" =>
                                    regs_tmp(23 downto 20) := data(7 downto 4);
                                    regs_tmp(19 downto 16) := data(3 downto 0);
                                    regs_wr <='1';
                                when others =>
                                    null;
                            end case;
                            regs_wdata <= regs_tmp;
                        end if;

                    elsif conv_integer(addr) = 240 then

                        if data(7 downto 0) = "10000000" then
                            extra_mode := '1';
                        else
                            extra_mode := '0';
                        end if;

                    end if;

                end if;




            when "11" =>





                inst_cache(conv_integer(slot)/2) <= conv_integer(regs_rdata(23 downto 20));

                rhythm <= rflag(5);


                if rflag(5) = '1' and 12 <= slot then
                    case slot is
                        when "01100" | "01101" =>
                            kflag := rflag(4);
                        when "01110" =>
                            kflag := rflag(0);
                        when "01111" =>
                            kflag := rflag(3);
                        when "10000" =>
                            kflag := rflag(2);
                        when "10001" =>
                            kflag := rflag(1);
                        when others => null;
                    end case;
                else
                    kflag := '0';
                end if;

                kflag := kflag or regs_rdata(12);


                kll := (("0"&kl_table(conv_integer(regs_rdata(8 downto 5))))
                         - ("0"&("111"-regs_rdata(11 downto 9))&"000")) & '0';

                if kll(kll'high) ='1' or slot_voice_data.kl = "00" then
                    kll := (others=>'0');
                else
                    kll := shr(kll, "11" - slot_voice_data.kl );
                end if;


                if rflag(5) = '1' and (slot = "01110" or slot = "10000") then
                    tll := ('0' & regs_rdata(23 downto 20) & "000");
                elsif( slot(0) = '0' )then
                    tll := ('0' & slot_voice_data.tl & '0');
                else
                    tll := ('0' & regs_rdata(19 downto 16) & "000");
                end if;

                tll := tll + kll;

                if tll(tll'high) ='1' then
                    tl <= (others=>'1');
                else
                    tl <= tll(tl'range);
                end if;


                fnum <= regs_rdata(8 downto 0);
                blk <= regs_rdata(11 downto 9);
                key <= kflag;

                if rflag(5) = '1' and 14 <= slot then
                    if slot_voice_data.kr = '1' then
                        rks <= "0101";
                    else
                        rks <= "00" & regs_rdata(11 downto 10);
                    end if;
                else
                    if slot_voice_data.kr = '1' then
                        rks <= regs_rdata(11 downto 9) & regs_rdata(8);
                    else
                        rks <= "00" & regs_rdata(11 downto 10);
                    end if;
                end if;





                am <= slot_voice_data.am;
                pm <= slot_voice_data.pm;
                ml <= slot_voice_data.ml;
                wf_buf := slot_voice_data.wf;
                fb_buf := slot_voice_data.fb;
                wf <= wf_buf;
                fb <= fb_buf;
                ar <= slot_voice_data.ar;
                dr <= slot_voice_data.dr;
                sl <= slot_voice_data.sl;


                if( kflag = '1' ) then
                    if slot_voice_data.eg = '1' then
                        rr <= "0000";
                    else
                        rr <= slot_voice_data.rr;
                    end if;
                else
                    if (slot(0) = '0') and not ( rflag(5) = '1' and (7 <= conv_integer(slot)/2) ) then
                        rr  <= "0000";
                    elsif regs_rdata(13) = '1' then
                        rr  <= "0101";
                    elsif slot_voice_data.eg = '0' then
                        rr  <= "0111";
                    else
                        rr  <= slot_voice_data.rr;
                    end if;
                end if;

            end case;

        end if;

end if;
end if;
end process;


    --  現在のスロットの音色データ読み出しアドレスラッチ (第１ステージ)


    w_channel       <= slot( 4 downto 1 );
--  w_is_carrier    <= slot( 0 );



ss_rdata <= ss_local_data or ss_u_register_memory_data or ss_vmem_data;
ss_initialized <= '1' and ss_u_register_memory_ready and ss_vmem_ready;

end rtl;
