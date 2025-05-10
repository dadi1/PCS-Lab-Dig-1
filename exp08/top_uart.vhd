library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_uart is
  port(
    -- Clock e Reset
    clk_in     : in  std_logic;    -- Clock de referência (ex: 50MHz)
    reset_n    : in  std_logic;    -- Reset ativo baixo
    -- Divisor Latch (DLL/DLM) em chaves
    keys_low   : in  std_logic_vector(7 downto 0); -- DLL
    keys_high  : in  std_logic_vector(7 downto 0); -- DLM
    -- Word configurável (LCR) em chaves
    key_LCR    : in  std_logic_vector(6 downto 0);
    -- THR: dados a transmitir
    keys_data  : in  std_logic_vector(7 downto 0);
    btn_load   : in  std_logic;    -- botão de carga THR
    -- Status em LEDs
    led_thr_empty : out std_logic;
    led_tx_done   : out std_logic;
    -- Serial TX
    serial_tx     : out std_logic;
    -- Serial RX
    serial_rx     : in  std_logic;
    keys_RBR      : in  std_logic_vector(7 downto 0); -- para ler RBR manualmente
    btn_read      : in  std_logic;    -- botão de leitura RBR
    led_rx_data   : out std_logic_vector(7 downto 0);
    led_rx_ready  : out std_logic
  );
end entity;

architecture rtl of top_uart is
  -- sinais internos
  signal dll, dlm      : std_logic_vector(7 downto 0);
  signal divisor       : std_logic_vector(15 downto 0);
  signal clk_brg       : std_logic;
  signal lcr_word_len  : std_logic_vector(1 downto 0);
  signal lcr_stop_bs   : std_logic;
  signal lcr_par_en    : std_logic;
  signal lcr_par_type  : std_logic_vector(1 downto 0);
  signal lcr_break     : std_logic;
  signal thr_empty_i   : std_logic;
  signal tsr_empty_i   : std_logic;
  signal tsr_empty_reg : std_logic;
  signal rbr_data      : std_logic_vector(7 downto 0);
  signal rbr_ready_i   : std_logic;

begin
  -- Divisor latch via chaves
  dll <= keys_low;
  dlm <= keys_high;
  divisor <= dlm & dll;

  -- Baud Rate Generator
  U_BRG: entity work.baudRateGenerator
    generic map(WIDTH => 16)
    port map(
      clk       => clk_in,
      reset     => not reset_n,
      divisor   => divisor,
      baudOut_n => clk_brg
    );

  -- linha de controle LCR via chaves
  lcr_word_len <= key_LCR(1 downto 0);
  lcr_stop_bs  <= key_LCR(2);
  lcr_par_en   <= key_LCR(3);
  lcr_par_type <= key_LCR(5 downto 4);
  lcr_break    <= key_LCR(6);

  -- THR, TCC, TSR
  U_TCC: entity work.TCC
    port map(
      clk     => clk_brg,
      reset   => not reset_n,
      data_in => keys_data,
      load_thr       => btn_load,
      lcr_word_len  => lcr_word_len,
      lcr_stop_bs   => lcr_stop_bs,
      lcr_par_en    => lcr_par_en,
      lcr_par_type  => lcr_par_type,
      lcr_break     => lcr_break,
      bit_tick      => clk_brg,
      serial_out    => serial_tx,
      thr_empty     => thr_empty_i,
      tsr_empty     => tsr_empty_i
    );
  led_thr_empty <= thr_empty_i;
  led_tx_done   <= tsr_empty_i;

  -- RBR, RSR
  U_RSR: entity work.RSR
    port map(
      clk     => clk_brg,
      reset   => not reset_n,
      serial_in => serial_rx,
      load_rbr  => btn_read,
      data_rbr  => keys_RBR,
      rbr_data_out => rbr_data,
      rbr_empty    => open
    );
  led_rx_data  <= rbr_data;

  -- LSR para RX ready
  U_LSR: entity work.LSR
    port map(
      clk           => clk_brg,
      reset         => not reset_n,
      thr_empty_in  => thr_empty_i,
      tsr_empty_in  => tsr_empty_i,
      lsr_thr_empty => open,
      lsr_tx_empty  => open
    );
  led_rx_ready <= rbr_ready_i;

end architecture;