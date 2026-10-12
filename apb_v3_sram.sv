module apb_v3_sram #(
                    parameter ADDR_BUS_WIDTH     = 32,
                    parameter DATA_BUS_WIDTH     = 32,
                    parameter MEMSIZE            = 64,
                    parameter MEM_BLOCK_SIZE     = 8,
                    parameter RESET_VAL          = 0,
                    parameter EN_WAIT_DELAY_FUNC = 0,
                    parameter MIN_RAND_WAIT_CYC  = 0,
                    parameter MAX_RAND_WAIT_CYC  = 1
                    )(
                    input  wire                         PRESETn,
                    input  wire                         PCLK,
                    input  wire                         PSEL,
                    input  wire                         PENABLE,
                    input  wire                         PWRITE,
                    input  wire [ADDR_BUS_WIDTH-1:0]    PADDR,
                    input  wire [DATA_BUS_WIDTH-1:0]    PWDATA,
                    output reg  [DATA_BUS_WIDTH-1:0]    PRDATA,
                    output reg                          PREADY,
                    output reg                          PSLVERR
                    );       
  
  localparam int WORD_STRIDE=DATA_BUS_WIDTH/8; localparam int MEM_BYTES=MEMSIZE*WORD_STRIDE; localparam int BYTE_IDX_WIDTH=$clog2(MEM_BYTES); localparam int WAIT_CNT_WIDTH=(MAX_RAND_WAIT_CYC>0)?$clog2(MAX_RAND_WAIT_CYC+1):1; typedef enum logic [1:0] {ST_IDLE,ST_SETUP,ST_ACCESS} apb_state_e; apb_state_e state_q,state_d; reg [7:0] mem_bytes[0:MEM_BYTES-1]; integer i; initial begin for(i=0;i<MEM_BYTES;i=i+1) mem_bytes[i]=RESET_VAL[((i%WORD_STRIDE)*8)+:8]; end wire addr_in_range=(PADDR<=(MEM_BYTES-WORD_STRIDE)); wire addr_valid_c=addr_in_range; reg [BYTE_IDX_WIDTH-1:0] byte_base_q; reg addr_valid_q; reg write_q; reg [WAIT_CNT_WIDTH-1:0] wait_target_q; reg [WAIT_CNT_WIDTH-1:0] wait_cnt_q; wire wait_done=(wait_cnt_q>=wait_target_q); always @(posedge PCLK or negedge PRESETn) begin if(!PRESETn) state_q<=ST_IDLE; else state_q<=state_d; end always @(*) begin state_d=state_q; case(state_q) ST_IDLE: begin if(PSEL&&!PENABLE) state_d=ST_SETUP; end ST_SETUP: begin if(PSEL&&PENABLE) state_d=ST_ACCESS; else if(!PSEL) state_d=ST_IDLE; end ST_ACCESS: begin if(PREADY) begin if(PSEL&&!PENABLE) state_d=ST_SETUP; else state_d=ST_IDLE; end end default: state_d=ST_IDLE; endcase end always @(posedge PCLK or negedge PRESETn) begin if(!PRESETn) begin byte_base_q<='0; addr_valid_q<=1'b0; write_q<=1'b0; end else if(state_q==ST_SETUP&&state_d==ST_ACCESS) begin byte_base_q<=PADDR[BYTE_IDX_WIDTH-1:0]; addr_valid_q<=addr_valid_c; write_q<=PWRITE; end end always @(posedge PCLK or negedge PRESETn) begin if(!PRESETn) begin wait_cnt_q<='0; wait_target_q<='0; end else if(state_q==ST_SETUP&&state_d==ST_ACCESS) begin wait_cnt_q<='0; if(EN_WAIT_DELAY_FUNC) wait_target_q<=$urandom_range(MAX_RAND_WAIT_CYC,MIN_RAND_WAIT_CYC); else wait_target_q<='0; end else if(state_q==ST_ACCESS&&!PREADY) wait_cnt_q<=wait_cnt_q+1'b1; end always @(*) begin if(state_q==ST_ACCESS) PREADY=EN_WAIT_DELAY_FUNC?wait_done:1'b1; else PREADY=1'b0; end always @(*) begin PSLVERR=(state_q==ST_ACCESS)&&PREADY&&!addr_valid_q; end integer k; always @(posedge PCLK) begin if(state_q==ST_ACCESS&&PREADY&&write_q&&addr_valid_q) begin for(k=0;k<WORD_STRIDE;k=k+1) begin mem_bytes[byte_base_q+k]<=(PADDR==ADDR_BUS_WIDTH/2)?'b0:PWDATA[(k*8)+:8]; end end end integer j; always @(posedge PCLK or negedge PRESETn) begin if(!PRESETn) PRDATA<=RESET_VAL[DATA_BUS_WIDTH-1:0]; else if(state_q==ST_SETUP&&state_d==ST_ACCESS&&!PWRITE) begin if(addr_valid_c) begin for(j=0;j<WORD_STRIDE;j=j+1) PRDATA[(j*8)+:8]<=mem_bytes[PADDR[BYTE_IDX_WIDTH-1:0]+j]; end else PRDATA<=RESET_VAL[DATA_BUS_WIDTH-1:0]; end end
  
endmodule
