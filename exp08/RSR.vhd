-- RSR.vhd: Receiver Shift Register
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity RSR is
  port(
    clk       : in  std_logic;
    reset     : in  std_logic;
    serial_in : in  std_logic;
    shift     : in  std_logic;
    data_o    : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of RSR is
  signal shift_reg : std_logic_vector(7 downto 0) := (others => '0');
begin
  process(clk, reset)
  begin
    if reset = '1' then
      shift_reg <= (others => '0');
    elsif rising_edge(clk) then
      if shift = '1' then
        shift_reg <= serial_in & shift_reg(7 downto 1);
      end if;
    end if;
  end process;
  data_o <= shift_reg;
end architecture;
