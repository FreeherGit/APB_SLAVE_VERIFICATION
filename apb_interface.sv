
interface apb_if #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
) (
    input logic pclk
);

    logic presetn;
    logic [ADDR_WIDTH-1:0] paddr;
    logic pselx;
    logic penable;
    logic pwrite;
    logic [DATA_WIDTH-1:0] pwdata;

    logic [DATA_WIDTH-1:0] prdata;
    logic pready;
    logic pslverr;

    // Setup must be followed by access.
    property p_setup_to_access;
        @(posedge pclk)
        disable iff (!presetn)
        (pselx && !penable) |=> (pselx && penable);
    endproperty

    // Controls must remain stable during wait states.
    property p_stable_during_wait;
        @(posedge pclk)
        disable iff (!presetn)
        (pselx && penable && !pready)
        |=> (pselx && penable &&
             $stable(paddr) &&
             $stable(pwrite) &&
             $stable(pwdata));
    endproperty

    // Access must continue while the slave is not ready.
    property p_hold_access;
        @(posedge pclk)
        disable iff (!presetn)
        (pselx && penable && !pready)
        |=> (pselx && penable);
    endproperty

    // Error must be asserted only for a completed transfer.
    property p_error_valid;
        @(posedge pclk)
        disable iff (!presetn)
        pslverr |-> (pselx && penable && pready);
    endproperty

    a_setup_to_access:
        assert property (p_setup_to_access)
        else $error("APB: setup-to-access violation");

    a_stable_during_wait:
        assert property (p_stable_during_wait)
        else $error("APB: controls changed during wait");

    a_hold_access:
        assert property (p_hold_access)
        else $error("APB: access ended before completion");

    a_error_valid:
        assert property (p_error_valid)
        else $error("APB: PSLVERR outside completed transfer");

endinterface

