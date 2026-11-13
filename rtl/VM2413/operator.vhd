--
-- Operator.vhd
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
entity Operator is
    port (
        clk     : in    std_logic;
        reset   : in    std_logic;
        clkena  : in    std_logic;

        slot    : in    SLOT_TYPE;
        stage   : in    STAGE_TYPE;
        rhythm  : in    std_logic;

        WF      : in    WF_TYPE;
        FB      : in    FB_TYPE;

        noise   : in    std_logic;
        pgout   : in    std_logic_vector( 17 downto 0 );    --  整数部 9bit, 小数部 9bit
        egout   : in    std_logic_vector( 12 downto 0 );

        faddr   : buffer   CH_TYPE;
        fdata   : in    SIGNED_LI_TYPE;

        opout   : buffer   std_logic_vector( 13 downto 0 )     -- 整数部 8bit, 小数部 6bit
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
end Operator;

architecture rtl of Operator is

    component SineTable
        port (
            clk     : in    std_logic;
            clkena  : in    std_logic;
            wf      : in    std_logic;
            addr    : in    std_logic_vector( 17 downto 0 );    --  整数部 9bit, 小数部 9bit
            data    : buffer   std_logic_vector( 13 downto 0 )     --  整数部 8bit, 小数部 6bit
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

    signal addr         : std_logic_vector( 17 downto 0 );
    signal data         : std_logic_vector( 13 downto 0 );
    signal w_is_carrier : std_logic;
    signal w_modula_m   : std_logic_vector( LI_TYPE'high + 2 + 9 downto 0 );
    signal w_modula_c   : std_logic_vector( LI_TYPE'high + 2 + 9 downto 0 );
    signal w_modula     : std_logic_vector( LI_TYPE'high + 2 + 9 downto 0 );
    signal ff_egout     : std_logic_vector( 12 downto 0 );
    signal ss_local_data : std_logic_vector(31 downto 0) := (others=>'0');
    signal ss_u_sine_table_data : std_logic_vector(31 downto 0);
    signal ss_u_sine_table_ready : std_logic;

begin

    --  サイン波（対数表現）--------------------------------------------------
    --  addr 指定した次々サイクルに data が出てくる
    --
    --  stage   X 00    X 01    X 10    X 11    X 00
    --  addr            X 確定
    --  data                            X 確定
    --  opout                                   X 確定
    --
    u_sine_table : SineTable
    port map(
        clk     => clk,
        clkena  => clkena,
        wf      => wf,
        addr    => addr,
        data    => data
    ,
ss_hold=>ss_hold, ss_addr=>ss_addr, ss_read=>ss_read, ss_write=>ss_write, ss_wdata=>ss_wdata, ss_rdata=>ss_u_sine_table_data, ss_initialized=>ss_u_sine_table_ready);

    w_is_carrier    <=  slot(0);
    w_modula_m      <=  (others => '0') when( fb = "000" )else
                        shr( '0' & fdata.value & '0' & "000000000", "111" xor fb );
    w_modula_c      <=  fdata.value & "00" & "000000000";
    w_modula        <=  w_modula_c  when( w_is_carrier = '1' )else
                        w_modula_m;

    process(clk,reset)

        variable opout_buf  : std_logic_vector( 13 downto 0 );  --  整数部 8bit, 小数部 6bit

variable ss_v_addr : std_logic_vector(17 downto 0);
variable ss_v_ff_egout : std_logic_vector(12 downto 0);
variable ss_v_faddr : std_logic_vector(3 downto 0);
variable ss_v_opout : std_logic_vector(13 downto 0);
variable ss_response : std_logic_vector(31 downto 0);
begin
if reset='1' then
ss_local_data <= (others=>'0');

            opout       <= (others => '0');
            ff_egout    <= (others => '0');

elsif rising_edge(clk) then

ss_response := (others=>'0');
if ss_hold='1' and (ss_read='1' or ss_write='1') then
ss_v_addr := addr;
ss_v_ff_egout := ff_egout;
ss_v_faddr := conv_std_logic_vector(faddr,4);
ss_v_opout := opout;

if ss_read='1' then
case conv_integer(ss_addr) is
when 96 =>
ss_response(17 downto 0) := addr(17 downto 0);
ss_response(30 downto 18) := ff_egout(12 downto 0);
when 97 =>
ss_response(3 downto 0) := ss_v_faddr(3 downto 0);
ss_response(17 downto 4) := opout(13 downto 0);
when others => null; end case;
end if;
if ss_write='1' then
case conv_integer(ss_addr) is
when 96 =>
ss_v_addr(17 downto 0) := ss_wdata(17 downto 0);
addr <= ss_v_addr;
ss_v_ff_egout(12 downto 0) := ss_wdata(30 downto 18);
ff_egout <= ss_v_ff_egout;
when 97 =>
ss_v_faddr(3 downto 0) := ss_wdata(3 downto 0);
faddr <= conv_integer(ss_v_faddr);
ss_v_opout(13 downto 0) := ss_wdata(17 downto 4);
opout <= ss_v_opout;
when others => null; end case;
end if;
end if;
ss_local_data <= ss_response;

if ss_hold='0' then

            if( clkena = '1' )then
                if( stage = "00" )then

                    if(    rhythm = '1' and ( slot = 14 or slot = 17 ))then
                        addr <= (not noise) & "01111111" & "000000000";
                    elsif( rhythm = '1' and slot = 15 )then
                        addr <= (not pgout(pgout'high)) & "01111111" & "000000000";
                    elsif( rhythm = '1' and slot = 16 )then
                        addr <= pgout;
                    else
                        if( fdata.sign = '0' )then
                            addr <= pgout + w_modula(pgout'range);
                        else
                            addr <= pgout - w_modula(pgout'range);
                        end if;
                    end if;

                elsif( stage = "01" )then

                elsif( stage = "10" )then
                    ff_egout <= egout;


                    if( slot(0) = '1' )then
                        if( conv_integer(slot)/2 = 8 )then
                            faddr <= 0;
                        else
                            faddr <= conv_integer(slot)/2 + 1;
                        end if;
                    end if;
                elsif( stage = "11" )then

                    if ( ( '0' & ff_egout ) + ('0'& data(12 downto 0) ) ) < "10000000000000" then
                        opout_buf := data(13) & (ff_egout + data(12 downto 0) );
                    else
                        opout_buf := data(13) & "1111111111111";
                    end if;
                    opout <= opout_buf;

                end if;
            end if;


end if;
end if;
end process;

ss_rdata <= ss_local_data or ss_u_sine_table_data;
ss_initialized <= '1' and ss_u_sine_table_ready;

end rtl;
