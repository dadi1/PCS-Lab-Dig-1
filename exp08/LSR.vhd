-- LSR.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity LSR is
  port(
    clk            : in  std_logic;
    reset          : in  std_logic;
    thr_empty_in   : in  std_logic;
    tsr_empty_in   : in  std_logic;
    rbr_empty_in   : in  std_logic;
    lsr_thr_empty  : out std_logic;
    lsr_tx_empty   : out std_logic;
    lsr_rx_ready   : out std_logic
  );
end entity;

architecture rtl of LSR is
begin
  process(clk, reset)
  begin
    if reset = '1' then
      lsr_thr_empty <= '1';
      lsr_tx_empty  <= '1';
      lsr_rx_ready  <= '0';
    elsif rising_edge(clk) then
      lsr_thr_empty <= thr_empty_in;
      lsr_tx_empty  <= tsr_empty_in;
      lsr_rx_ready  <= not rbr_empty_in;
    end if;
  end process;
end architecture;