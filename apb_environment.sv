
class apb_environment #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int  MEM_WORD = 64
);

    virtual apb_if #(ADDR_WIDTH, DATA_WIDTH) vif;

    mailbox #(apb_transaction #(ADDR_WIDTH, DATA_WIDTH)) mon2sb;
apb_coverage #(ADDR_WIDTH, DATA_WIDTH, MEM_WORD) cov;
    apb_driver #(
        ADDR_WIDTH, DATA_WIDTH
    ) drv;

    apb_monitor #(
        ADDR_WIDTH, DATA_WIDTH
    ) mon;

    apb_scoreboard #(
       ADDR_WIDTH, DATA_WIDTH, MEM_WORD  ) sb;

    bit started;

function new(
    virtual apb_if #(ADDR_WIDTH, DATA_WIDTH) vif,
    apb_coverage #(ADDR_WIDTH, DATA_WIDTH, MEM_WORD) shared_cov = null
);
    this.vif = vif;
    mon2sb = new();
    drv = new(vif);

    if (shared_cov == null)
        cov = new();
    else
        cov = shared_cov;

    mon = new(vif, mon2sb, cov);
    sb = new(mon2sb);
    started = 0;
endfunction

    task start();

        if (!started) begin

            started = 1;

            fork
                mon.run();
                sb.run();
            join_none

        end

    endtask

    task reset();

        drv.reset_bus();

        // Synchronize the reference model with the
        // configured reset-memory assumption.
        sb.reset_model();

    endtask

    task wait_for_transfers(
        input int unsigned target,
        input int unsigned timeout_cycles = 200
    );

        int unsigned cycles;
        bit found;

        cycles = 0;
        found = 0;

        while (cycles < timeout_cycles && !found) begin

            if (sb.completed_count >= target)
                found = 1;
            else begin
                @(posedge vif.pclk);
                cycles++;
            end

        end

	if (!found)begin
            $error(
                "ENVIRONMENT: timeout waiting for %0d completed transfers",
                target
            );
	    sb.error_count++;
    end

    endtask

endclass

