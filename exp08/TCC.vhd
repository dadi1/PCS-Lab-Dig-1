-- TCC.vhd: Transmitter Timing & Control
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TCC is
  port(
    clk           : in  std_logic;
    reset         : in  std_logic;
    data_in       : in  std_logic_vector(7 downto 0);
    load_thr      : in  std_logic;
    lcr_word_len  : in  std_logic_vector(1 downto 0);
    lcr_stop_bs   : in  std_logic;
    lcr_par_en    : in  std_logic;
    lcr_par_type  : in  std_logic_vector(1 downto 0);
    lcr_break     : in  std_logic;
    bit_tick      : in  std_logic;
    serial_out    : out std_logic;
    thr_empty     : out std_logic;
    tsr_empty     : out std_logic
  );
end entity;

architecture rtl of TCC is
  type state_type is (IDLE, LOAD_TSR, START_BIT, DATA_BITS, PARITY_BIT, STOP_BITS, CLEANUP);
  signal state       : state_type := IDLE;
  signal bit_count   : integer range 0 to 7 := 0;
  signal par_bit     : std_logic := '0';
  signal shift_load  : std_logic := '0';
  signal shift_shift : std_logic := '0';
  signal shift_out   : std_logic := '1';

begin
  -- Shift register instance
  U_TSR: entity work.TSR port map(
    clk    => clk,
    reset  => reset,
    load   => shift_load,
    shift  => shift_shift,
    data_i => data_in,
    data_o => shift_out,
    empty  => tsr_empty
  );

  process(clk, reset)
  begin
    if reset = '1' then
      state      <= IDLE;
      thr_empty  <= '1';
      tsr_empty  <= '1';
      serial_out <= '1';
      bit_count  <= 0;
    elsif rising_edge(clk) then
      -- default
      shift_load  <= '0';
      shift_shift <= '0';
      case state is
        when IDLE =>
          serial_out <= '1' when lcr_break = '0' else '0';
          thr_empty  <= not load_thr;
          if load_thr = '1' then
            state <= LOAD_TSR;
          end if;
        when LOAD_TSR =>
          -- load TSR
          shift_load <= '1';
          thr_empty  <= '0';
          tsr_empty  <= '0';
          -- calculate parity
          if lcr_par_en = '1' then
            par_bit <= xor reduce data_in;
          end if;
          bit_count <= 0;
          state <= START_BIT;
        when START_BIT =>
          serial_out <= '0';
          if bit_tick = '1' then
            state <= DATA_BITS;
          end if;
        when DATA_BITS =>
          serial_out <= shift_out;
          if bit_tick = '1' then
            shift_shift <= '1';
            if bit_count = to_integer(unsigned(lcr_word_len)) then
              state <= (lcr_par_en = '1') ? PARITY_BIT : STOP_BITS;
            else
              bit_count <= bit_count + 1;
            end if;
          end if;
        when PARITY_BIT =>
          serial_out <= (lcr_par_type = "01") ? par_bit : not par_bit;
          if bit_tick = '1' then
            state <= STOP_BITS;
          end if;
        when STOP_BITS =>
          serial_out <= '1';
          if bit_tick = '1' then
            state <= CLEANUP;
          end if;
        when CLEANUP =>
          thr_empty <= '1';
          tsr_empty <= '1';
          state     <= IDLE;
        when others => state <= IDLE;
      end case;
    end if;
  end process;
end architecture;