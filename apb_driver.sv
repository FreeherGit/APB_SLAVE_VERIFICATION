
class apb_driver #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
);

    virtual apb_if #(ADDR_WIDTH, DATA_WIDTH) vif;

    int unsigned failed_transfers;

    function new(
        virtual apb_if #(ADDR_WIDTH, DATA_WIDTH) vif
    );
        this.vif = vif;
        failed_transfers = 0;
    endfunction

    task reset_bus();

        @(negedge vif.pclk);
        vif.presetn = 0;
        vif.pselx   = 0;
        vif.penable = 0;
        vif.pwrite  = 0;
        vif.paddr   = '0;
        vif.pwdata  = '0;

        // Synchronous reset: hold low across active clock edges.
        repeat (3) @(negedge vif.pclk);

        vif.presetn = 1;
        @(negedge vif.pclk);

    endtask

    task transfer(
        input  bit [ADDR_WIDTH-1:0] addr,
        input  bit [DATA_WIDTH-1:0] wdata,
        input  bit                  write,
        output bit [DATA_WIDTH-1:0] rdata,
        output bit                  error,
        output bit                  success,
        input  int unsigned         timeout_cycles = 100
    );

        int unsigned cycles;
        bit completed;

        rdata     = '0;
        error     = 0;
        success   = 0;
        cycles    = 0;
        completed = 0;

        // SETUP phase.
        @(negedge vif.pclk);
        vif.pselx   = 1;
        vif.penable = 0;
        vif.paddr   = addr;
        vif.pwrite  = write;
        vif.pwdata  = wdata;

        // ACCESS phase.
        @(negedge vif.pclk);
        vif.penable = 1;

        // Wait for the slave to complete the transfer.
        while (!completed && cycles < timeout_cycles) begin

            @(posedge vif.pclk);

            if (vif.pready === 1'b1) begin
                rdata     = vif.prdata;
                error     = vif.pslverr;
                completed = 1;
                success   = 1;
            end
            else if (vif.pready !== 1'b0) begin
                $error("APB: PREADY is X or Z");
                completed = 1;
                success   = 0;
            end

            cycles++;

        end

        if (!success) begin
            failed_transfers++;
            $error("APB transfer failed or timed out at address %h",
                   addr);
        end

        // Return the bus to IDLE.
        @(negedge vif.pclk);
        vif.pselx   = 0;
        vif.penable = 0;
        vif.pwrite  = 0;
        vif.paddr   = '0;
        vif.pwdata  = '0;

    endtask

endclass

