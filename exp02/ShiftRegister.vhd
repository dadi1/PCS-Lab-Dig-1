entity shiftregister is
    generic(
        WIDTH: natural := 8 -- tamanho em bits
    );
    port(
        clock, reset: in std_logic; -- Clock e reset assincrono ativo alto.
        loadOrShift: in std_logic_vector(1 downto 0);
        -- 00: nada acontece
        -- 01: descolocamento para direita.
        -- 10: descolamento para esquerda.
        -- 11: carga externa paralela.
        serial_i : in std_logic; -- Entrada serial.
        data_i: in std_logic_vector(WIDTH-1 downto 0); -- Entrada Paralela.
        data_o : out std_logic_vector(WIDTH-1 downto 0); -- Saida Paralela.
        serial_o_r: out std_logic; -- Saida serial direita.
        serial_o_l: out std_logic -- Saida serial esquerda.
    );
end shiftregister

architecture rtl of shiftregister is
    signal reg : std_logic_vector(WIDTH-1 downto 0);
begin
    process(clock, reset)
    begin
        if reset = '1' then
            reg <= (others => '0') -- Reset Assíncrono.

        elsif rising_edge(clock) then
            case loadOrShift is
                when "00" =>
                    null;
                -- nada acontece

                when "01" =>
                    reg <= serial_i & reg(WIDTH-1 downto 1);
                    -- Descolamento para direita.

                when "10" =>
                    reg <= reg(WIDTH-2 downto 0) & serial_i;
                    -- Descolamento para a esquerda.
                
                when "11" =>
                    reg <= data_i;
                    -- Entrada da carga paralela.
                
                when others =>
                    null;
            
            end case;
        end if;
    end process;

    data_o <= reg;
    serial_o_r <= reg(0);
    serial_o_l <= reg(WIDTH-1)
end rtl;