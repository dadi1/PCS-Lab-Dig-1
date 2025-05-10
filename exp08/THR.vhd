-- THR.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity THR is
  port(
    clk      : in  std_logic;
    reset    : in  std_logic;
    load     : in  std_logic;
    data_in  : in  std_logic_vector(7 downto 0);
    data_out : out std_logic_vector(7 downto 0);
    empty    : out std_logic
  );
end entity;

architecture rtl of THR is
  signal reg_thr : std_logic_vector(7 downto 0) := (others => '0');
begin
  process(clk, reset)
  begin
    if reset = '1' then
      reg_thr <= (others => '0');
    elsif rising_edge(clk) then
      if load = '1' and empty = '1' then
        reg_thr <= data_in;
      end if;
    end if;
  end process;
  data_out <= reg_thr;
  empty    <= '1' when reg_thr = (others => '0') else '0';
end architecture;