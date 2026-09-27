`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/21/2026 04:29:07 PM
// Design Name: 
// Module Name: Lock_ctr
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


module Lock_ctr(
    input clk,
    input rst,
    input [3:0] digit_in,
    output reg unlocked_led

    );
    
    reg [1:0] state;    
    reg [1:0] next_state;
    
    localparam LOCKED = 2'b00;
    localparam WAIT_D2 = 2'b01;
    localparam WAIT_D3 = 2'b10;
    localparam UNLOCKED = 2'b11;
    
    //pass 139
    localparam [3:0] DIGIT_1 = 4'd1;
    localparam [3:0] DIGIT_2 = 4'd3;
    localparam [3:0] DIGIT_3 = 4'd9;
    
    
    always @(posedge clk or posedge rst) begin
        if(rst)
            state <= LOCKED;
        else
            state <= next_state;
    end
    
    always @(*) begin
        next_state = state;
        
        case (state)
        
            LOCKED: begin
                if(digit_in == DIGIT_1)
                    next_state = WAIT_D2;
                else
                    next_state = LOCKED;                        
            end 
             
            WAIT_D2: begin
                if(digit_in == DIGIT_2)
                    next_state = WAIT_D3;
                else
                    next_state = LOCKED;                        
            end  
                 
            WAIT_D3: begin
                if(digit_in == DIGIT_3)
                    next_state = UNLOCKED;
                else
                    next_state = LOCKED;                        
            end       
            
            UNLOCKED: begin
                next_state = UNLOCKED;
            end
            
            default: begin
                next_state = LOCKED;
            end
                               
        endcase  
    end
    
    always @(*) begin
        if(state == UNLOCKED)
            unlocked_led = 1'b1;
        else
            unlocked_led = 1'b0;
    end
    
endmodule
