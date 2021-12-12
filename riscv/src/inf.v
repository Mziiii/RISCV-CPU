`include "config.v"

module inf (
    input wire clk,
    input wire rst,
    input wire rdy,

    //ic
    output reg oIC_en,
    output wire [`AddrBus] oIC_pc,
    //
    input wire iIC_en,
    input wire [`InstBus] iIC_inst,
    input wire [`AddrBus] iIC_pc,
    //is
    output reg oIS_en,
    output wire [`AddrBus] oIS_pc,
    output wire [`InstBus] oIS_inst,

    //rob
    input wire iROB_full,

    //bp
    output reg oBP_en,
    output wire [`AddrBus] oBP_pc,
    input wire iBP_en,
    input wire [`AddrBus] iBP_nxpc
);
    reg [`AddrBus] PC;
    integer i;
    reg  [`FIFOBus] q_rd_ptr;
    wire [`FIFOBus] d_rd_ptr;
    reg  [`FIFOBus] q_wr_ptr;
    wire [`FIFOBus] d_wr_ptr;
    reg             q_empty;
    wire            d_empty;
    reg             q_full;
    wire            d_full;
    
    reg  [`InstBus] q_data_inst [2**`FIFOLen-1:0];
    wire [`InstBus] d_data_inst;
    reg  [`AddrBus] q_data_pc [2**`FIFOLen-1:0];
    wire [`AddrBus] d_data_pc;
    
    wire rd_en_prot;
    wire wr_en_prot;
    
    assign oBP_en = !q_full;
    assign oBP_pc = PC;
    always @(posedge clk)
    begin
        if (rst)
        begin
            q_rd_ptr <= 0;
            q_wr_ptr <= 0;
            q_empty  <= 1'b1;
            q_full   <= 1'b0;
            PC       <= 0;
        end
        else if (rdy)
        begin
            //todo:jalr
            q_rd_ptr              <= d_rd_ptr;
            q_wr_ptr              <= d_wr_ptr;
            q_empty               <= d_empty;
            q_full                <= d_full;
            q_data_inst[q_wr_ptr] <= d_data_inst;
            q_data_pc[q_wr_ptr]   <= d_data_pc;
            PC                    <= iBP_nxpc;
            if (iIC_pc[6:0] == 7'b1101111) begin  // JAL
                PC <= PC + {{12{iIC_inst[31]}},
                iIC_inst[19: 12],
                iIC_inst[20],
                iIC_inst[30: 21],
                1'b0};
            end
        end
            end
            // Derive "protected" read/write signals.
            assign rd_en_prot = (!iROB_full && !q_empty);
            assign wr_en_prot = (iIC_en && !q_full);
            
            // Handle writes.
            assign d_wr_ptr    = (wr_en_prot)  ? q_wr_ptr + 1'h1 : q_wr_ptr;
            assign d_data_inst = (wr_en_prot)  ? iIC_inst        : q_data_inst[q_wr_ptr];
            assign d_data_pc   = (wr_en_prot)  ? iIC_pc          : q_data_pc[q_wr_ptr];
            
            // Handle reads.
            assign d_rd_ptr = (rd_en_prot)  ? q_rd_ptr + 1'h1 : q_rd_ptr;
            
            wire [`FIFOBus] addr_bits_wide_1;
            assign addr_bits_wide_1 = 1;
            
            // Detect empty state:
            //   1) We were empty before and there was no write.
            //   2) We had one entry and there was a read.//
            assign d_empty = ((q_empty && !wr_en_prot) ||
            (((q_wr_ptr - q_rd_ptr) == addr_bits_wide_1) && rd_en_prot&&wr_en_prot));
            
            // Detect full state:
            //   1) We were full before and there was no read.
            //   2) We had n-1 entries and there was a write.
            assign d_full = ((q_full && !rd_en_prot) ||
            (((q_rd_ptr - q_wr_ptr) == addr_bits_wide_1) && wr_en_prot&&rd_en_prot));
            
            assign oIC_en   = !q_full;
            assign oIC_pc   = iBP_nxpc;
            assign oIS_en   = !q_empty&&!iROB_full;
            assign oIS_inst = q_data_inst[q_rd_ptr];
            assign oIS_pc   = q_data_pc[q_rd_ptr];
            
            endmodule
