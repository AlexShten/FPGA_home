`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/04/2026 04:57:29 PM
// Design Name: 
// Module Name: tb_mb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module tb_mb;

    reg        diff_clock_rtl_0_clk_p;
    reg        diff_clock_rtl_0_clk_n;
    reg        reset_rtl_0;
    reg [2:0]  buttons_tri_i;
    wire [3:0] leds_tri_o;


    design_1_wrapper dut (
        .buttons_tri_i        (buttons_tri_i),
        .diff_clock_rtl_0_clk_n(diff_clock_rtl_0_clk_n),
        .diff_clock_rtl_0_clk_p(diff_clock_rtl_0_clk_p),
        .leds_tri_o           (leds_tri_o),
        .reset_rtl_0          (reset_rtl_0)
    );

    initial begin
        diff_clock_rtl_0_clk_p = 1'b0;
        diff_clock_rtl_0_clk_n = 1'b1;

        forever begin
            #5000;
            diff_clock_rtl_0_clk_p = ~diff_clock_rtl_0_clk_p;
            diff_clock_rtl_0_clk_n = ~diff_clock_rtl_0_clk_n;
        end
    end

    initial begin

        buttons_tri_i = 3'b001;
        reset_rtl_0 = 1'b0;

        #1000000;

        reset_rtl_0 = 1'b1;

        #1100000000;

        $finish;
    end


    always @(leds_tri_o) begin
        $display("[%0t ps] LED = %b", $time, leds_tri_o);
    end

endmodule