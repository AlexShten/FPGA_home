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
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module tb_frame_receiver;

    // ========================================================
    // Parameters
    // ========================================================

    localparam FRAME_WIDTH  = 320;
    localparam FRAME_HEIGHT = 200;

    localparam FRAME_BYTES  = FRAME_WIDTH * FRAME_HEIGHT;
    localparam FRAME_WORDS  = FRAME_BYTES / 4;


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
        .FRAME_WIDTH  (FRAME_WIDTH),
        .FRAME_HEIGHT (FRAME_HEIGHT),
        .FIFO_DEPTH   (1024)
    ) dut (

        .aclk           (aclk),
        .aresetn        (aresetn),

        .start          (start),

        .data_in        (data_in),
        .data_valid     (data_valid),
        .data_ready      (data_ready),

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
    integer error_count;


    // ========================================================
    // TLAST flag
    // ========================================================

    reg tlast_received;


    // ========================================================
    // AXI stall monitor
    //
    // When:
    //
    //     TVALID = 1
    //     TREADY = 0
    //
    // TDATA and TLAST must remain unchanged.
    // ========================================================

    reg        stall_active;
    reg [31:0] stall_data;
    reg        stall_last;


    // ========================================================
    // AXI monitor
    // ========================================================

    always @(posedge aclk) begin

        if (aresetn &&
            m_axis_tvalid &&
            m_axis_tready) begin


            // ------------------------------------------------
            // Check word 0
            // ------------------------------------------------

            if (received_words == 0) begin

                if (m_axis_tdata !== 32'h03020100) begin

                    $display(
                        "ERROR: word 0: got %08h expected 03020100",
                        m_axis_tdata
                    );

                    error_count = error_count + 1;

                end
                else begin

                    $display(
                        "OK: word 0 = %08h",
                        m_axis_tdata
                    );

                end

            end


            // ------------------------------------------------
            // Check word 1
            // ------------------------------------------------

            if (received_words == 1) begin

                if (m_axis_tdata !== 32'h07060504) begin

                    $display(
                        "ERROR: word 1: got %08h expected 07060504",
                        m_axis_tdata
                    );

                    error_count = error_count + 1;

                end
                else begin

                    $display(
                        "OK: word 1 = %08h",
                        m_axis_tdata
                    );

                end

            end


            // ------------------------------------------------
            // Check word 2
            // ------------------------------------------------

            if (received_words == 2) begin

                if (m_axis_tdata !== 32'h0B0A0908) begin

                    $display(
                        "ERROR: word 2: got %08h expected 0B0A0908",
                        m_axis_tdata
                    );

                    error_count = error_count + 1;

                end
                else begin

                    $display(
                        "OK: word 2 = %08h",
                        m_axis_tdata
                    );

                end

            end


            // ------------------------------------------------
            // Check final word
            // ------------------------------------------------

            if (received_words == FRAME_WORDS - 1) begin

                if (m_axis_tdata !== 32'hFFFEFDFC) begin

                    $display(
                        "ERROR: final word: got %08h expected FFFEFDFC",
                        m_axis_tdata
                    );

                    error_count = error_count + 1;

                end
                else begin

                    $display(
                        "OK: final word = %08h",
                        m_axis_tdata
                    );

                end

            end


            // ------------------------------------------------
            // TLAST
            // ------------------------------------------------

            if (m_axis_tlast) begin

                $display(
                    "TLAST received: word=%0d data=%08h time=%0t",
                    received_words + 1,
                    m_axis_tdata,
                    $time
                );

                tlast_received = 1'b1;


                // TLAST must be on the last word

                if (received_words + 1 != FRAME_WORDS) begin

                    $display(
                        "ERROR: TLAST received on word %0d, expected %0d",
                        received_words + 1,
                        FRAME_WORDS
                    );

                    error_count = error_count + 1;

                end

            end
            else begin

                // Final word must contain TLAST

                if (received_words == FRAME_WORDS - 1) begin

                    $display(
                        "ERROR: final word does not have TLAST"
                    );

                    error_count = error_count + 1;

                end

            end


            // ------------------------------------------------
            // Count transferred word
            // ------------------------------------------------

            received_words = received_words + 1;

        end

    end


    // ========================================================
    // AXI stall monitor
    // ========================================================

    always @(posedge aclk) begin

        if (aresetn) begin

            if (m_axis_tvalid && !m_axis_tready) begin

                if (!stall_active) begin

                    stall_active = 1'b1;

                    stall_data = m_axis_tdata;
                    stall_last = m_axis_tlast;

                end
                else begin

                    if (m_axis_tdata !== stall_data) begin

                        $display(
                            "ERROR: TDATA changed while TREADY=0: old=%08h new=%08h",
                            stall_data,
                            m_axis_tdata
                        );

                        error_count = error_count + 1;

                    end


                    if (m_axis_tlast !== stall_last) begin

                        $display(
                            "ERROR: TLAST changed while TREADY=0"
                        );

                        error_count = error_count + 1;

                    end

                end

            end
            else begin

                stall_active = 1'b0;

            end

        end

    end


    // ========================================================
    // Send one byte
    // ========================================================

    task send_byte;
        input [7:0] value;
        begin
            // Подготовить данные на отрицательном фронте
            @(negedge aclk);

            data_in    = value;
            data_valid = 1'b1;

            // Ждем готовности приемника
            while (!data_ready)
                @(negedge aclk);

            // Теперь следующий posedge — гарантированный прием
            @(posedge aclk);

            // После приема убираем valid
            @(negedge aclk);

            data_valid = 1'b0;

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

        error_count    = 0;

        tlast_received = 1'b0;

        stall_active = 1'b0;
        stall_data   = 32'h00000000;
        stall_last   = 1'b0;


        // ----------------------------------------------------
        // Reset
        // ----------------------------------------------------

        repeat (5)
            @(posedge aclk);

        aresetn = 1'b1;


        // ----------------------------------------------------
        // Test 1:
        //
        // Data before START must be ignored.
        // ----------------------------------------------------

        $display("");
        $display("========================================");
        $display("TEST 1: data before START");
        $display("========================================");

        data_in    = 8'hAA;
        data_valid = 1'b1;

        repeat (10)
            @(posedge aclk);

        data_valid = 1'b0;


        // ----------------------------------------------------
        // Start frame
        // ----------------------------------------------------

        $display("");
        $display("========================================");
        $display("START FRAME");
        $display("========================================");

        start = 1'b1;

        @(posedge aclk);
        @(posedge aclk);

        start = 1'b0;

        @(posedge aclk);


        // ----------------------------------------------------
        // Check receiver after START
        // ----------------------------------------------------

        $display(
            "AFTER START: data_ready=%b data_valid=%b",
            data_ready,
            data_valid
        );


        // ----------------------------------------------------
        // Send complete frame
        //
        // 64000 bytes:
        //
        // 00 01 02 03 04 05 ...
        //
        // Expected words:
        //
        // 03020100
        // 07060504
        // 0B0A0908
        // ...
        // FFFEFDFC
        // ----------------------------------------------------

        $display("");
        $display("========================================");
        $display("SENDING FRAME");
        $display("========================================");

        for (i = 0; i < FRAME_BYTES; i = i + 1) begin

            send_byte(i[7:0]);

        end


        // ----------------------------------------------------
        // Input complete
        // ----------------------------------------------------

        $display("");
        $display("========================================");
        $display("ALL INPUT BYTES SENT");
        $display("received_bytes = %0d",
                 received_bytes);
        $display("========================================");


        // ----------------------------------------------------
        // Check byte count
        // ----------------------------------------------------

        if (received_bytes != FRAME_BYTES) begin

            $display(
                "ERROR: received_bytes = %0d, expected %0d",
                received_bytes,
                FRAME_BYTES
            );

            error_count = error_count + 1;

        end
        else begin

            $display(
                "OK: received_bytes = %0d",
                received_bytes
            );

        end


        // ----------------------------------------------------
        // Wait for TLAST handshake
        // ----------------------------------------------------

        $display("");
        $display("WAITING FOR TLAST...");

        wait (tlast_received);


        // Allow monitor to finish updating counter

        @(posedge aclk);


        // ----------------------------------------------------
        // Check number of words
        // ----------------------------------------------------

        if (received_words != FRAME_WORDS) begin

            $display(
                "ERROR: received_words = %0d, expected %0d",
                received_words,
                FRAME_WORDS
            );

            error_count = error_count + 1;

        end
        else begin

            $display(
                "OK: received_words = %0d",
                received_words
            );

        end


        // ----------------------------------------------------
        // Check TLAST
        // ----------------------------------------------------

        if (!tlast_received) begin

            $display(
                "ERROR: TLAST was not received"
            );

            error_count = error_count + 1;

        end
        else begin

            $display(
                "OK: TLAST received"
            );

        end


        // ----------------------------------------------------
        // Final result
        // ----------------------------------------------------

        $display("");
        $display("========================================");

        if (error_count == 0) begin

            $display("TEST PASSED");

        end
        else begin

            $display(
                "TEST FAILED: %0d errors",
                error_count
            );

        end

        $display("========================================");


        // ----------------------------------------------------
        // Finish
        // ----------------------------------------------------

        #100;

        $finish;

    end


    // ========================================================
    // Backpressure generator
    //
    // Generate 20 AXI stalls during frame transmission.
    //
    // After the 20th stall TREADY remains HIGH.
    // ========================================================

    integer bp_count;

    initial begin

        // Wait until some words have been transmitted

        wait (received_words >= 20);


        // ----------------------------------------------------
        // Generate 20 backpressure events
        // ----------------------------------------------------

        for (bp_count = 0;
             bp_count < 20;
             bp_count = bp_count + 1) begin


            // ------------------------------------------------
            // Normal operation
            // ------------------------------------------------

            m_axis_tready = 1'b1;

            repeat (30)
                @(posedge aclk);


            // ------------------------------------------------
            // AXI stall
            // ------------------------------------------------

            $display(
                "AXI BACKPRESSURE #%0d: TREADY=0 time=%0t",
                bp_count + 1,
                $time
            );

            m_axis_tready = 1'b0;

            repeat (10)
                @(posedge aclk);


            // ------------------------------------------------
            // Resume
            // ------------------------------------------------

            $display(
                "AXI BACKPRESSURE #%0d RELEASE: TREADY=1 time=%0t",
                bp_count + 1,
                $time
            );

            m_axis_tready = 1'b1;

        end


        // ----------------------------------------------------
        // Backpressure test complete
        // ----------------------------------------------------

        $display("");
        $display("========================================");
        $display("BACKPRESSURE TEST COMPLETE");
        $display("TREADY permanently HIGH");
        $display("========================================");

        m_axis_tready = 1'b1;

    end


    // ========================================================
    // VCD dump
    // ========================================================

    initial begin

        $dumpfile("tb_frame_receiver.vcd");
        $dumpvars(0, tb_frame_receiver);

    end

endmodule