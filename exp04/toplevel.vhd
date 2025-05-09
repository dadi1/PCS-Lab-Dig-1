library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity uart_top_3state is
  port (
    clk_50MHz   : in  std_logic;
    reset       : in  std_logic;
    serial_out  : out std_logic;           -- TX para Analog Discovery
    baud_clock  : out std_logic;           -- debug do BRG
    ctrl0, ctrl1: out std_logic;           -- debug load_shift[1:0]
    done_flag   : out std_logic            -- indica fim de frame
  );
end entity;

architecture Structural of uart_top_3state is

  signal pll_clk   : std_logic;
  signal brg_tick  : std_logic;
  signal loadShift : std_logic_vector(1 downto 0);
  signal done_cycle: std_logic;

  constant DIV16 : std_logic_vector(15 downto 0) := x"000C";

  component ip_pll
    port(refclk, rst: in std_logic; outclk_0: out std_logic; locked: out std_logic);
  end component;

  component baudRateGenerator
    port(clock, reset: in std_logic; divisor: in std_logic_vector(15 downto 0);
         baudOut_n: out std_logic);
  end component;

  component ttc_3state
    port(clk, reset, enable: in std_logic; serial_i: in std_logic;
         load_shift: out std_logic_vector(1 downto 0);
         done_cycle: out std_logic);
  end component;

  component shiftregister
    generic(WIDTH: natural := 8);
    port(clock, reset: in std_logic; loadOrShift: in std_logic_vector(1 downto 0);
         serial_i: in std_logic; data_i: in std_logic_vector(WIDTH-1 downto 0);
         data_o: out std_logic_vector(WIDTH-1 downto 0);
         serial_o_r, serial_o_l: out std_logic);
  end component;

begin

  -- 1) PLL 50→1.8432MHz
  pll_inst: ip_pll port map(refclk=>clk_50MHz, rst=>reset, outclk_0=>pll_clk, locked=>open);

  -- 2) BRG: gera pulso de baud (div = 12)
  brg_inst: baudRateGenerator
    port map(clock=>pll_clk, reset=>reset, divisor=>DIV16, baudOut_n=>brg_tick);

  -- 3) FSM otimizada de 3 estados
  ttc_inst: ttc_3state
    port map(clk=>brg_tick, reset=>reset, enable=>'1',
             serial_i=>serial_out,  -- feedback da própria linha
             load_shift=>loadShift, done_cycle=>done_cycle);

  -- 4) TSR: shiftregister envia 'B' (01000010)
  tsr_inst: shiftregister generic map(WIDTH=>8)
    port map(clock=>brg_tick, reset=>reset,
             loadOrShift=>loadShift, serial_i=>'0',
             data_i=>"01000010",
             data_o=>open, serial_o_r=>serial_out, serial_o_l=>open);

  -- Debug GPIOs
  baud_clock <= brg_tick;
  ctrl0      <= loadShift(0);
  ctrl1      <= loadShift(1);
  done_flag  <= done_cycle;

end architecture;
