--
-- OutputGenerator.vhd
--
-- Copyright (c) 2006 Mitsutaka Okazaki (brezza@pokipoki.org)
-- All rights reserved.
--
-- Redistribution and use of this source code or any derivative works, are
-- permitted provided that the following conditions are met:
--
-- 1. Redistributions of source code must retain the above copyright notice,
--      this list of conditions and the following disclaimer.
-- 2. Redistributions in binary form must reproduce the above copyright
--      notice, this list of conditions and the following disclaimer in the
--      documentation and/or other materials provided with the distribution.
-- 3. Redistributions may not be sold, nor may they be used in a commercial
--      product or activity without specific prior written permission.
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
entity OutputGenerator is
    port (
        clk         : in    std_logic;
        reset       : in    std_logic;
        clkena      : in    std_logic;
        slot        : in    SLOT_TYPE;
        stage       : in    STAGE_TYPE;

        rhythm      : in    std_logic;
        opout       : in    std_logic_vector( 13 downto 0 );

        faddr       : in    CH_TYPE;
        fdata       : buffer   SIGNED_LI_TYPE;

        maddr       : in    SLOT_TYPE;
        mdata       : buffer   SIGNED_LI_TYPE
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
end OutputGenerator;

architecture RTL of OutputGenerator is

    component FeedbackMemory
        port (
            clk     : in    std_logic;
            reset   : in    std_logic;
            wr      : in    std_logic;
            waddr   : in    CH_TYPE;
            wdata   : in    SIGNED_LI_TYPE;
            raddr   : in    CH_TYPE;
            rdata   : buffer   SIGNED_LI_TYPE
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

    component OutputMemory
        port (
            clk     : in    std_logic;
            reset   : in    std_logic;
            wr      : in    std_logic;
            addr    : in    SLOT_TYPE;
            wdata   : in    SIGNED_LI_TYPE;
            rdata   : buffer   SIGNED_LI_TYPE;
            addr2   : in    SLOT_TYPE;
            rdata2  : buffer   SIGNED_LI_TYPE
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

    component LinearTable
        port (
            clk      : in   std_logic;
            reset    : in   std_logic;
            addr     : in   std_logic_vector( 13 downto 0 );
            data     : buffer  SIGNED_LI_TYPE
        );
    end component;

    function AVERAGE ( L : SIGNED_LI_TYPE ; R : SIGNED_LI_TYPE ) return SIGNED_LI_TYPE is
        variable vL, vR : std_logic_vector(LI_TYPE'high + 2 downto 0);
    begin

        --  ïÑçÜÅ{ê‚ëŒíl Å® ÇQÇÃï‚êî
        if( L.sign = '0' )then
            vL := "00" & L.value;
        else
            vL := not ( "00" & L.value ) + '1';
        end if;
        if( R.sign = '0' )then
            vR := "00" & R.value;
        else
            vR := not ( "00" & R.value ) + '1';
        end if;

        vL := vL + vR;

        --  ÇQÇÃï‚êî Å® ïÑçÜÅ{ê‚ëŒílÅAÇ¬Ç¢Ç≈Ç… 1/2 î{ÅBÇ±Ç±Ç≈ÇPÉrÉbÉgè¡é∏ÅB
        if vL(vL'high) = '0' then -- positive
            return ( sign => '0', value => vL(vL'high-1 downto 1) );
        else -- negative
            vL := not ( vL - '1' );
            return ( sign => '1', value => vL(vL'high-1 downto 1) );
        end if;

    end;

    signal fb_wr, mo_wr : std_logic;
    signal fb_addr      : CH_TYPE;
    signal mo_addr      : SLOT_TYPE;
    signal li_data, fb_wdata, mo_wdata, mo_rdata : SIGNED_LI_TYPE;
    signal ss_local_data : std_logic_vector(31 downto 0) := (others=>'0');
    signal ss_Fmem_data : std_logic_vector(31 downto 0);
    signal ss_Fmem_ready : std_logic;
    signal ss_Mmem_data : std_logic_vector(31 downto 0);
    signal ss_Mmem_ready : std_logic;

begin

    Fmem : FeedbackMemory port map(
        clk     => clk,
        reset   => reset,
        wr      => fb_wr,
        waddr   => fb_addr,
        wdata   => fb_wdata,
        raddr   => faddr,
        rdata   => fdata
    ,
ss_hold=>ss_hold, ss_addr=>ss_addr, ss_read=>ss_read, ss_write=>ss_write, ss_wdata=>ss_wdata, ss_rdata=>ss_Fmem_data, ss_initialized=>ss_Fmem_ready);

    Mmem : OutputMemory port map(
        clk     => clk,
        reset   => reset,
        wr      => mo_wr,
        addr    => mo_addr,
        wdata   => mo_wdata,
        rdata   => mo_rdata,
        addr2   => maddr,
        rdata2  => mdata
    ,
ss_hold=>ss_hold, ss_addr=>ss_addr, ss_read=>ss_read, ss_write=>ss_write, ss_wdata=>ss_wdata, ss_rdata=>ss_Mmem_data, ss_initialized=>ss_Mmem_ready);

    Ltbl : LinearTable port map (
        clk     => clk,
        reset   => reset,
        addr    => opout,           --  0Å`127 (opout ÇÕ FF ÇÃèoóÕÇæÇ©ÇÁÉ_ÉCÉåÉNÉgÇ…ì¸ÇÍÇƒÇ‡ñ‚ëËÇ»Ç¢Åj
        data    => li_data          --  0Å`511
    );

    process(clk,reset)


variable ss_v_fb_wr : std_logic_vector(0 downto 0);
variable ss_v_mo_wr : std_logic_vector(0 downto 0);
variable ss_v_fb_addr : std_logic_vector(3 downto 0);
variable ss_v_mo_addr : std_logic_vector(4 downto 0);
variable ss_v_fb_wdata : std_logic_vector(9 downto 0);
variable ss_v_mo_wdata : std_logic_vector(9 downto 0);
variable ss_response : std_logic_vector(31 downto 0);
begin
if reset='1' then
ss_local_data <= (others=>'0');

            mo_wr <= '0';
            fb_wr <= '0';

elsif rising_edge(clk) then

ss_response := (others=>'0');
if ss_hold='1' and (ss_read='1' or ss_write='1') then
ss_v_fb_wr := (0 => fb_wr);
ss_v_mo_wr := (0 => mo_wr);
ss_v_fb_addr := conv_std_logic_vector(fb_addr,4);
ss_v_mo_addr := mo_addr;
ss_v_fb_wdata := CONV_SIGNED_LI_VECTOR(fb_wdata);
ss_v_mo_wdata := CONV_SIGNED_LI_VECTOR(mo_wdata);

if ss_read='1' then
case conv_integer(ss_addr) is
when 79 =>
ss_response(0) := fb_wr;
ss_response(1) := mo_wr;
ss_response(5 downto 2) := ss_v_fb_addr(3 downto 0);
ss_response(10 downto 6) := mo_addr(4 downto 0);
ss_response(20 downto 11) := ss_v_fb_wdata(9 downto 0);
ss_response(30 downto 21) := ss_v_mo_wdata(9 downto 0);
when others => null; end case;
end if;
if ss_write='1' then
case conv_integer(ss_addr) is
when 79 =>
ss_v_fb_wr(0) := ss_wdata(0);
fb_wr <= ss_v_fb_wr(0);
ss_v_mo_wr(0) := ss_wdata(1);
mo_wr <= ss_v_mo_wr(0);
ss_v_fb_addr(3 downto 0) := ss_wdata(5 downto 2);
fb_addr <= conv_integer(ss_v_fb_addr);
ss_v_mo_addr(4 downto 0) := ss_wdata(10 downto 6);
mo_addr <= ss_v_mo_addr;
ss_v_fb_wdata(9 downto 0) := ss_wdata(20 downto 11);
fb_wdata <= CONV_SIGNED_LI(ss_v_fb_wdata);
ss_v_mo_wdata(9 downto 0) := ss_wdata(30 downto 21);
mo_wdata <= CONV_SIGNED_LI(ss_v_mo_wdata);
when others => null; end case;
end if;
end if;
ss_local_data <= ss_response;

if ss_hold='0' then

            if( clkena = '1' )then
                mo_addr <= slot;

                if( stage = 0 )then
                    mo_wr   <= '0';
                    fb_wr   <= '0';

                elsif( stage = 1 )then

                elsif( stage = 2 )then

                elsif( stage = 3 )then

                    if( slot(0) = '0' )then

                        fb_addr <= conv_integer(slot)/2;
                        fb_wdata<= AVERAGE(mo_rdata, li_data);
                        fb_wr   <= '1';
                    end if;

                    mo_wdata<= li_data;
                    mo_wr   <= '1';
                end if;
            end if;


end if;
end if;
end process;


ss_rdata <= ss_local_data or ss_Fmem_data or ss_Mmem_data;
ss_initialized <= '1' and ss_Fmem_ready and ss_Mmem_ready;

end rtl;
