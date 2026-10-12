
class apb_monitor #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
);

    virtual apb_if #(ADDR_WIDTH, DATA_WIDTH) vif;

    mailbox #(apb_transaction #(ADDR_WIDTH, DATA_WIDTH)) mon2sb;

    int unsigned observed_transfers;
    int unsigned write_wait_cycles;
    int unsigned read_wait_cycles;

    function new(
        virtual apb_if #(ADDR_WIDTH, DATA_WIDTH) vif,
        mailbox #(apb_transaction #(ADDR_WIDTH, DATA_WIDTH)) mon2sb
    );
        this.vif = vif;
        this.mon2sb = mon2sb;

        observed_transfers = 0;
        write_wait_cycles  = 0;
        read_wait_cycles   = 0;
    endfunction

    task run();

        apb_transaction #(ADDR_WIDTH, DATA_WIDTH) tr;

        int unsigned current_wait_cycles;
        bit in_access;

        current_wait_cycles = 0;
        in_access = 0;

        forever begin
            @(negedge vif.pclk);

            if (vif.presetn !== 1'b1) begin
                current_wait_cycles = 0;
                in_access = 0;
            end
            else if (vif.pselx === 1'b1 &&
                     vif.penable === 1'b1) begin

                if (!in_access) begin
                    in_access = 1;
                    current_wait_cycles = 0;

                    $display(
                        "\n[MONITOR] ACCESS START | Type=%s | Addr=0x%08h",
                        vif.pwrite ? "WRITE" : "READ",
                        vif.paddr
                    );
                end

                if (vif.pready === 1'b0) begin
                    current_wait_cycles++;

                    $display(
                        "[WAIT] Time=%0t | Type=%s | Addr=0x%08h | PREADY=0 | Stalled cycle=%0d",
                        $time,
                        vif.pwrite ? "WRITE" : "READ",
                        vif.paddr,
                        current_wait_cycles
                    );
                end
                else if (vif.pready === 1'b1) begin

                    $display(
                        "[READY] Time=%0t | Type=%s | Addr=0x%08h | Wait cycles=%0d",
                        $time,
                        vif.pwrite ? "WRITE" : "READ",
                        vif.paddr,
                        current_wait_cycles
                    );

                    if (vif.pwrite === 1'b1)
                        write_wait_cycles += current_wait_cycles;
                    else
                        read_wait_cycles += current_wait_cycles;

                    tr = new();

                    tr.addr  = vif.paddr;
                    tr.wdata = vif.pwdata;
                    tr.rdata = vif.prdata;
                    tr.write = vif.pwrite;
                    tr.error = vif.pslverr;

                    observed_transfers++;
                    mon2sb.put(tr);

                    $display(
                        "[MONITOR] TRANSFER #%0d captured | PSLVERR=%0b",
                        observed_transfers,
                        vif.pslverr
                    );

                    in_access = 0;
                    current_wait_cycles = 0;
                end
            end
            else begin
                in_access = 0;
                current_wait_cycles = 0;
            end
        end

    endtask

    task report_wait_summary();

        $display("\n========================================");
        $display("       MONITOR WAIT-STATE SUMMARY");
        $display("========================================");
        $display("Observed transfers : %0d", observed_transfers);
        $display("Write wait cycles  : %0d", write_wait_cycles);
        $display("Read wait cycles   : %0d", read_wait_cycles);
        $display("Total wait cycles  : %0d",
                 write_wait_cycles + read_wait_cycles);
        $display("========================================");

    endtask

endclass

