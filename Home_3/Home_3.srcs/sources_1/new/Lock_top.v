`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/27/2026 08:01:48 PM
// Design Name: 
// Module Name: Lock_top
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


module Lock_top(

    input clk,    
    input rst,
    input btn0,
    input btn1,
    input btn2,
    input btn3,
    input btn4,
    input btn5,
    input btn6,
    input btn7,
    input btn8,
    input btn9,
    output unlocked_led

    );
    
    wire btn0_cln;
    wire btn1_cln;
    wire btn2_cln;
    wire btn3_cln;
    wire btn4_cln;
    wire btn5_cln;
    wire btn6_cln;
    wire btn7_cln;
    wire btn8_cln;
    wire btn9_cln;
    reg [3:0] digit_in;
    
    Debounce #(.COUNT_MAX(200000)) db0 (
        .clk(clk),
        .btn_raw(btn0),
        .btn_cln(btn0_cln)
    );

    Debounce #(.COUNT_MAX(200000)) db1 (
        .clk(clk),
        .btn_raw(btn1),
        .btn_cln(btn1_cln)
    );

    Debounce #(.COUNT_MAX(200000)) db2 (
        .clk(clk),
        .btn_raw(btn2),
        .btn_cln(btn2_cln)
    );

    Debounce #(.COUNT_MAX(200000)) db3 (
        .clk(clk),
        .btn_raw(btn3),
        .btn_cln(btn3_cln)
    );

    Debounce #(.COUNT_MAX(200000)) db4 (
        .clk(clk),
        .btn_raw(btn4),
        .btn_cln(btn4_cln)
    );

    Debounce #(.COUNT_MAX(200000)) db5 (
        .clk(clk),
        .btn_raw(btn5),
        .btn_cln(btn5_cln)
    );

    Debounce #(.COUNT_MAX(200000)) db6 (
        .clk(clk),
        .btn_raw(btn6),
        .btn_cln(btn6_cln)
    );

    Debounce #(.COUNT_MAX(200000)) db7 (
        .clk(clk),
        .btn_raw(btn7),
        .btn_cln(btn7_cln)
    );

    Debounce #(.COUNT_MAX(200000)) db8 (
        .clk(clk),
        .btn_raw(btn8),
        .btn_cln(btn8_cln)
    );

    Debounce #(.COUNT_MAX(200000)) db9 (
        .clk(clk),
        .btn_raw(btn9),
        .btn_cln(btn9_cln)
    );
    
    always @(*) begin

        if      (btn0_cln) digit_in = 4'd0;
        else if (btn1_cln) digit_in = 4'd1;
        else if (btn2_cln) digit_in = 4'd2;
        else if (btn3_cln) digit_in = 4'd3;
        else if (btn4_cln) digit_in = 4'd4;
        else if (btn5_cln) digit_in = 4'd5;
        else if (btn6_cln) digit_in = 4'd6;
        else if (btn7_cln) digit_in = 4'd7;
        else if (btn8_cln) digit_in = 4'd8;
        else if (btn9_cln) digit_in = 4'd9;
        else               digit_in = 4'd0;

    end
    
    Lock_ctr lock (
        .clk(clk),
        .rst(rst),
        .digit_in(digit_in),
        .unlocked_led(unlocked_led)
    );
    
endmodule
