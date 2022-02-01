`include "config.v"

module rob (
    input wire clk,
    input wire rst,
    input wire rdy,

    output reg clr,
    output reg [`AddrBus] oINF_j_pc,

    //inf 
    output reg            oINF_full,

    input wire            iDP_nick_en,
    //send nick to dispatch
    output reg            oDP_nick_en,
    output reg [`NickBus] oDP_nick,


    //dispatch to rs/slb
    input wire            iDP_en,
    input wire [`OpBus]   iDP_op,
    input wire [`NickBus] iDP_rd_nick,
    input wire            iDP_pd,


    //ex
    input wire            iEX_en,
    input wire [`NickBus] iEX_nick,
    input wire [`DataBus] iEX_dt,
    input wire            iEX_ac,
    input wire [`AddrBus] iEX_j_pc,

    //slb
    input wire            iSLB_en,
    input wire [`NickBus] iSLB_nick,
    input wire [`DataBus] iSLB_dt,

    //
    output reg            oSLB_commit_en,//todo:output 
    output reg [`NickBus] oSLB_commit_nick,

    //commit: write back to regfile 
    output reg            oRF_en,
    output reg [`NameBus] oRF_rd_regnm,
    output reg [`DataBus] oRF_rd_dt,
    output reg [`NickBus] oRF_rd_nick
);
    
    //fifo
    reg [`RobBus] occupied;
    reg commit[`RobBus];
    reg [`NameBus] regnm[`RobBus];
    reg [`DataBus] dt[`RobBus];
    reg ls[`RobBus];//load_store
    reg ac[`RobBus];//actually
    reg pd[`RobBus];//preditcted
    reg [`AddrBus] j_pc[`RobBus];//jumped_pc
    
    reg [`NickBus] rd_ptr,wt_ptr;
    wire full  = &occupied;
    wire empty = !(|occupied);
    
    wire [`NickBus] rd_nx_ptr;
    assign rd_nx_ptr = (rd_ptr == 5'b11111)?1:rd_ptr+1;

    integer i;

    //dispatch and commit
    always @(*) begin
        if(rst) begin
            oINF_full = 1'b0;
            oDP_nick_en    = 1'b0;
            oDP_nick  = 0;
            wt_ptr    = 1;
        end 
        else if(rdy) begin
            oINF_full = full;
            if(iDP_nick_en&&!full) begin
                oDP_nick_en = 1'b1;
                oDP_nick = rd_ptr;
                if(wt_ptr!=5')wt_ptr = wt_nx_ptr;
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            for(i = 0; i < `RobNum; i = i + 1) begin
                regnm[i] <= 0;
                dt[i]    <= 0;
                commit[i]     <= 1'b0;
                j_pc[i]  <= 0;
                ac[i]    <= `NotJump;
                pd[i]    <= `NotJump;
                ls[i]    <= 1'b0;
            end
            occupied       <= 0;
            rd_ptr         <= 1;
            //output
            clr            <= 1'b0;
            oRF_en         <= 1'b0;
            oSLB_commit_en <= 1'b0;
        end
        else if (rdy) begin

            if(iDP_en) begin
                occupied[iDP_rd_nick] <= 1'b1;
                pd[iDP_rd_nick] <= iDP_pd;
                case(iDP_op) 
                `SB,
                `SH,
                `SW:
                ls[iDP_rd_nick] <= `Store;
                default;
                endcase
            end
            
            if (!empty && commit[rd_ptr]) begin
                if (ls[rd_ptr]) begin
                    oRF_en           <= 1'b0;
                    oSLB_commit_en   <= 1'b1;
                    oSLB_commit_nick <= rd_ptr;
                    commit[rd_ptr]   <= 1'b0;
                    occupied[rd_ptr] <= 1'b0;
                end
                else begin
                    //read from fifo when !empty
                    oSLB_commit_en <= 1'b0;
                    oRF_en         <= 1'b1;
                    oRF_rd_dt      <= dt[rd_ptr];
                    oRF_rd_nick    <= rd_ptr;
                    oRF_rd_regnm   <= regnm[rd_ptr];
                    if (empty) begin//empty
                    
                        end else rd_ptr <= rd_nx_ptr;
                        commit[rd_ptr]  <= 1'b0;
                        if (pd[rd_ptr] != ac[rd_ptr]) begin
                            clr       <= 1'b1;//
                            //todo: reset!!!!!!
                            oINF_j_pc <= j_pc[rd_ptr];
                        end
                    end
                    end else begin

                end
                if (iEX_en) begin
                    dt[iEX_nick]   <= iEX_dt;
                    ac[iEX_nick]   <= iEX_ac;
                    commit[iEX_nick]    <= 1'b1;
                    j_pc[iEX_nick] <= iEX_j_pc;
                end
                if (iSLB_en) begin
                    dt[iSLB_nick] <= iSLB_dt;
                    commit[iSLB_nick]  <= 1'b1;
                end
            end
        end
    endmodule