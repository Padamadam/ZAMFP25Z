------------------------------------------------------------------------------------
---- Company: 
---- Engineer: 
---- 
---- Create Date: 14.11.2025 11:46:50
---- Design Name: 
---- Module Name: tb_uart_tx - Behavioral
---- Project Name: 
---- Target Devices: 
---- Tool Versions: 
---- Description: 
---- 
---- Dependencies: 
---- 
---- Revision:
---- Revision 0.01 - File Created
---- Additional Comments:
---- 
------------------------------------------------------------------------------------


library IEEE;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_1164.ALL;


entity tb_uart_tx is
end tb_uart_tx;

--architecture sim of tb_uart_tx is

--    constant c_clock_frequency : positive := 1000000; -- 1Mhz
--    constant c_baud            : positive := 9600;
    
--    signal clk : std_logic := '0';
--    signal reset : std_logic := '0';
    
--    signal data_stream_in : std_logic_vector(7 downto 0) := (others => '0');
--    signal data_stream_in_stb : std_logic := '0'; -- sygnalizowanie ze dane na magistrali sa do odebrania
    
--    signal data_stream_in_ack : std_logic;
--    signal tx: std_logic;
    
--    begin
--        uut : entity work.uart
--            generic map(
--                baud => c_baud,
--                clock_frequency => c_clock_frequency
--                )
            
--            port map(
--                clock => clk,
--                reset => reset,
--                data_stream_in => data_stream_in,
--                data_stream_in_stb => data_stream_in_stb,
--                data_stream_in_ack => data_stream_in_ack,
--                data_stream_out => open,    -- ten tb nie testuje rx
--                data_stream_out_stb => open,    -- ten tb nie testuje rx
--                tx => tx,
--                rx => '1'       -- ten tb nie testuje rx
--                );
               
--                clock_gen : process -- generator zegara
--                begin
--                    clk <= '0';
--                    wait for 500ns;
--                    clk <= '1';
--                    wait for 500ns;
--                end process clock_gen; 
                
            
--                reset_gen : process -- generator resetu
--                begin
--                    reset <= '1';
--                    wait for 5 us;  -- 5 okresow zegara
--                    reset <= '0';
--                    wait;       -- proces niech wykona sie tylko raz
--                end process reset_gen;
                
--                stimulus : process
--                begin
--                    -- zwolnienie resetu
--                    wait until reset = '0';
--                    wait for 20 us; -- dodatkowe czekanie na stabilizacje
                    
--                    -- bajt na tx
--                    data_stream_in <= x"A6";    -- 1010 0110
--                    wait for 10 us;
                    
--                    -- strobe
--                    data_stream_in_stb <= '1';
--                    wait until data_stream_in_ack = '1'; -- strobe musi byc wlaczane na tyle dlugo aby tx_baud_tick w niego trafil
                    
--                    data_stream_in_stb <= '0';
                    
--                    wait until data_stream_in_ack = '0';
                    
--                    wait for 5 ms;    -- odczekanie na wyslanie calej ramki
                    
--                    assert false 
--                        report "KONIEC SYMULACJI" 
--                        severity failure;
                        
--                end process stimulus;
--    end architecture sim;
                      
    

