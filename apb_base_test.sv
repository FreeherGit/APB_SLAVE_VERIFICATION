
virtual class apb_base_test #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int MEM_WORD   = 64
);

    virtual apb_if #(ADDR_WIDTH, DATA_WIDTH) vif;

    apb_coverage #(ADDR_WIDTH, DATA_WIDTH, MEM_WORD) cov;

    apb_environment #(
        ADDR_WIDTH, DATA_WIDTH, MEM_WORD
    ) env;

    int unsigned local_failures;

    function new(
        virtual apb_if #(ADDR_WIDTH, DATA_WIDTH) vif,
        apb_coverage #(ADDR_WIDTH, DATA_WIDTH, MEM_WORD) shared_cov = null
    );

        this.vif = vif;

        if (shared_cov == null)
            cov = new();
        else
            cov = shared_cov;

        env = new(vif, cov);
        local_failures = 0;

    endfunction

    pure virtual task run_test();

    task prepare_test();

        env.start();
        env.reset();

        $display("\n========================================");
        $display("Starting APB test");
        $display("ADDR_WIDTH = %0d", ADDR_WIDTH);
        $display("DATA_WIDTH = %0d", DATA_WIDTH);
        $display("========================================");

    endtask

    task do_transfer(
        input  bit [31:0] addr,
        input  bit [63:0] wdata,
        input  bit        write,
        output bit [63:0] rdata,
        output bit        error
    );

        bit [ADDR_WIDTH-1:0] a;
        bit [DATA_WIDTH-1:0] wd;
        bit [DATA_WIDTH-1:0] rd;
        bit success;

        a  = addr;
        wd = wdata[DATA_WIDTH-1:0];
        rd = '0;

        env.drv.transfer(
            a, wd, write, rd, error, success
        );

        rdata = '0;
        rdata[DATA_WIDTH-1:0] = rd;

        if (!success)
            local_failures++;

    endtask

    task finish_test(input int unsigned expected_transfers);

        env.wait_for_transfers(expected_transfers);

        #1;

        env.sb.report();

        $display("Driver timeouts : %0d",
                 env.drv.failed_transfers);
        $display("Local failures  : %0d", local_failures);

        if (env.sb.error_count == 0 &&
            env.drv.failed_transfers == 0 &&
            local_failures == 0) begin

            $display("TEST RESULT: PASS");

        end
        else begin

            $error("TEST RESULT: FAIL");

        end

    endtask

endclass

