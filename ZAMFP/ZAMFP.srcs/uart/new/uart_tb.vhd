library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tb is
end uart_tb;

architecture sim of uart_tb is

    -- sygnały testowe
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal rx  : std_logic := '1'; -- linia idle
    signal tx  : std_logic;

    signal data_in      : std_logic_vector(7 downto 0) := (others => '0');
    signal data_in_stb  : std_logic := '0';
    signal data_in_ack  : std_logic;
    signal data_out     : std_logic_vector(7 downto 0);
    signal data_out_stb : std_logic;

    constant clock_period : time := 20 ns;      -- 50 MHz
    constant baud         : integer := 115200;
    constant baud_cycles  : integer := 50_000_000 / baud;
    constant baud_period  : time := clock_period * baud_cycles;

    -- zestawy danych do testów
    type byte_array_t is array (natural range <>) of std_logic_vector(7 downto 0);
    constant rx_test_data : byte_array_t := (x"41", x"42", x"43"); -- 'A','B','C'
    constant tx_test_data : byte_array_t := (x"31", x"32", x"33"); -- '1','2','3'

begin

    -- zegar 50 MHz
    clk <= not clk after clock_period / 2;

    DUT: entity work.uart
        port map(
            clock        => clk,
            reset        => rst,
            data_in      => data_in,
            data_in_stb  => data_in_stb,
            data_in_ack  => data_in_ack,
            data_out     => data_out,
            data_out_stb => data_out_stb,
            tx           => tx,
            rx           => rx
        );

    -- wysyłanie rx i tx
    process
        variable received_tx : std_logic_vector(7 downto 0);
    begin
        -- reset
        rst <= '1';
        wait for 100 ns;
        rst <= '0';
        wait for 1 us;

        --rx
        for i in rx_test_data'range loop
            -- start bit
            rx <= '0';
            wait for baud_period;

            for b in 0 to 7 loop
                rx <= rx_test_data(i)(b);
                wait for baud_period;
            end loop;

            -- stop bit
            rx <= '1';
            wait for baud_period;

            -- odstęp między bajtami
            wait for 20 us;
        end loop;

        -- wysyłanie bajtów z TB i odczyt TX
        for i in tx_test_data'range loop
            -- załaduj bajt
            data_in <= tx_test_data(i);
            data_in_stb <= '1';
            wait for clock_period;
            data_in_stb <= '0';

            -- odczyt TX
            received_tx := (others => '0');

            -- poczekaj na start bit
            wait until tx = '0';
            wait for baud_period;

            -- odczytaj 8 bitów danych
            for b in 0 to 7 loop
                received_tx(b) := tx;
                wait for baud_period;
            end loop;

            -- poczekaj na stop bit
            wait for baud_period;

            -- krótkie opóźnienie przed kolejnym bajtem
            wait for 20 us;
        end loop;
        wait;
    end process;

end architecture sim;