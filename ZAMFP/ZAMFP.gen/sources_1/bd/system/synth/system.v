//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2025.1 (win64) Build 6140274 Thu May 22 00:12:29 MDT 2025
//Date        : Sun Nov 23 16:20:55 2025
//Host        : AdamLegion running 64-bit major release  (build 9200)
//Command     : generate_target system.bd
//Design      : system
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CORE_GENERATION_INFO = "system,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=system,x_ipVersion=1.00.a,x_ipLanguage=VERILOG,numBlks=3,numReposBlks=3,numNonXlnxBlks=0,numHierBlks=0,maxHierDepth=0,numSysgenBlks=0,numHlsBlks=0,numHdlrefBlks=3,numPkgbdBlks=0,bdsource=USER,synth_mode=Hierarchical}" *) (* HW_HANDOFF = "system.hwdef" *) 
module system
   (clk,
    rst,
    rx_0,
    tx_0);
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.CLK CLK" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.CLK, ASSOCIATED_RESET rst, CLK_DOMAIN system_clk, FREQ_HZ 50000000, FREQ_TOLERANCE_HZ 0, INSERT_VIP 0, PHASE 0.0" *) input clk;
  input rst;
  input rx_0;
  output tx_0;

  wire clk;
  wire [7:0]ram_0_dout;
  wire rst;
  wire rx_0;
  wire tx_0;
  wire uart_0_data_in_ack;
  wire [7:0]uart_0_data_out;
  wire uart_0_data_out_stb;
  wire [6:0]uart_ram_ctrl_0_ram_addr;
  wire [7:0]uart_ram_ctrl_0_ram_din;
  wire uart_ram_ctrl_0_ram_write_en;
  wire [7:0]uart_ram_ctrl_0_uart_data_out;
  wire uart_ram_ctrl_0_uart_data_out_stb;

  system_ram_0_0 ram_0
       (.addr(uart_ram_ctrl_0_ram_addr),
        .clk(clk),
        .din(uart_ram_ctrl_0_ram_din),
        .dout(ram_0_dout),
        .rst(rst),
        .write_en(uart_ram_ctrl_0_ram_write_en));
  system_uart_0_0 uart_0
       (.clock(clk),
        .data_in(uart_ram_ctrl_0_uart_data_out),
        .data_in_ack(uart_0_data_in_ack),
        .data_in_stb(uart_ram_ctrl_0_uart_data_out_stb),
        .data_out(uart_0_data_out),
        .data_out_stb(uart_0_data_out_stb),
        .reset(rst),
        .rx(rx_0),
        .tx(tx_0));
  system_uart_ram_ctrl_0_0 uart_ram_ctrl_0
       (.clk(clk),
        .ram_addr(uart_ram_ctrl_0_ram_addr),
        .ram_din(uart_ram_ctrl_0_ram_din),
        .ram_dout(ram_0_dout),
        .ram_write_en(uart_ram_ctrl_0_ram_write_en),
        .rst(rst),
        .uart_data_in(uart_0_data_out),
        .uart_data_in_stb(uart_0_data_out_stb),
        .uart_data_out(uart_ram_ctrl_0_uart_data_out),
        .uart_data_out_ack(uart_0_data_in_ack),
        .uart_data_out_stb(uart_ram_ctrl_0_uart_data_out_stb));
endmodule
