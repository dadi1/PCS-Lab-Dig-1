library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity counter is
    generic(
        WIDTH: natural := 24 -- Tamanho em bits.
    );
    port (
        clock, reset : in std_logic; -- Clock e reset assíncrono ativo alto.
        enable : in std_logic; -- Habilita contagem.
        load : in std_logic; -- Carga paralela.
        up : in std_logic; -- 0 : contagem decrescente , 1 : crescente.
        data_i : in std_logic_vector(WIDTH-1 downto 0); -- Entrada paralela.
        data_o : out std_logic_vector(WIDTH-1 downto 0) -- Saída paralela.
    );
end counter;

architecture rtl of counter is
    signal count : unsigned(WIDTH-1 downto 0);
begin
    process(clock)
    begin
        if rising_edge(clock) then

            if reset = '1' then
                count <= (others => '0'); -- Reset síncrono

            elsif enable = '1' then
                if load = '1' then
                    count <= unsigned(data_i); -- Carga paralela síncrona.
                else
                    if up = '1' then -- Contagem crescente.
                        count <= count + 1;
                    else -- Contagem decrescente.
                        count <= count - 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    data_o <= std_logic_vector(count); -- Conversão para a saída.
end rtl;