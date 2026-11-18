--
-- Opll.vhd
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
    use work.vm2413.all;

use ieee.std_logic_arith.conv_std_logic_vector;
entity opll is
    port(
        xin         : in  std_logic;
        xout        : buffer std_logic;
        xena        : in  std_logic;
        d           : in  std_logic_vector( 7 downto 0 );
        a           : in  std_logic;
        cs_n        : in  std_logic;
        we_n        : in  std_logic;
        ic_n        : in  std_logic;
        mixout      : buffer std_logic_vector(13 downto 0 )
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
end opll;

architecture rtl of opll is
    component slotcounter
    generic (
        delay   : in    integer
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
    end component;

    component controller port (
        clk     : in    std_logic;
        reset   : in    std_logic;
        clkena  : in    std_logic;

        slot    : in    slot_type;
        stage   : in    stage_type;

        wr      : in    std_logic;
        addr    : in    std_logic_vector( 7 downto 0 );
        data    : in    std_logic_vector( 7 downto 0 );

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

    component envelopegenerator
    port (
        clk     : in    std_logic;
        reset   : in    std_logic;
        clkena  : in    std_logic;

        slot    : in    slot_type;
        stage   : in    stage_type;
        rhythm  : in    std_logic;

        am      : in    am_type;
        tl      : in    db_type;
        ar      : in    ar_type;
        dr      : in    dr_type;
        sl      : in    sl_type;
        rr      : in    rr_type;
        rks     : in    rks_type;
        key     : in    std_logic;

        egout   : buffer   std_logic_vector( 12 downto 0 )
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

    component phasegenerator
    port (
        clk     : in    std_logic;
        reset   : in    std_logic;
        clkena  : in    std_logic;

        slot    : in    slot_type;
        stage   : in    stage_type;
        rhythm  : in    std_logic;

        pm      : in    pm_type;
        ml      : in    ml_type;
        blk     : in    blk_type;
        fnum    : in    fnum_type;
        key     : in    std_logic;

        noise   : buffer   std_logic;
        pgout   : buffer   std_logic_vector( 17 downto 0 )
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

    component operator
    port (
        clk     : in    std_logic;
        reset   : in    std_logic;
        clkena  : in    std_logic;
        slot    : in    slot_type;
        stage   : in    stage_type;
        rhythm  : in    std_logic;

        wf      : in    wf_type;
        fb      : in    fb_type;

        noise   : in    std_logic;
        pgout   : in    std_logic_vector( 17 downto 0 );
        egout   : in    std_logic_vector( 12 downto 0 );

        faddr   : buffer   ch_type;
        fdata   : in    signed_li_type;

        opout   : buffer   std_logic_vector( 13 downto 0 )
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

    component outputgenerator
    port (
        clk     : in    std_logic;
        reset   : in    std_logic;
        clkena  : in    std_logic;
        slot    : in    slot_type;
        stage   : in    stage_type;
        rhythm  : in    std_logic;

        opout   : in    std_logic_vector( 13 downto 0 );

        faddr   : in    ch_type;
        fdata   : buffer   signed_li_type;

        maddr   : in    slot_type;
        mdata   : buffer   signed_li_type
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

    component temporalmixer
    port (
        clk     : in std_logic;
        reset   : in std_logic;
        clkena  : in std_logic;

        slot    : in slot_type;
        stage   : in stage_type;

        rhythm  : in std_logic;

        maddr   : buffer slot_type;
        mdata   : in signed_li_type;

        mixout  : buffer std_logic_vector(13 downto 0)
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

    signal reset    : std_logic;

    signal opllptr  : std_logic_vector( 7 downto 0 );
    signal oplldat  : std_logic_vector( 7 downto 0 );
    signal opllwr   : std_logic;

    signal am       : am_type;
    signal pm       : pm_type;
    signal wf       : wf_type;
    signal tl       : db_type;
    signal fb       : fb_type;
    signal ar       : ar_type;
    signal dr       : dr_type;
    signal sl       : sl_type;
    signal rr       : rr_type;
    signal ml       : ml_type;
    signal fnum     : fnum_type;
    signal blk      : blk_type;
    signal rks      : rks_type;
    signal key      : std_logic;

    signal rhythm   : std_logic;

    signal noise    : std_logic;
    signal pgout    : std_logic_vector( 17 downto 0 );

    signal egout    : std_logic_vector( 12 downto 0 );

    signal opout    : std_logic_vector( 13 downto 0 );


    signal faddr    : ch_type;
    signal maddr    : slot_type;
    signal fdata    : signed_li_type;
    signal mdata    : signed_li_type;

    signal state2   : std_logic_vector( 6 downto 0 );
    signal state5   : std_logic_vector( 6 downto 0 );
    signal state8   : std_logic_vector( 6 downto 0 );
    signal slot     : slot_type;
    signal slot2    : slot_type;
    signal slot5    : slot_type;
    signal slot8    : slot_type;
    signal stage    : stage_type;
    signal stage2   : stage_type;
    signal stage5   : stage_type;
    signal stage8   : stage_type;

    signal ss_local_data : std_logic_vector(31 downto 0) := (others=>'0');
    signal ss_s0_data : std_logic_vector(31 downto 0);
    signal ss_s0_ready : std_logic;
    signal ss_s2_data : std_logic_vector(31 downto 0);
    signal ss_s2_ready : std_logic;
    signal ss_s5_data : std_logic_vector(31 downto 0);
    signal ss_s5_ready : std_logic;
    signal ss_s8_data : std_logic_vector(31 downto 0);
    signal ss_s8_ready : std_logic;
    signal ss_ct_data : std_logic_vector(31 downto 0);
    signal ss_ct_ready : std_logic;
    signal ss_eg_data : std_logic_vector(31 downto 0);
    signal ss_eg_ready : std_logic;
    signal ss_pg_data : std_logic_vector(31 downto 0);
    signal ss_pg_ready : std_logic;
    signal ss_op_data : std_logic_vector(31 downto 0);
    signal ss_op_ready : std_logic;
    signal ss_og_data : std_logic_vector(31 downto 0);
    signal ss_og_ready : std_logic;
    signal ss_tm_data : std_logic_vector(31 downto 0);
    signal ss_tm_ready : std_logic;

begin

    xout    <= xin;
    reset   <= not ic_n;

    process(xin,reset)


variable ss_v_opllptr : std_logic_vector(7 downto 0);
variable ss_v_oplldat : std_logic_vector(7 downto 0);
variable ss_v_opllwr : std_logic_vector(0 downto 0);
variable ss_response : std_logic_vector(31 downto 0);
begin
if reset='1' then
ss_local_data <= (others=>'0');

            opllwr  <= '0';
            opllptr <= (others =>'0');

elsif rising_edge(xin) then

ss_response := (others=>'0');
if ss_hold='1' and (ss_read='1' or ss_write='1') then
ss_v_opllptr := opllptr;
ss_v_oplldat := oplldat;
ss_v_opllwr := (0 => opllwr);

if ss_read='1' then
case conv_integer(ss_addr) is
when 77 =>
ss_response(7 downto 0) := opllptr(7 downto 0);
ss_response(15 downto 8) := oplldat(7 downto 0);
ss_response(16) := opllwr;
when others => null; end case;
end if;
if ss_write='1' then
case conv_integer(ss_addr) is
when 77 =>
ss_v_opllptr(7 downto 0) := ss_wdata(7 downto 0);
opllptr <= ss_v_opllptr;
ss_v_oplldat(7 downto 0) := ss_wdata(15 downto 8);
oplldat <= ss_v_oplldat;
ss_v_opllwr(0) := ss_wdata(16);
opllwr <= ss_v_opllwr(0);
when others => null; end case;
end if;
end if;
ss_local_data <= ss_response;

if ss_hold='0' then

            if( xena = '1' )then
                if(    cs_n = '0' and we_n = '0' and a = '0' )then
                    opllptr <= d;
                    opllwr  <= '0';
                elsif( cs_n = '0' and we_n = '0' and a = '1' )then
                    oplldat <= d;
                    opllwr  <= '1';
                end if;
            end if;


end if;
end if;
end process;


    s0: slotcounter
    generic map(
        delay   => 0
    )
    port map(
        clk     => xin,
        reset   => reset,
        clkena  => xena,
        slot    => slot,
        stage   => stage
    ,
ss_hold=>ss_hold, ss_addr=>ss_addr, ss_read=>ss_read, ss_write=>ss_write, ss_wdata=>ss_wdata, ss_rdata=>ss_s0_data, ss_initialized=>ss_s0_ready);

    s2: slotcounter
    generic map(
        delay   => 2
    )
    port map(
        clk     => xin,
        reset   => reset,
        clkena  => xena,
        slot    => slot2,
        stage   => stage2
    ,
ss_hold=>ss_hold, ss_addr=>ss_addr, ss_read=>ss_read, ss_write=>ss_write, ss_wdata=>ss_wdata, ss_rdata=>ss_s2_data, ss_initialized=>ss_s2_ready);

    s5: slotcounter
    generic map(
        delay   => 5
    )
    port map(
        clk     => xin,
        reset   => reset,
        clkena  => xena,
        slot    => slot5,
        stage   => stage5
    ,
ss_hold=>ss_hold, ss_addr=>ss_addr, ss_read=>ss_read, ss_write=>ss_write, ss_wdata=>ss_wdata, ss_rdata=>ss_s5_data, ss_initialized=>ss_s5_ready);

    s8: slotcounter
    generic map(
        delay   => 8
    )
    port map(
        clk     => xin,
        reset   => reset,
        clkena  => xena,
        slot    => slot8,
        stage   => stage8
    ,
ss_hold=>ss_hold, ss_addr=>ss_addr, ss_read=>ss_read, ss_write=>ss_write, ss_wdata=>ss_wdata, ss_rdata=>ss_s8_data, ss_initialized=>ss_s8_ready);

    -- no delay
    ct: controller port map (
        xin,reset,xena, slot, stage, opllwr,opllptr,oplldat,
        am,pm,wf,ml,tl,fb,ar,dr,sl,rr,blk,fnum,rks,key,rhythm,
ss_hold,ss_addr,ss_read,ss_write,ss_wdata,ss_ct_data,ss_ct_ready);

    -- 2 stages delay
    eg: envelopegenerator port map (
        xin,reset,xena,
        slot2, stage2, rhythm,
        am, tl, ar, dr, sl, rr, rks, key,
        egout
    ,
ss_hold,ss_addr,ss_read,ss_write,ss_wdata,ss_eg_data,ss_eg_ready);

    pg: phasegenerator port map (
        xin,reset,xena,
        slot2, stage2, rhythm,
        pm, ml, blk, fnum, key,
        noise, pgout
    ,
ss_hold,ss_addr,ss_read,ss_write,ss_wdata,ss_pg_data,ss_pg_ready);

    -- 5 stages delay
    op: operator port map (
        xin,reset,xena,
        slot5, stage5, rhythm,
        wf, fb, noise, pgout, egout, faddr, fdata, opout
    ,
ss_hold,ss_addr,ss_read,ss_write,ss_wdata,ss_op_data,ss_op_ready);

    -- 8 stages delay
    og: outputgenerator port map (
        xin, reset, xena, slot8, stage8, rhythm,
        opout, faddr, fdata, maddr, mdata
    ,
ss_hold,ss_addr,ss_read,ss_write,ss_wdata,ss_og_data,ss_og_ready);

    -- independent from delay
    tm: temporalmixer port map (
        xin, reset, xena,
        slot, stage, rhythm,
        maddr, mdata,
        mixout
    ,
ss_hold,ss_addr,ss_read,ss_write,ss_wdata,ss_tm_data,ss_tm_ready);

ss_rdata <= ss_local_data or ss_s0_data or ss_s2_data or ss_s5_data or ss_s8_data or ss_ct_data or ss_eg_data or ss_pg_data or ss_op_data or ss_og_data or ss_tm_data;
ss_initialized <= '1' and ss_s0_ready and ss_s2_ready and ss_s5_ready and ss_s8_ready and ss_ct_ready and ss_eg_ready and ss_pg_ready and ss_op_ready and ss_og_ready and ss_tm_ready;

end rtl;
