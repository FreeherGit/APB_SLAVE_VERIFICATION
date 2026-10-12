
class apb_walking1_test #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int MEM_WORDS  = 64
) extends apb_base_test #(ADDR_WIDTH, DATA_WIDTH);

    // Call the base-class constructor
    function new(virtual apb_if vif);
        super.new(vif);
    endfunction

    bit [DATA_WIDTH-1:0] data;
    bit [DATA_WIDTH-1:0] read_data;
    bit [63:0] rdata;
    bit error;

    int unsigned transfer_count;
    int unsigned addr;
    int unsigned i;

    // Keep your existing run() task below this point.

    task run_test();

        $display("\n========================================");
        $display(" WALKING-1 TEST: ALL VALID ADDRESSES");
        $display(" Memory words = %0d", MEM_WORDS);
        $display(" Data width   = %0d bits", DATA_WIDTH);
        $display("========================================\n");

        transfer_count = 0;

        // Visit every word-aligned address.
        for (addr = 0; addr < MEM_WORDS; addr++) begin

            $display("\nTesting address = 0x%08h",
                     addr * (DATA_WIDTH / 8));

            // Generate and test each walking-one pattern.
            data = '0;
            data[0] = 1'b1;

            for (i = 0; i < DATA_WIDTH; i++) begin

                // Write the walking-one pattern.
                do_transfer(
                    addr * (DATA_WIDTH / 8),
                    data,
                    1'b1,
                    rdata,
                    error
                );

                transfer_count++;

                if (error) begin
                    $error("WRITE ERROR: addr=0x%08h data=0x%h",
                           addr * (DATA_WIDTH / 8), data);
                end

                // Read back the same address.
                do_transfer(
                    addr * (DATA_WIDTH / 8),
                    '0,
                    1'b0,
                    rdata,
                    error
                );

                transfer_count++;
                read_data = rdata[DATA_WIDTH-1:0];

                if (error || read_data !== data) begin
                    $error("WALKING-1 FAIL: addr=0x%08h expected=0x%h actual=0x%h error=%0b",
                           addr * (DATA_WIDTH / 8),
                           data, read_data, error);
                end
                else begin
                    $display("PASS: addr=0x%08h data=0x%h",
                             addr * (DATA_WIDTH / 8), data);
                end

                // Shift the one to the next bit position.
                data = data << 1;

            end

            // Write zero after all walking-one patterns.
            do_transfer(
                addr * (DATA_WIDTH / 8),
                '0,
                1'b1,
                rdata,
                error
            );

            transfer_count++;

            // Read back zero.
            do_transfer(
                addr * (DATA_WIDTH / 8),
                '0,
                1'b0,
                rdata,
                error
            );

            transfer_count++;
            read_data = rdata[DATA_WIDTH-1:0];

            if (error || read_data !== '0) begin
                $error("ZERO CHECK FAIL: addr=0x%08h expected=0 actual=0x%h error=%0b",
                       addr * (DATA_WIDTH / 8), read_data, error);
            end
            else begin
                $display("ZERO CHECK PASS: addr=0x%08h",
                         addr * (DATA_WIDTH / 8));
            end

        end

        $display("\n========================================");
        $display(" WALKING-1 TEST COMPLETE");
        $display(" Addresses tested = %0d", MEM_WORDS);
        $display(" Transfers issued = %0d", transfer_count);
        $display("========================================\n");

        finish_test(transfer_count);

    endtask

endclass

