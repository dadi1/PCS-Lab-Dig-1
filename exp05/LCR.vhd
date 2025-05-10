library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity LCR is
    port (
        clock, reset : in std_logic;
        mux          : in std_logic_vector(1 downto 0);
        writen_en    : in std_logic;
        data_i       : in std_logic_vector(7 downto 0);
        word_len     : in std_logic_vector(1 downto 0);
        stop_bits    : in std_logic;
        par_en       : in std_logic;
        par_type     : in std_logic;
        break_ctrl   : out std_logic
    );
end entity;

architecture rtl of LCR is
    
    signal lcr_reg : std_logic_vector(7 downto 0) := (others => '0'); -- sinais de entrada paralela.

    begin
        process(clock, reset)
        begin 
            if reset = '1' then
                lcr_reg <= (others => '0');
            elsif(clock'event and clock = '1') then
                if write_en '1' and addr = "00" then
                    lcr_reg <= data_i;
                end if;
            end if;
        end process;

    word_len <= lcr_reg(1 downto 0);
    stop_bits <= lcr_reg(2);
    par_en <= lcr_reg(3);
    par_type <= lcr_reg(5 downto 4);
    break_ctrl <= lcr_reg(6);
end architecture;
 