


class apb_wait_test #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
) extends apb_base_test #(ADDR_WIDTH, DATA_WIDTH);

    int unsigned transfer_count;
    int unsigned write_wait_cycles;
    int unsigned read_wait_cycles;

    bit monitor_done;

    logic [DATA_WIDTH-1:0] rdata;
    logic error;

function new(
    virtual apb_if #(ADDR_WIDTH, DATA_WIDTH) vif,
    apb_coverage #(ADDR_WIDTH, DATA_WIDTH, 64) shared_cov = null
);
    super.new(vif, shared_cov);
endfunction

    // Monitor APB access and count every stalled cycle.
    task monitor_wait_states();

        int unsigned current_wait_cycles;
        bit in_access;

        current_wait_cycles = 0;
        in_access = 0;

        forever begin
            @(negedge vif.pclk);

            if (monitor_done)
                break;

            if (vif.presetn === 1'b1 &&
                vif.pselx   === 1'b1 &&
                vif.penable === 1'b1) begin

                if (!in_access) begin
                    in_access = 1'b1;
                    current_wait_cycles = 0;

                    $display(
                        "\n[MONITOR] ACCESS START | Type=%s | Address=0x%08h",
                        vif.pwrite ? "WRITE" : "READ",
                        vif.paddr
                    );
                end

                if (vif.pready === 1'b0) begin

                    current_wait_cycles++;

                    if (vif.pwrite === 1'b1)
                        write_wait_cycles++;
                    else
                        read_wait_cycles++;

                    $display(
                        "[WAIT] Time=%0t | Type=%s | Address=0x%08h | PREADY=0 | Stalled cycle=%0d",
                        $time,
                        vif.pwrite ? "WRITE" : "READ",
                        vif.paddr,
                        current_wait_cycles
                    );

                end
                else if (vif.pready === 1'b1) begin

                    $display(
                        "[READY] Time=%0t | Type=%s | Address=0x%08h | PREADY=1 | Wait cycles=%0d",
                        $time,
                        vif.pwrite ? "WRITE" : "READ",
                        vif.paddr,
                        current_wait_cycles
                    );

                    in_access = 1'b0;
                    current_wait_cycles = 0;
                end
            end
            else begin
                in_access = 1'b0;
                current_wait_cycles = 0;
            end
        end

    endtask


    task run_test();

        $display("\n");
        $display("================================================");
        $display("         APB WAIT-STATE VERIFICATION");
        $display("================================================");

        prepare_test();

        transfer_count   = 0;
        write_wait_cycles = 0;
        read_wait_cycles  = 0;
        monitor_done      = 0;

        $display("[INFO] Wait-state test started at %0t", $time);
        $display("[INFO] Expected: PREADY stays LOW during stalls.");
        $display("[INFO] Expected: PREADY eventually becomes HIGH.");

        fork
            monitor_wait_states();
        join_none


        // ------------------------------------------------
        // TEST 1: WRITE WITH WAIT STATES
        // ------------------------------------------------

        $display("\n-----------------------------------------------");
        $display("TEST 1: WRITE WITH WAIT STATES");
        $display("Address : 0x00000000");
        $display("Data    : 0xA5C37E19");
        $display("-----------------------------------------------");

        do_transfer(
            ADDR_WIDTH'(32'h0000_0000),
            DATA_WIDTH'(32'hA5C3_7E19),
            1'b1,
            rdata,
            error
        );

        transfer_count++;

        if (error !== 1'b0) begin
            $error("[FAIL] WRITE returned PSLVERR=%b", error);
            local_failures++;
        end
        else begin
            $display("[PASS] WRITE completed without PSLVERR");
        end


        // ------------------------------------------------
        // TEST 2: READ BACK THE WRITTEN DATA
        // ------------------------------------------------

        $display("\n-----------------------------------------------");
        $display("TEST 2: READ WITH WAIT STATES");
        $display("Address  : 0x00000000");
        $display("Expected : 0xA5C37E19");
        $display("-----------------------------------------------");

        do_transfer(
            ADDR_WIDTH'(32'h0000_0000),
            DATA_WIDTH'('0),
            1'b0,
            rdata,
            error
        );

        transfer_count++;

        if (error !== 1'b0) begin
            $error("[FAIL] READ returned PSLVERR=%b", error);
            local_failures++;
        end
        else if (rdata !== DATA_WIDTH'(32'hA5C3_7E19)) begin
            $error(
                "[FAIL] READ DATA mismatch | Expected=0x%08h | Actual=0x%08h",
                DATA_WIDTH'(32'hA5C3_7E19),
                rdata
            );
            local_failures++;
        end
        else begin
            $display("[PASS] READ DATA matches: 0x%08h", rdata);
        end


        // Allow the monitor to finish sampling before stopping.
        @(negedge vif.pclk);
        monitor_done = 1'b1;

        // Allow the monitor process to observe monitor_done.
        @(negedge vif.pclk);

        // ------------------------------------------------
        // FINAL SUMMARY
        // ------------------------------------------------

        $display("\n================================================");
        $display("           WAIT-STATE TEST SUMMARY");
        $display("================================================");
        $display("Transfers attempted : %0d", transfer_count);
        $display("Write wait cycles   : %0d", write_wait_cycles);
        $display("Read wait cycles    : %0d", read_wait_cycles);
        $display("Total wait cycles   : %0d",
                 write_wait_cycles + read_wait_cycles);
        $display("Failures recorded   : %0d", local_failures);

        if (write_wait_cycles == 0) begin
            $error("[FAIL] No write wait cycles observed");
            local_failures++;
        end
        else begin
            $display("[PASS] Write wait states observed");
        end

        if (read_wait_cycles == 0) begin
            $error("[FAIL] No read wait cycles observed");
            local_failures++;
        end
        else begin
            $display("[PASS] Read wait states observed");
        end

        if (local_failures == 0)
            $display("OVERALL RESULT: PASS");
        else
            $display("OVERALL RESULT: FAIL");

        $display("================================================");

        finish_test(transfer_count);

    endtask

endclass

