----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 23.11.2025 16:27:21
-- Design Name: 
-- Module Name: system_tb - sim
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
use IEEE.STD_LOGIC_1164.ALL;

use std.textio.all;
use ieee.std_logic_textio.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity system_tb is
--  Port ( );
end system_tb;

architecture sim of system_tb is
    constant Tclk : time := 20ns; -- 50Mhz
    constant clock_frequency : integer := 50000000; -- 50MHz
    constant baud   : integer := 115200;
    constant baud_cycles : integer := clock_frequency / baud;
    constant bit_period : time := Tclk * (baud_cycles); -- poniewaz licznik ma 0 to DIVIDER bitow
    
    -- symulacje sygnalow
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal rx_0 : std_logic := '1';
    signal tx_0 : std_logic;
    

begin
    clk <= not clk after Tclk/2;
    
    reset_proc : process
    begin
        rst <= '1';
        wait for 200ns;
        rst <= '0';
        wait;
    end process;
   
   dut : entity work.system_rtl
        port map(
            clk => clk,
            rst => rst,
            rx_0 => rx_0,
            tx_0 => tx_0
        );
        
        stim_proc : process
            variable L : line;
            variable rx_byte : std_logic_vector(7 downto 0);
            
            procedure uart_send_byte(
                signal rx : out std_logic;
                constant data : in std_logic_vector(7 downto 0)) is
            begin
                -- start bit
                rx <= '0';
                wait for bit_period;
                
                -- dane
                for i in 0 to 7 loop
                    rx <= data(i);
                    wait for bit_period;
                end loop;
                
                -- stop bit
                rx <= '1';
                wait for bit_period;
                
                wait for bit_period; -- jedna przerwa miedzy bajtami, dla czytelnosci
            end procedure;    
            
            procedure uart_recv_byte(   -- procedura ktora przetworzy bajty otrzymane z linii tx od systemu
                signal tx : in std_logic;
                variable data : out std_logic_vector(7 downto 0)) is
                
            begin
                wait until tx = '0';
                
                -- trzeba trafic w srodek bitu aby odczytac poprawnie jego stan
                wait for bit_period + bit_period / 2;   -- wiec przeczekujemy bit startu i pol bitu danych
--                wait for bit_period;
                
                for i in 0 to 7 loop
                    data(i) := tx;
                    wait for bit_period;
                end loop;
                
                 -- stop bit, przeczekanie jego
                wait for bit_period;
            end procedure;
   
        -- test generalny
        begin
            wait until rst = '0';
            wait for 5*bit_period; -- chwila przerwy po resecie
            
            -- zapisz xA1 pod adres x61
            uart_send_byte(rx_0, x"A5");
            -- konwersja x61 do wektora ktory laczony jest z 0 (WRITE)
            uart_send_byte(rx_0, '0' & std_logic_vector(to_unsigned(16#61#, 7)));
            uart_send_byte(rx_0, x"A1");
            
            uart_recv_byte(tx_0, rx_byte); -- powinno byc 5A
            write(L, string'("RESP WRITE PRE = 0x")); hwrite(L, rx_byte);
            writeline(output, L);
            
            uart_recv_byte(tx_0, rx_byte); -- 0 & adres ramu
            write(L, string'("RESP WRITE HDR = 0x")); hwrite(L, rx_byte);
            writeline(output, L);
            
            write(L, string'("CZY TY W OGOLE TU JESTES??"));
            writeline(output, L);
            
            uart_recv_byte(tx_0, rx_byte); -- xA1
            write(L, string'("RESP WRITE DATA = 0x")); hwrite(L, rx_byte);
            writeline(output, L);
            
            
            
            -- odczytaj spod adres x61
            uart_send_byte(rx_0, x"A5");
            -- konwersja x61 do wektora ktory laczony jest z 0 (WRITE)
            uart_send_byte(rx_0, '1' & std_logic_vector(to_unsigned(16#61#, 7)));
            uart_send_byte(rx_0, x"00");   -- zawsze trzeba wyslac padding ramki
            
            uart_recv_byte(tx_0, rx_byte); -- powinno byc 5A
            write(L, string'("RESP READ PRE = 0x")); hwrite(L, rx_byte);
            writeline(output, L);
            
            uart_recv_byte(tx_0, rx_byte); -- 1 & adres ramu czyli xBD
            write(L, string'("RESP READ HDR = 0x")); hwrite(L, rx_byte);
            writeline(output, L);
            
            uart_recv_byte(tx_0, rx_byte); -- xA1
            write(L, string'("RESP READ DATA = 0x")); hwrite(L, rx_byte);
            writeline(output, L);
            
            assert rx_byte = x"A1"
                report "READ data is wrong..."
                severity error;
                
            wait; -- KONIEC
   
        end process;
end sim;
