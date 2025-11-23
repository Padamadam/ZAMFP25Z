----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 22.11.2025 23:32:54
-- Design Name: 
-- Module Name: uart_ram_ctrl_tb - Behavioral
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


-- TODO: CZYM W ZASADZIE ODROZNIC STB OD ACK?

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;
use ieee.std_logic_textio.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity uart_ram_ctrl_tb is
end uart_ram_ctrl_tb;

architecture sim of uart_ram_ctrl_tb is
    constant Tclk : time := 20ns; -- 50MHz z uarta
    
    signal clk: std_logic := '0';
    signal rst: std_logic := '1';
    
    signal uart_data_in : std_logic_vector(7 downto 0) := (others => '0');
    signal uart_data_in_stb : std_logic := '0';
    
    signal uart_data_out : std_logic_vector(7 downto 0) := (others => '0');
    signal uart_data_out_stb : std_logic := '0';
    signal uart_data_out_ack : std_logic := '0';
    
    signal ram_addr : std_logic_vector(6 downto 0);
    signal ram_write_en : std_logic;
    signal ram_din : std_logic_vector(7 downto 0);
    signal ram_dout : std_logic_vector(7 downto 0);
    
begin
    clk <= not clk after Tclk/2;
    
    reset_proc : process
    begin
        rst <= '1';
        wait for 200ns;
        rst <= '0';
        wait;
    end process reset_proc;
    
    uut_ctrl : entity work.uart_ram_ctrl
        port map(
        clk => clk,
        rst => rst,
        
        -- uart rx (z komputera)
        uart_data_in => uart_data_in,
        uart_data_in_stb => uart_data_in_stb,
        
        -- uart tx (dane do komputera)
        uart_data_out => uart_data_out,
        uart_data_out_stb => uart_data_out_stb,
        uart_data_out_ack => uart_data_out_ack,
        
        -- ram
        ram_addr => ram_addr,
        ram_write_en => ram_write_en,
        ram_din => ram_din,
        ram_dout => ram_dout
        );
        
        uut_ram : entity work.ram
            generic map(
                DATA_WIDTH => 8,
                ADDR_WIDTH => 7
                )
            port map(
                clk => clk,
                rst => rst,
                addr => ram_addr,
                write_en => ram_write_en,
                din => ram_din,
                dout => ram_dout
            );
            
            
            -- proces generujacy ack z kazdym razem jak kontroler wystawi out_stb
--            ack_proc : process(clk)
--            begin
--                if rising_edge(clk) then
                    uart_data_out_ack <= uart_data_out_stb;
--                end if;
--            end process ack_proc;
            
            -- stymulowanie sygnalu
            stim_proc : process
                variable L : line;
                variable hdr : std_logic_vector(7 downto 0);
                
                variable dir : std_logic;
    
                -- testowa tablica adresow do pozapisywania
                type addr_array_t is array (natural range <>) of std_logic_vector(6 downto 0);
                constant addr : addr_array_t := (
                    std_logic_vector(to_unsigned(16#71#, 7)),
                    std_logic_vector(to_unsigned(16#31#, 7)),
                    std_logic_vector(to_unsigned(16#32#, 7)),
                    std_logic_vector(to_unsigned(16#61#, 7)),
                    std_logic_vector(to_unsigned(16#09#, 7)),
                    std_logic_vector(to_unsigned(16#77#, 7)),
                    std_logic_vector(to_unsigned(16#01#, 7)),
                    std_logic_vector(to_unsigned(16#10#, 7))
                );
                
                -- testowa tablica danych do pozapisywania
                type byte_array_t is array (natural range <>) of std_logic_vector(7 downto 0);
                constant write_data : byte_array_t := (
                    x"11", x"21", x"28", x"a1", x"b9", x"c7", x"91", x"f2"
                    );
                
            begin
                wait until rst = '0';
                wait until rising_edge(clk);
                
                dir := '0';
                
            for i in write_data'range loop
                --------
                -- WRITE                
                --------
                uart_data_in <= x"A5";
                uart_data_in_stb <= '1';
                wait until rising_edge(clk);
                uart_data_in_stb <= '0';
                wait for 10*Tclk;    -- 10 taktow czekania jak 10 bitow w uarcie
                
                -- header z kierunkiem write
                hdr := dir & addr(i);
                uart_data_in <= hdr;
                uart_data_in_stb <= '1';
                wait until rising_edge(clk);
                uart_data_in_stb <= '0';
                wait for 10*Tclk;    -- 10 taktow czekania jak 10 bitow w uarcie
                
 
                uart_data_in <= write_data(i);
                uart_data_in_stb <= '1';
                wait until rising_edge(clk);
                uart_data_in_stb <= '0';
                
                -- trzeba zaczekac az bedziemy mieli potwierdzenie ze bajty zostaly wypuszczone
                -- tak samo to dziala na pc, bo on sam nie wysle ramki dopoki nie dostanie calej ramki z powrotem
                wait until uart_data_out_stb = '1';  -- zaczęła się odpowiedź
                wait until uart_data_out_stb = '0';  -- odpowiedź się skończyła
                
                
                write(L, string'("Koniec przesylu ramki WRITE, addr="));
                write(L, to_integer(unsigned(ram_addr)));
                write(L, string'(" ram_dout="));
                write(L, to_integer(unsigned(ram_dout)));
                writeline(output, L);
            end loop;
   
            wait for 10*Tclk; -- przerwa miedzy petlami
   
            
            --------
            -- READ                
            --------
            dir := '1';
            for i in write_data'range loop
            
                exit when i*3 > write_data'high;    -- wyjdz jesli przeiterowalismy co 3 adres
                
                uart_data_in <= x"A5";
                uart_data_in_stb <= '1';
                wait until rising_edge(clk);
                uart_data_in_stb <= '0';
                wait for 10*Tclk;    -- 10 taktow czekania jak 10 bitow w uarcie
                
                -- header z kierunkiem read
                hdr := dir & addr(i*3); -- teraz odczytujmemy co 0, 3 i 6 adres
                uart_data_in <= hdr;
                uart_data_in_stb <= '1';
                wait until rising_edge(clk);
                uart_data_in_stb <= '0';
                wait for 10*Tclk;    -- 10 taktow czekania jak 10 bitow w uarcie
                
                uart_data_in <= x"00";
                uart_data_in_stb <= '1';
                wait until rising_edge(clk);
                uart_data_in_stb <= '0';
                
                -- trzeba zaczekac az bedziemy mieli potwierdzenie ze bajty zostaly wypuszczone
                -- tak samo to dziala irl, bo fpga chwile zajmuje wyslanie wszystkich bitow
                wait until uart_data_out_stb = '1';  -- zaczęła się odpowiedź
                wait until uart_data_out_stb = '0';  -- odpowiedź się skończyła
                
                
                write(L, string'("Koniec przesylu ramki READ, addr="));
                write(L, to_integer(unsigned(ram_addr)));
                write(L, string'(" ram_dout="));
                write(L, to_integer(unsigned(ram_dout)));
                writeline(output, L);
            end loop;
                        
            wait;
        end process stim_proc;   
                              
end sim;
