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

    input wire iROB_wrong,//todo:

    //
    output reg oROB_en,
    output reg [`OpBus] oROB_op,
    output reg [`AddrBus] oROB_pc,
    output reg [`ImmBus] oROB_imm,
    output reg [`NickBus] oROB_rd_nick,
    // output reg oROB_rs1_valid,
    output reg [`NickBus] oROB_rs1_nick,
    output reg [`DataBus] oROB_rs1_dt,
    // output reg oROB_rs2_valid,
    output reg [`NickBus] oROB_rs2_nick,
    output reg [`DataBus] oROB_rs2_dt
);

    reg [`DataBus] reg_dt[`RegNumBus];
    reg [`NickBus] reg_nick[`RegNumBus];

    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for ( i=0 ;i<`RegNum ;i=i+1 ) begin
               reg_dt[i]<=0;
               reg_nick[i]<=0; 
            end
            oROB_en<=0;
            oROB_imm<=0;
            oROB_op<=0;
            oROB_pc<=0;
            oROB_rd_nick<=0;
            oROB_rs1_dt<=0;
            oROB_rs1_nick<=0;
            oROB_rs2_dt<=0;
            oROB_rs2_nick<=0;
        end
        else if(iROB_wrong) begin
            for ( i=0 ;i<`RegNum ;i=i+1 ) begin
               reg_nick[i]<=0; 
            end
            oROB_en<=0;
            oROB_imm<=0;
            oROB_op<=0;
            oROB_pc<=0;
            oROB_rd_nick<=0;
            oROB_rs1_dt<=0;
            oROB_rs1_nick<=0;
            oROB_rs2_dt<=0;
            oROB_rs2_nick<=0;
        end
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
            case(iIS_op) 
            `LUI,
            `AUIPC:begin
                oROB_rs1_nick  <= 0;
                oROB_rs1_dt    <= 0;
                oROB_rs2_nick  <= 0;
                oROB_rs2_dt    <= 0;
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
                oROB_rs1_nick  <= reg_nick[iIS_rs1_regnm];
                oROB_rs1_dt    <= reg_dt[iIS_rs1_regnm];
                oROB_rs2_nick  <= 0;
                oROB_rs2_dt    <= 0;
            end
            default:begin
                oROB_rs1_nick  <= reg_nick[iIS_rs1_regnm];
                oROB_rs1_dt    <= reg_dt[iIS_rs1_regnm];
                oROB_rs2_nick  <= reg_nick[iIS_rs2_regnm];
                oROB_rs2_dt    <= reg_dt[iIS_rs2_regnm];
            end
            endcase
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
