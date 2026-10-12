
class apb_back_to_back_test #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int MEM_WORDS  =64
) extends apb_base_test #(ADDR_WIDTH, DATA_WIDTH);

    function new(virtual apb_if vif);
        super.new(vif);
    endfunction

    localparam int BYTES_PER_WORD = DATA_WIDTH / 8;

    bit [63:0] rdata;
    bit error;

    bit [DATA_WIDTH-1:0] expected_mem [0:MEM_WORDS-1];

    int unsigned transfer_count;
    int unsigned pass_count;
    int unsigned fail_count;

    bit [DATA_WIDTH-1:0] write_data;
    bit [DATA_WIDTH-1:0] actual_data;
    int unsigned addr;

    task run_test();

        transfer_count = 0;
        pass_count     = 0;
        fail_count     = 0;

        $display("\n==========================================");
        $display("        APB BACK-TO-BACK TEST");
        $display("==========================================");
        $display("Memory words: %0d", MEM_WORDS);

        // PHASE 1: Write every memory address consecutively
        $display("\nPHASE 1: Back-to-back writes");

        for (int i = 0; i < MEM_WORDS; i++) begin

            addr = i * BYTES_PER_WORD;

            // Generate a different, reproducible value per address
            write_data = DATA_WIDTH'(32'hA5000000 + i);
            expected_mem[i] = write_data;

            do_transfer(
                addr,
                write_data,
                1'b1,
                rdata,
                error
            );

            transfer_count++;

            if (error) begin
                $error("WRITE FAIL: Address=0x%0h, Data=0x%0h",
                       addr, write_data);
                fail_count++;
            end
            else begin
                $display("WRITE PASS: Address=0x%0h, Data=0x%0h",
                         addr, write_data);
                pass_count++;
            end

        end

        // PHASE 2: Read every memory address consecutively
        $display("\nPHASE 2: Back-to-back reads");

        for (int i = 0; i < MEM_WORDS; i++) begin

            addr = i * BYTES_PER_WORD;

            do_transfer(
                addr,
                '0,
                1'b0,
                rdata,
                error
            );

            transfer_count++;

            if (error) begin
                $error("READ FAIL: Address=0x%0h returned an error",
                       addr);
                fail_count++;
            end
            else begin
                actual_data = rdata[DATA_WIDTH-1:0];

                if (actual_data === expected_mem[i]) begin
                    $display(
                        "READ PASS: Address=0x%0h, Expected=0x%0h, Actual=0x%0h",
                        addr, expected_mem[i], actual_data
                    );
                    pass_count++;
                end
                else begin
                    $error(
                        "READ FAIL: Address=0x%0h, Expected=0x%0h, Actual=0x%0h",
                        addr, expected_mem[i], actual_data
                    );
                    fail_count++;
                end
            end

        end

        // SUMMARY
        $display("\n==========================================");
        $display("       BACK-TO-BACK TEST SUMMARY");
        $display("==========================================");
        $display("Memory addresses tested: %0d", MEM_WORDS);
        $display("Transfers attempted    : %0d", transfer_count);
        $display("Checks passed          : %0d", pass_count);
        $display("Checks failed          : %0d", fail_count);
        $display("==========================================\n");

        finish_test(transfer_count);

    endtask

endclass

