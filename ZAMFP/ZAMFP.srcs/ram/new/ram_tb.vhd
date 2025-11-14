----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05.11.2025 18:50:58
-- Design Name: 
-- Module Name: ram_tb - Behavioral
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

use IEEE.NUMERIC_STD.ALL;
use std.textio.all;
use IEEE.std_logic_textio.all;


entity ram_tb is
--  Port ( );
end ram_tb;

architecture sim of ram_tb is
    constant Tclk : time := 10 ns;      -- okres 10ns -> 100MHz
    signal clk : std_logic := '0';      -- zegar systemowy TB
    signal rst : std_logic := '1';      -- reset poczatkowo aktywny

    
    signal addr : std_logic_vector(6 downto 0) := (others => '0');
    signal write_en : std_logic := '0';
    signal din : std_logic_vector(7 downto 0) := (others => '0');
    signal dout : std_logic_vector(7 downto 0);
    
begin
    reset_proc : process
    begin
        rst <= '1';
        wait for 10*Tclk;       -- reset przez 10 cykli (100ns)
        rst <= '0';
        wait;                    -- zatrzymanie procesu
    end process reset_proc;
    
    uut_ram : entity work.ram
        generic map(
            DATA_WIDTH => 8,
            ADDR_WIDTH => 7
        )
        
        port map (
            clk => clk,
            rst => rst,
            addr => addr,
            write_en => write_en,
            din => din,
            dout => dout
        );
        
        -- generator zegara
        clk <= not clk after Tclk/2;
        
        stim_proc : process
            variable L : line;  -- text IO
            variable expected : std_logic_vector(7 downto 0);
        begin
            -- zwolnienie resetu
            wait until rst = '0';
            
            -- pierwsze narastajace zbocze po resecie
            wait until rising_edge(clk);
            
            -- zapis do RAM
            addr <= "0000001";
            din <= x"AA";
            write_en <= '1';
            
            wait until rising_edge(clk);    -- zapisanie din do ramu
            
            write_en <= '0';    -- wylaczenie zapisu
            
            write(L, string'("TB: WRITE addr=0x"));
            hwrite(L, addr);
            write(L, string'(" data=0x"));
            hwrite(L, din);
            writeline(output, L);
            
            
            -- odczyt z ram
            addr <= "0000001";
            write_en <= '0';
            
            wait until rising_edge(clk);
            
            write(L, string'("TB: READ addr=0x"));
            hwrite(L, addr);
            write(L, string'(" data=0x"));
            hwrite(L, dout);
            writeline(output, L);
            
            -- asercja
            assert(dout = x"AA")
                report "Blad asercji"
                severity error;
            
            -- petla zapisu
            for i in 0 to 7 loop
                expected := std_logic_vector(TO_UNSIGNED(i * 3, 8));
                
                addr <= std_logic_vector(TO_UNSIGNED(i, addr'length));
                
                write_en <= '1';
                din <= expected;

                wait until rising_edge(clk);
               
                write_en <= '0';
                wait until rising_edge(clk);
                
                write(L, string'("TB: WRITE addr=0x"));
                hwrite(L, addr);
                write(L, string'(" data=0x"));
                hwrite(L, din);
                writeline(output, L);
            end loop;
                
                
            -- petla odczytu
            for i in 0 to 7 loop
                expected := std_logic_vector(TO_UNSIGNED(i * 3, 8));
                
                addr <= std_logic_vector(TO_UNSIGNED(i, addr'length));
                write_en <= '0';
                
                wait until rising_edge(clk);
                wait for 0ns;
                
                write(L, string'("TB: READ addr=0x"));
                hwrite(L, addr);
                write(L, string'(" data=0x"));
                hwrite(L, dout);
                writeline(output, L);
                
                if (dout = expected) then
                     write(L, string'("READ pass for addr=0x"));
                    hwrite(L, addr);
                    writeline(output, L);
                else
                    assert false
                        report "Blad asercji dla addr=..."
                        severity error;
                end if;
                    
            end loop;

            wait;
            
        end process stim_proc;
             
end architecture sim;

