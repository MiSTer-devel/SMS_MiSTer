-- ============================================================================
-- cart_eeprom.vhd
-- GG EEPROM Cartridge Mapper
-- Games: Pro Yakyuu GG League, The Majors Pro Baseball,
--        World Series Baseball [v0/v1], World Series Baseball '95
--
-- Write $8000:  bit 2=CS  bit 1=CLK  bit 0=DI   (MAME & Genesis-Plus-GX convention)
-- Read  $8000:  bit 0=DO
--
-- ROM banking (standard Sega $FFFD-$FFFF) is handled unchanged in system.vhd.
-- ============================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cart_eeprom is
    port (
        clk_sys    : in  std_logic;
        ce_cpu     : in  std_logic;
        reset_n    : in  std_logic;
        soft_reset : in  std_logic := '0';
        -- Z80 bus
        A        : in  std_logic_vector(15 downto 0);
        D_in     : in  std_logic_vector(7 downto 0);
        D_out    : out std_logic_vector(7 downto 0);
        WR_n     : in  std_logic;
        RD_n     : in  std_logic;
        MREQ_n   : in  std_logic;
        M1_n     : in  std_logic := '1';
        enabled  : in  std_logic;
        mapper_eeprom : in std_logic := '1';
        nvram_e  : in  std_logic := '0';
        -- Bus drive indicator: '1' when cart_eeprom is actively driving D_out
        bus_active : out std_logic;
        -- NVRAM (byte-wide, 128×8-bit)
        nvram_a  : out std_logic_vector(6 downto 0);
        nvram_di : out std_logic_vector(7 downto 0);
        nvram_do : in  std_logic_vector(7 downto 0);
        nvram_we : out std_logic;
        -- Save-state passthrough
        ss_out   : out std_logic_vector(63 downto 0);
        ss_in    : in  std_logic_vector(63 downto 0) := (others => '0');
        ss_set   : in  std_logic := '0'
    );
end cart_eeprom;

architecture rtl of cart_eeprom is
    signal eep_cs       : std_logic := '0';
    signal eep_clk      : std_logic := '0';
    signal eep_di       : std_logic := '0';
    signal eep_do       : std_logic;
    signal eep_lines    : std_logic_vector(7 downto 0) := (others => '0');
    signal nv_a         : std_logic_vector(6 downto 0);
    signal nv_di        : std_logic_vector(7 downto 0);
    signal nv_we        : std_logic;
    signal eep_ss_out   : std_logic_vector(63 downto 0);

    signal fffc_window_en   : std_logic := '0';
    signal bus_active_i     : std_logic;
begin
    eeprom_inst : entity work.eeprom_93c46
        port map (
            clk_sys    => clk_sys,
            ce_cpu     => ce_cpu,
            reset_n    => reset_n,
            soft_reset => soft_reset,
            cs_in      => eep_cs,
            clk_in     => eep_clk,
            di         => eep_di,
            do         => eep_do,
            nvram_a    => nv_a,
            nvram_di   => nv_di,
            nvram_do   => nvram_do,
            nvram_we   => nv_we,
            ss_out     => eep_ss_out,
            ss_in      => ss_in,
            ss_set     => ss_set
        );

    nvram_a  <= nv_a;
    nvram_di <= nv_di;
    nvram_we <= nv_we when enabled = '1' else '0';

    -- Bus active calculation (using eep_cs OR fffc_window_en)
    bus_active_i <= '1' when (enabled = '1' and A = x"8000" and (eep_cs = '1' or fffc_window_en = '1')) else '0';
    bus_active   <= bus_active_i;

    -- Clean production savestate vector passthrough:
    -- [63:11] eeprom_93c46 state, [10:6] eep_lines(7:3), [5] eep_cs, [4] eep_clk, [3] eep_di, [2] fffc_window_en, [1] we_r, [0] data_o
    ss_out <= eep_ss_out(63 downto 11) & eep_lines(7 downto 3) & eep_cs & eep_clk & eep_di & fffc_window_en & eep_ss_out(1 downto 0);

    -- Control register write & Port 0x8000 / 0xFFFC write sniffer
    process(clk_sys)
    begin
        if rising_edge(clk_sys) then
            if reset_n = '0' then
                eep_cs           <= '0';
                eep_clk          <= '0';
                eep_di           <= '0';
                eep_lines        <= (others => '0');
                fffc_window_en   <= '0';
            elsif ss_set = '1' and mapper_eeprom = '1' then
                eep_cs           <= ss_in(5);
                eep_clk          <= ss_in(4);
                eep_di           <= ss_in(3);
                fffc_window_en   <= ss_in(2);
                eep_lines        <= ss_in(10 downto 6) & ss_in(5) & ss_in(4) & ss_in(3);
            elsif mapper_eeprom = '1' then
                if WR_n = '0' and MREQ_n = '0' then
                    if A = x"8000" then
                        eep_cs        <= D_in(2);  -- bit 2 = CS
                        eep_clk       <= D_in(1);  -- bit 1 = CLK
                        eep_di        <= D_in(0);  -- bit 0 = DI
                        eep_lines     <= D_in;
                    elsif A(15 downto 0) = x"FFFC" then
                        fffc_window_en   <= D_in(3);  -- Bit 3 of $FFFC dynamically enables EEPROM window!
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- Read: return eep_lines(7..3) & eep_cs & '1' & eep_do to match Genesis Plus GX
    -- (bit 2 = CS, bit 1 = CLK = '1', bit 0 = DO)
    D_out <= (eep_lines(7 downto 3) & eep_cs & '1' & eep_do) when (enabled = '1' and A = x"8000" and (eep_cs = '1' or fffc_window_en = '1')) else
             (others => '0');
end rtl;
