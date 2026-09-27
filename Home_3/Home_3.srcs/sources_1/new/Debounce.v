`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/27/2026 07:49:41 PM
// Design Name: 
// Module Name: Debounce
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


module Debounce #(parameter integer COUNT_MAX = 200000)(

    input clk,
    input btn_raw,
    output reg btn_cln
    );
    
    reg [17:0] counter;
    
    always @(posedge clk) begin
    
        if (btn_raw != btn_cln) begin
            counter <= counter + 1;
            if(counter == COUNT_MAX) begin
                btn_cln <= btn_raw;
                counter <= 0;
            end
        end
        else counter <= 0;
    end    
    
endmodule
