`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/06/2026 03:38:10 PM
// Design Name: 
// Module Name: tb_frame_receiver
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

module tb_frame_receiver;

    // ========================================================
    // Clock
    // ========================================================

    reg aclk;

    initial begin
        aclk = 1'b0;
        forever #5 aclk = ~aclk;
    end


    // ========================================================
    // Reset
    // ========================================================

    reg aresetn;


    // ========================================================
    // Start
    // ========================================================

    reg start;


    // ========================================================
    // External input
    // ========================================================

    reg [7:0] data_in;
    reg       data_valid;
    wire      data_ready;


    // ========================================================
    // AXI4-Stream
    // ========================================================

    wire [31:0] m_axis_tdata;
    wire        m_axis_tvalid;

    reg         m_axis_tready;

    wire        m_axis_tlast;


    // ========================================================
    // DUT
    // ========================================================

    frame_receiver #(
        .FRAME_WIDTH  (320),
        .FRAME_HEIGHT (200),
        .FIFO_DEPTH   (1024)
    ) dut (

        .aclk           (aclk),
        .aresetn        (aresetn),

        .start          (start),

        .data_in        (data_in),
        .data_valid     (data_valid),
        .data_ready     (data_ready),

        .m_axis_tdata   (m_axis_tdata),
        .m_axis_tvalid  (m_axis_tvalid),
        .m_axis_tready  (m_axis_tready),
        .m_axis_tlast   (m_axis_tlast)
    );


    // ========================================================
    // Counters
    // ========================================================

    integer received_words;
    integer received_bytes;


    // ========================================================
    // AXI monitor
    // ========================================================

    always @(posedge aclk) begin

        if (aresetn &&
            m_axis_tvalid &&
            m_axis_tready) begin

            received_words = received_words + 1;

            if (m_axis_tlast) begin

                $display(
                    "TLAST received: word=%0d data=%h time=%0t",
                    received_words,
                    m_axis_tdata,
                    $time
                );
            end
        end
    end


    // ========================================================
    // Send one byte
    // ========================================================

    task send_byte;

        input [7:0] value;

        begin

            @(posedge aclk);

            while (!data_ready)
                @(posedge aclk);

            data_in    <= value;
            data_valid <= 1'b1;

            @(posedge aclk);

            while (!data_ready)
                @(posedge aclk);

            data_valid <= 1'b0;

            received_bytes = received_bytes + 1;

        end

    endtask


    // ========================================================
    // Main test
    // ========================================================

    integer i;

    initial begin

        // ----------------------------------------------------
        // Initial values
        // ----------------------------------------------------

        aresetn        = 1'b0;

        start          = 1'b0;

        data_in        = 8'h00;
        data_valid     = 1'b0;

        m_axis_tready  = 1'b1;

        received_words = 0;
        received_bytes = 0;


        // ----------------------------------------------------
        // Reset
        // ----------------------------------------------------

        repeat (5)
            @(posedge aclk);

        aresetn = 1'b1;


        // ----------------------------------------------------
        // Test 1:
        // data before START must be ignored
        // ----------------------------------------------------

        $display("TEST 1: data before START");

        data_in    = 8'hAA;
        data_valid = 1'b1;

        repeat (10)
            @(posedge aclk);

        data_valid = 1'b0;


        // ----------------------------------------------------
        // Start frame
        // ----------------------------------------------------

        $display("START FRAME");

        @(posedge aclk);

        start = 1'b1;

        @(posedge aclk);

        start = 1'b0;


        // ----------------------------------------------------
        // Send full frame
        //
        // Data pattern:
        //
        // byte 0 = 00
        // byte 1 = 01
        // byte 2 = 02
        // ...
        //
        // Expected first words:
        //
        // 03020100
        // 07060504
        // 0B0A0908
        // ...
        // ----------------------------------------------------

        for (i = 0; i < 64000; i = i + 1) begin

            send_byte(i[7:0]);

        end


        // ----------------------------------------------------
        // Wait for last AXI word
        // ----------------------------------------------------

        wait (m_axis_tlast &&
              m_axis_tvalid &&
              m_axis_tready);

        @(posedge aclk);


        // ----------------------------------------------------
        // Check number of words
        // ----------------------------------------------------

        if (received_words != 16000) begin

            $display(
                "ERROR: received_words = %0d, expected 16000",
                received_words
            );

        end else begin

            $display(
                "OK: received_words = %0d",
                received_words
            );

        end


        // ----------------------------------------------------
        // Finish
        // ----------------------------------------------------

        $display("TEST FINISHED");

        #100;

        $finish;

    end


    // ========================================================
    // VCD dump
    // ========================================================

    initial begin
        $dumpfile("tb_frame_receiver.vcd");
        $dumpvars(0, tb_frame_receiver);
    end

endmodule
