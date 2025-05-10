-- uart.vhd: Integração completa do transmissor e receptor UART (Experiência 8)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart is
  port(
    -- Barramento de registradores
    A       : in  std_logic_vector(2 downto 0);  -- endereços 000–111
    ADS     : in  std_logic;                     -- address strobe (ativo '0')
    D_in    : in  std_logic_vector(7 downto 0);  -- dados de escrita
    WR      : in  std_logic;                     -- write enable (ativo '1')
    RD      : in  std_logic;                     -- read enable (ativo '1')
    D_out   : out std_logic_vector(7 downto 0);  -- dados de leitura
    MR      : in  std_logic;                     -- master reset (ativo '1')

    -- UART lines
    SIN     : in  std_logic;                     -- serial in
    SOUT    : out std_logic;                     -- serial out

    -- Status
    TXRDY   : out std_logic;                     -- THR/TSR empty (bit6 LSR_TX)
    RXRDY   : out std_logic                      -- data ready (bit0 LSR_RX)
  );
end entity;

architecture rtl of uart is
  -- Internal registers
  signal dll, dlm       : std_logic_vector(7 downto 0);
  signal ier            : std_logic_vector(7 downto 0);
  signal iir            : std_logic_vector(7 downto 0);
  signal lcr            : std_logic_vector(7 downto 0);
  signal mcr            : std_logic_vector(7 downto 0);
  signal lsr_tx_reg     : std_logic_vector(7 downto 0);
  signal rbr_data       : std_logic_vector(7 downto 0);
  signal lsr_rx_reg     : std_logic_vector(7 downto 0);

  -- Wires between modules
  signal baud_clk       : std_logic;
  signal tx_data_req    : std_logic;
  signal tx_end_bit     : std_logic;
  signal tx_ctrl        : std_logic_vector(1 downto 0);
  signal tx_par         : std_logic_vector(1 downto 0);
  signal tx_thr_data    : std_logic_vector(7 downto 0);

  signal rx_ctrl        : std_logic_vector(1 downto 0);
  signal clk16          : std_logic;
  signal pe_flag, fe_flag : std_logic;
  signal rsr_data       : std_logic_vector(7 downto 0);
  signal load_rbr       : std_logic;
  signal dr_flag, oe_flag : std_logic;

begin
  -- 1) Divisor de Baud (DLL/DLM formam o divisor 16-bit)
  Baud: entity work.baudRateGenerator
    port map(
      clock    => baud_clk,   -- note: baud_clk <- pll output
      reset    => MR,
      divisor  => dlm & dll,
      baud_out => baud_clk   -- reuse as both clock and output
    );

  -- 2) Escrita/Leitura de registradores
  regfile: process(WR, RD, ADS, A, D_in, lcr, dll, dlm, ier, iir, lsr_tx_reg, rbr_data, lsr_rx_reg)
  begin
    -- Default outputs
    D_out <= (others => '0');
    -- Write
    if WR = '1' and ADS = '0' then
      case A is
        -- DLL (bit0)
        when "000" => dll <= D_in;
        -- DLM (bit1)
        when "001" => dlm <= D_in;
        -- IER
        when "010" => ier <= D_in;
        -- IIR (read) / FCR (write ignored)
        when "011" => null;
        -- LCR
        when "100" => lcr <= D_in;
        -- MCR
        when "101" => mcr <= D_in;
        -- LSR (read-only)
        when "110" => null;
        -- MSR / SCR
        when "111" => null;
        when others => null;
      end case;
    end if;
    -- Read
    if RD = '1' then
      case A is
        when "000" => D_out <= dll;
        when "001" => D_out <= dlm;
        when "010" => D_out <= ier;
        when "011" => D_out <= iir;
        when "100" => D_out <= lcr;
        when "101" => D_out <= mcr;
        when "110" => D_out <= lsr_tx_reg;
        when "111" => D_out <= lsr_rx_reg;
        when others => D_out <= (others => '0');
      end case;
    end if;
  end process;

  -- 3) Transmitter
  TX: entity work.transmitter
    port map(
      clock       => baud_clk,
      reset       => MR,
      startbit    => WR and ADS = '0' and A = "001",  -- write to THR
      mux          => A(1 downto 0),
      data_i      => D_in,
      control_LCR_out => lcr,
      saida_s     => SOUT,
      THRE        => lsr_tx_reg(5),
      TEMT        => lsr_tx_reg(6),
      controlTX_0s=> tx_ctrl(0),
      controlTX_1s=> tx_ctrl(1),
      clk_ttc_s   => baud_clk
    );
  TXRDY <= not lsr_tx_reg(6);

  -- 4) Line Status Register TX
  LSR_TX: entity work.LSR_TX
    port map(
      clock         => baud_clk,
      reset         => MR,
      data_request  => tx_data_req,
      endbit        => tx_end_bit,
      mux           => A(1 downto 0),
      data_o        => lsr_tx_reg
    );

  -- 5) Receiver Timing & Control
  RTC: entity work.RTC
    port map(
      clock        => baud_clk,
      reset        => MR,
      serial       => SIN,
      control_LCR  => lcr,
      control      => rx_ctrl,
      clk_out      => clk16,
      pe           => pe_flag,
      fe           => fe_flag
    );

  -- 6) Receiver Shift Register
  RSR: entity work.RSR
    port map(
      clock        => clk16,
      reset        => MR,
      loadOrShift  => rx_ctrl,
      serial_i     => SIN,
      data_o       => rsr_data
    );

  -- 7) Receiver Buffer Register
  load_rbr <= '1' when rx_ctrl = "11" else '0';
  RBR: entity work.RBR
    port map(
      clock    => clk16,
      reset    => MR,
      load     => load_rbr,
      read     => RD and ADS = '1',
      data_i   => rsr_data,
      data_o   => rbr_data,
      dr_o     => dr_flag,
      oe_o     => oe_flag
    );

  RXRDY <= dr_flag;

  -- 8) Line Status Register RX
  LSR_RX: entity work.LSR
    port map(
      clock      => clk16,
      reset      => MR,
      dr_i       => dr_flag,
      oe_i       => oe_flag,
      pe_i       => pe_flag,
      fe_i       => fe_flag,
      read_lsr   => RD and ADS = '1',
      data_o     => lsr_rx_reg
    );

end architecture;
