
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

    // Counts assertion failures for the testbench.
    int unsigned assertion_failures = 0;

    // -------------------------------------------------------
    // ASSERTION 1: SETUP MUST BE FOLLOWED BY ACCESS
    // -------------------------------------------------------
    property p_setup_to_access;
        @(posedge pclk)
        disable iff (!presetn)
        (pselx && !penable) |=> (pselx && penable);
    endproperty

    a_setup_to_access:
        assert property (p_setup_to_access)
        else begin
            assertion_failures++;
            $error("[APB ASSERTION FAILED] SETUP was not followed by ACCESS. Expected PSEL=1 and PENABLE=1 in the next cycle.");
        end


    // -------------------------------------------------------
    // ASSERTION 2: SIGNALS MUST REMAIN STABLE DURING WAIT
    // -------------------------------------------------------
    property p_stable_during_wait;
        @(posedge pclk)
        disable iff (!presetn)
        (pselx && penable && !pready)
        |=> (pselx && penable &&
             $stable(paddr) &&
             $stable(pwrite) &&
             $stable(pwdata));
    endproperty

    a_stable_during_wait:
        assert property (p_stable_during_wait)
        else begin
            assertion_failures++;
            $error("[APB ASSERTION FAILED] Signals changed during a wait state. PSEL and PENABLE must remain high; PADDR, PWRITE, and PWDATA must remain stable.");
        end


    // -------------------------------------------------------
    // ASSERTION 3: ACCESS MUST CONTINUE DURING WAIT
    // -------------------------------------------------------
    property p_hold_access;
        @(posedge pclk)
        disable iff (!presetn)
        (pselx && penable && !pready)
        |=> (pselx && penable);
    endproperty

    a_hold_access:
        assert property (p_hold_access)
        else begin
            assertion_failures++;
            $error("[APB ASSERTION FAILED] ACCESS ended before the slave was ready. PREADY was low, so PSEL and PENABLE must remain high.");
        end


    // -------------------------------------------------------
    // ASSERTION 4: PSLVERR MUST ONLY BE HIGH ON COMPLETION
    // -------------------------------------------------------
    property p_error_valid;
        @(posedge pclk)
        disable iff (!presetn)
        pslverr |-> (pselx && penable && pready);
    endproperty

    a_error_valid:
        assert property (p_error_valid)
        else begin
            assertion_failures++;
            $error("[APB ASSERTION FAILED] PSLVERR was high outside a completed ACCESS transfer. Expected PSEL=1, PENABLE=1, and PREADY=1.");
        end

endinterface

