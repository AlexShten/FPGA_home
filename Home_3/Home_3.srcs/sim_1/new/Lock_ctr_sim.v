`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/27/2026 07:19:44 PM
// Design Name: 
// Module Name: Lock_ctr_sim
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


module Lock_ctr_sim;

    reg        clk;
    reg        rst;
    reg  [3:0] digit_in;
    wire       unlocked_led;
    
    
    Lock_ctr dut (
        .clk(clk),
        .rst(rst),
        .digit_in(digit_in),
        .unlocked_led(unlocked_led)
        
        );


    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin

        rst = 1;
        digit_in = 4'd0;

        #2;

        if (unlocked_led !== 1'b0)
            $display("ERROR: reset -> unlocked_led should be 0");
        else
            $display("PASS: reset -> LOCKED");


        rst = 0;

        digit_in = 4'd1;
        @(posedge clk);
        #1;

        if (unlocked_led !== 1'b0)
            $display("ERROR: LOCKED -> WAIT_D2");
        else
            $display("PASS: LOCKED -> WAIT_D2");

        digit_in = 4'd3;
        @(posedge clk);
        #1;

        if (unlocked_led !== 1'b0)
            $display("ERROR: WAIT_D2 -> WAIT_D3");
        else
            $display("PASS: WAIT_D2 -> WAIT_D3");

        digit_in = 4'd9;
        @(posedge clk);
        #1;

        if (unlocked_led !== 1'b1)
            $display("ERROR: WAIT_D3 -> UNLOCKED");
        else
            $display("PASS: WAIT_D3 -> UNLOCKED");

        digit_in = 4'd0;
        @(posedge clk);
        #1;

        if (unlocked_led !== 1'b1)
            $display("ERROR: UNLOCKED should remain UNLOCKED");
        else
            $display("PASS: UNLOCKED remains UNLOCKED");

        rst = 1;
        #2;

        if (unlocked_led !== 1'b0)
            $display("ERROR: reset failed");

        rst = 0;



        digit_in = 4'd1;
        @(posedge clk);
        #1;

        digit_in = 4'd3;
        @(posedge clk);
        #1;

        digit_in = 4'd7;
        @(posedge clk);
        #1;

        if (unlocked_led !== 1'b0)
            $display("ERROR: wrong digit in WAIT_D3");
        else
            $display("PASS: wrong digit in WAIT_D3 -> LOCKED");


        $display("--------------------------------");
        $display("TEST FINISHED");
        $display("--------------------------------");

        $finish;
    end

endmodule
