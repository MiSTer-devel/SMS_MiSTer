--
-- RegisterMemory.vhd
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
entity RegisterMemory is
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
end RegisterMemory;

architecture rtl of registermemory is
    -- Channel information storage: single-read, single-write SRAM.
    type regs_array_type is array (0 to 8) of std_logic_vector( 23 downto 0 );
    signal regs_array : regs_array_type;
    attribute ramstyle : string;
    attribute ramstyle of regs_array : signal is "logic";

    signal ss_local_data : std_logic_vector(31 downto 0) := (others=>'0');
    signal ss_mem_active : std_logic;
    signal ss_mem_index : integer range 0 to 8;
    signal ss_mem_ready : std_logic := '0';
    signal ss_mem_vector : std_logic_vector(23 downto 0);

begin
    process( reset, clk )
        variable init_state : integer range 0 to 9;
    begin
        if( reset = '1' )then
ss_mem_ready <= '0';
            init_state := 0;
        elsif rising_edge(clk) then
            ss_mem_ready <= '0'; if init_state=9 then ss_mem_ready <= '1'; end if;
if ss_hold='0' then
if( init_state /= 9 )then
                --  起動してすぐに RAM の内容を初期化する
                regs_array( init_state ) <= (others => '0');
                init_state := init_state + 1;
            elsif( wr = '1' )then
                --  書き込みサイクル
                regs_array( conv_integer(addr) ) <= idata;
            end if;
            --  読み出しは常時

elsif ss_write='1' and ss_mem_active='1' then
regs_array(ss_mem_index)<=ss_wdata(21 downto 14) & "00" & ss_wdata(13 downto 0);
end if;
if ss_mem_active='1' then odata <= regs_array(ss_mem_index); else odata <= regs_array( conv_integer(addr) ); end if;
        end if;
    end process;
ss_mem_active <= '1' when ss_hold='1' and conv_integer(ss_addr)>=0 and conv_integer(ss_addr)<=8 else '0';
ss_mem_index <= conv_integer(ss_addr)-0 when conv_integer(ss_addr)>=0 and conv_integer(ss_addr)<=8 else 0;
ss_mem_vector <= odata;
ss_local_data <= (9 downto 0 => '0') & ss_mem_vector(23 downto 16) & ss_mem_vector(13 downto 0) when ss_mem_active='1' else (others=>'0');

ss_rdata <= ss_local_data;
ss_initialized <= ss_mem_ready;

end rtl;
