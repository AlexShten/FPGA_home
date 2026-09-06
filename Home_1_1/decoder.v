`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/03/2026 06:17:24 PM
// Design Name: 
// Module Name: decoder
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


module decoder #(parameter WIDTH = 3) (

    input wire [WIDTH-1:0] selection,
    output reg [2**WIDTH-1:0] out
    
);

    always @(*) begin
        out = 0;
        out[selection] = 1'b1;    
    end
    
endmodule
