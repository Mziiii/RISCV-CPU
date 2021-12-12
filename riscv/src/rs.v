`include "config.v"

module rs (
    inout wire clk,
    input wire rst,
    input wire rdy,

    //rob
    input wire            iROB_en,
    input wire [`OpBus]   iROB_op,
    input wire [`AddrBus] iROB_pc,
    input wire [`ImmBus]  iROB_imm,
    input wire [`NickBus] iROB_rd_nick,
    input wire [`NickBus] iROB_rs1_nick,
    input wire [`DataBus] iROB_rs1_dt,
    input wire [`NickBus] iROB_rs2_nick,
    input wire [`DataBus] iROB_rs2_dt,

    //from ex
    input wire            iEX_en,
    input wire [`NickBus] iEX_rd_nick,
    input wire [`DataBus] iEX_rd_dt,

    //from slb
    input wire            iSLB_en,
    input wire [`NickBus] iSLB_rd_nick,
    input wire [`DataBus] iSLB_rd_dt,

    //ex
    output wire            oEX_en,
    output wire [`AddrBus] oEX_pc,
    output wire [`OpBus]   oEX_op,
    output wire [`ImmBus]  oEX_imm,
    output wire [`NickBus] oEX_rd_nick,
    output wire [`DataBus] oEX_rs1_dt,
    output wire [`DataBus] oEX_rs2_dt
);

    reg [`NickBus] rd_nick[`RSNum],rs1_nick[`RSNum],rs2_nick[`RSNum];
    reg [`DataBus] rs1_dt[`RSNum],rs2_dt[`RSNum];
    reg [`OpBus] op[`RSNum];
    reg [`AddrBus] pc[`RSNum];
    reg [`ImmBus] imm[`RSNum];
    
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0;i<`RSNum ; i = i+1) begin
                rd_nick[i]  = 0;
                rs1_nick[i] = 0;
                rs2_nick[i] = 0;
                rs1_dt[i]   = 0;
                rs2_dt[i]   = 0;
                op[i]       = 0;
                pc[i]       = 0;
                imm[i]      = 0;
            end
        end
        else if (rdy) begin
            if(iROB_en)begin
                //
            end
            
        end
            end
            endmodule
