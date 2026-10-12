
class apb_scoreboard #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH  = 32,
    parameter int MEM_WORDS  = 64
);

    localparam int BYTES_PER_WORD = DATA_WIDTH / 8;

    mailbox #(apb_transaction #(ADDR_WIDTH, DATA_WIDTH)) mon2sb;

    bit [DATA_WIDTH-1:0] expected_mem [0:MEM_WORDS-1];

    int unsigned completed_count;
    int unsigned error_count;

    function new(
        mailbox #(apb_transaction #(ADDR_WIDTH, DATA_WIDTH)) mon2sb
    );
        this.mon2sb = mon2sb;
        completed_count = 0;
        error_count = 0;
        reset_model();
    endfunction

    function void reset_model();
        foreach (expected_mem[i])
            expected_mem[i] = '0;
    endfunction

    function bit valid_address(bit [ADDR_WIDTH-1:0] addr);

        if ((addr % BYTES_PER_WORD) != 0)
            return 0;

        if ((addr / BYTES_PER_WORD) >= MEM_WORDS)
            return 0;

        return 1;

    endfunction

    task run();

        apb_transaction #(ADDR_WIDTH, DATA_WIDTH) tr;
        int unsigned index;
        bit expected_error;

        forever begin

            mon2sb.get(tr);
            completed_count++;

            expected_error = !valid_address(tr.addr);

            if (tr.error !== expected_error) begin
                error_count++;

                $error(
                    "SCOREBOARD: PSLVERR mismatch addr=%h expected=%0b actual=%0b",
                    tr.addr, expected_error, tr.error
                );
            end

            if (valid_address(tr.addr)) begin

                index = tr.addr / BYTES_PER_WORD;

                if (tr.write) begin

                    if (!tr.error) begin
                        expected_mem[index] = tr.wdata;

                        $display(
                            "SCOREBOARD: WRITE addr=%h data=%h",
                            tr.addr, tr.wdata
                        );
                    end

                end
                else begin

                    if (tr.rdata !== expected_mem[index]) begin
                        error_count++;

                        $error(
                            "SCOREBOARD: READ mismatch addr=%h expected=%h actual=%h",
                            tr.addr,
                            expected_mem[index],
                            tr.rdata
                        );
                    end
                    else begin
                        $display(
                            "SCOREBOARD: READ PASS addr=%h data=%h",
                            tr.addr, tr.rdata
                        );
                    end

                end

            end
            else begin

                if (!tr.write && tr.rdata !== '0) begin
                    error_count++;

                    $error(
                        "SCOREBOARD: Invalid read returned nonzero data addr=%h data=%h",
                        tr.addr, tr.rdata
                    );
                end

            end

        end

    endtask

    task report();

        $display("\n========== SCOREBOARD REPORT ==========");
        $display("Completed transfers : %0d", completed_count);
        $display("Checking errors     : %0d", error_count);
        $display("========================================");

    endtask

endclass

