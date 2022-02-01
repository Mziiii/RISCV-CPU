`include "config.v"

 module slb (
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire clr,

    //rob (if en absolutely can write)
    input wire            iDP_en,
    input wire [`OpBus]   iDP_op,
    input wire [`AddrBus] iDP_pc,
    input wire [`ImmBus]  iDP_imm,
    input wire [`NickBus] iDP_rd_nick,
    input wire [`NickBus] iDP_rs1_nick,
    input wire [`DataBus] iDP_rs1_dt,
    input wire [`NickBus] iDP_rs2_nick,
    input wire [`DataBus] iDP_rs2_dt,

    //check update
    //ex calculate 
    input wire            iEX_en,
    input wire [`NickBus] iEX_nick,
    input wire [`DataBus] iEX_dt,
    //slb calculate
    input wire            iSLB_en,
    input wire [`NickBus] iSLB_nick,
    input wire [`DataBus] iSLB_dt,

    //send ->RS/SLB/ROB update
    //->rs
    output reg            oRS_en,
    output reg [`NickBus] oRS_nick,
    output reg [`DataBus] oRS_dt,
    //->slb
    output reg            oSLB_en,
    output reg [`NickBus] oSLB_nick,
    output reg [`DataBus] oSLB_dt,
    //->rob
    output reg            oROB_en,
    output reg [`NickBus] oROB_nick,
    output reg [`DataBus] oROB_dt,

    //execute ST!
    input wire            iROB_commit_en,
    input wire [`NickBus] iROB_commit_nick,
    //->cache update LD/remove ST
    //free to reach cache!
    output reg            oDC_en,//have data!
    output reg            oDC_ls,
    output reg [`NickBus] oDC_nick,
    output reg [`LenBus]  oDC_len,
    output reg [`AddrBus] oDC_addr,
    output reg [`DataBus] oDC_dt,//only ST
    //back LD
    input wire            iDC_en,//have data!
    input wire [`NickBus] iDC_nick,
    input wire [`DataBus] iDC_dt,

    output reg oINF_full
 );
    
    //contents in fifo
    reg [`SLBNumBus] occupied;
    reg            ls[`SLBNumBus];//0 l 1 s
    reg [`OpBus]   op[`SLBNumBus];//
    reg [`AddrBus] pc[`SLBNumBus];//todo：maybe used in predictor
    reg [`ImmBus]  imm[`SLBNumBus];//add imm when rs1/rs2 rdy
    reg [`NickBus] rs1_nick[`SLBNumBus];
    reg [`NickBus] rs2_nick[`SLBNumBus];
    reg [`DataBus] rs1_dt[`SLBNumBus];
    reg [`DataBus] rs2_dt[`SLBNumBus];
    //get fifo works/moves
    reg [`SLBNumBus] rs1_valid,rs2_valid;
    
    wire empty = &(~occupied);
    wire full = &occupied;
    wire valid = |(occupied&rs1_valid&rs2_valid);
    //
    wire [`RSBus] idx = iDP_rd_nick;
    
    integer i;
    always @(posedge clk) begin
        if (rst||clr) begin
            for (i = 0; i< `SLBNum; i = i+1) begin
                ls[i]        <= 1'b0;
                rs1_dt[i]    <= 0;
                rs2_dt[i]    <= 0;
                rs1_nick[i]  <= 0;
                rs2_nick[i]  <= 0;
                imm[i]       <= 0;
                op[i]        <= 0;
                pc[i]        <= 0;
                rs1_valid[i] <= 1'b0;
                rs2_valid[i] <= 1'b0;
            end
            occupied <= 0;
        end
        else if (rdy) begin
            oINF_full <= full;
            if (iEX_en) begin
                    for(i = 0;i<`RSNum;i = i+1) begin
                        if (occupied[i] == 1'b1) begin
                            if (rs1_valid[i] == 1'b0&&rs1_nick[i] == iEX_nick) begin
                                rs1_valid[i] <= 1'b1;
                                rs1_nick[i]  <= 0;
                                rs1_dt[i]    <= iEX_dt;
                            end
                                if (rs2_valid[i] == 1'b0&&rs2_nick[i] == iEX_nick)begin
                                    rs2_valid[i] <= 1'b1;
                                    rs2_nick[i]  <= 0;
                                    rs2_dt[i]    <= iEX_dt;
                                end
                        end
                    end
                end
                    if (iSLB_en) begin
                        for (i = 0;i<`RSNum ; i = i+1) begin
                            if (occupied[i] == 1'b1) begin
                                if (rs1_valid[i] == 1'b0&&rs1_nick[i] == iSLB_nick) begin
                                    rs1_valid[i] <= 1'b1;
                                    rs1_nick[i]  <= 0;
                                    rs1_dt[i]    <= iSLB_dt;
                                end
                                    if (rs2_valid[i] == 1'b0&&rs2_nick[i] == iSLB_nick)begin
                                        rs2_valid[i] <= 1'b1;
                                        rs2_nick[i]  <= 0;
                                        rs2_dt[i]    <= iSLB_dt;
                                    end
                            end
                        end
                    end

            if(iDC_en) begin
                oRS_en              <= 1'b1;
                oSLB_en             <= 1'b1;
                oROB_en             <= 1'b1;
                oRS_nick            <= iDC_nick;
                oSLB_nick           <= iDC_nick;
                oROB_nick           <= iDC_nick;
                oRS_dt              <= iDC_dt;
                oSLB_dt             <= iDC_dt;
                oROB_dt             <= iDC_dt;
                occupied[iDC_nick]  <= 1'b0;
                rs1_valid[iDC_nick] <= 1'b0;
                rs1_nick[iDC_nick]  <= 0;
                rs1_dt[iDC_nick]    <= 0;
                rs2_valid[iDC_nick] <= 1'b0;
                rs2_nick[iDC_nick]  <= 0;
                rs2_dt[iDC_nick]    <= 0;
                imm[iDC_nick]       <= 0;
                op[iDC_nick]        <= 0;
                pc[iDC_nick]        <= 0;
                ls[iDC_nick]        <= 0;
            end

            oDC_en <= 1'b0;
            if(valid) begin
                if(iROB_commit_en) begin
                    if(occupied[iROB_commit_nick]&&rs1_valid[iROB_commit_nick]&&rs2_valid[iROB_commit_nick])begin
                        oDC_en   <= 1'b1;
                        oDC_ls   <= `Store;
                        oDC_addr <= rs1_dt[iROB_commit_nick] + imm[iROB_commit_nick];
                        oDC_dt   <= rs2_dt[iROB_commit_nick];
                        oDC_nick <= iROB_commit_nick;
                        case (op[iROB_commit_nick])
                            `SB: oDC_len <= `One;
                            `SH:oDC_len <= `Two;
                            `SW:oDC_len <=`Four;
                            default; 
                        endcase
                        rs1_valid[iROB_commit_nick] <= 1'b0;
                        rs1_nick[iROB_commit_nick]  <= 0;
                        rs1_dt[iROB_commit_nick]    <= 0;
                        rs2_valid[iROB_commit_nick] <= 1'b0;
                        rs2_nick[iROB_commit_nick]  <= 0;
                        rs2_dt[iROB_commit_nick]    <= 0;
                        imm[iROB_commit_nick]       <= 0;
                        op[iROB_commit_nick]        <= 0;
                        pc[iROB_commit_nick]        <= 0;
                        ls[iROB_commit_nick]        <= 0;
                        occupied[iROB_commit_nick]  <= 1'b0;
                    end
                end
                else begin
                    for (i = `RSNum-1; i>=0; i = i-1 ) begin
                        if(occupied[i]&&rs1_valid[i]&&ls[i]==`Load) begin
                            oDC_en<=1'b1;
                            oDC_ls<=`Load;
                            oDC_nick<=i[`NickBus];
                            oDC_dt<=0;
                            oDC_addr<=rs1_dt[i]+imm[i];
                            case (op[i])
                                `LB,
                                `LBU:oDC_len <= `One;
                                `LH,
                                `LHU:oDC_len <= `Two;
                                `LW:oDC_len <= `Four; 
                                default; 
                            endcase
                        end
                    end
                end
            end

            if (iDP_en) begin
                case(iDP_op)
                `SB,
                `SH,
                `SW,
                `LB,
                `LBU,
                `LH,
                `LHU,
                `LW:begin
                    occupied[idx]  <= 1'b1;
                    op[idx]        <= iDP_op;
                    pc[idx]        <= iDP_pc;
                    imm[idx]       <= iDP_imm;
                    rs1_nick[idx]  <= iDP_rs1_nick;
                rs2_nick[idx]  <= iDP_rs2_nick;
                rs1_dt[idx]    <= iDP_rs1_dt;
                rs2_dt[idx]    <= iDP_rs2_dt;
                rs1_valid[idx] <= iDP_rs1_nick == 0?1'b1:1'b0;
                rs2_valid[idx] <= iDP_rs2_nick == 0?1'b1:1'b0;
                case (iDP_op)
                    `SB,
                    `SH,
                    `SW:ls[idx]      <= `Store;
                    default: ls[idx] <= `Load;
                endcase
                end
            end
        end
    end
            
endmodule
