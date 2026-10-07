`timescale 1ns / 1ps

module tb_axi4_full_ram;

    localparam DATA_WIDTH = 32;
    localparam ADDR_WIDTH = 16;
    localparam MEM_DEPTH  = 16384;

    localparam FRAME_WORDS = 16000;

    reg                         aclk;
    reg                         aresetn;

    reg  [ADDR_WIDTH-1:0]      awaddr;
    reg  [7:0]                 awlen;
    reg  [2:0]                 awsize;
    reg  [1:0]                 awburst;
    reg                         awvalid;
    wire                        awready;

    reg  [DATA_WIDTH-1:0]      wdata;
    reg  [DATA_WIDTH/8-1:0]    wstrb;
    reg                         wlast;
    reg                         wvalid;
    wire                        wready;

    wire [1:0]                 bresp;
    wire                        bvalid;
    reg                         bready;

    reg  [ADDR_WIDTH-1:0]      araddr;
    reg  [7:0]                 arlen;
    reg  [2:0]                 arsize;
    reg  [1:0]                 arburst;
    reg                         arvalid;
    wire                        arready;

    wire [DATA_WIDTH-1:0]      rdata;
    wire                        rlast;
    wire [1:0]                 rresp;
    wire                        rvalid;
    reg                         rready;

    integer errors;
    integer i;
    integer base_word;
    integer burst_words;
    integer remaining_words;
    integer received_words;
    reg [31:0] expected;

    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------

    axi4_full_ram #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .MEM_DEPTH(MEM_DEPTH)
    ) dut (
        .s_axi_aclk    (aclk),
        .s_axi_aresetn (aresetn),

        .s_axi_awaddr  (awaddr),
        .s_axi_awlen   (awlen),
        .s_axi_awsize  (awsize),
        .s_axi_awburst (awburst),
        .s_axi_awvalid (awvalid),
        .s_axi_awready (awready),

        .s_axi_wdata   (wdata),
        .s_axi_wstrb   (wstrb),
        .s_axi_wlast   (wlast),
        .s_axi_wvalid  (wvalid),
        .s_axi_wready  (wready),

        .s_axi_bresp   (bresp),
        .s_axi_bvalid  (bvalid),
        .s_axi_bready  (bready),

        .s_axi_araddr  (araddr),
        .s_axi_arlen   (arlen),
        .s_axi_arsize  (arsize),
        .s_axi_arburst (arburst),
        .s_axi_arvalid (arvalid),
        .s_axi_arready (arready),

        .s_axi_rdata   (rdata),
        .s_axi_rlast   (rlast),
        .s_axi_rresp  (rresp),
        .s_axi_rvalid (rvalid),
        .s_axi_rready (rready)
    );

    // ------------------------------------------------------------
    // Clock
    // ------------------------------------------------------------

    initial begin
        aclk = 1'b0;
        forever #5 aclk = ~aclk;
    end

    // ------------------------------------------------------------
    // AXI write burst
    //
    // start_word = first 32-bit word index
    // words      = number of beats
    // ------------------------------------------------------------

    task axi_write_burst;
        input integer start_word;
        input integer words;

        integer k;
        begin
            // AW channel
            @(negedge aclk);

            awaddr  = start_word * 4;
            awlen   = words - 1;
            awsize  = 3'd2;       // 4 bytes
            awburst = 2'b01;      // INCR
            awvalid = 1'b1;

            while (!awready)
                @(negedge aclk);

            @(negedge aclk);
            awvalid = 1'b0;

            // W channel
            for (k = 0; k < words; k = k + 1) begin

                wdata  = (start_word + k) ^ 32'hA5A50000;
                wstrb  = 4'b1111;
                wlast  = (k == words - 1);
                wvalid = 1'b1;

                while (!wready)
                    @(negedge aclk);

                @(negedge aclk);
                wvalid = 1'b0;
            end

            // B channel
            bready = 1'b1;

            while (!bvalid)
                @(negedge aclk);

            if (bresp !== 2'b00) begin
                $display(
                    "ERROR: BRESP = %b for write burst start=%0d words=%0d",
                    bresp, start_word, words
                );
                errors = errors + 1;
            end

            @(negedge aclk);
            bready = 1'b0;
        end
    endtask

    // ------------------------------------------------------------
    // AXI read burst
    //
    // Checks all returned data and RLAST.
    // ------------------------------------------------------------

    task axi_read_burst;
        input integer start_word;
        input integer words;

        integer k;
        begin
            // AR channel
            @(negedge aclk);

            araddr  = start_word * 4;
            arlen   = words - 1;
            arsize  = 3'd2;       // 4 bytes
            arburst = 2'b01;      // INCR
            arvalid = 1'b1;

            while (!arready)
                @(negedge aclk);

            @(negedge aclk);
            arvalid = 1'b0;

            // R channel
            rready = 1'b1;

            for (k = 0; k < words; k = k + 1) begin

                while (!rvalid)
                    @(negedge aclk);

                expected = (start_word + k) ^ 32'hA5A50000;

                if (rdata !== expected) begin
                    $display(
                        "ERROR: READ word=%0d got=%08h expected=%08h",
                        start_word + k, rdata, expected
                    );
                    errors = errors + 1;
                end

                if (rlast !== (k == words - 1)) begin
                    $display(
                        "ERROR: RLAST word=%0d got=%b expected=%b",
                        start_word + k, rlast, (k == words - 1)
                    );
                    errors = errors + 1;
                end

                if (rresp !== 2'b00) begin
                    $display(
                        "ERROR: RRESP word=%0d = %b",
                        start_word + k, rresp
                    );
                    errors = errors + 1;
                end

                @(negedge aclk);
            end

            rready = 1'b0;
        end
    endtask

    // ------------------------------------------------------------
    // Test
    // ------------------------------------------------------------

    initial begin

        $dumpfile("tb_axi4_full_ram.vcd");
        $dumpvars(0, tb_axi4_full_ram);

        errors = 0;

        awaddr  = 0;
        awlen   = 0;
        awsize  = 0;
        awburst = 0;
        awvalid = 0;

        wdata   = 0;
        wstrb   = 0;
        wlast   = 0;
        wvalid  = 0;

        bready  = 0;

        araddr  = 0;
        arlen   = 0;
        arsize  = 0;
        arburst = 0;
        arvalid = 0;

        rready  = 0;

        aresetn = 1'b0;

        repeat (5)
            @(negedge aclk);

        aresetn = 1'b1;

        // ========================================================
        // TEST 1: small write/read bursts
        // ========================================================

        $display("");
        $display("========================================");
        $display("TEST 1: small AXI bursts");
        $display("========================================");

        axi_write_burst(0, 4);
        axi_write_burst(4, 8);
        axi_write_burst(12, 16);

        axi_read_burst(0, 4);
        axi_read_burst(4, 8);
        axi_read_burst(12, 16);

        // ========================================================
        // TEST 2: full 64000-byte frame
        //
        // 16000 words, split into AXI bursts of <= 256 beats.
        // ========================================================

        $display("");
        $display("========================================");
        $display("TEST 2: full frame 64000 bytes");
        $display("========================================");

        remaining_words = FRAME_WORDS;
        base_word       = 0;

        while (remaining_words > 0) begin

            if (remaining_words > 256)
                burst_words = 256;
            else
                burst_words = remaining_words;

            axi_write_burst(base_word, burst_words);

            base_word       = base_word + burst_words;
            remaining_words = remaining_words - burst_words;
        end

        $display("FULL FRAME WRITE COMPLETE");

        // Read the complete frame back.
        remaining_words = FRAME_WORDS;
        base_word       = 0;
        received_words  = 0;

        while (remaining_words > 0) begin

            if (remaining_words > 256)
                burst_words = 256;
            else
                burst_words = remaining_words;

            axi_read_burst(base_word, burst_words);

            base_word       = base_word + burst_words;
            remaining_words = remaining_words - burst_words;
            received_words  = received_words + burst_words;
        end

        $display("FULL FRAME READ COMPLETE");
        $display("received_words = %0d", received_words);

        // ========================================================
        // Result
        // ========================================================

        $display("");
        $display("========================================");

        if (errors == 0) begin
            $display("TEST PASSED");
            $display("16000 words / 64000 bytes verified");
        end
        else begin
            $display("TEST FAILED: %0d errors", errors);
        end

        $display("========================================");

        #100;
        $finish;
    end

endmodule
