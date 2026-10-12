
class apb_generator #(
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 32
);

  mailbox #(apb_transaction #(ADDR_WIDTH, DATA_WIDTH)) gen2drv;

  function new(
    mailbox #(apb_transaction #(ADDR_WIDTH, DATA_WIDTH)) gen2drv
  );
    this.gen2drv = gen2drv;
  endfunction

  task generate_write(
    input bit [ADDR_WIDTH-1:0] addr,
    input bit [DATA_WIDTH-1:0] data
  );
    apb_transaction #(ADDR_WIDTH, DATA_WIDTH) tr;

    tr = new();
    tr.addr  = addr;
    tr.wdata = data;
    tr.write = 1'b1;

    gen2drv.put(tr);
  endtask

  task generate_read(
    input bit [ADDR_WIDTH-1:0] addr
  );
    apb_transaction #(ADDR_WIDTH, DATA_WIDTH) tr;

    tr = new();
    tr.addr  = addr;
    tr.wdata = '0;
    tr.write = 1'b0;

    gen2drv.put(tr);
  endtask

endclass

