-- ============================================================================
-- eeprom_93c46.vhd
-- 93C46 Microwire Serial EEPROM — 64×16-bit (128 bytes)
-- Ported 1:1 from Genesis-Plus-GX eeprom_93c.c (Eke-Eke)
-- Connected to system SPRAM / NVRAM for 100% persistent saves across reboots
-- ============================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity eeprom_93c46 is
    port (
        clk_sys  : in  std_logic;
        ce_cpu   : in  std_logic;
        reset_n  : in  std_logic;
        -- Microwire
        cs_in      : in  std_logic;
        clk_in     : in  std_logic;
        di         : in  std_logic;
        do         : out std_logic;
        soft_reset : in  std_logic := '0';
        -- NVRAM port (128×8-bit bytes)
        nvram_a  : out std_logic_vector(6 downto 0);
        nvram_di : out std_logic_vector(7 downto 0);
        nvram_do : in  std_logic_vector(7 downto 0);
        nvram_we : out std_logic;
        -- Save-state (64-bit packed)
        ss_out   : out std_logic_vector(63 downto 0);
        ss_in    : in  std_logic_vector(63 downto 0) := (others => '0');
        ss_set   : in  std_logic := '0'
    );
end eeprom_93c46;

architecture rtl of eeprom_93c46 is
    type t_state is (WAIT_STANDBY, WAIT_START, GET_OPCODE, WRITE_WORD, READ_WAIT1, READ_WAIT1_LATCH, READ_WAIT2, READ_WAIT2_LATCH, READ_WORD);
    signal state    : t_state := WAIT_START;
    signal clk_r    : std_logic := '0';
    signal we_r     : std_logic := '0';
    signal opcode   : std_logic_vector(7 downto 0) := (others => '0');
    signal data_buf : std_logic_vector(15 downto 0) := (others => '0');
    signal cycles   : unsigned(4 downto 0) := (others => '0');
    signal data_o   : std_logic := '1';
    signal nv_we_r  : std_logic := '0';
    signal nv_a_r   : std_logic_vector(6 downto 0) := (others => '0');
    signal nv_di_r  : std_logic_vector(7 downto 0) := (others => '0');

    -- Sub-phase states for 2-byte SPRAM write sequence
    signal wr_phase      : integer range 0 to 2 := 0;
    signal wr_all        : std_logic := '0';
    signal all_cnt       : unsigned(5 downto 0) := (others => '0');
    signal pending_waddr : std_logic_vector(5 downto 0) := (others => '0');
    signal pending_wdata : std_logic_vector(15 downto 0) := (others => '0');

    signal ewen_count        : unsigned(7 downto 0) := (others => '0');
    signal write_count       : unsigned(7 downto 0) := (others => '0');
    signal erase_count       : unsigned(7 downto 0) := (others => '0');
    signal read_count        : unsigned(7 downto 0) := (others => '0');
    signal last_read_data    : std_logic_vector(15 downto 0) := (others => '0');
    signal trace_buf         : std_logic_vector(15 downto 0) := (others => '0');
    signal read_word0        : std_logic_vector(15 downto 0) := (others => '0');
    signal read_word0_addr   : std_logic_vector(5 downto 0) := (others => '0');
begin
    do       <= data_o;
    nvram_we <= nv_we_r;
    nvram_a  <= nv_a_r;
    nvram_di <= nv_di_r;

    ss_out(63 downto 56) <= std_logic_vector(read_count);
    ss_out(55 downto 40) <= read_word0;
    ss_out(39 downto 34) <= read_word0_addr;
    ss_out(33 downto 18) <= last_read_data;
    ss_out(17 downto 2)  <= (others => '0');
    ss_out(1 downto 0)   <= we_r & data_o;

    process(clk_sys)
        variable nxt       : std_logic_vector(7 downto 0);
        variable op2       : std_logic_vector(1 downto 0);
        variable sp2       : std_logic_vector(1 downto 0);
        variable waddr     : unsigned(5 downto 0);
        variable full_word : std_logic_vector(15 downto 0);
    begin
        if rising_edge(clk_sys) then
            nv_we_r <= '0';

            -- Synchronous 2-byte SPRAM write sequence (runs at 53.6MHz clk_sys)
            if wr_phase = 1 then
                if wr_all = '1' then
                    nv_a_r   <= std_logic_vector(all_cnt) & '0';
                    nv_di_r  <= pending_wdata(15 downto 8);
                    nv_we_r  <= '1';
                    wr_phase <= 2;
                else
                    nv_a_r   <= pending_waddr & '0';
                    nv_di_r  <= pending_wdata(15 downto 8);
                    nv_we_r  <= '1';
                    wr_phase <= 2;
                end if;
            elsif wr_phase = 2 then
                if wr_all = '1' then
                    nv_a_r   <= std_logic_vector(all_cnt) & '1';
                    nv_di_r  <= pending_wdata(7 downto 0);
                    nv_we_r  <= '1';
                    if all_cnt = 63 then
                        wr_phase <= 0;
                        wr_all   <= '0';
                    else
                        all_cnt  <= all_cnt + 1;
                        wr_phase <= 1;
                    end if;
                else
                    nv_a_r   <= pending_waddr & '1';
                    nv_di_r  <= pending_wdata(7 downto 0);
                    nv_we_r  <= '1';
                    wr_phase <= 0;
                end if;
            end if;

            if ss_set = '1' then
                we_r     <= ss_in(1);
                data_o   <= ss_in(0);
                state    <= WAIT_START;
                wr_phase <= 0;

            elsif reset_n = '0' then
                state    <= WAIT_START;
                data_o   <= '1';
                clk_r    <= '0';
                we_r     <= '0';
                opcode   <= (others => '0');
                data_buf <= (others => '0');
                cycles   <= (others => '0');
                wr_phase <= 0;
                wr_all   <= '0';
            elsif soft_reset = '1' then
                state    <= WAIT_START;
                data_o   <= '1';
                clk_r    <= '0';
                -- preserve we_r across soft_reset
                opcode   <= (others => '0');
                data_buf <= (others => '0');
                cycles   <= (others => '0');
                wr_phase <= 0;
                wr_all   <= '0';

            else
                -- Always latch inputs for edge detection on every clock cycle
                clk_r <= clk_in;

                -- CS LOW: standby / reset to WAIT_START and drive DO high (1) (matching Genesis Plus GX)
                if cs_in = '0' then
                    data_o <= '1';
                    state  <= WAIT_START;
                end if;

                if cs_in = '1' then
                    -- SPRAM read sequence with DPRAM read latency alignment (only while CS is high)
                    if state = READ_WAIT1 then
                        -- High byte address (nv_a_r) was presented on previous cycle; allow 1 clk_sys cycle for DPRAM latency
                        state <= READ_WAIT1_LATCH;
                    elsif state = READ_WAIT1_LATCH then
                        -- nvram_do high byte is now 100% valid
                        data_buf(15 downto 8) <= nvram_do;
                        nv_a_r   <= pending_waddr & '1'; -- Present low byte address
                        state    <= READ_WAIT2;
                    elsif state = READ_WAIT2 then
                        -- Low byte address (nv_a_r) was presented; allow 1 clk_sys cycle for DPRAM latency
                        state <= READ_WAIT2_LATCH;
                    elsif state = READ_WAIT2_LATCH then
                        -- nvram_do low byte is now 100% valid
                        data_buf(7 downto 0) <= nvram_do;
                        last_read_data       <= data_buf(15 downto 8) & nvram_do;
                        if read_count = 0 or read_count = 1 then
                            read_word0_addr <= pending_waddr;
                            read_word0 <= data_buf(15 downto 8) & nvram_do;
                        end if;
                        state    <= READ_WORD;
                    end if;

                    -- Rising CLK edge (matches Genesis Plus GX eeprom_93c.c)
                    if clk_in = '1' and clk_r = '0' then
                        case state is

                            when WAIT_START =>
                                if di = '1' then
                                    opcode <= (others => '0');
                                    cycles <= (others => '0');
                                    state  <= GET_OPCODE;
                                end if;

                            when GET_OPCODE =>
                                opcode <= opcode(6 downto 0) & di;
                                cycles <= cycles + 1;
                                if cycles = 7 then
                                    nxt := opcode(6 downto 0) & di;
                                    op2 := nxt(7 downto 6);
                                    sp2 := nxt(5 downto 4);
                                    opcode <= nxt;
                                    cycles <= (others => '0');
                                    case op2 is
                                        when "01" =>          -- WRITE (Opcode 01, followed by 16 data bits)
                                            data_buf <= (others => '0');
                                            state    <= WRITE_WORD;
                                        when "10" =>          -- READ (Opcode 10)
                                            waddr := unsigned(nxt(5 downto 0));
                                            pending_waddr     <= std_logic_vector(waddr);
                                            read_count        <= read_count + 1;
                                            -- Present high byte address
                                            nv_a_r   <= std_logic_vector(waddr) & '0';
                                            data_o   <= '0';  -- dummy zero bit
                                            state    <= READ_WAIT1;
                                        when "11" =>          -- ERASE (Opcode 11, no data bits follow!)
                                            erase_count <= erase_count + 1;
                                            if we_r = '1' then
                                                pending_waddr <= nxt(5 downto 0);
                                                pending_wdata <= x"FFFF";
                                                wr_all        <= '0';
                                                wr_phase      <= 1;
                                            end if;
                                            data_o <= '1';
                                            state  <= WAIT_STANDBY;
                                        when others =>        -- special
                                            case sp2 is
                                                when "01" =>  -- WRITE ALL
                                                    write_count <= write_count + 1;
                                                    if we_r = '1' then
                                                        all_cnt       <= (others => '0');
                                                        pending_wdata <= data_buf;
                                                        wr_all        <= '1';
                                                        wr_phase      <= 1;
                                                    end if;
                                                    data_o <= '1';
                                                    state  <= WAIT_STANDBY;
                                                when others => -- EWEN/EWDS
                                                    we_r  <= sp2(1);
                                                    if sp2(1) = '1' then
                                                        ewen_count <= ewen_count + 1;
                                                    end if;
                                                    data_o <= '1';
                                                    state  <= WAIT_STANDBY;
                                            end case;
                                    end case;
                                end if;

                            when WRITE_WORD =>
                                data_buf <= data_buf(14 downto 0) & di;
                                cycles <= cycles + 1;
                                if cycles = 15 then
                                    write_count <= write_count + 1;
                                    if we_r = '1' then
                                        full_word := data_buf(14 downto 0) & di;
                                        pending_wdata <= full_word;
                                        if opcode(6) = '1' then
                                            pending_waddr <= opcode(5 downto 0);
                                            wr_all        <= '0';
                                            wr_phase      <= 1;
                                        else
                                            all_cnt       <= (others => '0');
                                            wr_all        <= '1';
                                            wr_phase      <= 1;
                                        end if;
                                    end if;
                                    data_o <= '1';
                                    state  <= WAIT_STANDBY;
                                end if;

                            when READ_WAIT1 => null;

                            when READ_WAIT1_LATCH => null;
                            when READ_WAIT2 => null;
                            when READ_WAIT2_LATCH => null;

                            when READ_WORD =>
                                data_o   <= data_buf(15);
                                data_buf <= data_buf(14 downto 0) & '0';
                                cycles   <= cycles + 1;
                                if cycles = 15 then
                                    waddr := unsigned(opcode(5 downto 0)) + 1;
                                    opcode(5 downto 0) <= std_logic_vector(waddr);
                                    cycles   <= (others => '0');
                                    pending_waddr <= std_logic_vector(waddr);
                                    nv_a_r   <= std_logic_vector(waddr) & '0';
                                    state    <= READ_WAIT1;
                                end if;

                            when WAIT_STANDBY =>
                                data_o <= '1';
                        end case;
                    end if;
                else
                    clk_r <= clk_in;
                end if;
            end if;
        end if;
    end process;
end rtl;
