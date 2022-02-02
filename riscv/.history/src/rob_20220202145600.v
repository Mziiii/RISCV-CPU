`include "config.v"

module rob (
    input wire clk,
    input wire rst,
    input wire rdy,

    output reg clr,
    output reg [`AddrBus] oINF_j_pc,

    input wire iclr,
    //inf 
    output reg            oINF_full,

    input wire            iIND_en,
    input wire [`NameBus] iIND_rd_regnm,
    //send nick to dispatch(->rf/dispatch)
    output reg            oROB_nick_en,
    output reg [`NickBus] oROB_nick,
    output reg [`NameBus] oROB_nick_regnm,

    //dispatch to rs/slb
    input wire            iDP_en,
    input wire [`OpBus]   iDP_op,
    input wire            iDP_pd,
    input wire [`NickBus] iDP_rd_nick,
    input wire [`NickBus] iDP_rd_regnm,


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
    output reg            oSLB_store_en,//todo:output 
    output reg [`NickBus] oSLB_store_nick,

    //commit: write back to regfile 
    output reg            oRF_en,
    output reg [`NameBus] oRF_rd_regnm,
    output reg [`DataBus] oRF_rd_dt,
    output reg [`NickBus] oRF_rd_nick
);
    
    //fifo
    reg [`RobBus]  occupied;
    reg            commit[`RobBus];
    reg [`NameBus] regnm[`RobBus];
    reg [`DataBus] dt[`RobBus];
    reg            ls[`RobBus];//load_store: 1'b1(`Store) only when being store.1'b0 represents the other cases
    reg            ac[`RobBus];//actually
    reg            pd[`RobBus];//preditcted
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
            oINF_full       = 1'b0;
            oROB_nick_en    = 1'b0;
            oROB_nick       = 0;
            oROB_nick_regnm = 0;
            wt_ptr          = 1;
        end 
        else if(rdy) begin
            oINF_full = full;
            if(iIND_en&&!full) begin
                oROB_nick_en    = 1'b1;
                oROB_nick       = wt_ptr;
                oROB_nick_regnm = iIND_rd_regnm;
                if(wt_ptr!=5'b11111) wt_ptr = wt_ptr + 1;
                else wt_ptr=1;
            end 
            else begin
                oROB_nick_en    = 1'b0;
                oROB_nick       = 0;
                oROB_nick_regnm = 0;
            end
        end else begin
            oINF_full       = 0;
            oROB_nick_en    = 1'b0;
            oROB_nick       = 0;
            oROB_nick_regnm = 0;
        end
    end

    always @(posedge clk) begin
        if (rst||iclr) begin
            for(i = 0; i < `RobNum; i = i + 1) begin
                regnm[i] <= 0;
                dt[i]    <= 0;
                commit[i]<= 1'b0;
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
            oSLB_store_en  <= 1'b0;
        end
        else if (rdy) begin

            if(iDP_en) begin
                regnm[iDP_rd_nick]    <= iDP_rd_regnm;
                occupied[iDP_rd_nick] <= 1'b1;
                pd[iDP_rd_nick]       <= iDP_pd;
                case(iDP_op) 
                `SB,
                `SH,
                `SW:
                ls[iDP_rd_nick] <= `Store;
                default;
                endcase
            end

            if (iEX_en) begin
                dt[iEX_nick]     <= iEX_dt;
                ac[iEX_nick]     <= iEX_ac;
                commit[iEX_nick] <= 1'b1;
                j_pc[iEX_nick]   <= iEX_j_pc;
            end
            if (iSLB_en) begin
                if(ls[iSLB_nick]) begin
                    occupied[rd_ptr] <= 1'b0;
                    regnm[rd_ptr]    <= 0;
                    dt[rd_ptr]       <= 0;
                    commit[rd_ptr]   <= 1'b0;
                    j_pc[rd_ptr]     <= 0;
                    ac[rd_ptr]       <= `NotJump;
                    pd[rd_ptr]       <= `NotJump;
                    ls[rd_ptr]       <= 1'b0;
                end
                dt[iSLB_nick]      <= iSLB_dt;
                commit[iSLB_nick]  <= 1'b1;
            end
            
            if (!empty && (commit[rd_ptr] || ls[rd_ptr])) begin
                if (ls[rd_ptr]) begin
                    oRF_en           <= 1'b0;
                    oSLB_store_en    <= 1'b1;
                    oSLB_store_nick  <= rd_ptr;
                    clr              <= 1'b0;
                end
                else if (pd[rd_ptr] != ac[rd_ptr]) begin
                    clr              <= 1'b1;//
                    oSLB_store_en    <= 1'b0;
                    oINF_j_pc        <= j_pc[rd_ptr];
                    oRF_en           <= 1'b1;
                    oRF_rd_dt        <= dt[rd_ptr];
                    oRF_rd_nick      <= rd_ptr;
                    oRF_rd_regnm     <= regnm[rd_ptr];
                end
                else begin
                    clr              <= 1'b0;
                    //read from fifo when !empty
                    oSLB_store_en    <= 1'b0;
                    oRF_en           <= 1'b1;
                    oRF_rd_dt        <= dt[rd_ptr];
                    oRF_rd_nick      <= rd_ptr;
                    oRF_rd_regnm     <= regnm[rd_ptr];
                    //clr when commit
                    occupied[rd_ptr] <= 1'b0;
                    regnm[rd_ptr]    <= 0;
                    dt[rd_ptr]       <= 0;
                    commit[rd_ptr]   <= 1'b0;
                    j_pc[rd_ptr]     <= 0;
                    ac[rd_ptr]       <= `NotJump;
                    pd[rd_ptr]       <= `NotJump;
                    ls[rd_ptr]       <= 1'b0;
                    //
                    rd_ptr <= rd_nx_ptr;
                end
            end else begin
                clr            <= 1'b0;
                oRF_en         <= 1'b0;
                oSLB_store_en  <= 1'b0;
            end

        end else begin
            clr            <= 1'b0;
            oRF_en         <= 1'b0;
            oSLB_store_en  <= 1'b0;
        end
    end
endmodule