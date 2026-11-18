--
-- EnvelopeGenerator.vhd
-- The envelope generator module of VM2413
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
entity envelopegenerator is
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

        egout   : buffer   std_logic_vector( 12 downto 0 )     --  小数部 6bit
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
end envelopegenerator;

architecture rtl of envelopegenerator is

    component EnvelopeMemory
        port (
            clk     : in    std_logic;
            reset   : in    std_logic;

            waddr   : in    slot_type;
            wr      : in    std_logic;
            wdata   : in    egdata_type;
            raddr   : in    slot_type;
            rdata   : buffer   egdata_type
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

    component AttackTable
        port(
            clk     : in    std_logic;
            clkena  : in    std_logic;
            addr    : in    std_logic_vector( 21 downto 0 );    -- 小数部 15bit
            data    : buffer   std_logic_vector( 12 downto 0 )
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

    signal rslot    : slot_type;
    signal memin    : egdata_type;
    signal memout   : egdata_type;
    signal memwr    : std_logic;

    signal aridx    : std_logic_vector( 21 downto 0 );
    signal ardata   : std_logic_vector( 12 downto 0 );  --  小数部 6bit
    signal ss_local_data : std_logic_vector(31 downto 0) := (others=>'0');
    signal ss_u_envelope_memory_data : std_logic_vector(31 downto 0);
    signal ss_u_envelope_memory_ready : std_logic;
    signal ss_u_attack_table_data : std_logic_vector(31 downto 0);
    signal ss_u_attack_table_ready : std_logic;

begin

    --  Attack テーブル
    u_attack_table: AttackTable
    port map (
        clk     =>  clk,
        clkena  =>  clkena,
        addr    =>  aridx,
        data    =>  ardata
    ,
ss_hold=>ss_hold, ss_addr=>ss_addr, ss_read=>ss_read, ss_write=>ss_write, ss_wdata=>ss_wdata, ss_rdata=>ss_u_attack_table_data, ss_initialized=>ss_u_attack_table_ready);

    u_envelope_memory: EnvelopeMemory
    port map (
        clk     =>  clk,
        reset   =>  reset,
        waddr   =>  slot,
        wr      =>  memwr,
        wdata   =>  memin,
        raddr   =>  rslot,
        rdata   =>  memout
    ,
ss_hold=>ss_hold, ss_addr=>ss_addr, ss_read=>ss_read, ss_write=>ss_write, ss_wdata=>ss_wdata, ss_rdata=>ss_u_envelope_memory_data, ss_initialized=>ss_u_envelope_memory_ready);

    --  EnvelopeMemory のプリフェッチ
    process(clk,reset)



        variable lastkey    : std_logic_vector(18-1 downto 0);
        variable rm         : std_logic_vector(4 downto 0);
        variable egtmp      : std_logic_vector(db_type'high + 8 downto 0);  --  小数部 6bit
        variable amphase    : std_logic_vector(19 downto 0);
        variable egphase    : egphase_type;
        variable egstate    : egstate_type;
        variable dphase     : egphase_type;
        variable ntable     : std_logic_vector(17 downto 0);

variable ss_v_rslot : std_logic_vector(4 downto 0);
variable ss_v_memin : std_logic_vector(24 downto 0);
variable ss_v_memwr : std_logic_vector(0 downto 0);
variable ss_v_egout : std_logic_vector(12 downto 0);
variable ss_v_lastkey : std_logic_vector(17 downto 0);
variable ss_v_amphase : std_logic_vector(19 downto 0);
variable ss_v_egphase : std_logic_vector(22 downto 0);
variable ss_v_egstate : std_logic_vector(1 downto 0);
variable ss_v_ntable : std_logic_vector(17 downto 0);
variable ss_response : std_logic_vector(31 downto 0);
begin
if reset='1' then
ss_local_data <= (others=>'0');

            rslot   <= (others => '0');


            rm      := (others=>'0');
            lastkey := (others=>'0');
            memwr   <= '0';
            egstate := Finish;
            egphase := (others=>'0');
            ntable  := (others => '1');
            amphase(amphase'high downto amphase'high-4) := "00001";
            amphase(amphase'high-5 downto 0)            := (others=>'0');


elsif rising_edge(clk) then
aridx <= egphase(21 downto 0);
ss_response := (others=>'0');
if ss_hold='1' and (ss_read='1' or ss_write='1') then
ss_v_rslot := rslot;
ss_v_memin := CONV_EGDATA_VECTOR(memin);
ss_v_memwr := (0 => memwr);
ss_v_egout := egout;
ss_v_lastkey := lastkey;
ss_v_amphase := amphase;
ss_v_egphase := egphase;
ss_v_egstate := egstate;
ss_v_ntable := ntable;

if ss_read='1' then
case conv_integer(ss_addr) is
when 86 =>
ss_response(4 downto 0) := rslot(4 downto 0);
ss_response(29 downto 5) := ss_v_memin(24 downto 0);
ss_response(30) := memwr;
when 87 =>
ss_response(12 downto 0) := egout(12 downto 0);
ss_response(30 downto 13) := lastkey(17 downto 0);
when 88 =>
ss_response(19 downto 0) := amphase(19 downto 0);
when 89 =>
ss_response(22 downto 0) := egphase(22 downto 0);
ss_response(24 downto 23) := egstate(1 downto 0);
when 90 =>
ss_response(17 downto 0) := ntable(17 downto 0);
when others => null; end case;
end if;
if ss_write='1' then
case conv_integer(ss_addr) is
when 86 =>
ss_v_rslot(4 downto 0) := ss_wdata(4 downto 0);
rslot <= ss_v_rslot;
ss_v_memin(24 downto 0) := ss_wdata(29 downto 5);
memin <= CONV_EGDATA(ss_v_memin);
ss_v_memwr(0) := ss_wdata(30);
memwr <= ss_v_memwr(0);
when 87 =>
ss_v_egout(12 downto 0) := ss_wdata(12 downto 0);
egout <= ss_v_egout;
ss_v_lastkey(17 downto 0) := ss_wdata(30 downto 13);
lastkey := ss_v_lastkey;
when 88 =>
ss_v_amphase(19 downto 0) := ss_wdata(19 downto 0);
amphase := ss_v_amphase;
when 89 =>
ss_v_egphase(22 downto 0) := ss_wdata(22 downto 0);
egphase := ss_v_egphase;
ss_v_egstate(1 downto 0) := ss_wdata(24 downto 23);
egstate := ss_v_egstate;
when 90 =>
ss_v_ntable(17 downto 0) := ss_wdata(17 downto 0);
ntable := ss_v_ntable;
when others => null; end case;
end if;
end if;
ss_local_data <= ss_response;

if ss_hold='0' then

            if( clkena = '1' )then
                if( stage = "10" )then
                    if( slot = "10001" )then
                        rslot <= (others => '0');
                    else
                        rslot <= slot + 1;
                    end if;
                end if;
            end if;





            if( clkena = '1' )then

                ntable( 17 downto 1 )   := ntable( 16 downto 0 );
                ntable( 0 )             := ntable( 17 ) xor ntable( 14 );


                amphase := amphase + '1';
                if amphase(amphase'high downto amphase'high-4) = "11111" then
                    amphase(amphase'high downto amphase'high-4) := "00001";
                end if;

                if stage = 0 then
                    egstate := memout.state;
                    egphase := memout.phase;

                elsif stage = 1 then


                elsif stage = 2 then
                    case egstate is
                        when Attack =>
                            rm := '0'&ar;
                            egtmp := ("00"&tl&"000000") + ("00"&ardata);
                        when Decay  =>
                            rm := '0'&dr;
                            egtmp := ("00"&tl&"000000") + ("00"&egphase(22-1 downto 22-7-6));
                        when Release=>
                            rm := '0'&rr;
                            egtmp := ("00"&tl&"000000") + ("00"&egphase(22-1 downto 22-7-6));
                        when Finish =>
                            egtmp(egtmp'high downto egtmp'high -1) := "00";
                            egtmp(egtmp'high-2 downto 0) := (others=>'1');
                    end case;


                    if ntable(0)='1' and conv_integer(slot)/2 = 7 and rhythm = '1' then
                        egtmp := egtmp + "010000000000000";
                    end if;


                    if am ='1' then
                        if (amphase(amphase'high) = '0') then

                            egtmp := egtmp + ("00000"&(amphase(amphase'high-1 downto amphase'high-4-6)-"0001000000"));
                        else

                            egtmp := egtmp + ("00000"&("1111000000"-amphase(amphase'high-1 downto amphase'high-4-6)));
                        end if;
                    end if;


                    if egtmp(egtmp'high downto egtmp'high-1) = "00" then
                        egout <= egtmp(egout'range);
                    else
                        egout <= (others=>'1');
                    end if;

                    if rm /= "00000" then

                        rm := rm + rks(3 downto 2);
                        if rm(rm'high)='1' then
                            rm(3 downto 0):="1111";
                        end if;

                        case egstate is
                            when Attack =>
                                dphase(dphase'high downto 5) := (others=>'0');
                                dphase(5 downto 0) := "110" * ('1'&rks(1 downto 0));
                                dphase := SHL( dphase, rm(3 downto 0) );
                                egphase := egphase - dphase(egphase'range);
                            when Decay | Release =>
                                dphase(dphase'high downto 3) := (others=>'0');
                                dphase(2 downto 0) := '1'&rks(1 downto 0);
                                dphase  := SHL(dphase, rm(3 downto 0) - '1');
                                egphase := egphase + dphase(egphase'range);
                            when Finish =>
                                null;
                        end case;

                    end if;

                    case egstate is
                        when Attack =>
                            if egphase(egphase'high) = '1' then
                                egphase := (others=>'0');
                                egstate := Decay;
                            end if;
                        when Decay =>
                            if egphase(egphase'high downto egphase'high-4) >= '0'&sl then
                                egstate := Release;
                            end if;
                        when Release =>
                            if( egphase(egphase'high downto egphase'high-4) >= "01111" ) then
                                egstate:= Finish;
                            end if;
                        when Finish =>
                            egphase := (others => '1');
                    end case;

                    if lastkey(conv_integer(slot)) = '0' and key = '1' then
                        egphase(egphase'high):= '0';
                        egphase(egphase'high-1 downto 0) := (others =>'1');
                        egstate:= Attack;
                    elsif lastkey(conv_integer(slot)) = '1' and key = '0' and egstate /= Finish then
                        egstate:= Release;
                    end if;
                    lastkey(conv_integer(slot)) := key;


                    memin <= ( state => egstate, phase => egphase );
                    memwr <='1';
                elsif stage = 3 then

                    memwr <='0';
                end if;
            end if;


end if;
end if;
end process;




ss_rdata <= ss_local_data or ss_u_envelope_memory_data or ss_u_attack_table_data;
ss_initialized <= '1' and ss_u_envelope_memory_ready and ss_u_attack_table_ready;

end rtl;
