----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 14.11.2025 18:00:28
-- Design Name: 
-- Module Name: tb_uart_rx - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_1164.ALL;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tb_uart_rx is
----  Port ( );
end tb_uart_rx;

--architecture sim of tb_uart_rx is
--    constant c_clock_frequency : positive := 1000000; -- 1Mhz
--    constant c_baud            : positive := 9600;
    
--    signal clk : std_logic := '0';
--    signal reset : std_logic := '0';
    
--    signal data_stream_out : std_logic_vector(7 downto 0) := (others => '0');
--    signal data_stream_out_stb : std_logic := '0'; -- sygnalizowanie ze dane na magistrali sa do wyslania
--    signal rx: std_logic;
    
--    -- obliczenie baudu jak w uart.vhd
--    constant clk_period : time := 1 sec / c_clock_frequency;
--    constant c_rx_div : integer := c_clock_frequency / (c_baud * 16);
--    -- okres oversampla (rx_baud_tick) = (c_rx_div + 1) taktów zegara
--    constant oversample_period : time := clk_period * (c_rx_div + 1);

--    -- faktyczny czas trwania bitu (16 sampli)
--    constant bit_period : time := oversample_period * 16;
    
--    procedure send_uart_byte(signal rx : out std_logic; data : in std_logic_vector(7 downto 0)) is
--    begin
--        -- stan bezczynny
--        rx <= '1';
--        wait for bit_period;
        
--        -- bit startu
--        rx <= '0';
--        wait for bit_period;
        
--        -- wystawienie bitow danych
--        for i in 0 to 7 loop
--            rx <= data(i);
--            wait for bit_period;
--        end loop;
        
--        --stopbit
--        rx <= '1';
--        wait for bit_period;
--    end procedure send_uart_byte;
    
--begin
--    uut: entity work.uart
--    generic map(
--        baud => c_baud,
--        clock_frequency => c_clock_frequency
--        )
--    port map(
--        clock => clk,
--        reset => reset,
--        data_stream_in => (others => '0'), -- tx to pusta linia
--        data_stream_in_ack => open,
--        data_stream_in_stb => '0',
--        data_stream_out => data_stream_out,
--        data_stream_out_stb => data_stream_out_stb,
--        tx => open,
--        rx => rx
--    );
        
--    clock_gen : process -- generator zegara
--            begin
--                clk <= '0';
--                wait for 500ns;
--                clk <= '1';
--                wait for 500ns;
--            end process clock_gen; 
            
        
--    reset_gen : process -- generator resetu
--    begin
--        reset <= '1';
--        wait for 5 us;  -- 5 okresow zegara
--        reset <= '0';
--        wait;       -- proces niech wykona sie tylko raz
--    end process reset_gen;
   
    
--    stimulus : process
--    begin
--        -- zwolnienie resetu
--        wait until reset = '0';
--        wait for 20 us; -- dodatkowe czekanie na stabilizacje
        
--        -- wyslanie bajtu testowego
--        send_uart_byte(rx, x"AC");
        
--        -- zgloszenie odebrania bajtu przez strobe uarta
--        wait until data_stream_out_stb = '1';
        
--        assert data_stream_out = x"AC";
--            report "UART RX: ODEBRANO ZLY BAJT"
--            severity error;
            
--        wait;     
        
    
--    end process stimulus;
--end sim;
