`include "config.v"

module dispatch (
    input wire clk,
    input wire rst,
    input wire rdy,

    //from decoder
    input wire            iIND_en,
    input wire [`NameBus] iIND_rs1_regnm,
    input wire [`NameBus] iIND_rs2_regnm,
    input wire [`NameBus] iIND_rd_regnm,
    input wire [`OpBus]   iIND_op,
    input wire [`AddrBus] iIND_pc,
    input wire [`ImmBus]  iIND_imm,
    input wire            iIND_pd,

    output reg            oROB_nick_en,
    //from ROB  to get rd_nick
    input wire            iROB_nick_en,
    input wire [`NickBus] iROB_nick,

    //from regfile to get rs1_nick
    output reg            oRF_en,
    output reg [`NameBus] oRF_rs1_regnm,
    output reg [`NameBus] oRF_rs2_regnm,
    input wire [`NickBus] iRF_rs1_nick,
    input wire [`NickBus] iRF_rs2_nick,
    input wire [`DataBus] iRF_rs1_dt,
    input wire [`DataBus] iRF_rs2_dt,

    //to rob/rs/slb
    output reg            oDP_en,
    output reg [`OpBus]   oDP_op,
    output reg [`AddrBus] oDP_pc,
    output reg [`ImmBus]  oDP_imm,
    output reg [`NickBus] oDP_rd_nick,
    output reg [`NickBus] oDP_rs1_nick,
    output reg [`NickBus] oDP_rs2_nick,
    output reg [`DataBus] oDP_rs1_dt,
    output reg [`DataBus] oDP_rs2_dt,
    output reg            oDP_pd
);
    
    always @(*) begin
        if (rst) begin
            oROB_nick_en  = 1'b0;
            oRF_en        = 1'b0;
            oRF_rs1_regnm = 0;
            oRF_rs2_regnm = 0;
            oDP_en        = 1'b0;
            oDP_op        = 0;
            oDP_pc        = 0;
            oDP_pd        = 1'b0;
            oDP_imm       = 0;
            oDP_rd_nick   = 0;
            oDP_rs1_nick  = 0;
            oDP_rs2_nick  = 0;
            oDP_rs1_dt    = 0;
            oDP_rs2_dt    = 0;
            end else if (rdy) begin
            if (iIND_en) begin
                oROB_nick_en  = 1'b1;
                oRF_en        = 1'b1;
                oRF_rs1_regnm = iIND_rs1_regnm;
                oRF_rs2_regnm = iIND_rs2_regnm;
                if (iROB_nick_en) begin
                    //with combination, if rob full inf won't send inst
                    oDP_en       = 1'b1;
                    oDP_op       = iIND_op;
                    oDP_imm      = iIND_imm;
                    oDP_pc       = iIND_pc;
                    oDP_pd       = iIND_pd;
                    oDP_rd_nick  = iROB_nick;
                    case(iIND_op)
                        `LUI,
                        `AUIPC:begin
                            oDP_rs1_nick = 0;
                            oDP_rs1_dt   = 0;
                            oDP_rs2_nick = 0;
                            oDP_rs2_dt   = 0;
                        end
                        `LB,
                        `LBU,
                        `LH,
                        `LHU,
                        `LW,
                        //
                        `JALR,
                        `ADDI,
                        `SLLI,
                        `SLTI,
                        `SLTIU,
                        `XORI,
                        `SRLI,
                        `SRAI,
                        `ORI,
                        `ANDI:begin
                            oDP_rs1_nick = iRF_rs1_nick;
                            oDP_rs1_dt   = iRF_rs1_dt;
                            oDP_rs2_nick = 0;
                            oDP_rs2_dt   = 0;
                        end
                        default:begin
                            oDP_rs1_nick = iRF_rs1_nick;
                            oDP_rs1_dt   = iRF_rs1_dt;
                            oDP_rs2_nick = iRF_rs2_nick;
                            oDP_rs2_dt   = iRF_rs2_dt;
                        end
                    endcase
                end
                end else begin
                oROB_nick_en  = 1'b0;
                oRF_en        = 1'b0;
                oRF_rs1_regnm = 0;
                oRF_rs2_regnm = 0;
                oDP_en        = 1'b0;
                oDP_op        = 0;
                oDP_pc        = 0;
                oDP_pd        = 1'b0;
                oDP_imm       = 0;
                oDP_rd_nick   = 0;
                oDP_rs1_nick  = 0;
                oDP_rs2_nick  = 0;
                oDP_rs1_dt    = 0;
                oDP_rs2_dt    = 0;
            end
            end else begin
            oROB_nick_en  = 1'b0;
            oRF_en        = 1'b0;
            oRF_rs1_regnm = 0;
            oRF_rs2_regnm = 0;
            oDP_en        = 1'b0;
            oDP_op        = 0;
            oDP_pc        = 0;
            oDP_pd        = 1'b0;
            oDP_imm       = 0;
            oDP_rd_nick   = 0;
            oDP_rs1_nick  = 0;
            oDP_rs2_nick  = 0;
            oDP_rs1_dt    = 0;
            oDP_rs2_dt    = 0;
        end
    end
    
endmodule
