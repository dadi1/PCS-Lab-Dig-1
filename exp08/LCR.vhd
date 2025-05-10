-- LCR.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity LCR is
  port(
    clk        : in  std_logic;
    reset      : in  std_logic;
    write_en   : in  std_logic;
    data_in    : in  std_logic_vector(7 downto 0);
    word_len   : out std_logic_vector(1 downto 0);
    stop_bits  : out std_logic;
    par_en     : out std_logic;
    par_type   : out std_logic_vector(1 downto 0);
    break_ctrl : out std_logic
  );
end entity;

architecture rtl of LCR is
  signal lcr_reg : std_logic_vector(7 downto 0) := (others => '0');
begin
  process(clk, reset)
  begin
    if reset = '1' then
      lcr_reg <= (others => '0');
    elsif rising_edge(clk) then
      if write_en = '1' then
        lcr_reg <= data_in;
      end if;
    end if;
  end process;

  word_len   <= lcr_reg(1 downto 0);
  stop_bits  <= lcr_reg(2);
  par_en     <= lcr_reg(3);
  par_type   <= lcr_reg(5 downto 4);
  break_ctrl <= lcr_reg(6);
end architecture;
