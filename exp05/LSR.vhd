library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity LSR is
    port(
        clock, reset  : in std_logic;
        thr_empty_in  : in std_logic; -- 1 se THR estiver vazio.
        tsr_empty_in  : in std_logic; -- 1 e TSR estiver vazio.
        lsr_thr_empty : out std_logic; -- 1 quando não houver carga no THR.
        lsr_tx_empty  : out std_logic --  se FSM estiver no estado IDLE.
    );
end entity;

architecture rtl of LSR is

begin
    process(clock, reset)
    begin

        if reset = '1' then
            lsr_thr_empty <= '1';
            lsr_tx_empty <= '1';
        elsif (clock'event and clock = '1') then
            lsr_thr_empty <= thr_empyt_in;
            lsr_tx_empty <= tsr_empty_in;
        
        end if;
    end process;
end architecture;
