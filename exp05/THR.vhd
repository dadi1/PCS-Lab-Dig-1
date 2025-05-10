library IEEE
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity THR is
    port (
        clock, reset  : in std_logic;
        load_thr      : in std_logic;
        data_in       : in std_logic_vector(7 downto 0);
        lsr_thr_empty : in std_logic;
        thr_data_out  : out std_logic_vector(7 downto 0);
        thr_empty_out : out std_logic;
    );
end entity;

architecture rtl of THR is
    signal reg_thr: std_logic_vector(7 downto 0) := (others => '0');
begin 
    process(clock, reset)
    begin
        if reset = '1' then
            reg_thr <= (others => '0');
        elsif (clock'event and clock ='1') then
            if load_thr = '1' and lsr_thr_empty = '1' then
                reg_thr <= data_in;
            end if;
        end if;
    end process;

    thr_data_out <= reg_thr;
    thr_empty_out <= '1' when reg_thr = (others => '0') else '0';
end architecture;