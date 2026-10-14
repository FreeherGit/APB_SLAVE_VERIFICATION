class apb_coverage #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int MEM_WORD   = 64
);

    localparam int WORD_BYTES = DATA_WIDTH / 8;
    localparam longint unsigned MEM_BYTES = MEM_WORD * WORD_BYTES;

    // Fields sampled by the covergroup
    bit sample_write;
    bit sample_error;
    int unsigned sample_addr_region;
    int unsigned sample_wait_cycles;
    int unsigned sample_data_kind;

    int unsigned sampled_transfers;

    // Data classification:
    // 0 = all zeros
    // 1 = all ones
    // 2 = mixed data
    // 3 = not applicable (read transfer)

    covergroup apb_cg;

        option.per_instance = 1;

        cp_transfer_type : coverpoint sample_write {
            bins read_transfer  = {0};
            bins write_transfer = {1};
        }

        cp_address_region : coverpoint sample_addr_region {
            bins low_address     = {0};
            bins middle_address  = {1};
            bins high_address    = {2};
            bins invalid_address = {3};
        }

        cp_error : coverpoint sample_error {
            bins no_error = {0};
            bins error    = {1};
        }

        // FIX 1: Aligned wait cycle bins with the DUT's realistic capabilities
        cp_wait_cycles : coverpoint sample_wait_cycles {
            bins no_wait    = {0};
            bins short_wait = {[1:2]};
            bins max_wait   = {[3:5]};
        }

        cp_write_data : coverpoint sample_data_kind {
            bins all_zeros      = {0};
            bins all_ones       = {1};
            bins mixed_data     = {2};
            bins not_applicable = {3};
        }

        transfer_x_address :
            cross cp_transfer_type, cp_address_region;

        transfer_x_error :
            cross cp_transfer_type, cp_error;

        // FIX 2: Added a cross to ensure all data types are explicitly tested during WRITEs
        transfer_x_data : cross cp_transfer_type, cp_write_data {
            // Ignore 'not_applicable' for writes, and ignore data patterns for reads
            ignore_bins read_data = binsof(cp_transfer_type.read_transfer) && 
                                    !binsof(cp_write_data.not_applicable);
            ignore_bins write_na  = binsof(cp_transfer_type.write_transfer) && 
                                    binsof(cp_write_data.not_applicable);
        }

    endgroup


    function new();
        sampled_transfers = 0;
        apb_cg = new();
    endfunction


    function void sample_transfer(
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [DATA_WIDTH-1:0] wdata,
        input bit write,
        input bit error,
        input int unsigned wait_cycles
    );

        longint unsigned address_value;

        address_value = addr;

        sample_write       = write;
        sample_error       = error;
        sample_wait_cycles = wait_cycles;

        // Divide the address space into regions.
        if (address_value >= MEM_BYTES)
            sample_addr_region = 3;
        else if (address_value < MEM_BYTES / 4)
            sample_addr_region = 0;
        else if (address_value < MEM_BYTES / 2)
            sample_addr_region = 1;
        else
            sample_addr_region = 2;

        // Classify write data. For reads, data-pattern
        // coverage is marked not applicable.
        if (!write)
            sample_data_kind = 3;
        else if (wdata == '0)
            sample_data_kind = 0;
        else if (&wdata)
            sample_data_kind = 1;
        else
            sample_data_kind = 2;

        apb_cg.sample();
        sampled_transfers++;

        $display(
            "[COVERAGE] Transfer=%0d Type=%s Addr=0x%08h Error=%0b Wait=%0d",
            sampled_transfers,
            write ? "WRITE" : "READ",
            addr,
            error,
            wait_cycles
        );

    endfunction


    function void report();

        $display("\n========================================");
        $display("       APB FUNCTIONAL COVERAGE");
        $display("========================================");
        $display("Completed transfers sampled : %0d",
                 sampled_transfers);
        $display("Functional coverage         : %0.2f%%",
                 apb_cg.get_coverage());
        $display("========================================\n");

    endfunction

endclass
