`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/13/2026 09:53:36 PM
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

    input wire clk,
    input wire rst,
    input wire load,
    input wire [3:0] data_in,
    input wire en,
    input wire up_down,
    output reg [3:0] count    

    );
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= 4'b0000;
        end
        else if (load) begin
            count <= data_in;
        end
        else if (en) begin
            if (up_down)
                count <= count + 1'b1;
            else
                count <= count - 1'b1;
        end
    end
    
endmodule
