`include "config.v"

module rob (
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire clr,

    output reg oRF_nick_en,
    output wire [`NickBus] oRF_nick_latest,
    
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
    output wire            oRS_en,
    output wire [`OpBus]   oRS_op,
    output wire [`AddrBus] oRS_pc,
    output wire [`ImmBus]  oRS_imm,
    output wire [`NickBus] oRS_rd_nick,
    /* output wire            oRS_rs1_valid,*/
    output wire [`NickBus] oRS_rs1_nick,
    output wire [`DataBus] oRS_rs1_dt,
    /* output wire            oRS_rs2_valid,*/
    output wire [`NickBus] oRS_rs2_nick,
    output wire [`DataBus] oRS_rs2_dt,

    //select to slb(copy)
    output wire            oSLB_en,
    output wire [`OpBus]   oSLB_op,
    output wire [`AddrBus] oSLB_pc,
    output wire [`ImmBus]  oSLB_imm,
    output wire [`NickBus] oSLB_rd_nick,
    /*output wire            oSLB_rs1_valid,*/
    output wire [`NickBus] oSLB_rs1_nick,
    output wire [`DataBus] oSLB_rs1_dt,
    /* output wire            oSLB_rs2_valid,*/
    output wire [`NickBus] oSLB_rs2_nick,
    output wire [`DataBus] oSLB_rs2_dt,

    //ex
    input wire            iEX_en,
    input wire [`NickBus] iEX_rd_nick,
    input wire [`DataBus] iEX_rd_dt,
    input wire            iEX_isBJ,

    //slb
    input wire            iSLB_en,
    input wire [`NickBus] iSLB_rd_nick,
    input wire [`DataBus] iSLB_rd_dt,
    input wire            iSLB_isS,

    //
    output wire oSLB_commit_en,//todo:output 

    //
    output reg             oRF_en,
    output wire [`NameBus] oRF_rd_regnm,
    output wire [`DataBus] oRF_rd_dt,
    output wire [`NickBus] oRF_rd_nick,

    //inf 
    output reg oINF_full
);
    
    reg [`NickBus] nick_latest;
    
    assign oRF_nick_latest = nick_latest;
    //
    reg commit;
    
    //fifo
    reg [`NameBus] regnm_fifo[`RobNum];
    reg [`DataBus] dt_fifo[`RobNum];
    reg isS_fifo[`RobNum];
    reg isBJ_fifo[`RobNum];
    reg full,empty;
    reg [`NickBus] tail,head;

    reg [`NameBus] regnm_top;
    reg [`DataBus] dt_top;
    reg isS_top;
    reg isBJ_top;
    
    wire [`NickBus] tail_nxt,head_nxt;
    assign tail_nxt = (tail == 5'b11111)?1:tail+1;
    assign head_nxt = (head == 5'b11111)?1:head+1;
    integer i;
    always @(posedge clk) begin
        if (rst||clr) begin
            for(i = 0;i<`RobNum;i = i+1) begin
                regnm_fifo[i]   <= 0;
                dt_fifo[i]      <= 0;
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
                    `SW,
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
                if (!empty && commit) begin//read from fif o when !empty
                    oRF_en       <= 1;
                    oRF_rd_dt    <= dt_fifo[head];
                    oRF_rd_nick  <= head;
                    oRF_rd_regnm <= regnm_fifo[head];
                    if (head == tail&&!iRF_en) begin
                        empty <= 1'b0;
                    end
                    else begin
                        head <= head_nxt;
                    end
                end
                    if (iEX_en) begin//write in fif o when !full
                        
                        
                        // if (tail == 5'b11111) begin
                        //     tail <= tail_nxt;
                        //     if (head == 1) begin
                        //         full        <= 1'b1;
                        //         oINF_full   <= 1'b1;
                        //         oRF_nick_en <= 1'b0;
                        //     end
                        // end
                        // else begin
                        //     tail <= tail_nxt;
                        //     if (tail+1 == head) begin
                        //         full        <= 1'b1;
                        //         oINF_full   <= 1'b1;
                        //         oRF_nick_en <= 1'b0;
                        //     end
                        // end
                    end
                    if(iSLB_en) begin//todo:
                        
                    end
        end
            end
            endmodule
            
            
            //todo: full!  
            //todo:SLB!