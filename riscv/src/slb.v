`include "config.v"
 
 module slb (
    input wire clk,
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

    //ex calculate 
    input wire            iEX_en,
    input wire [`NickBus] iEX_nick,
    input wire [`DataBus] iEX_dt,

    //slb calculate
    input wire            iSLB_en,
    input wire [`NickBus] iSLB_nick,
    input wire [`DataBus] iSLB_dt,

    //send ->RS/SLB/ROB
    output wire            oRS_en,
    output wire [`NickBus] oRS_nick,
    output wire [`DataBus] oRS_dt,

    output wire            oSLB_en,
    output wire [`NickBus] oSLB_nick,
    output wire [`DataBus] oSLB_dt,

    output wire            oROB_en,
    output wire [`NickBus] oROB_nick,
    output wire [`DataBus] oROB_dt,

    //cache 
    input wire iCACHE_en
    //todo:cache


 );
     

    reg isS_fifo[`SLBNum];
    reg [`NickBus] nick_fifo[`SLBNum];
    reg [`DataBus] dt_fifo[`SLBNum];
    reg [`SLBBus] tail,head;
    reg full,empty;

    wire [`SLBBus] tail_nxt,head_nxt;

    integer i;
    always @(posedge clk) begin
        if(rst) begin
            for (i = 0; i< `SLBNum; i=i+1) begin
                isS_fifo[i]=1'b0;
                dt_fifo[i]=0;
                nick_fifo[i]=0;
            end
            head<=1;
            tail<=1;
            full<=1'b0;
            empty<=1'b1;
        end
        else if(rdy) begin
            if(iROB_en) begin
                case (iROB_op) 
                    `SB,
                    `SH,
                    `SW:isS_fifo[tail]<=1'b1;
                    default: isS_fifo[tail]<=1'b0;
                endcase
                case (iROB_op)
                    `LB,
                    `LH,
                    `LW,
                    `LB,
                    `LHU:begin
                        
                    end
                    default;
                endcase
            end
        end
    end

 endmodule