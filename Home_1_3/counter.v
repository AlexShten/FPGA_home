`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/06/2026 09:22:24 PM
// Design Name: 
// Module Name: counter
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


module counter(
    input  wire       clk,
    input  wire       reset,
    output reg [3:0]  led
);

    always @(posedge clk) begin
        if (reset)
            led <= 4'b0000;
        else
            led <= led + 1'b1;
    end

endmodule
