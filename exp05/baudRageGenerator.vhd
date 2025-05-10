library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity baudRateGenerator is
    generic (
            WIDTH: natural := 16; -- largura do contador.
    )
    port (
        clock, reset : in std_logic; -- Clock e reset assíncronos.
        divisor      : in std_logic_vector(WIDTH-1 downto 0); -- divisor programável.
        baudOut_n    : out std_logic -- Saída do clock dividido.
    );
end baudRateGenerator;

architecture impl of baudRateGenerator is

    -- Sinais para o contador.
    signal reset_counter : std_logic := '1';
    signal data_counter  : std_logic_vector(WIDTH-1 downto 0);
    signal count         : std_logic_vector(WIDTH-1 downto 0);

    -- Sinal do baudRateGenerator.
    signal brg_out : std_logic := '0';
    signal div_reg : unsigned(divisor);

    -- Implementação do componente contador.
    component couter is
        port (
        clock, reset : in std_logic; -- Clock e reset assíncrono ativo alto.
        enable       : in std_logic; -- Habilita contagem.
        load         : in std_logic; -- Carga paralela.
        up           : in std_logic; -- 0 : contagem decrescente , 1 : crescente.
        data_i       : in std_logic_vector(WIDTH-1 downto 0); -- Entrada paralela.
        data_o       : out std_logic_vector(WIDTH-1 downto 0) -- Saída paralela.
    );
end counter;

-- inicio.
begin

    -- Instanciação do contador.
    contador : counter is
        port map(
            clock => clock,
            reset => reset_counter,
            enable => '1',
            load => '0',
            up => '1', -- contagem crescente.
            data_i => data_counter,
            data_o => count
        )
    
    -- inicio do processo.
    process(clock, reset)
    begin 
        if reset = '1' then
            reset_counter <= '1';
            brg_out <= '0'

        elsif rising_edge(clock) then 
            if unsigned(count) = div_reg then
                reset_clock <= '1';
                baudOut_n <= '1';
            else
                reset_counter <= '0';
                baudOut_n <= '0';
            
            endif;
        endif;
    end process;
end architecture;