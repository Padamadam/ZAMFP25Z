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
    constant bit_period : time := Tclk * (baud_cycles);
    
    -- UART monitorujący tx_0
    signal mon_data_out      : std_logic_vector(7 downto 0);
    signal mon_data_out_stb  : std_logic;
    signal mon_data_in_ack   : std_logic := '0';
    signal mon_tx_dummy      : std_logic;

    
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
        
    uart_monitor : entity work.uart
        generic map(
            baud            => baud,
            clock_frequency => clock_frequency
        )
        port map(
            clock        => clk,
            reset        => rst,

            data_in      => (others => '0'),
            data_in_stb  => '0',
            data_in_ack  => open,

            data_out     => mon_data_out,      -- TU wyjdą bajty z tx_0
            data_out_stb => mon_data_out_stb,

            tx           => mon_tx_dummy,      -- nieużywany
            rx           => tx_0               
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
                                
                wait for bit_period; -- jedna przerwa miedzy bajtami, dla czytelnosci;
            end procedure;    
            
--            procedure uart_recv_byte(   -- procedura ktora przetworzy bajty otrzymane z linii tx od systemu
--                signal tx : in std_logic;
--                variable data : out std_logic_vector(7 downto 0)) is
                
--            begin
--                wait until tx'event and tx = '0';
                
--                -- trzeba trafic w srodek bitu aby odczytac poprawnie jego stan
----                wait for bit_period + bit_period / 2;   -- wiec przeczekujemy bit startu i pol bitu danych
--                wait for bit_period;
       
                
                                
--                for i in 0 to 7 loop
--                    data(i) := tx;
--                    wait for bit_period;
----                    wait_bit(clk);
--                end loop;
                
--                 -- stop bit, przeczekanie jego
--                wait for bit_period;
----                wait_bit(clk);
--            end procedure;
   
        -- test generalny
        begin
            wait until rst = '0';
            
            wait for 5*bit_period;
            
             -- zapisz xA1 pod adres x61
                uart_send_byte(rx_0, x"A5");
                -- konwersja x61 do wektora ktory laczony jest z 0 (WRITE)
                uart_send_byte(rx_0, '0' & std_logic_vector(to_unsigned(16#61#, 7)));
                uart_send_byte(rx_0, x"A1");
                
                -- odpowiedź WRITE
                wait until mon_data_out_stb = '1';
                rx_byte := mon_data_out;
                write(L, string'("RESP WRITE PRE = 0x")); hwrite(L, rx_byte);
                writeline(output, L);
    
                wait until mon_data_out_stb = '1';
                rx_byte := mon_data_out;
                write(L, string'("RESP WRITE HDR = 0x")); hwrite(L, rx_byte);
                writeline(output, L);
    
    --            write(L, string'("CZY TY W OGOLE TU JESTES??"));
                writeline(output, L);
    
                wait until mon_data_out_stb = '1';
                rx_byte := mon_data_out;
                write(L, string'("RESP WRITE DATA = 0x")); hwrite(L, rx_byte);
                writeline(output, L);
    
                -- odczytaj spod adres x61
                uart_send_byte(rx_0, x"A5");
                -- konwersja x61 do wektora ktory laczony jest z 0 (WRITE)
                uart_send_byte(rx_0, '1' & std_logic_vector(to_unsigned(16#61#, 7)));
                uart_send_byte(rx_0, x"00");   -- zawsze trzeba wyslac padding ramki
    
                -- odpowiedź READ
                wait until mon_data_out_stb = '1';
                rx_byte := mon_data_out;
                write(L, string'("RESP READ PRE = 0x")); hwrite(L, rx_byte);
                writeline(output, L);
    
                wait until mon_data_out_stb = '1';
                rx_byte := mon_data_out;
                write(L, string'("RESP READ HDR = 0x")); hwrite(L, rx_byte);
                writeline(output, L);
    
                wait until mon_data_out_stb = '1';
                rx_byte := mon_data_out;
                write(L, string'("RESP READ DATA = 0x")); hwrite(L, rx_byte);
                writeline(output, L);
    
                assert rx_byte = x"A1"
                    report "READ data is wrong..."
                    severity error;
            
           for i in 0 to 7 loop           
                -- debug: wypisz numer iteracji
                write(L, i);
                writeline(output, L);
            
                wait for 20*bit_period;
            
                ----------------------------------------------------------------
                -- WRITE: A5, (0 & addr), data
                ----------------------------------------------------------------
                uart_send_byte(rx_0, x"A5");
                uart_send_byte(rx_0, '0' & std_logic_vector(to_unsigned(i*3, 7)));  -- WRITE, addr=i*3
                uart_send_byte(rx_0, std_logic_vector(to_unsigned(i*2, 8)));       -- data=i*2
            
                -- odpowiedź WRITE
                wait until mon_data_out_stb = '1';  -- PRE
                rx_byte := mon_data_out;
                write(L, string'("RESP WRITE PRE = 0x")); hwrite(L, rx_byte);
                writeline(output, L);
            
                wait until mon_data_out_stb = '1';  -- HDR
                rx_byte := mon_data_out;
                write(L, string'("RESP WRITE HDR = 0x")); hwrite(L, rx_byte);
                writeline(output, L);
            
                wait until mon_data_out_stb = '1';  -- DATA
                rx_byte := mon_data_out;
                write(L, string'("RESP WRITE DATA = 0x")); hwrite(L, rx_byte);
                writeline(output, L);
            

                uart_send_byte(rx_0, x"A5");
                uart_send_byte(rx_0, '1' & std_logic_vector(to_unsigned(i*3, 7)));  -- READ, addr=i*3
                uart_send_byte(rx_0, x"00");
            
                wait until mon_data_out_stb = '1';  -- PRE
                rx_byte := mon_data_out;
                write(L, string'("RESP READ PRE = 0x")); hwrite(L, rx_byte);
                writeline(output, L);
            
                wait until mon_data_out_stb = '1';  -- HDR
                rx_byte := mon_data_out;
                write(L, string'("RESP READ HDR = 0x")); hwrite(L, rx_byte);
                writeline(output, L);
            
                wait until mon_data_out_stb = '1';  -- DATA
                rx_byte := mon_data_out;
                write(L, string'("RESP READ DATA = 0x")); hwrite(L, rx_byte);
                writeline(output, L);
            
                -- sprawdzenie danych
                assert to_integer(unsigned(rx_byte)) = i*2
                    report "READ data is wrong..."
                    severity error;
            
            end loop;
            wait; -- KONIEC
   
        end process;
end sim;
