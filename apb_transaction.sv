
class apb_transaction #(
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 32
);

  rand bit [ADDR_WIDTH-1:0] addr;
  rand bit [DATA_WIDTH-1:0] wdata;

  bit [DATA_WIDTH-1:0] rdata;
  bit write;
  bit error;

  function new();
  endfunction

endclass

