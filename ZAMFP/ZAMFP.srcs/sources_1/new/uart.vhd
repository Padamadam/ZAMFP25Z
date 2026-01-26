library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart is
    generic(
        baud            : positive := 9600;
        clock_frequency : positive := 50_000_000
    );
    port(
        clock       : in  std_logic;
        reset       : in  std_logic;

        data_in     : in  std_logic_vector(7 downto 0);
        data_in_stb : in  std_logic;
        data_in_ack : out std_logic;

        data_out    : out std_logic_vector(7 downto 0);
        data_out_stb: out std_logic;

        tx          : out std_logic;
        rx          : in  std_logic
    );
end uart;

architecture rtl of uart is

    -- ZMIANA: zamiast globalnego baud_tick jest stala BIT_TICKS,
    -- a czas bitu liczony jest lokalnymi licznikami w TX i RX (od początku ramki).
    signal BIT_TICKS : integer := clock_frequency / baud;
    
    -- TX
    type tx_state_t is (TX_IDLE, TX_START, TX_DATA, TX_STOP);
    signal tx_state    : tx_state_t := TX_IDLE;
    signal tx_shift    : std_logic_vector(7 downto 0) := (others => '1');
    signal tx_bit_idx  : integer  := 0;
    signal tx_tick_cnt : integer  := 0;  -- to ten nowy licznik ZMIANA - USUNIECIE RANGE BO NIEPOTRZEBNE

    signal tx_reg      : std_logic := '1';  -- linia spoczynkowo = 1

    -- RX
    type rx_state_t is (RX_IDLE, RX_START, RX_DATA, RX_STOP);
    signal rx_state    : rx_state_t := RX_IDLE;
    signal rx_shift    : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_bit_idx  : integer range 0 to 7 := 0;
    signal rx_tick_cnt : integer  := 0;  -- nowy licznik TAK JAK WYZEJ

    signal data_out_reg    : std_logic_vector(7 downto 0) := (others => '0');
    signal data_out_stb_reg: std_logic := '0';
    
    --autobaud
    signal auto_tick_cnt  : integer := 0;
    signal auto_baud_done : std_logic := '0';
    signal prev_rx        : std_logic := '1';
    signal bit_idx        : integer := 0;
    signal prev_rx_bit     : std_logic := '1';
    signal last_edge_cnt   : integer := 0;
    signal first_period    : integer := 0;
    signal measuring       : std_logic  := '0';

begin
    tx           <= tx_reg;
    data_out     <= data_out_reg;
    data_out_stb <= data_out_stb_reg;
    data_in_ack <= '1' when (tx_state = TX_IDLE and data_in_stb = '1') else '0';

    --autobaud
process(clock)
    constant pattern_55_bits : std_logic_vector(7 downto 0) := "01010101"; 
    
begin
    if rising_edge(clock) then
        if reset = '1' then
            BIT_TICKS      <= clock_frequency / 115200; -- default --ciężko tutaj bez dzielenia
            auto_tick_cnt  <= 0;
            prev_rx_bit    <= '1';
            last_edge_cnt  <= 0;
            bit_idx        <= 0;
            first_period   <= 0;
            measuring      <= '0';
            auto_baud_done <= '0';
        else
            if auto_baud_done = '0' then
                auto_tick_cnt <= auto_tick_cnt + 1;

                -- wykrycie zbocza
                if prev_rx_bit /= rx then
                    if measuring = '0' then
                        -- pierwsze zbocze (start bit)
                        measuring <= '1';
                        auto_tick_cnt <= 0;
                        bit_idx <= 0;
                    else
                        -- kolejne zbocze -> okres obecnego bitu
                        if bit_idx = 0 then
                            -- zapisujemy pierwszy okres
                            first_period <= auto_tick_cnt;
                            auto_tick_cnt <= 0;
                            bit_idx <= 1;
                        else
                            -- porównujemy z pierwszym okresem
                            if abs(auto_tick_cnt - first_period) <= 1 then
                                -- zgadza się (tolerancja 1 cykl)
                                auto_tick_cnt <= 0;
                                bit_idx <= bit_idx + 1;
                            else
                                -- błąd, reset
                                measuring <= '0';
                                bit_idx <= 0;
                                auto_tick_cnt <= 0;
                            end if;
                        end if;

                        -- jeśli 8 okresów poprawnych
                        if bit_idx = 8 then
                            BIT_TICKS <= first_period;
                            auto_baud_done <= '1';
                            measuring <= '0';
                            bit_idx <= 0;
                        end if;
                    end if;
                    prev_rx_bit <= rx;
                    auto_tick_cnt <= 0; -- reset licznika po zboczu
                end if;
            end if;
        end if;
    end if;
end process;



    -- TX
    process(clock)
    begin
        if rising_edge(clock) then
            if reset = '1' then
                tx_state    <= TX_IDLE;
                tx_reg      <= '1';
                tx_shift    <= (others => '1');
                tx_bit_idx  <= 0;
                tx_tick_cnt <= 0;  
            else
                case tx_state is

                    when TX_IDLE =>
                        tx_reg      <= '1';
                        tx_tick_cnt <= 0;  -- jak nie dziala to niech bedzie 0

                        if data_in_stb = '1' then
                            -- ZMIANA: ładujemy bajt i od razu wymuszamy start bit (0),
                            tx_shift    <= data_in;
                            tx_bit_idx  <= 0;
                            tx_reg      <= '0';  -- start bit
                            tx_tick_cnt <= 0; -- bardzo wazne : wyzerowanie licznika bitu na poczatku startu ramki
                            tx_state    <= TX_START;
                        end if;

                    when TX_START =>
                        -- ZMIANA: start bit trwa dokładnie BIT_TICKS cykli od momentu startu,
                        -- a nie "do kolejnego globalnego baud_tick".
                        if tx_tick_cnt = BIT_TICKS - 1 then
                            tx_tick_cnt <= 0;
                            tx_state    <= TX_DATA;
                            tx_reg      <= tx_shift(0);  -- pierwszy bit danych (LSB)
                        else
                            tx_tick_cnt <= tx_tick_cnt + 1; --!!!!!!!!!!!!!!!!!!!! DO ZMIANY
                        end if;

                    when TX_DATA =>
                        if tx_tick_cnt = BIT_TICKS - 1 then
                            tx_tick_cnt <= 0;

                            if tx_bit_idx = 7 then
                                tx_reg     <= '1';   -- stop bit
                                tx_state   <= TX_STOP;
                            else
                                -- przesuwanie
                                tx_bit_idx <= tx_bit_idx + 1;
                                tx_shift   <= '0' & tx_shift(7 downto 1);  -- przesunięcie w prawo
                                tx_reg     <= tx_shift(1);  -- kolejny LSB po przesunięciu
                            end if;
                        else
                            tx_tick_cnt <= tx_tick_cnt + 1; --!!!!!!!!!!!!!!!!!!!! DO ZMIANY
                        end if;

                    when TX_STOP =>
                        -- ZMIANA: bit stopu też ma dokładnie BIT_TICKS cykli,
                        -- liczonych lokalnie, zamiast polegania na globalnym ticku.
                        if tx_tick_cnt = BIT_TICKS - 1 then
                            tx_tick_cnt <= 0;
                            tx_state    <= TX_IDLE;
                            tx_reg      <= '1';
                        else
                            tx_tick_cnt <= tx_tick_cnt + 1; --!!!!!!!!!!!!!!!!!!!! DO ZMIANY
                        end if;

                end case;
            end if;
        end if;
    end process;

    -- RX
    process(clock)
    begin
        if rising_edge(clock) then
            if reset = '1' then
                rx_state        <= RX_IDLE;
                rx_shift        <= (others => '0');
                rx_bit_idx      <= 0;
                rx_tick_cnt     <= 0;
                data_out_reg    <= (others => '0');
                data_out_stb_reg<= '0';
            else
                data_out_stb_reg <= '0';

                case rx_state is

                    when RX_IDLE =>
                        rx_tick_cnt <= 0;
                        if rx = '0' then
                            rx_state    <= RX_START;
                            rx_tick_cnt <= 0;
                        end if;

                    when RX_START =>
                        -- ZMIANA: czekamy ~pół bitu od momentu wykrycia startu,
                        -- żeby dalej próbkując co BIT_TICKS trafić w środki bitów danych.
                        if rx_tick_cnt = (BIT_TICKS-1)/2 then
                            rx_tick_cnt <= 0;
                            rx_bit_idx  <= 0;
                            rx_state    <= RX_DATA;
                        else
                            rx_tick_cnt <= rx_tick_cnt + 1; --!!!!!!!!!!!!!!!!!!!! DO ZMIANY
                        end if;

                    when RX_DATA =>
                        if rx_tick_cnt = BIT_TICKS - 1 then
                            rx_tick_cnt <= 0;

                            -- ZMIANA: próbkujemy środek bitu danych (co BIT_TICKS od 0.5 bitu),
                            -- dzięki temu pierwszy odczyt to bit0, a nie start.
                            rx_shift <= rx & rx_shift(7 downto 1); --!!!!!!!!!!!!!!!!!!!! DO ZMIANY

                            if rx_bit_idx = 7 then
                                rx_state <= RX_STOP;
                            else
                                rx_bit_idx <= rx_bit_idx + 1; --!!!!!!!!!!!!!!!!!!!! DO ZMIANY
                            end if;
                        else
                            rx_tick_cnt <= rx_tick_cnt + 1;
                        end if;

                    when RX_STOP =>
                        -- ZMIANA: bit stopu też liczony lokalnie rx_tick_cnt a nie baud_tick
                        if rx_tick_cnt = BIT_TICKS - 1 then
                            rx_tick_cnt  <= 0;
                            data_out_reg <= rx_shift;
                            data_out_stb_reg <= '1';  -- pełny bajt gotowy
                            rx_state     <= RX_IDLE;
                        else
                            rx_tick_cnt <= rx_tick_cnt + 1;
                        end if;

                end case;
            end if;
        end if;
    end process;
end rtl;