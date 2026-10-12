
class apb_reset_test #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
) extends apb_base_test #(ADDR_WIDTH, DATA_WIDTH);

    function new(virtual apb_if vif);
        super.new(vif);
    endfunction

    localparam int BYTES_PER_WORD = DATA_WIDTH / 8;

    // Two non-consecutive word addresses
    localparam int ADDR1 = 2 * BYTES_PER_WORD;
    localparam int ADDR2 = 7 * BYTES_PER_WORD;

    bit [63:0] rdata;
    bit [DATA_WIDTH-1:0] actual_data;
    bit error;

    int unsigned transfer_count;
    int unsigned pass_count;
    int unsigned fail_count;

    task run_test();

        transfer_count = 0;
        pass_count     = 0;
        fail_count     = 0;

        $display("\n==========================================");
        $display("             APB RESET TEST");
        $display("==========================================");
        $display("Address 1: 0x%0h", ADDR1);
        $display("Address 2: 0x%0h", ADDR2);

        // PHASE 1: Write initial data to two addresses
        $display("\nPHASE 1: Write data before reset");

        do_transfer(ADDR1, DATA_WIDTH'(32'hA5A55A5A),
                    1'b1, rdata, error);
        transfer_count++;

        if (error) begin
            $error("FAIL: Initial write failed at address 0x%0h",
                   ADDR1);
            fail_count++;
        end
        else begin
            $display("PASS: Wrote 0x%0h to address 0x%0h",
                     DATA_WIDTH'(32'hA5A55A5A), ADDR1);
            pass_count++;
        end

        do_transfer(ADDR2, DATA_WIDTH'(32'h12345678),
                    1'b1, rdata, error);
        transfer_count++;

        if (error) begin
            $error("FAIL: Initial write failed at address 0x%0h",
                   ADDR2);
            fail_count++;
        end
        else begin
            $display("PASS: Wrote 0x%0h to address 0x%0h",
                     DATA_WIDTH'(32'h12345678), ADDR2);
            pass_count++;
        end

        // PHASE 2: Assert reset
        $display("\nPHASE 2: Assert reset");

        @(negedge vif.pclk);
        vif.presetn = 1'b0;

        repeat (3) @(posedge vif.pclk);

        $display("Reset asserted for 3 clock cycles.");

        // PHASE 3: Deassert reset
        @(negedge vif.pclk);
        vif.presetn = 1'b1;

        repeat (2) @(posedge vif.pclk);
        @(negedge vif.pclk);

        $display("Reset deasserted.");

        // PHASE 4: Read both addresses after reset
        $display("\nPHASE 3: Check memory contents after reset");

        do_transfer(ADDR1, '0, 1'b0, rdata, error);
        transfer_count++;

        if (error) begin
            $error("FAIL: Read error at address 0x%0h after reset",
                   ADDR1);
            fail_count++;
        end
        else begin
            actual_data = rdata[DATA_WIDTH-1:0];

            if (actual_data === '0) begin
                $display("PASS: Address 0x%0h cleared after reset",
                         ADDR1);
                pass_count++;
            end
            else begin
                $error("FAIL: Address 0x%0h contains 0x%0h after reset",
                       ADDR1, actual_data);
                fail_count++;
            end
        end

        do_transfer(ADDR2, '0, 1'b0, rdata, error);
        transfer_count++;

        if (error) begin
            $error("FAIL: Read error at address 0x%0h after reset",
                   ADDR2);
            fail_count++;
        end
        else begin
            actual_data = rdata[DATA_WIDTH-1:0];

            if (actual_data === '0) begin
                $display("PASS: Address 0x%0h cleared after reset",
                         ADDR2);
                pass_count++;
            end
            else begin
                $error("FAIL: Address 0x%0h contains 0x%0h after reset",
                       ADDR2, actual_data);
                fail_count++;
            end
        end

        // PHASE 5: Write new data after reset
        $display("\nPHASE 4: Write new data after reset");

        do_transfer(ADDR1, DATA_WIDTH'(32'hDEADBEEF),
                    1'b1, rdata, error);
        transfer_count++;

        if (error) begin
            $error("FAIL: Post-reset write failed at address 0x%0h",
                   ADDR1);
            fail_count++;
        end
        else begin
            $display("PASS: Wrote 0x%0h to address 0x%0h",
                     DATA_WIDTH'(32'hDEADBEEF), ADDR1);
            pass_count++;
        end

        do_transfer(ADDR2, DATA_WIDTH'(32'hCAFEBABE),
                    1'b1, rdata, error);
        transfer_count++;

        if (error) begin
            $error("FAIL: Post-reset write failed at address 0x%0h",
                   ADDR2);
            fail_count++;
        end
        else begin
            $display("PASS: Wrote 0x%0h to address 0x%0h",
                     DATA_WIDTH'(32'hCAFEBABE), ADDR2);
            pass_count++;
        end

        // PHASE 6: Read both addresses and verify new data
        $display("\nPHASE 5: Verify new data after reset");

        do_transfer(ADDR1, '0, 1'b0, rdata, error);
        transfer_count++;

        if (error) begin
            $error("FAIL: Final read error at address 0x%0h", ADDR1);
            fail_count++;
        end
        else begin
            actual_data = rdata[DATA_WIDTH-1:0];

            if (actual_data === DATA_WIDTH'(32'hDEADBEEF)) begin
                $display("PASS: Address 0x%0h = 0x%0h",
                         ADDR1, actual_data);
                pass_count++;
            end
            else begin
                $error("FAIL: Address 0x%0h expected 0x%0h, got 0x%0h",
                       ADDR1, DATA_WIDTH'(32'hDEADBEEF), actual_data);
                fail_count++;
            end
        end

        do_transfer(ADDR2, '0, 1'b0, rdata, error);
        transfer_count++;

        if (error) begin
            $error("FAIL: Final read error at address 0x%0h", ADDR2);
            fail_count++;
        end
        else begin
            actual_data = rdata[DATA_WIDTH-1:0];

            if (actual_data === DATA_WIDTH'(32'hCAFEBABE)) begin
                $display("PASS: Address 0x%0h = 0x%0h",
                         ADDR2, actual_data);
                pass_count++;
            end
            else begin
                $error("FAIL: Address 0x%0h expected 0x%0h, got 0x%0h",
                       ADDR2, DATA_WIDTH'(32'hCAFEBABE), actual_data);
                fail_count++;
            end
        end

        // SUMMARY
        $display("\n==========================================");
        $display("          RESET TEST SUMMARY");
        $display("==========================================");
        $display("Transfers attempted : %0d", transfer_count);
        $display("Checks passed       : %0d", pass_count);
        $display("Checks failed       : %0d", fail_count);
        $display("==========================================\n");

        finish_test(transfer_count);

    endtask

endclass

