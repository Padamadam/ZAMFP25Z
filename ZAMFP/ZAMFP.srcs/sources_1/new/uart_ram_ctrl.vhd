----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 22.11.2025 18:27:47
-- Design Name: 
-- Module Name: uart_ram_ctrl - Behavioral
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

entity uart_ram_ctrl is
    port(
        clk : in std_logic;
        rst : in std_logic;
        
        -- uart rx (z komputera)
        uart_data_in : in std_logic_vector(7 downto 0);
        uart_data_in_stb : in std_logic;
        
        -- uart tx (dane do komputera)
        uart_data_out : out std_logic_vector(7 downto 0);
        uart_data_out_stb : out std_logic;
        uart_data_out_ack : in std_logic;
        
        -- ram
        ram_addr : out std_logic_vector(6 downto 0);
        ram_write_en : out std_logic;
        ram_din : out std_logic_vector(7 downto 0);
        ram_dout : in std_logic_vector(7 downto 0)
        );
 
end uart_ram_ctrl;

architecture Behavioral of uart_ram_ctrl is
    -- stany stany fajowa jazda
    type state_t is(
        ST_IDLE,    -- tutaj sprawdzana jest preambula
        ST_RECV_HDR,    -- naglowek (czyli dir i adres)
        ST_RECV_DATA,
        ST_WRITE,
        ST_READ,
        ST_READ_WAIT,
        ST_SEND_PRE,
        ST_SEND_HDR,
        ST_SEND_DATA
        );
                 
    signal read_wait_done : std_logic := '0';
    signal state : state_t := ST_IDLE;
    
    constant PRE_REQUEST : std_logic_vector(7 downto 0) := x"A5";
    constant PRE_ANSWER : std_logic_vector(7 downto 0) := x"5A";
    
    signal dir_bit : std_logic; -- 0=WRITE, 1=READ
    signal addr_reg : std_logic_vector(6 downto 0);     -- adres RAM
    signal data_rx_reg : std_logic_vector(7 downto 0);  -- dane z PC
    
    -- dane odczytane z ram do odpowiedzi
    signal data_ram_reg : std_logic_vector(7 downto 0); 
        
    
begin
    process(clk)
    variable L : line;

    begin
        if rising_edge(clk) then
            if rst='1' then
                state <= ST_IDLE;
                uart_data_out_stb <= '0';
                ram_write_en <= '0';
                read_wait_done  <= '0';     -- reset flagi
            else
                uart_data_out_stb <= '0';
                ram_write_en <= '0';
                -- glowna maszyna stanow
                case state is
                    when ST_IDLE =>
                        if uart_data_in_stb = '1' then
--                            write(L, string'("DATA IN STB"));
                            writeline(output, L);
                            if uart_data_in = PRE_REQUEST then
--                                write(L, string'("PREAMBULA OK"));
                                writeline(output, L);
                                -- poprawna preambula
                                state <= ST_RECV_HDR;
                            end if;
                        end if;
                    when ST_RECV_HDR =>
                        if uart_data_in_stb = '1' then
                            dir_bit <= uart_data_in(7);
                            addr_reg <= uart_data_in(6 downto 0);
                            
                            state <= ST_RECV_DATA;
                        end if;
                    when ST_RECV_DATA =>
                        if uart_data_in_stb = '1' then
                            data_rx_reg <= uart_data_in;
                            
                            if dir_bit = '0' then
                                state <= ST_WRITE;
                            else
                                state <= ST_READ;
                            end if;
                        end if;
                    when ST_WRITE =>
                        ram_addr <= addr_reg;
                        ram_din <= data_rx_reg;
                        ram_write_en <= '1';
                        
                        -- wyslanie odpowiedzi o zapisie
                        state <= ST_SEND_PRE;
                    when ST_READ =>
                        ram_addr <= addr_reg;
                        ram_write_en <= '0'; -- jest juz na poczatku ale tutaj na wszelki wypadek
                        read_wait_done <= '0';  -- flaga do czekania
                        state <= ST_READ_WAIT; -- trzeba zaczekac bo ram ma jeden takt opoznienia w odczycie
                    when ST_READ_WAIT =>
                        if read_wait_done = '0' then
                            -- teraz ram jeszcze aktualizuje dout, dlatego trzeba zaczekac jeden takt
                            read_wait_done <= '1';
                        else
                            -- dopiero teraz na dout otrzymano dane z ramu
                            data_ram_reg <= ram_dout;
                            state <= ST_SEND_PRE;
                        end if;
                    when ST_SEND_PRE =>
                        uart_data_out <= PRE_ANSWER; -- x5A
                        uart_data_out_stb <= '1';
                        
                        if uart_data_out_ack = '1' then -- sprawdzenie ze uart potwierdzil wysylke
                            state <= ST_SEND_HDR;
                        end if;
                    when ST_SEND_HDR =>
                        uart_data_out <= dir_bit & addr_reg; -- header
                        uart_data_out_stb <= '1'; -- gotowy do wyslania
                        
                        if uart_data_out_ack = '1' then
                            state <= ST_SEND_DATA;
                        end if;
                        
                    when ST_SEND_DATA =>
                        if dir_bit = '0' then -- WRITE
                            -- odeslanie tegon co zapisano aby potwierdzic ze dane sie nie przeksztalcily
                            uart_data_out <= data_rx_reg;
                        else
                            uart_data_out <= data_ram_reg;  -- odczytany ram
                        end if;
                        
                        uart_data_out_stb <= '1';
                        if uart_data_out_ack = '1' then
                            state <= ST_IDLE;
                        end if;
                    end case;
                end if;
        end if;
     end process;
end Behavioral;
