
class apb_protocol_test #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
) extends apb_base_test #(ADDR_WIDTH, DATA_WIDTH);

    function new(
        virtual apb_if #(ADDR_WIDTH, DATA_WIDTH) vif
    );
        super.new(vif);
    endfunction

    virtual task run_test();

        bit [63:0] rdata;
        bit error;

        prepare_test();

        $display("TEST: APB protocol and signal stability");

        repeat (3) @(posedge vif.pclk);

        do_transfer(0, 64'h87654321, 1, rdata, error);
        do_transfer(0, 0,            0, rdata, error);

        if (rdata[DATA_WIDTH-1:0] !==
            DATA_WIDTH'(64'h87654321)) begin
            local_failures++;
            $error("Protocol test: readback mismatch");
        end

        finish_test(2);

    endtask

endclass

