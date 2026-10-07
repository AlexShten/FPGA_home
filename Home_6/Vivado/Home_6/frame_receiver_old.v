`timescale 1ns / 1ps

module frame_receiver #(
    parameter FRAME_WIDTH  = 320,
    parameter FRAME_HEIGHT = 200,
    parameter FIFO_DEPTH   = 1024
)(
    input  wire        aclk,
    input  wire        aresetn,

    input  wire        start,

    input  wire [7:0]  data_in,
    input  wire        data_valid,
    output wire        data_ready,

    output reg  [31:0] m_axis_tdata,
    output reg         m_axis_tvalid,
    input  wire        m_axis_tready,
    output reg         m_axis_tlast
);

    // ========================================================
    // Frame parameters
    // ========================================================

    localparam integer FRAME_BYTES =
        FRAME_WIDTH * FRAME_HEIGHT;

    localparam integer FRAME_WORDS =
        FRAME_BYTES / 4;

    localparam integer PTR_WIDTH =
        $clog2(FIFO_DEPTH);

    localparam integer COUNT_WIDTH =
        $clog2(FIFO_DEPTH + 1);


    // ========================================================
    // FIFO
    // ========================================================

    reg [7:0] fifo_mem [0:FIFO_DEPTH-1];

    reg [PTR_WIDTH-1:0] fifo_wr_ptr;
    reg [PTR_WIDTH-1:0] fifo_rd_ptr;

    reg [COUNT_WIDTH-1:0] fifo_count;


    // ========================================================
    // Start edge detector
    // ========================================================

    reg start_d;


    // ========================================================
    // Frame state
    // ========================================================

    reg frame_active;

    reg [15:0] frame_byte_count;

    reg [13:0] words_sent;


    // ========================================================
    // Input handshake
    // ========================================================

    assign data_ready =
        frame_active &&
        (fifo_count < FIFO_DEPTH);

    wire fifo_write;

    assign fifo_write =
        frame_active &&
        data_valid &&
        data_ready;


    // ========================================================
    // AXI handshake
    // ========================================================

    wire axis_transfer;

    assign axis_transfer =
        m_axis_tvalid &&
        m_axis_tready;


    // ========================================================
    // Can load a new AXI word?
    //
    // We can load a word when:
    //
    // 1. AXI output register is empty
    //
    // OR
    //
    // 2. Current AXI word is being transferred.
    //
    // In both cases at least four bytes must be available.
    // ========================================================

    wire axis_load;

    assign axis_load =
        (fifo_count >= 4) &&
        (!m_axis_tvalid || m_axis_tready) &&
        (words_sent < FRAME_WORDS);


    // ========================================================
    // Sequential logic
    // ========================================================

    always @(posedge aclk or negedge aresetn) begin

        if (!aresetn) begin

            start_d          <= 1'b0;

            frame_active     <= 1'b0;
            frame_byte_count <= 16'd0;

            fifo_wr_ptr      <= 0;
            fifo_rd_ptr      <= 0;
            fifo_count       <= 0;

            words_sent       <= 0;

            m_axis_tdata     <= 32'd0;
            m_axis_tvalid    <= 1'b0;
            m_axis_tlast     <= 1'b0;

        end
        else begin

            // ------------------------------------------------
            // Save START state
            // ------------------------------------------------

            start_d <= start;


            // =================================================
            // START new frame
            // =================================================

            if (start && !start_d) begin

                $display(">>> START CONDITION ENTERED <<<");

                frame_active     <= 1'b1;
                frame_byte_count <= 16'd0;

                fifo_wr_ptr      <= 0;
                fifo_rd_ptr      <= 0;
                fifo_count       <= 0;

                words_sent       <= 0;

                m_axis_tdata     <= 32'd0;
                m_axis_tvalid    <= 1'b0;
                m_axis_tlast     <= 1'b0;

            end
            else begin

                // =================================================
                // FIFO WRITE
                // =================================================

                if (fifo_write) begin

                    if (frame_byte_count < 8) begin
                        $display(
                            "FIFO WRITE: time=%0t ptr=%0d data=%02h frame_byte_count=%0d",
                            $time,
                            fifo_wr_ptr,
                            data_in,
                            frame_byte_count
                        );
                    end

                    fifo_mem[fifo_wr_ptr] <= data_in;


                    // --------------------------------------------
                    // Write pointer
                    // --------------------------------------------

                    if (fifo_wr_ptr == FIFO_DEPTH - 1)
                        fifo_wr_ptr <= 0;
                    else
                        fifo_wr_ptr <= fifo_wr_ptr + 1'b1;


                    // --------------------------------------------
                    // Frame byte counter
                    // --------------------------------------------

                    frame_byte_count <= frame_byte_count + 1'b1;


                    // --------------------------------------------
                    // Last byte of frame
                    // --------------------------------------------

                    if (frame_byte_count == FRAME_BYTES - 1) begin

                        frame_active <= 1'b0;

                    end

                end


                // =================================================
                // AXI WORD LOAD
                // =================================================

                if (axis_load) begin

                    if (words_sent < 4) begin
                        $display(
                            "AXIS LOAD DEBUG: time=%0t rd_ptr=%0d count=%0d bytes=%02h %02h %02h %02h",
                            $time,
                            fifo_rd_ptr,
                            fifo_count,
                            fifo_mem[fifo_rd_ptr],
                            fifo_mem[fifo_rd_ptr + 1],
                            fifo_mem[fifo_rd_ptr + 2],
                            fifo_mem[fifo_rd_ptr + 3]
                        );
                    end

                    // ------------------------------------------------
                    // Read four bytes from FIFO
                    //
                    // Byte order:
                    //
                    // byte 0 -> bits  7:0
                    // byte 1 -> bits 15:8
                    // byte 2 -> bits 23:16
                    // byte 3 -> bits 31:24
                    //
                    // Example:
                    //
                    // 00 01 02 03
                    //
                    // becomes:
                    //
                    // 32'h03020100
                    // ------------------------------------------------

                    if (fifo_rd_ptr <= FIFO_DEPTH - 4) begin

                        m_axis_tdata <= {
                            fifo_mem[fifo_rd_ptr + 3],
                            fifo_mem[fifo_rd_ptr + 2],
                            fifo_mem[fifo_rd_ptr + 1],
                            fifo_mem[fifo_rd_ptr]
                        };

                    end
                    else begin

                        case (fifo_rd_ptr)

                            FIFO_DEPTH - 3:
                                m_axis_tdata <= {
                                    fifo_mem[0],
                                    fifo_mem[FIFO_DEPTH-1],
                                    fifo_mem[FIFO_DEPTH-2],
                                    fifo_mem[FIFO_DEPTH-3]
                                };

                            FIFO_DEPTH - 2:
                                m_axis_tdata <= {
                                    fifo_mem[1],
                                    fifo_mem[0],
                                    fifo_mem[FIFO_DEPTH-1],
                                    fifo_mem[FIFO_DEPTH-2]
                                };

                            FIFO_DEPTH - 1:
                                m_axis_tdata <= {
                                    fifo_mem[2],
                                    fifo_mem[1],
                                    fifo_mem[0],
                                    fifo_mem[FIFO_DEPTH-1]
                                };

                            default:
                                m_axis_tdata <= 32'd0;

                        endcase

                    end


                    // ------------------------------------------------
                    // AXI VALID
                    // ------------------------------------------------

                    m_axis_tvalid <= 1'b1;


                    // ------------------------------------------------
                    // TLAST
                    // ------------------------------------------------

                    if (words_sent == FRAME_WORDS - 1)
                        m_axis_tlast <= 1'b1;
                    else
                        m_axis_tlast <= 1'b0;


                    // ------------------------------------------------
                    // Advance FIFO read pointer by 4
                    // ------------------------------------------------

                    if (fifo_rd_ptr >= FIFO_DEPTH - 4)
                        fifo_rd_ptr <=
                            fifo_rd_ptr - (FIFO_DEPTH - 4);
                    else
                        fifo_rd_ptr <=
                            fifo_rd_ptr + 4;

                end


                // =================================================
                // AXI TRANSFER
                // =================================================

                if (axis_transfer) begin

                    words_sent <= words_sent + 1'b1;

                end


                // =================================================
                // AXI output register becomes empty
                //
                // Important:
                //
                // If axis_load is also true, a new word is loaded
                // in the same clock, so VALID must remain asserted.
                // =================================================

                if (axis_transfer && !axis_load) begin

                    m_axis_tvalid <= 1'b0;
                    m_axis_tlast  <= 1'b0;

                end


                // =================================================
                // FIFO COUNT
                // =================================================

                case ({fifo_write, axis_load})

                    2'b10: begin

                        fifo_count <= fifo_count + 1'b1;

                    end


                    2'b01: begin

                        fifo_count <= fifo_count - 4;

                    end


                    2'b11: begin

                        fifo_count <= fifo_count - 3;

                    end


                    default: begin

                        fifo_count <= fifo_count;

                    end

                endcase

            end

        end

    end

endmodule