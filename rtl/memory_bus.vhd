library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Combinational memory windows, bus strobes, and CPU memory-read data.
entity memory_bus is
	port (
		A : in std_logic_vector(15 downto 0);
		sc3000_en : in std_logic;
		sc_cart_ram : in std_logic_vector(1 downto 0);
		mapper_castle : in std_logic;
		sc_multicart_en : in std_logic;
		WR_n : in std_logic;
		RD_n : in std_logic;
		MREQ_n : in std_logic;
		ss_freeze : in std_logic;
		mapper_eeprom : in std_logic;
		nvram_e : in std_logic;
		nvram_ex : in std_logic;
		nvram_cme : in std_logic;
		dahjee_cart_access : in std_logic;
		eeprom_bus_active : in std_logic;
		eeprom_D_out : in std_logic_vector(7 downto 0);
		nvram_D_out : in std_logic_vector(7 downto 0);
		ram_D_out : in std_logic_vector(7 downto 0);
		irom_D_out : in std_logic_vector(7 downto 0);
		ram_WR : out std_logic;
		nvram_WR : out std_logic;
		rom_RD : out std_logic;
		memory_D_out : out std_logic_vector(7 downto 0)
	);
end entity;

architecture rtl of memory_bus is
	signal sc_cart_ram_32k:		std_logic;
	signal sc_cart_ram_low:		std_logic;
	signal sc_cart_ram_high:	std_logic;
	signal sc_cart_ram_rd:		std_logic;
	signal sc_multicart_upper:	std_logic;
	signal sc_multicart_open:	std_logic;
begin
	sc_cart_ram_32k <= '1' when (sc3000_en='1' and sc_cart_ram="11") or mapper_castle='1' else '0';
	sc_cart_ram_low <= '1' when ((sc3000_en='1' and sc_cart_ram/="00") or mapper_castle='1') and A(15 downto 14)="10" else '0';
	sc_cart_ram_high <= '1' when sc_cart_ram_32k='1' and A(15 downto 14)="11" else '0';
	sc_cart_ram_rd <= sc_cart_ram_low or sc_cart_ram_high;
	sc_multicart_upper <= '1' when sc_multicart_en='1' and A(15)='1' else '0';
	sc_multicart_open <= '1' when sc_multicart_en='1' and A(15 downto 14)="10" and sc_cart_ram="00" else '0';

	ram_WR   <= not WR_n when ss_freeze = '0' and MREQ_n='0' and A(15 downto 14)="11" and sc_cart_ram_32k='0' else '0';
	nvram_WR <= not WR_n when ss_freeze = '0' and MREQ_n='0' and mapper_eeprom = '0' and (((A(15 downto 14)="10" and nvram_e = '1')
						or (A(15 downto 14)="11" and nvram_ex = '1')
						or (A(15 downto 13)="101" and nvram_cme = '1'))
						or sc_cart_ram_low='1'
						or sc_cart_ram_high='1'
						or (dahjee_cart_access='1' and A(15 downto 13)="001")) else '0';
	rom_RD   <= not RD_n when MREQ_n='0' and A(15 downto 14)/="11" and sc_multicart_upper='0'
	                     and not (mapper_castle='1' and A(15)='1')
	                     and not (dahjee_cart_access='1' and A(15 downto 13)="001") else '0';

	process (A,eeprom_bus_active,eeprom_D_out,sc_cart_ram_rd,nvram_D_out,
	         sc_multicart_open,nvram_ex,ram_D_out,nvram_cme,nvram_e,
	         dahjee_cart_access,irom_D_out)
	begin
		if eeprom_bus_active = '1' then
			memory_D_out <= eeprom_D_out;
		elsif sc_cart_ram_rd='1' then
			memory_D_out <= nvram_D_out;
		elsif sc_multicart_open='1' then
			memory_D_out <= x"FF";
		elsif A(15 downto 14)="11" and nvram_ex = '1' then
			memory_D_out <= nvram_D_out;
		elsif A(15 downto 14)="11" and nvram_ex = '0' then
			memory_D_out <= ram_D_out;
		elsif A(15 downto 13)="101" and nvram_cme  = '1' then
			memory_D_out <= nvram_D_out;
		elsif A(15 downto 14)="10" and nvram_e  = '1' then
			memory_D_out <= nvram_D_out;
		elsif dahjee_cart_access = '1' and A(15 downto 13) = "001" then
			-- Dahjee Type A: RAM at 0x2000-0x3FFF reads from nvram block
			memory_D_out <= nvram_D_out;
		else
			memory_D_out <= irom_D_out;
		end if;
	end process;
end architecture;
