
module tb_top;

  // --------------------------------
  // Configuration parameters
  // --------------------------------
  localparam int ADDR_WIDTH = 32;
  localparam int DATA_WIDTH = 32;
  localparam MEMSIZE    = 64;

  // Change these values to test other configurations.
  // Example: ADDR_WIDTH = 16, DATA_WIDTH = 16

  // --------------------------------
  // Clock and reset
  // --------------------------------
  bit pclk = 0;

  always #5 pclk = ~pclk;

  // --------------------------------
  // APB interface
  // --------------------------------
  apb_if #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) intf (
    .pclk(pclk)
  );

  // --------------------------------
  // DUT
  // --------------------------------
  // Replace apb_slave with your actual DUT module
  // and adjust the port connections to match its RTL.
  //
  // If you do not have RTL yet, you may temporarily
  // instantiate a simulation-only mock slave.

  apb_v3_sram #(
    .ADDR_BUS_WIDTH(ADDR_WIDTH),
    .DATA_BUS_WIDTH(DATA_WIDTH),
    .MEMSIZE(MEMSIZE),
    .EN_WAIT_DELAY_FUNC(1),
    .MIN_RAND_WAIT_CYC(2),
    .MAX_RAND_WAIT_CYC(4)
  ) dut (
    .PCLK    (intf.pclk),
    .PRESETn (intf.presetn),
    .PADDR   (intf.paddr),
    .PSEL   (intf.pselx),
    .PENABLE (intf.penable),
    .PWRITE  (intf.pwrite),
    .PWDATA  (intf.pwdata),
    .PRDATA  (intf.prdata),
    .PREADY  (intf.pready),
    .PSLVERR (intf.pslverr)
  );

  // --------------------------------
  // Test selection
  // --------------------------------
  initial begin : test_runner

    string test_name;

    if (!$value$plusargs("TEST=%s", test_name))
      test_name = "write";

    $display("------------------------------------");
    $display(" APB SLAVE VERIFICATION TESTBENCH");
    $display(" ADDR_WIDTH = %0d", ADDR_WIDTH);
    $display(" DATA_WIDTH = %0d", DATA_WIDTH);
    $display(" Selected test = %s", test_name);
    $display("------------------------------------");

    case (test_name)

      "reset": begin
        apb_reset_test #(ADDR_WIDTH, DATA_WIDTH) t;
        t = new(intf);
        t.run_test();
      end

      "write": begin
        apb_write_test #(ADDR_WIDTH, DATA_WIDTH) t;
        t = new(intf);
        t.run_test();
      end

      "read": begin
        apb_read_test #(ADDR_WIDTH, DATA_WIDTH) t;
        t = new(intf);
        t.run_test();
      end


      "back_to_back": begin
        apb_back_to_back_test #(ADDR_WIDTH, DATA_WIDTH) t;
        t = new(intf);
        t.run_test();
      end

      "error": begin
        apb_error_test #(ADDR_WIDTH, DATA_WIDTH) t;
        t = new(intf);
        t.run_test();
      end
    "walking1": begin
    apb_walking1_test #(ADDR_WIDTH, DATA_WIDTH) t;
    t = new(intf);
    t.run_test();
    end
       "overwrite": begin
    apb_overwrite_test #(ADDR_WIDTH, DATA_WIDTH) t;
    t = new(intf);
    t.run_test();
    end
"wait": begin
    apb_wait_test #(ADDR_WIDTH, DATA_WIDTH) t;
    t = new(intf);
    t.run_test();
    end

      "protocol": begin
        apb_protocol_test #(ADDR_WIDTH, DATA_WIDTH) t;
        t = new(intf);
        t.run_test();
      end

      "parameter": begin
        apb_parameter_test #(ADDR_WIDTH, DATA_WIDTH) t;
        t = new(intf);
        t.run_test();
      end

      default: begin
        $fatal(1, "Unknown TEST=%s", test_name);
      end

    endcase

    $display("------------------------------------");
    $display(" APB TEST COMPLETED");
    $display("------------------------------------");

    $finish;
  end

endmodule

