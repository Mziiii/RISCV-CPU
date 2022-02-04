`include "config.v"

module dispatch (
    input wire clk,
    input wire rst,
    input wire rdy,

    //from ROB to get rd_nick
    input wire            iROB_nick_en,
    input wire [`NickBus] iROB_nick,

    //from regfile to get rs1_nick
    input wire            iRF_en,
    input wire [`NickBus] iRF_rs1_nick,
    input wire [`NickBus] iRF_rs2_nick,
    input wire [`DataBus] iRF_rs1_dt,
    input wire [`DataBus] iRF_rs2_dt,
    input wire [`OpBus]   iRF_op,
    input wire [`AddrBus] iRF_pc,
    input wire [`ImmBus]  iRF_imm,
    input wire            iRF_pd,
    input wire [`NameBus] iRF_rd_regnm,

    //to rob/rs/slb
    output reg            oDP_en,
    output reg [`OpBus]   oDP_op,
    output reg [`AddrBus] oDP_pc,
    output reg [`ImmBus]  oDP_imm,
    output reg [`NickBus] oDP_rd_nick,
    output reg [`NameBus] oDP_rd_regnm,
    output reg [`NickBus] oDP_rs1_nick,
    output reg [`NickBus] oDP_rs2_nick,
    output reg [`DataBus] oDP_rs1_dt,
    output reg [`DataBus] oDP_rs2_dt,
    output reg            oDP_pd
);
    
    always @(*) begin
        if (rst) begin
            oDP_en        = 1'b0;
            oDP_op        = 0;
            oDP_pc        = 0;
            oDP_pd        = 1'b0;
            oDP_imm       = 0;
            oDP_rd_nick   = 0;
            oDP_rd_regnm  = 0;
            oDP_rs1_nick  = 0;
            oDP_rs2_nick  = 0;
            oDP_rs1_dt    = 0;
            oDP_rs2_dt    = 0;
        end 
        else if (rdy) 
        begin
            if (iRF_en) begin
                if (iROB_nick_en) begin
                    //with combination, if rob full inf won't send inst
                    oDP_en       = 1'b1;
                    oDP_op       = iRF_op;
                    oDP_imm      = iRF_imm;
                    oDP_pc       = iRF_pc;
                    oDP_pd       = iRF_pd;
                    oDP_rd_nick  = iROB_nick;
                    case(iRF_op)
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
                     case(iRF_op) 
                        `SB,
                        `SH,
                        `SW,
                        `BEQ,
                        `BNE,
                        `BLT,
                        `BGE,
                        `BLTU,
                        `BGEU:begin
                            oDP_rd_regnm = iRF_rd_regnm;

                        end
                        default:begin
                            oDP_rd_regnm = iRF_rd_regnm;
                        end
                    endcase
                end
            end else begin
                oDP_en        = 1'b0;
                oDP_op        = 0;
                oDP_pc        = 0;
                oDP_pd        = 1'b0;
                oDP_imm       = 0;
                oDP_rd_nick   = 0;
                oDP_rd_regnm  = 0;
                oDP_rs1_nick  = 0;
                oDP_rs2_nick  = 0;
                oDP_rs1_dt    = 0;
                oDP_rs2_dt    = 0;
            end
        end else begin
            oDP_en        = 1'b0;
            oDP_op        = 0;
            oDP_pc        = 0;
            oDP_pd        = 1'b0;
            oDP_imm       = 0;
            oDP_rd_nick   = 0;
            oDP_rd_regnm  = 0;
            oDP_rs1_nick  = 0;
            oDP_rs2_nick  = 0;
            oDP_rs1_dt    = 0;
            oDP_rs2_dt    = 0;
        end
    end
    
endmodule
