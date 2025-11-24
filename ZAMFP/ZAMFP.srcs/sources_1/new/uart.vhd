library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity uart is
    generic(
        baud            : positive := 115200;        -- prędkość transmisji
        clock_frequency : positive := 50000000       -- zegar wejściowy FPGA
    );
    port(
        clock       : in  std_logic;                 -- zegar systemowy
        reset       : in  std_logic;                 -- reset 

        data_in     : in  std_logic_vector(7 downto 0);  -- bajt do wysłania
        data_in_stb : in  std_logic;                     -- żądanie wysłania
        data_in_ack : out std_logic;                     -- potwierdzenie pobrania bajtu

        data_out    : out std_logic_vector(7 downto 0);  -- odebrany bajt
        data_out_stb: out std_logic;                     -- sygnał bajt gotowy

        tx          : out std_logic;                     -- wyjście UART
        rx          : in  std_logic                      -- wejście UART
    );
end uart;

architecture rtl of uart is

    -- gnerator impulsów zgodnych z baud rate
    constant DIVIDER : integer := clock_frequency / baud;

    signal baud_cnt  : integer range 0 to DIVIDER := 0; -- licznik do generacji ticka
    signal baud_tick : std_logic := '0';                -- impuls co 1 bit UART

    -- tx
    type tx_state_t is (TX_IDLE, TX_START, TX_BITS, TX_STOP);
    signal tx_state : tx_state_t := TX_IDLE;            -- aktualny stan nadajnika
    signal tx_reg   : std_logic_vector(9 downto 0);     
    -- 10 bitów: start(0), 8 danych, stop(1)
    signal tx_pos   : integer range 0 to 9 := 0;        -- aktualny wysyłany bit

    -- rx
    type rx_state_t is (RX_IDLE, RX_START, RX_BITS, RX_STOP);
    signal rx_state : rx_state_t := RX_IDLE;            -- aktualny stan odbiornika
    signal rx_reg   : std_logic_vector(7 downto 0);     -- rejestr odebranych bitów
    signal rx_pos   : integer range 0 to 7 := 0;        -- który bit odbieramy

begin

    -- ack - uart pobiera bajt tylko gdy jest w stanie IDLE
    data_in_ack <= '1' when (tx_state = TX_IDLE and data_in_stb = '1') else '0';

    --nadajemy zawsze bit na pozycji tx_reg(0)
    tx <= tx_reg(0);


    -- tworzy impuls co DIVIDER cykli zegara

    process(clock)
    begin
        if rising_edge(clock) then
            if reset = '1' then
                baud_cnt  <= 0;
                baud_tick <= '0';
            else
                if baud_cnt = DIVIDER then
                    baud_cnt  <= 0;
                    baud_tick <= '1';  -- wygeneruj impuls
                else
                    baud_cnt  <= baud_cnt + 1;
                    baud_tick <= '0';
                end if;
            end if;
        end if;
    end process;

    -- tx
    process(clock)
    begin
        if rising_edge(clock) then
            if reset = '1' then
                tx_state <= TX_IDLE;
                tx_reg   <= (others => '1');   -- linia TX spoczywa w stanie '1'
                tx_pos   <= 0;

            else
                case tx_state is

                    when TX_IDLE =>
                        -- oczekujemy na sygnał wysłania
                        if data_in_stb = '1' then
                            -- składamy pełną ramkę UART: start (0), 8 bitów danych, stop (1)
                            tx_reg <= '1' & data_in & '0';  -- LSB wysyłane jako pierwsze
                            tx_pos <= 0;
                            tx_state <= TX_START;
                        end if;

                    when TX_START =>
                        -- wysyłamy pierwszy bit ramki (bit startu = 0)
                        if baud_tick = '1' then
                            tx_state <= TX_BITS;
                        end if;

                    when TX_BITS =>
                        -- przesuwamy rejestr, wysyłamy kolejne bity danych
                        if baud_tick = '1' then
                            tx_reg <= '1' & tx_reg(9 downto 1);

                            if tx_pos = 8 then         -- wszystkie dane wysłane
                                tx_state <= TX_STOP;
                            else
                                tx_pos <= tx_pos + 1;
                            end if;
                        end if;

                    when TX_STOP =>
                        -- wysyłamy bit stopu (1)
                        if baud_tick = '1' then
                            tx_state <= TX_IDLE;
                        end if;

                end case;
            end if;
        end if;
    end process;

    -- rx
    data_out <= rx_reg; -- wyjście danych

    process(clock)
    variable L : line;

    begin
        if rising_edge(clock) then
            if reset = '1' then
                rx_state <= RX_IDLE;
                rx_reg <= (others => '0');
                rx_pos <= 0;
                data_out_stb <= '0';

            else
                data_out_stb <= '0'; -- domyślnie brak nowego bajtu

                case rx_state is

                    when RX_IDLE =>
                        -- czekamy na start bit (linia opada do 0)
                        if rx = '0' then
                            rx_state <= RX_START;
                        end if;

                    when RX_START =>
                        -- potwierdzenie start bitu
                        if baud_tick = '1' then
                            rx_pos <= 0;
                            rx_state <= RX_BITS;
                        end if;

                    when RX_BITS =>
                        -- wczytywanie kolejnych bitów danych
                        if baud_tick = '1' then
                            rx_reg <= rx & rx_reg(7 downto 1);

                            if rx_pos = 7 then
                                rx_state <= RX_STOP;
                            else
                                rx_pos <= rx_pos + 1;
                            end if;
                        end if;

                    when RX_STOP =>
                        -- oczekiwanie na bit stopu (powinien być = 1)
                        if baud_tick = '1' then
                            data_out_stb <= '1';  -- odebrano cały bajt
                            hwrite(L, rx_reg);
                            writeline(output, L);
                            rx_state <= RX_IDLE;
                        end if;

                end case;
            end if;
        end if;
    end process;

end rtl;