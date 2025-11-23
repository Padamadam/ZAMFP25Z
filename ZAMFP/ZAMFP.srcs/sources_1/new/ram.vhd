----------------------------------------------------------------------------------
-- Company: EiTI PW
-- Engineer: Adam Rybojad
-- 
-- Create Date: 04.11.2025 17:29:41
-- Design Name: 
-- Module Name: ram - Behavioral
-- Project Name: ZAMFP25Z
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

use std.textio.all;
use IEEE.std_logic_textio.all;

entity ram is
    generic (
        DATA_WIDTH : integer := 8;
        ADDR_WIDTH : integer := 7
    );
    
    port(
        clk : in std_logic;
        rst : in std_logic;
        addr : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
        write_en : in std_logic;
        din : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        dout : out std_logic_vector(DATA_WIDTH - 1 downto 0)
        );
end ram;

architecture Behavioral of ram is
    type ram_t is array (0 to 2**ADDR_WIDTH - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal mem : ram_t := (others => (others => '0'));
    attribute ram_style : string;
    attribute ram_style of mem : signal is "block";
          
begin    
    process(clk) is
        -- synthesis translate_off
        --variable L : line;
        -- synthesis translate_on
    begin
        if rising_edge(clk) then
            if rst = '1' then
                dout <= (others => '0');
            else
                if write_en = '1' then
                    mem(to_integer(unsigned(addr))) <= din;
                    dout <= din;
                    
                    -- synthesis translate_off
--                    write(L, string'("RAM WRITE: addr="));
--                    write(L, to_integer(unsigned(addr)));
--                    write(L, string'(" data=0x"));
--                    hwrite(L, din);
--                    writeline(output, L);
                    -- synthesis translate_on
                else
                    dout <= mem(to_integer(unsigned(addr)));
                    
                    -- synthesis translate_off
--                    write(L, string'("RAM READ: addr="));
--                    write(L, to_integer(unsigned(addr)));
--                    write(L, string'(" data= 0x"));
--                    write(L, mem(to_integer(unsigned(addr))));
--                    writeline(output, L);
                    -- synthesis translate_on
                end if;
            end if;
        end if;
    end process;    

end Behavioral;
