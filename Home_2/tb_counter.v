`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/13/2026 10:13:15 PM
// Design Name: 
// Module Name: tb_counter
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


module tb_counter;

    reg       clk;
    reg       rst;
    reg       load;
    reg [3:0] data_in;
    reg       en;
    reg       up_down;


    wire [3:0] count;


    counter inst(
        .clk     (clk),
        .rst     (rst),
        .load    (load),
        .data_in (data_in),
        .en      (en),
        .up_down (up_down),
        .count   (count)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    

/*    initial begin

//point 3
        rst = 0;
        load = 0;
        data_in = 4'd0;
        en = 0;
        up_down = 0;

        rst = 1;
        @(posedge clk);
        #1;
        rst = 0;

        load = 1;
        data_in = 4'd10;

        @(posedge clk);
        #1;

        load = 0;
        //check result
        if (count === 4'd10)
            $display("PASS: LOAD, count = %d", count);
        else
            $display("FAIL: LOAD, expected 10, got %d", count);            
            
//point 4            
        en = 1;
        up_down = 1;

        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;

        //check result
        if (count === 4'd13)
            $display("PASS: COUNT UP, count = %d", count);
        else
            $display("FAIL: COUNT UP, expected 13, got %d", count);

        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;

        //check result
        if (count === 4'd0)
            $display("PASS: OVERFLOW 15 -> 0, count = %d", count);
        else
            $display("FAIL: OVERFLOW, expected 0, got %d", count);
            
//point 5
        en = 0;
        
        @(posedge clk); #1;
        @(posedge clk); #1;

        //check result
        if (count === 4'd0)
            $display("PASS: VALUE 0, count = %d", count);
        else
            $display("FAIL: VALUE, expected 0, got %d", count);

//point 6
        en = 1;
        up_down = 0;
        
        @(posedge clk); #1;
        
        //check result
        if (count === 4'd15)
            $display("PASS: BACK 0 -> 15, count = %d", count);
        else
            $display("FAIL: BACK, expected 15, got %d", count);

//point 7
        load = 1;
        data_in = 4'd5;
        en = 1;
        up_down = 1;
        
        @(posedge clk); #1;
        
        //check result
        if (count === 4'd5)
            $display("PASS: VALUE 5, count = %d", count);
        else
            $display("FAIL: VALUE, expected 5, got %d", count);


        $finish;
    end
    */
    
    task automatic check_count;
        input [3:0] value;
        input [8*15-1:0] name;

        begin
            if (count === value)
                $display("PASS: %s, count = %d", name, count);
            else
                $display("FAIL: %s, expected = %d, got = %d",
                         name, value, count);
        end
    endtask
    
    initial begin

        rst = 0;
        load = 0;
        data_in = 4'd0;
        en = 0;
        up_down = 0;
        
        @(posedge clk);
        #1;

//point 3
        rst = 1;
        @(posedge clk);
        #1;
        rst = 0;

        load = 1;
        data_in = 4'd10;

        @(posedge clk);
        #1;

        load = 0;

        check_count(4'd10, "LOAD");

//point 4
        en = 1;
        up_down = 1;

        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;

        check_count(4'd13, "COUNT UP");

        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;

        check_count(4'd0, "OVERFLOW 15->0");        
        
//point 5
        en = 0;
        
        @(posedge clk); #1;
        @(posedge clk); #1;
        
        check_count(4'd0, "VALUE 0");

//point 6
        en = 1;
        up_down = 0;
        
        @(posedge clk); #1;
        
        check_count(4'd15, "BACK 0 -> 15");

//point 7
        load = 1;
        data_in = 4'd5;
        en = 1;
        up_down = 1;
        
        @(posedge clk); #1;
        
        check_count(4'd5, "VALUE 5");
        
//point bonus
        en = 0;
        up_down = 0;
        load = 1;
        data_in = 4'd8;        
        
        @(posedge clk); #1;
        
        load = 0;
        en = 1;
        up_down = 0;
        
        @(posedge clk); #1;
        
        check_count(4'd7, "BONUS = 7");
        
        $finish;
    end
    
    
endmodule
