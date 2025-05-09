library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ttc_3state is
  port (
    clk         : in  std_logic;              -- baud_tick do BRG
    reset       : in  std_logic;              -- reset síncrono ativo alto
    enable      : in  std_logic;              -- dispara transmissão
    serial_i    : in  std_logic;              -- linha serial do TSR
    load_shift  : out std_logic_vector(1 downto 0); -- controle do shiftregister
    done_cycle  : out std_logic               -- indica fim de frame
  );
end entity;

architecture RTL of ttc_3state is

  -- Estados possíveis
  type state_t is (IDLE, SEND, WAIT);
  signal current_state, next_state : state_t := IDLE;

  -- Contador de bit dentro do frame (0=start,1..8=data,9=paridade,10=stop)
  signal bit_index : integer range 0 to 10 := 0;
  signal parity    : std_logic := '0';

begin

  ----------------------------------------------------------------------------
  -- Processo 1: Registro de estado (state flip-flops)
  ----------------------------------------------------------------------------
  proc_state_reg: process(clk, reset)
  begin
    if reset = '1' then
      current_state <= IDLE;
    elsif rising_edge(clk) then
      current_state <= next_state;
    end if;
  end process;

  ----------------------------------------------------------------------------
  -- Processo 2: Lógica combinacional de próximo estado + saídas
  ----------------------------------------------------------------------------
  proc_next_and_output: process(current_state, enable, bit_index, serial_i)
  begin
    -- defaults
    load_shift  <= "00";
    done_cycle  <= '0';
    next_state  <= current_state;

    case current_state is

      --------------------------------------------------------------------------------
      when IDLE =>
        -- repouso: linha em '1'
        if enable = '1' then
          parity     <= '0';
          bit_index  <= 0;
          load_shift <= "11";    -- carrega TSR
          next_state <= SEND;
        end if;

      --------------------------------------------------------------------------------
      when SEND =>
        -- envia a cada baud_tick um bit conforme bit_index
        case bit_index is
          when 0 =>
            load_shift <= "01";  -- shift → start bit '0'
          when 1 to 8 =>
            load_shift <= "01";  -- shift → bits de dados
            parity     <= parity xor serial_i;
          when 9 =>
            load_shift <= "10";  -- output paridade
          when 10 =>
            load_shift <= "00";  -- output stop bit '1'
          when others =>
            null;
        end case;

        if bit_index = 10 then
          done_cycle <= '1';
          next_state <= WAIT;
        else
          next_state <= SEND;
        end if;

      --------------------------------------------------------------------------------
      when WAIT =>
        -- mantém repouso até enable voltar a '0'
        if enable = '0' then
          next_state <= IDLE;
        else
          next_state <= WAIT;
        end if;

    end case;
  end process;

  ----------------------------------------------------------------------------
  -- Sincronização do bit_index: avança só no baud_tick
  ----------------------------------------------------------------------------
  process(clk, reset)
  begin
    if reset = '1' then
      bit_index <= 0;
    elsif rising_edge(clk) then
      if current_state = SEND then
        if bit_index < 10 then
          bit_index <= bit_index + 1;
        end if;
      else
        bit_index <= 0;
      end if;
    end if;
  end process;

end architecture;
