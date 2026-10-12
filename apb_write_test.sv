
class apb_write_test #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int MEM_WORDS  =64
) extends apb_base_test #(ADDR_WIDTH, DATA_WIDTH);

    function new(virtual apb_if vif);
        super.new(vif);
    endfunction

    localparam int BYTES_PER_WORD = DATA_WIDTH / 8;

    bit [DATA_WIDTH-1:0] write_data;
    bit [DATA_WIDTH-1:0] expected_data;
    bit [DATA_WIDTH-1:0] actual_data;

    bit [63:0] rdata;
    bit error;

    int unsigned addr;
    int unsigned bit_index;
    int unsigned transfer_count;
    int unsigned pass_count;
    int unsigned fail_count;

    // Write a pattern, read it back, and compare.
    task write_and_check(
        input int unsigned address_index,
        input bit [DATA_WIDTH-1:0] pattern,
        input string test_name
    );

        expected_data = pattern;

        $display("\n-----------------------------------------------");
        $display("Test case      : %s", test_name);
        $display("Address        : 0x%08h",
                 address_index * BYTES_PER_WORD);
        $display("Expected data  : 0x%h", expected_data);

        // WRITE
        do_transfer(
            address_index * BYTES_PER_WORD,
            expected_data,
            1'b1,
            rdata,
            error
        );

        transfer_count++;

        if (error) begin
            fail_count++;
            $display("WRITE RESULT   : FAIL (APB error reported)");
            return;
        end

        $display("WRITE RESULT   : Transfer completed without APB error");

        // READ BACK THE SAME ADDRESS
        do_transfer(
            address_index * BYTES_PER_WORD,
            '0,
            1'b0,
            rdata,
            error
        );

        transfer_count++;
        actual_data = rdata[DATA_WIDTH-1:0];

        $display("Actual data    : 0x%h", actual_data);

        if (error) begin
            fail_count++;
            $display("READ RESULT    : FAIL (APB error reported)");
        end
        else if (actual_data === expected_data) begin
            pass_count++;
            $display("READ RESULT    : PASS");
            $display("COMPARE RESULT : PASS - data matches");
        end
        else begin
            fail_count++;
            $display("READ RESULT    : Transfer completed");
            $display("COMPARE RESULT : FAIL - data mismatch");
            $display("Expected       : 0x%h", expected_data);
            $display("Actual         : 0x%h", actual_data);
        end

    endtask

    task run_test();

        $display("\n================================================");
        $display(" APB WRITE AND READBACK CORNER-CASE TEST");
        $display(" Memory words : %0d", MEM_WORDS);
        $display(" Data width   : %0d bits", DATA_WIDTH);
        $display("================================================");

        transfer_count = 0;
        pass_count = 0;
        fail_count = 0;

        for (addr = 0; addr < MEM_WORDS; addr++) begin

            $display("\n========== ADDRESS 0x%08h ==========",
                     addr * BYTES_PER_WORD);

            // 1. All zeros
            write_and_check(addr, '0, "ALL ZEROS");

            // 2. All ones
            write_and_check(addr, '1, "ALL ONES");

            // 3. Alternating 1010...
            write_data = '0;
            for (bit_index = 0; bit_index < DATA_WIDTH; bit_index++)
                write_data[bit_index] = (bit_index % 2 == 1);

            write_and_check(addr, write_data, "ALTERNATING 1010");

            // 4. Alternating 0101...
            write_and_check(addr, ~write_data, "ALTERNATING 0101");

            // 5. Address-derived data
            write_data = DATA_WIDTH'(addr);
            write_and_check(addr, write_data, "ADDRESS-DERIVED DATA");

            // 6. Mixed bit pattern
            for (bit_index = 0; bit_index < DATA_WIDTH; bit_index++)
                write_data[bit_index] =
                    ((32'hA5A55A5A >> (bit_index % 32)) & 1'b1);

            write_and_check(addr, write_data, "MIXED BIT PATTERN");

            // 7. Walking-one patterns
            for (bit_index = 0; bit_index < DATA_WIDTH; bit_index++) begin
                write_data = '0;
                write_data[bit_index] = 1'b1;
                write_and_check(addr, write_data, "WALKING ONE");
            end

            // 8. Walking-zero patterns
            for (bit_index = 0; bit_index < DATA_WIDTH; bit_index++) begin
                write_data = '1;
                write_data[bit_index] = 1'b0;
                write_and_check(addr, write_data, "WALKING ZERO");
            end

        end

        $display("\n================================================");
        $display(" APB WRITE TEST SUMMARY");
        $display(" Total transfers : %0d", transfer_count);
        $display(" Passed checks  : %0d", pass_count);
        $display(" Failed checks  : %0d", fail_count);
        $display("================================================");

        if (fail_count == 0)
            $display("OVERALL RESULT: PASS");
        else
            $display("OVERALL RESULT: FAIL");

        finish_test(transfer_count);

    endtask

endclass

