
class apb_error_test #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
) extends apb_base_test #(ADDR_WIDTH, DATA_WIDTH);

    localparam int WORD_BYTES = DATA_WIDTH / 8;
    localparam int MEM_WORDS  = 64;

    function new(
        virtual apb_if #(ADDR_WIDTH, DATA_WIDTH) vif
    );
        super.new(vif);
    endfunction

    virtual task run_test();

        bit [63:0] rdata;
        bit error;
        bit [31:0] test_addr;

        prepare_test();

        $display("\n================================================");
        $display("              APB ERROR TEST");
        $display("================================================");
        $display("Memory depth : %0d words", MEM_WORDS);
        $display("Word size    : %0d bytes", WORD_BYTES);
        $display("Valid range  : 0x000 - 0x%0h",
                 (MEM_WORDS - 1) * WORD_BYTES);

        // TEST 1: Valid address
        test_addr = 0;

        $display("\nTEST 1: Read from a VALID address");
        $display("Attempting READ at address: 0x%0h", test_addr);

        do_transfer(test_addr, 0, 0, rdata, error);

        $display("Returned PSLVERR: %0b", error);
        $display("Returned PRDATA : 0x%0h",
                 rdata[DATA_WIDTH-1:0]);

        if (error === 1'b0) begin
            $display("[PASS] Valid address did not produce an error.");
        end
        else begin
            local_failures++;
            $error("[FAIL] Valid address unexpectedly produced an error.");
        end

        // TEST 2: Invalid address beyond memory range
        test_addr = MEM_WORDS * WORD_BYTES;

        $display("\nTEST 2: Read from an OUT-OF-RANGE address");
        $display("Attempting READ at address: 0x%0h", test_addr);
        $display("Expected PSLVERR: 1");
        $display("Expected PRDATA : 0x0");

        do_transfer(test_addr, 0, 0, rdata, error);

        $display("Returned PSLVERR: %0b", error);
        $display("Returned PRDATA : 0x%0h",
                 rdata[DATA_WIDTH-1:0]);

        if (error === 1'b1) begin
            $display("[PASS] Out-of-range address correctly returned PSLVERR.");
        end
        else begin
            local_failures++;
            $error("[FAIL] Out-of-range address did not return PSLVERR.");
        end

        if (rdata[DATA_WIDTH-1:0] === '0) begin
            $display("[PASS] Invalid read returned zero.");
        end
        else begin
            local_failures++;
            $error("[FAIL] Invalid read returned non-zero data.");
        end

        // TEST 3: Misaligned address
        test_addr = 1;

        $display("\nTEST 3: Read from a MISALIGNED address");
        $display("Attempting READ at address: 0x%0h", test_addr);
        $display("Expected PSLVERR: 1");

        do_transfer(test_addr, 0, 0, rdata, error);

        $display("Returned PSLVERR: %0b", error);
        $display("Returned PRDATA : 0x%0h",
                 rdata[DATA_WIDTH-1:0]);

        if (error === 1'b1) begin
            $display("[PASS] Misaligned address correctly returned PSLVERR.");
        end
        else begin
            local_failures++;
            $error("[FAIL] Misaligned address did not return PSLVERR.");
        end

        // SUMMARY
        $display("\n================================================");
        $display("             APB ERROR TEST SUMMARY");
        $display("================================================");
        $display("Transfers attempted: 3");
        $display("Failures recorded  : %0d", local_failures);

        if (local_failures == 0)
            $display("OVERALL RESULT: PASS");
        else
            $display("OVERALL RESULT: FAIL");

        $display("================================================\n");

        finish_test(3);

    endtask

endclass

