
class apb_read_test #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
) extends apb_base_test #(ADDR_WIDTH, DATA_WIDTH);

function new(
    virtual apb_if #(ADDR_WIDTH, DATA_WIDTH) vif,
    apb_coverage #(ADDR_WIDTH, DATA_WIDTH, 64) shared_cov = null
);
    super.new(vif, shared_cov);
endfunction
    localparam int BYTES_PER_WORD = DATA_WIDTH / 8;
    localparam int NUM_ORIGINAL = 4;
    localparam int NUM_NEW = 4;
    localparam int TOTAL_ADDRS = NUM_ORIGINAL + NUM_NEW;

    int unsigned original_addr [0:NUM_ORIGINAL-1];
    int unsigned new_addr [0:NUM_NEW-1];

    bit [DATA_WIDTH-1:0] expected_data [0:TOTAL_ADDRS-1];
    bit [DATA_WIDTH-1:0] actual_data;

    bit [63:0] rdata;
    bit error;

    int unsigned i;
    int unsigned transfer_count;
    int unsigned pass_count;
    int unsigned fail_count;

    task run_test();

        $display("\n================================================");
        $display(" APB READ RETENTION AND NEW-WRITE TEST");
        $display("================================================");

        transfer_count = 0;
        pass_count = 0;
        fail_count = 0;

        // Select original addresses (word indices).
        original_addr[0] = 0;
        original_addr[1] = 3;
        original_addr[2] = 7;
        original_addr[3] = 12;

        // Select different addresses for new writes.
        new_addr[0] = 1;
        new_addr[1] = 4;
        new_addr[2] = 8;
        new_addr[3] = 15;

        // ------------------------------------------------
        // PHASE 1: Initialize the original addresses.
        // ------------------------------------------------
        $display("\nPHASE 1: Initialize original addresses");

        for (i = 0; i < NUM_ORIGINAL; i++) begin

            expected_data[i] =
                DATA_WIDTH'(32'hA5001000 + i);

            $display("Initialize addr=0x%08h data=0x%h",
                     original_addr[i] * BYTES_PER_WORD,
                     expected_data[i]);

            do_transfer(
                original_addr[i] * BYTES_PER_WORD,
                expected_data[i],
                1'b1,
                rdata,
                error
            );

            transfer_count++;

            if (error) begin
                fail_count++;
                $display("INITIAL WRITE FAIL: APB error reported");
            end
            else begin
                $display("INITIAL WRITE PASS: transfer completed");
            end

        end

        // ------------------------------------------------
        // PHASE 2: Read and verify the original addresses.
        // ------------------------------------------------
        $display("\nPHASE 2: Read original addresses before new writes");

        for (i = 0; i < NUM_ORIGINAL; i++) begin

            do_transfer(
                original_addr[i] * BYTES_PER_WORD,
                '0,
                1'b0,
                rdata,
                error
            );

            transfer_count++;
            actual_data = rdata[DATA_WIDTH-1:0];

            $display("\nAddress  : 0x%08h",
                     original_addr[i] * BYTES_PER_WORD);
            $display("Expected : 0x%h", expected_data[i]);
            $display("Actual   : 0x%h", actual_data);

            if (error) begin
                fail_count++;
                $display("RESULT   : FAIL - APB read error");
            end
            else if (actual_data === expected_data[i]) begin
                pass_count++;
                $display("RESULT   : PASS - initial data verified");
            end
            else begin
                fail_count++;
                $display("RESULT   : FAIL - initial data mismatch");
            end

        end

        // ------------------------------------------------
        // PHASE 3: Write new data to different addresses.
        // ------------------------------------------------
        $display("\nPHASE 3: Write to different addresses");

        for (i = 0; i < NUM_NEW; i++) begin

            expected_data[NUM_ORIGINAL + i] =
                DATA_WIDTH'(32'h5A002000 + i);

            $display("New write addr=0x%08h data=0x%h",
                     new_addr[i] * BYTES_PER_WORD,
                     expected_data[NUM_ORIGINAL + i]);

            do_transfer(
                new_addr[i] * BYTES_PER_WORD,
                expected_data[NUM_ORIGINAL + i],
                1'b1,
                rdata,
                error
            );

            transfer_count++;

            if (error) begin
                fail_count++;
                $display("NEW WRITE FAIL: APB error reported");
            end
            else begin
                $display("NEW WRITE PASS: transfer completed");
            end

        end

        // ------------------------------------------------
        // PHASE 4: Read ALL addresses again.
        // ------------------------------------------------
        $display("\nPHASE 4: Read all addresses and verify data");
        $display("Original addresses must retain their values.");
        $display("New addresses must contain the new values.");

        for (i = 0; i < TOTAL_ADDRS; i++) begin

            if (i < NUM_ORIGINAL) begin

                do_transfer(
                    original_addr[i] * BYTES_PER_WORD,
                    '0,
                    1'b0,
                    rdata,
                    error
                );

                $display("\nAddress type: ORIGINAL ADDRESS");

                $display("Address  : 0x%08h",
                         original_addr[i] * BYTES_PER_WORD);

            end
            else begin

                do_transfer(
                    new_addr[i-NUM_ORIGINAL] * BYTES_PER_WORD,
                    '0,
                    1'b0,
                    rdata,
                    error
                );

                $display("\nAddress type: NEWLY WRITTEN ADDRESS");

                $display("Address  : 0x%08h",
                         new_addr[i-NUM_ORIGINAL] * BYTES_PER_WORD);

            end

            transfer_count++;
            actual_data = rdata[DATA_WIDTH-1:0];

            $display("Expected : 0x%h", expected_data[i]);
            $display("Actual   : 0x%h", actual_data);

            if (error) begin
                fail_count++;
                $display("RESULT   : FAIL - APB read error");
            end
            else if (actual_data === expected_data[i]) begin
                pass_count++;
                $display("RESULT   : PASS - data matches");
            end
            else begin
                fail_count++;
                $display("RESULT   : FAIL - data mismatch");
            end

        end

        // ------------------------------------------------
        // FINAL SUMMARY
        // ------------------------------------------------
        $display("\n================================================");
        $display(" APB READ TEST SUMMARY");
        $display(" Total transfers : %0d", transfer_count);
        $display(" Passed checks   : %0d", pass_count);
        $display(" Failed checks   : %0d", fail_count);
        $display("================================================");

        if (fail_count == 0)
            $display("OVERALL RESULT: PASS");
        else
            $display("OVERALL RESULT: FAIL");

        finish_test(transfer_count);

    endtask

endclass

