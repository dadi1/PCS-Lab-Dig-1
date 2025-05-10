library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TCC is
    port(
        clk        : in  std_logic;
        reset      : in  std_logic;
        load_thr   : in  std_logic;
        data_thr   : in  std_logic_vector(7 downto 0);
        word_len   : in  std_logic_vector(1 downto 0);
        stop_bits  : in  std_logic;
        par_en     : in  std_logic;
        par_type   : in  std_logic_vector(1 downto 0);
        break_ctrl : in  std_logic;
        bit_tick   : in  std_logic;
        serial_out : out std_logic;
        thr_empty  : out std_logic;
        tsr_empty  : out std_logic
    );
end entity;

architecture rtl of TCC is
    type state_type is (IDLE, LOAD_TSR, START_BIT, DATA_BITS, PARITY_BIT, STOP_BITS, CLEANUP);
    signal state       : state_type := IDLE;
    signal bit_count   : integer range 0 to 7 := 0;
    signal par_bit     : std_logic := '0';
    signal shift_load  : std_logic;
    signal shift_shift : std_logic;
    signal shift_out   : std_logic;
begin
    -- Instância de TSR interna
    U_TSR: entity work.TSR port map(
        clk       => clk,
        reset     => reset,
        load      => shift_load,
        shift     => shift_shift,
        data_i    => data_thr,
        data_o    => shift_out,
        tsr_empty => tsr_empty
    );

    process(clk, reset)
    begin
        if reset = '1' then
            state      <= IDLE;
            thr_empty  <= '1';
            tsr_empty  <= '1';
            serial_out <= '1';
        elsif rising_edge(clk) then
            shift_load  <= '0';
            shift_shift <= '0';
            case state is
                when IDLE =>
                    serial_out <= '1' when break_ctrl = '0' else '0';
                    thr_empty  <= load_thr = '0';
                    tsr_empty  <= '1';
                    if load_thr = '1' then
                        state <= LOAD_TSR;
                    end if;
                when LOAD_TSR =>
                    shift_load <= '1';
                    thr_empty  <= '0';
                    tsr_empty  <= '0';
                    -- calcula paridade
                    if par_en = '1' then
                        par_bit <= (data_thr(0) xor data_thr(1) xor data_thr(2) xor data_thr(3)
                                   xor data_thr(4) xor data_thr(5) xor data_thr(6) xor data_thr(7));
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
                        if bit_count = to_integer(unsigned(word_len)) then
                            state <= (par_en = '1') ? PARITY_BIT : STOP_BITS;
                        else
                            bit_count <= bit_count + 1;
                        end if;
                    end if;
                when PARITY_BIT =>
                    serial_out <= par_type(0) = '1' ? not par_bit : par_bit;
                    if bit_tick = '1' then
                        state <= STOP_BITS;
                    end if;
                when STOP_BITS =>
                    serial_out <= break_ctrl = '0' ? '1' : '0';
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