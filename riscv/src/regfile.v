`include "config.v"

module regfile(
    input wire clk,
    input wire rst,
    input wire rdy,

    //is
    input wire            iIS_en,
    input wire [`NameBus] iIS_rs1_regnm,
    input wire [`NameBus] iIS_rs2_regnm,
    input wire [`NameBus] iIS_rd_regnm,
    input wire [`OpBus]   iIS_op,
    input wire [`AddrBus] iIS_pc,
    input wire [`ImmBus]  iIS_imm,
    
    input wire            iROB_nick_en,
    input wire [`NickBus] iROB_nick_latest,

    //rob
    input wire iROB_en,
    input wire [`NameBus] iROB_rd_regnm,
    input wire [`DataBus] iROB_rd_dt,
    input wire [`NickBus] iROB_rd_nick,

    //
    output reg oROB_en,
    output wire [`OpBus] oROB_op,
    output wire [`AddrBus] oROB_pc,
    output wire [`ImmBus] oROB_imm,
    output wire [`NickBus] oROB_rd_nick,
    // output wire oROB_rs1_valid,
    output wire [`NickBus] oROB_rs1_nick,
    output wire [`DataBus] oROB_rs1_dt,
    // output wire oROB_rs2_valid,
    output wire [`NickBus] oROB_rs2_nick,
    output wire [`DataBus] oROB_rs2_dt
);

    reg [`DataBus] reg_dt[`RegNum];
    reg [`NickBus] reg_nick[`RegNum];
    always @(posedge clk) begin
        if (rst);
        else if (rdy) begin
        if (iIS_en && iROB_nick_en) begin
            reg_nick[iIS_rd_regnm] <= iROB_nick_latest;
            oROB_en                <= 1'b1;
            oROB_pc                <= iIS_pc;
            oROB_op                <= iIS_op;
            oROB_imm               <= iIS_imm;
            /*if (reg_nick[iIS_rs1_regnm] == 0) begin
                oROB_rs1_valid <= `VALID;
                oROB_rs1_nick  <= 0;
                oROB_rs1_dt    <= reg_dt[iIS_rs1_regnm];
            end
            else begin
                oROB_rs1_valid <= `INVALID;
                oROB_rs1_nick  <= reg_nick[iIS_rs1_regnm];
            end
            if (reg_nick[iIS_rs2_regnm] == 0) begin
                oROB_rs2_valid <= `VALID;
                oROB_rs2_nick  <= 0;
                oROB_rs2_dt    <= reg_dt[iIS_rs2_regnm];
            end
            else begin
                oROB_rs2_valid <= `INVALID;
                oROB_rs2_nick  <= reg_nick[iIS_rs2_regnm];
            end*/
            oROB_rd_nick   <= iROB_nick_latest;
            oROB_rs1_nick  <= reg_nick[iIS_rs1_regnm];
            oROB_rs1_dt    <= reg_dt[iIS_rs1_regnm];
            oROB_rs2_nick  <= reg_nick[iIS_rs2_regnm];
            oROB_rs2_dt    <= reg_dt[iIS_rs2_regnm];
        end
            if (iROB_en) begin
                if (reg_nick[iROB_rd_regnm] == iROB_rd_nick) begin
                    reg_nick[iROB_rd_regnm] <= 0;
                    reg_dt[iROB_rd_regnm]   <= iROB_rd_dt;
                end
            end
        end
    end
endmodule
