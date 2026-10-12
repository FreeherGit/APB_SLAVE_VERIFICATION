
class apb_overwrite_test #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int MEM_WORDS  = 64
) extends apb_base_test #(ADDR_WIDTH, DATA_WIDTH);

    function new(virtual apb_if vif);
        super.new(vif);
    endfunction

    localparam int BYTES_PER_WORD = DATA_WIDTH / 8;
    localparam int HALF_WORDS     = MEM_WORDS / 2;

    bit [DATA_WIDTH-1:0] initial_data;
    bit [DATA_WIDTH-1:0] overwrite_data;
    bit [DATA_WIDTH-1:0] expected_data;
    bit [DATA_WIDTH-1:0] actual_data;

    bit [63:0] rdata;
    bit error;

    int unsigned addr;
    int unsigned transfer_count;
    int unsigned pass_count;
    int unsigned fail_count;

    task run_test();

        $display("\n");
        $display("======================================================");
        $display(" APB WRITE, PARTIAL OVERWRITE AND READBACK TEST");
        $display(" Memory words     : %0d", MEM_WORDS);
        $display(" Data width       : %0d bits", DATA_WIDTH);
        $display(" Addresses to overwrite: %0d", HALF_WORDS);
        $display("======================================================");

        transfer_count = 0;
        pass_count = 0;
        fail_count = 0;

        // ------------------------------------------------
        // PHASE 1: Write every memory address.
        // ------------------------------------------------
        $display("\nPHASE 1: Initial write to ALL addresses");
        $display("Expected: each address stores its initial pattern.");

        for (addr = 0; addr < MEM_WORDS; addr++) begin

            initial_data = DATA_WIDTH'(32'hA5000000 ^ addr);
            
            do_transfer(
                addr * BYTES_PER_WORD,
                initial_data,
                1'b1,
                rdata,
                error
            );

            transfer_count++;

            if (error) begin
                fail_count++;
                $display("[WRITE ERROR] addr=0x%08h data=0x%h",
                         addr * BYTES_PER_WORD, initial_data);
            end
            else begin
                $display("[INITIAL WRITE] addr=0x%08h data=0x%h",
                         addr * BYTES_PER_WORD, initial_data);
            end

        end

        // ------------------------------------------------
        // Delay before overwriting.
        // ------------------------------------------------
        $display("\nWaiting 10 PCLK rising edges before overwrite...");
        repeat (10) @(posedge vif.pclk);
        $display("Delay complete.");

        // ------------------------------------------------
        // PHASE 2: Overwrite only the first half.
        // ------------------------------------------------
        $display("\nPHASE 2: Overwrite FIRST HALF only");
        $display("Addresses 0 through %0d will receive new data.",
                 HALF_WORDS - 1);
        $display("The second half should retain its initial data.");

        for (addr = 0; addr < HALF_WORDS; addr++) begin

            overwrite_data = DATA_WIDTH'(32'h5A000000 ^ addr);

            do_transfer(
                addr * BYTES_PER_WORD,
                overwrite_data,
                1'b1,
                rdata,
                error
            );

            transfer_count++;

            if (error) begin
                fail_count++;
                $display("[OVERWRITE ERROR] addr=0x%08h new_data=0x%h",
                         addr * BYTES_PER_WORD, overwrite_data);
            end
            else begin
                $display("[OVERWRITE] addr=0x%08h old_data=0x%h new_data=0x%h",
                         addr * BYTES_PER_WORD,
                         DATA_WIDTH'(32'hA5000000 ^ addr),
                         overwrite_data);
            end

        end

        // ------------------------------------------------
        // PHASE 3: Read EVERY address and compare.
        // ------------------------------------------------
        $display("\nPHASE 3: Readback and expected-versus-actual comparison");
        $display("First half: expect overwritten data.");
        $display("Second half: expect original data.");

        for (addr = 0; addr < MEM_WORDS; addr++) begin

            if (addr < HALF_WORDS)
                expected_data = DATA_WIDTH'(32'h5A000000 ^ addr);
            else
                expected_data = DATA_WIDTH'(32'hA5000000 ^ addr);

            do_transfer(
                addr * BYTES_PER_WORD,
                '0,
                1'b0,
                rdata,
                error
            );

            transfer_count++;
            actual_data = rdata[DATA_WIDTH-1:0];

            $display("\nAddress        : 0x%08h",
                     addr * BYTES_PER_WORD);
            $display("Expected data  : 0x%h", expected_data);
            $display("Actual data    : 0x%h", actual_data);

            if (error) begin
                fail_count++;
                $display("Result         : FAIL - APB transfer error");
            end
            else if (actual_data === expected_data) begin
                pass_count++;
                $display("Result         : PASS - data matches");
            end
            else begin
                fail_count++;
                $display("Result         : FAIL - data mismatch");
            end

        end

        // ------------------------------------------------
        // FINAL SUMMARY
        // ------------------------------------------------
        $display("\n");
        $display("======================================================");
        $display(" APB WRITE TEST SUMMARY");
        $display(" Total transfers : %0d", transfer_count);
        $display(" Readback PASS   : %0d", pass_count);
        $display(" Total failures  : %0d", fail_count);
        $display("======================================================");

        if (fail_count == 0)
            $display("OVERALL RESULT: PASS");
        else
            $display("OVERALL RESULT: FAIL");

        finish_test(transfer_count);

    endtask

endclass

