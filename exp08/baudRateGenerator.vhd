-- BaudRateGenerator.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity BaudRateGenerator is
  generic(
    WIDTH : natural := 16
  );
  port(
    clk       : in  std_logic;
    reset     : in  std_logic;
    divisor   : in  std_logic_vector(WIDTH-1 downto 0);
    baud_out  : out std_logic
  );
end entity;

architecture rtl of BaudRateGenerator is
  signal cnt     : unsigned(WIDTH-1 downto 0) := (others => '0');
  signal div_reg : unsigned(WIDTH-1 downto 0);
  signal brg     : std_logic := '0';
begin
  div_reg <= unsigned(divisor);
  process(clk, reset)
  begin
    if reset = '1' then
      cnt <= (others => '0');
      brg <= '0';
    elsif rising_edge(clk) then
      if cnt = div_reg then
        cnt <= (others => '0');
        brg <= not brg;
      else
        cnt <= cnt + 1;
      end if;
    end if;
  end process;
  baud_out <= brg;
end architecture;
