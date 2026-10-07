`timescale 1ns / 1ps

module tb_design_1;

    localparam integer FRAME_SIZE = 64000;
    localparam integer CLK_PERIOD = 10;       // 100 MHz

    reg         button_rtl;

    reg  [7:0]  data_in_0;
    wire        data_ready_0;
    reg         data_valid_0;

    reg         diff_clock_rtl_0_clk_p;
    reg         diff_clock_rtl_0_clk_n;

    reg         reset_rtl_0;


    design_1_wrapper dut (
        .button_rtl             (button_rtl),
        .data_in_0              (data_in_0),
        .data_ready_0           (data_ready_0),
        .data_valid_0           (data_valid_0),
        .diff_clock_rtl_0_clk_n (diff_clock_rtl_0_clk_n),
        .diff_clock_rtl_0_clk_p (diff_clock_rtl_0_clk_p),
        .reset_rtl_0            (reset_rtl_0)
    );


    initial begin

        diff_clock_rtl_0_clk_p = 1'b0;
        diff_clock_rtl_0_clk_n = 1'b1;

        forever begin

            #(CLK_PERIOD / 2);

            diff_clock_rtl_0_clk_p = ~diff_clock_rtl_0_clk_p;
            diff_clock_rtl_0_clk_n = ~diff_clock_rtl_0_clk_n;

        end

    end


    // ============================================================
    // Initial conditions / reset
    // ============================================================

    initial begin

        button_rtl = 1'b0;

        data_in_0    = 8'h00;
        data_valid_0 = 1'b0;

        reset_rtl_0 = 1'b0;

        // Hold reset for 100 ns
        #100;

        reset_rtl_0 = 1'b1;

        $display("");
        $display("==============================================");
        $display("RESET RELEASED");
        $display("==============================================");
        $display("");

    end


    // ============================================================
    // Send one byte
    // ============================================================

    task send_byte;

        input [7:0] value;

        begin

            @(negedge diff_clock_rtl_0_clk_p);

            data_in_0    = value;
            data_valid_0 = 1'b1;

            while (!data_ready_0)
                @(negedge diff_clock_rtl_0_clk_p);

            @(posedge diff_clock_rtl_0_clk_p);

            @(negedge diff_clock_rtl_0_clk_p);

            data_valid_0 = 1'b0;

        end

    endtask


    // ============================================================
    // Send complete frame
    // ============================================================

    integer i;

    task send_frame;

        begin

            $display("");
            $display("==============================================");
            $display("START SENDING FRAME");
            $display("FRAME SIZE = %0d bytes", FRAME_SIZE);
            $display("==============================================");
            $display("");

            for (i = 0; i < FRAME_SIZE; i = i + 1) begin

                send_byte(i[7:0]);

                if ((i % 10000) == 0)
                    $display("Sent %0d / %0d bytes",
                             i,
                             FRAME_SIZE);

            end

            $display("");
            $display("FRAME SENT");
            $display("");

        end

    endtask


    initial begin

        // --------------------------------------------------------
        // Wait for reset release
        // --------------------------------------------------------

        wait (reset_rtl_0 == 1'b0);

        #100000;

        // --------------------------------------------------------
        // Press button
        // --------------------------------------------------------

        $display("");
        $display("==============================================");
        $display("PRESS BUTTON");
        $display("==============================================");
        $display("");

        button_rtl = 1'b1;

        // --------------------------------------------------------
        // Keep button pressed for 5 ms
        // --------------------------------------------------------

        #100000;

        // --------------------------------------------------------
        // Release button
        // --------------------------------------------------------

        button_rtl = 1'b0;

        $display("");
        $display("BUTTON = 0");
        $display("BUTTON RELEASED");
        $display("");

        // --------------------------------------------------------
        // Give MicroBlaze a little time after button release
        // --------------------------------------------------------

        #200000;

        // --------------------------------------------------------
        // Check receiver state
        // --------------------------------------------------------

        $display("");
        $display("==============================================");
        $display("FRAME RECEIVER STATUS");
        $display("==============================================");

        $display("data_ready_0 = %b", data_ready_0);
        $display("data_valid_0 = %b", data_valid_0);
        $display("data_in_0    = %02X", data_in_0);

        // --------------------------------------------------------
        // Receiver must be ready
        // --------------------------------------------------------

        if (!data_ready_0) begin

            $display("");
            $display("ERROR:");
            $display("frame_receiver did not become ready.");
            $display("MicroBlaze may not have generated START.");
            $display("");

            $finish;

        end

        // --------------------------------------------------------
        // Send frame
        // --------------------------------------------------------

        send_frame;

        // --------------------------------------------------------
        // Give DMA time to finish
        // --------------------------------------------------------

        $display("");
        $display("==============================================");
        $display("FRAME TRANSMISSION FINISHED");
        $display("Waiting for DMA completion...");
        $display("==============================================");
        $display("");

        #100000;

        // --------------------------------------------------------
        // Finish
        // --------------------------------------------------------

        $display("");
        $display("==============================================");
        $display("SIMULATION FINISHED");
        $display("==============================================");
        $display("");

        $finish;

    end

endmodule