library ieee;
use ieee.std_logic_1164.all;

entity system_rtl is
    port (
        clk  : in  std_logic;
        rst  : in  std_logic;
        rx_0 : in  std_logic;
        tx_0 : out std_logic
    );
end entity;

architecture rtl of system_rtl is
    signal ram_dout_s          : std_logic_vector(7 downto 0);
    signal uart_data_in_ack_s  : std_logic;
    signal uart_rx_data_s      : std_logic_vector(7 downto 0);
    signal uart_rx_stb_s       : std_logic;
    signal uart_tx_data_s      : std_logic_vector(7 downto 0);
    signal uart_tx_stb_s       : std_logic;
    signal ram_addr_s          : std_logic_vector(6 downto 0);
    signal ram_din_s           : std_logic_vector(7 downto 0);
    signal ram_write_en_s      : std_logic;
begin

    ram_i : entity work.ram
        generic map (
            DATA_WIDTH => 8,
            ADDR_WIDTH => 7
        )
        port map (
            clk       => clk,
            rst       => rst,
            addr      => ram_addr_s,
            write_en  => ram_write_en_s,
            din       => ram_din_s,
            dout      => ram_dout_s
        );

    uart_i : entity work.uart
        generic map (
            baud            => 115200,
            clock_frequency => 50000000
        )
        port map (
            clock        => clk,
            reset        => rst,
            data_in      => uart_tx_data_s,
            data_in_stb  => uart_tx_stb_s,
            data_in_ack  => uart_data_in_ack_s,
            data_out     => uart_rx_data_s,
            data_out_stb => uart_rx_stb_s,
            tx           => tx_0,
            rx           => rx_0
        );

    uart_ctrl_i : entity work.uart_ram_ctrl
        port map (
            clk               => clk,
            rst               => rst,
            uart_data_in      => uart_rx_data_s,
            uart_data_in_stb  => uart_rx_stb_s,
            uart_data_out     => uart_tx_data_s,
            uart_data_out_stb => uart_tx_stb_s,
            uart_data_out_ack => uart_data_in_ack_s,
            ram_addr          => ram_addr_s,
            ram_write_en      => ram_write_en_s,
            ram_din           => ram_din_s,
            ram_dout          => ram_dout_s
        );
end architecture;