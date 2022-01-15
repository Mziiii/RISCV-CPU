`include "config.v"

module rob (
    input wire clk,
    input wire rst,
    input wire rdy,

    output reg oRF_nick_en,
    output reg [`NickBus] oRF_nick_latest,
    
    //regfile->rs/slb
    //regfile
    input wire            iRF_en,
    input wire [`OpBus]   iRF_op,
    input wire [`AddrBus] iRF_pc,
    input wire [`ImmBus]  iRF_imm,
    input wire [`NickBus] iRF_rd_nick,
    /* input wire            iRF_rs1_valid,*/
    input wire [`NickBus] iRF_rs1_nick,
    input wire [`DataBus] iRF_rs1_dt,
    /* input wire            iRF_rs2_valid,*/
    input wire [`NickBus] iRF_rs2_nick,
    input wire [`DataBus] iRF_rs2_dt,

    //select to rs(copy)
    output reg            oRS_en,
    output reg [`OpBus]   oRS_op,
    output reg [`AddrBus] oRS_pc,
    output reg [`ImmBus]  oRS_imm,
    output reg [`NickBus] oRS_rd_nick,
    /* output wire            oRS_rs1_valid,*/
    output reg [`NickBus] oRS_rs1_nick,
    output reg [`DataBus] oRS_rs1_dt,
    /* output wire            oRS_rs2_valid,*/
    output reg [`NickBus] oRS_rs2_nick,
    output reg [`DataBus] oRS_rs2_dt,

    //select to slb(copy)
    output reg            oSLB_en,
    output reg [`OpBus]   oSLB_op,
    output reg [`AddrBus] oSLB_pc,
    output reg [`ImmBus]  oSLB_imm,
    output reg [`NickBus] oSLB_rd_nick,
    /*output wire            oSLB_rs1_valid,*/
    output reg [`NickBus] oSLB_rs1_nick,
    output reg [`DataBus] oSLB_rs1_dt,
    /* output wire            oSLB_rs2_valid,*/
    output reg [`NickBus] oSLB_rs2_nick,
    output reg [`DataBus] oSLB_rs2_dt,

    //ex
    input wire            iEX_en,
    input wire [`NickBus] iEX_nick,
    input wire [`DataBus] iEX_dt,
    input wire            iEX_isBJ,
    input wire [`AddrBus] iEX_j_pc,

    //slb
    input wire            iSLB_en,
    input wire [`NickBus] iSLB_nick,
    input wire [`DataBus] iSLB_dt,

    //
    output reg            oSLB_commit_en,//todo:output 
    output reg [`NickBus] oSLB_commit_nick,

    //
    output reg            oRF_en,
    output reg [`NameBus] oRF_rd_regnm,
    output reg [`DataBus] oRF_rd_dt,
    output reg [`NickBus] oRF_rd_nick,

    //inf 
    output reg oINF_full,

    output reg oSLB_wrong,
    output reg oRF_wrong
);
    
    reg [`NickBus] nick_latest;
    
    assign oRF_nick_latest = nick_latest;
    
    //fifo
    reg commit[`RobBus];
    reg [`NameBus] regnm_fifo[`RobBus];
    reg [`DataBus] dt_fifo[`RobBus];
    reg ls_fifo[`RobBus];
    reg isBJ_fifo[`RobBus];
    reg full,empty;
    reg [`NickBus] tail,head;
    
    reg [`NameBus] regnm_top;
    reg [`DataBus] dt_top;
    reg ls_top;
    reg isBJ_top;
    
    wire [`NickBus] tail_nxt,head_nxt;
    assign tail_nxt = (tail == 5'b11111)?1:tail+1;
    assign head_nxt = (head == 5'b11111)?1:head+1;
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for(i = 0;i<`RobNum;i = i+1) begin
                regnm_fifo[i] <= 0;
                dt_fifo[i]    <= 0;
                commit[i]     <= 1'b0;
            end
            head        <= 1;
            tail        <= 1;
            full        <= 1'b0;
            empty       <= 1'b1;
            nick_latest <= 1;
        end
        else if (rdy) begin
            if (iRF_en)begin
                case(iRF_op)
                    `SB,
                    `SH,
                    `SW:begin
                        oSLB_en              <= 1'b1;
                        oSLB_imm             <= iRF_imm;
                        oSLB_op              <= iRF_op;
                        oSLB_pc              <= iRF_pc;
                        oSLB_rd_nick         <= iRF_rd_nick;
                        oSLB_rs1_dt          <= iRF_rs1_dt;
                        oSLB_rs1_nick        <= iRF_rs1_nick;
                        oSLB_rs2_dt          <= iRF_rs2_dt;
                        oSLB_rs2_nick        <= iRF_rs2_nick;
                        oRS_en               <= 1'b0;
                        ls_fifo[iRF_rd_nick] <= `Store;
                    end
                    `LB,
                    `LH,
                    `LW,
                    `LBU,
                    `LHU:begin
                        oSLB_en       <= 1'b1;
                        oSLB_imm      <= iRF_imm;
                        oSLB_op       <= iRF_op;
                        oSLB_pc       <= iRF_pc;
                        oSLB_rd_nick  <= iRF_rd_nick;
                        oSLB_rs1_dt   <= iRF_rs1_dt;
                        oSLB_rs1_nick <= iRF_rs1_nick;
                        oSLB_rs2_dt   <= iRF_rs2_dt;
                        oSLB_rs2_nick <= iRF_rs2_nick;
                        oRS_en        <= 1'b0;
                    end
                    default:begin
                        oRS_en       <= 1'b1;
                        oRS_op       <= iRF_op;
                        oRS_pc       <= iRF_pc;
                        oRS_imm      <= iRF_imm;
                        oRS_rd_nick  <= iRF_rd_nick;
                        oRS_rs1_dt   <= iRF_rs1_dt;
                        oRS_rs1_nick <= iRF_rs1_nick;
                        oRS_rs2_dt   <= iRF_rs2_dt;
                        oRS_rs2_nick <= iRF_rs2_nick;
                        oSLB_en      <= 1'b0;
                    end
                endcase
            end
            
            if (!empty && commit[head]) begin
                if (ls_fifo[head]) begin
                    oRF_en           <= 1'b0;
                    oSLB_commit_en   <= 1'b1;
                    oSLB_commit_nick <= head;
                    commit[head]     <= 1'b0;
                end
                else begin//read from fifo when !empty
                    oSLB_commit_en <= 1'b0;
                    oRF_en         <= 1'b1;
                    oRF_rd_dt      <= dt_fifo[head];
                    oRF_rd_nick    <= head;
                    oRF_rd_regnm   <= regnm_fifo[head];
                    if (head == tail&&!iRF_en) begin
                        empty <= 1'b0;
                    end
                    else begin
                        head <= head_nxt;
                    end
                    commit[head] <= 1'b0;
                end
                end else begin
                oRF_en  <= 1'b0;
                oSLB_en <= 1'b0;
            end
                if (iEX_en) begin
                    dt_fifo[iEX_nick]   <= iEX_dt;
                    isBJ_fifo[iEX_nick] <= iEX_isBJ;
                    commit[iEX_nick]    <= 1'b1;
                end
                    if (iSLB_en) begin
                        dt_fifo[iSLB_nick] <= iSLB_dt;
                        commit[iSLB_nick]  <= 1'b1;
                    end
        end
    end
endmodule  
            //todo: full!
