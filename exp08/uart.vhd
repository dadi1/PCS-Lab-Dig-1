library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart is
  port(
    -- Seletor de registrador
    A      : in  std_logic_vector(2 downto 0);
    ADS    : in  std_logic;
    -- Barramento de dados
    D_in   : in  std_logic_vector(7 downto 0);
    D_out  : out std_logic_vector(7 downto 0);
    -- Controles
    MR     : in  std_logic;
    WR     : in  std_logic;
    RD     : in  std_logic;
    -- Sinais de status
    RXRDY  : out std_logic;
    TXRDY  : out std_logic;
    -- Clock da UART
    RCLK   : in  std_logic;
    -- Serial
    SIN    : in  std_logic;
    SOUT   : out std_logic
  );
end entity;

architecture rtl of uart is
  -- Sinais internos de registradores
  signal dll, dlm : std_logic_vector(7 downto 0);
  signal lcr_bits : std_logic_vector(6 downto 0);
  signal thr_data : std_logic_vector(7 downto 0);
  signal rbr_data : std_logic_vector(7 downto 0);
  signal ier       : std_logic_vector(7 downto 0);
  signal iir, fcr : std_logic_vector(7 downto 0);
  signal lsr_thr_empty, lsr_tx_empty, lsr_rx_ready : std_logic;

  -- Baud Rate Generator divisor
  signal divisor   : std_logic_vector(15 downto 0);

  -- Clock dividido
  signal baud_clk  : std_logic;

begin
  -- Divisor latch: DLAB seleciona DLL/DLM
  process(MR)
  begin
    if MR='1' then
      dll <= (others=>'0'); dlm <= (others=>'0');
    end if;
  end process;
  divisor <= dlm & dll;

  -- PLL e BRG fora deste módulo (RCLK entra aqui)
  -- Gera baudscope
  BRG: entity work.baudRateGenerator
    port map(
      clk       => RCLK,
      reset     => MR,
      divisor   => divisor,
      baudOut_n => baud_clk
    );

  -- Instancia o transmissor (exp05)
  TX: entity work.uart_tx
    port map(
      clk_brg     => baud_clk,
      reset       => MR,
      data_in     => thr_data,
      load_thr    => WR when (ADS='0' and A="001") else '0',
      lcr_word_len=> lcr_bits(1 downto 0),
      lcr_stop_bs => lcr_bits(2),
      lcr_par_en  => lcr_bits(3),
      lcr_par_type=> lcr_bits(5 downto 4),
      lcr_break   => lcr_bits(6),
      serial_out  => SOUT,
      lsr_thr_empty => lsr_thr_empty,
      lsr_tx_empty  => lsr_tx_empty
    );
  TXRDY <= lsr_tx_empty;

  -- Instancia o receptor (exp07)
  RX: entity work.uart_rx
    port map(
      clk_brg    => baud_clk,
      reset      => MR,
      serial_in  => SIN,
      data_out   => rbr_data,
      data_ready => lsr_rx_ready
    );
  RXRDY <= lsr_rx_ready;

  -- LCR: registro de controle de linha
  LCR: entity work.LCR
    port map(
      clk       => RCLK,
      reset     => MR,
      addr      => A(2 downto 0),
      write_en  => WR,
      data_in   => D_in,
      word_len  => lcr_bits(1 downto 0),
      stop_bits => lcr_bits(2),
      par_en    => lcr_bits(3),
      par_type  => lcr_bits(5 downto 4),
      break_ctrl=> lcr_bits(6)
    );

  -- Demux de escrita e Mux de leitura de registradores
  process(A, ADS, WR, RD, D_in,
          dll, dlm, ier, rbr_data, lcr_bits, lsr_thr_empty, lsr_rx_ready)
  begin
    D_out <= (others=>'0');
    thr_data <= (others=>'0');
    case A is
      when "000" => -- DLL ou RBR
        if WR='1' and ADS='0' then dll <= D_in;
        elsif RD='1' then D_out <= rbr_data; end if;
      when "001" => -- DLM ou THR
        if WR='1' and ADS='0' then thr_data <= D_in;
        elsif RD='1' then D_out <= dll; end if;
      when "010" => -- IER
        if WR='1' and ADS='0' then ier <= D_in;
        elsif RD='1' then D_out <= ier; end if;
      when "011" => -- IIR/FCR
        if WR='1' and ADS='0' then fcr <= D_in;
        elsif RD='1' then D_out <= iir; end if;
      when "100" => -- LCR
        if RD='1' then D_out <= '0' & lcr_bits; end if;
      when "101" => -- MCR (não implementado)
        null;
      when "110" => -- LSR
        if RD='1' then D_out <= "000" & lsr_rx_ready & '0' & lsr_tx_empty & lsr_thr_empty; end if;
      when "111" => -- MSR/SCR (não implementado)
        null;
      when others => null;
    end case;
  end process;
end architecture;
