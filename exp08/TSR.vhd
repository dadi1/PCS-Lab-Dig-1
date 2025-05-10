entity TSR is
  port(
    clk    : in  std_logic;
    reset  : in  std_logic;
    load   : in  std_logic;
    shift  : in  std_logic;
    data_i : in  std_logic_vector(7 downto 0);
    data_o : out std_logic;
    empty  : out std_logic
  );
end entity;

architecture rtl of TSR is
  signal shift_reg : std_logic_vector(7 downto 0) := (others => '0');
begin
  process(clk, reset)
  begin
    if reset = '1' then
      shift_reg <= (others => '0');
    elsif rising_edge(clk) then
      if load = '1' then
        shift_reg <= data_i;
      elsif shift = '1' then
        shift_reg <= '0' & shift_reg(7 downto 1);
      end if;
    end if;
  end process;
  data_o <= shift_reg(0);
  empty  <= '1' when shift_reg = (others => '0') else '0';
end architecture;