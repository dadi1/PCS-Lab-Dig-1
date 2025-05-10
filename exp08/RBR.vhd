-- RBR.vhd: Receiver Buffer Register
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity RBR is
  port(
    clk          : in  std_logic;
    reset        : in  std_logic;
    load_rbr     : in  std_logic;
    data_in      : in  std_logic_vector(7 downto 0);
    data_out     : out std_logic_vector(7 downto 0);
    empty        : out std_logic
  );
end entity;

architecture rtl of RBR is
  signal reg_rbr : std_logic_vector(7 downto 0) := (others => '0');
begin
  process(clk, reset)
  begin
    if reset = '1' then
      reg_rbr <= (others => '0');
    elsif rising_edge(clk) then
      if load_rbr = '1' then
        reg_rbr <= data_in;
      end if;
    end if;
  end process;
  data_out <= reg_rbr;
  empty    <= '1' when reg_rbr = (others => '0') else '0';
end architecture;