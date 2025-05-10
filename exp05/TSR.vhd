library IEEE
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TRS is
    port(
        clock, reset  : in std_logic;
        load          : in std_logic;
        shift         : in std_logic;
        data_i        : in std_logic_vector(7 downto 0);
        data_o        : out std_logic;
        trs_empty     : out std_logic
    );
end entity;

architecture rtl of TSR is
    signal shift_reg: std_logic_vector(7 downto 0) := (others => '0');

begin
    process(clock, reset)
    begin
        if reset = '1' then
            shift_reg <= (others => '0');
        elsif (clock'event and clock = '1') then
            if load = '1' then
                shift_reg <= data_i;
            elsif shift = '1' then
                shift_reg <= '0' & shift_reg(7 downto 1);
            end if;
        end if;
    end process;

    data_o <= shift_reg(0);
    trs_empty <= '1' when shift_reg = (others => '0') else '0';
end architecture;