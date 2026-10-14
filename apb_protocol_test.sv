
class apb_protocol_test #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
) extends apb_base_test #(ADDR_WIDTH, DATA_WIDTH);

    function new(
        virtual apb_if #(ADDR_WIDTH, DATA_WIDTH) vif,
        apb_coverage #(ADDR_WIDTH, DATA_WIDTH, 64) shared_cov = null
    );
        super.new(vif, shared_cov);
    endfunction

    virtual task run_test();

        bit [63:0] rdata;
        bit error;

        int unsigned failures_before;
        int unsigned failures_after;
        int unsigned new_failures;

        // Record the count before this test starts.
        failures_before = vif.assertion_failures;

        prepare_test();

        $display("");
        $display("========================================");
        $display("TEST: APB protocol and signal stability");
        $display("========================================");

        repeat (3) @(posedge vif.pclk);

        // Write data to address 0.
        do_transfer(
            0,
            64'h87654321,
            1,
            rdata,
            error
        );

        // Read the data back from address 0.
        do_transfer(
            0,
            0,
            0,
            rdata,
            error
        );

        // Check readback data.
        if (rdata[DATA_WIDTH-1:0] !==
            DATA_WIDTH'(64'h87654321)) begin

            local_failures++;
            $error("[PROTOCOL TEST FAILED] Readback data does not match the written data.");

        end
        else begin
            $display("[PROTOCOL CHECK PASS] Readback data matches the written data.");
        end

        // Move away from the active clock edge before
        // reading the assertion failure counter.
        @(negedge vif.pclk);

        failures_after = vif.assertion_failures;
        new_failures = failures_after - failures_before;

        $display("");
        $display("========================================");
        $display("         ASSERTION CHECK REPORT");
        $display("========================================");

        if (new_failures == 0) begin
            $display("[ASSERTION CHECK PASS] No assertion failures were recorded during this test.");
        end
        else begin
            $display("[ASSERTION CHECK FAIL] %0d assertion failure(s) detected during this test.", new_failures);

            // Ensure the base test reports FAIL.
            local_failures += new_failures;
        end

        $display("Assertion failures in this test: %0d", new_failures);
        $display("========================================");

        finish_test(2);

    endtask

endclass

