`include "config.v"

module rs (
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire clr,

    output reg oINF_full,
    //rob(if en can absolutely write)
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
    //from ex
    input wire            iEX_en,
    input wire [`NickBus] iEX_nick,
    input wire [`DataBus] iEX_dt,
    //from slb
    input wire            iSLB_en,
    input wire [`NickBus] iSLB_nick,
    input wire [`DataBus] iSLB_dt,

    //ex
    output reg            oEX_en,
    output reg [`AddrBus] oEX_pc,
    output reg [`OpBus]   oEX_op,
    output reg [`ImmBus]  oEX_imm,
    output reg [`NickBus] oEX_rd_nick,
    output reg [`DataBus] oEX_rs1_dt,
    output reg [`DataBus] oEX_rs2_dt
);
    //contents in rs
    reg [`RSNumBus] occupied;
    reg [`NickBus] rs1_nick[`RSNumBus],rs2_nick[`RSNumBus];
    reg [`DataBus] rs1_dt[`RSNumBus],rs2_dt[`RSNumBus];
    reg [`OpBus] op[`RSNumBus];
    reg [`AddrBus] pc[`RSNumBus];
    reg [`ImmBus] imm[`RSNumBus];
    
    //rs works
    reg [`RSNumBus] rs1_valid,rs2_valid;
    
    wire empty = &(~occupied);
    wire full  = &occupied;
    wire valid = |(occupied&rs1_valid&rs2_valid);
    //
    wire [`RSBus] idx = iDP_rd_nick;
    
    integer i;
    always @(posedge clk) begin
        if (rst||clr) begin
            for (i = 0;i<`RSNum ; i = i+1) begin
                rs1_nick[i] <= 0;
                rs2_nick[i] <= 0;
                rs1_dt[i]   <= 0;
                rs2_dt[i]   <= 0;
                op[i]       <= 0;
                pc[i]       <= 0;
                imm[i]      <= 0;
            end
            rs1_valid <= 0;
            rs2_valid <= 0;
            occupied  <= 0;
            //output
            oINF_full   <= 1'b0;
            oEX_en      <= 1'b0;
            oEX_op      <= 0;
            oEX_pc      <= 0;
            oEX_imm     <= 0;
            oEX_rd_nick <= 0;
            oEX_rs1_dt  <= 0;
            oEX_rs2_dt  <= 0;
        end
        else if (rdy) begin
            oINF_full <= full;
            if (iEX_en) begin
                for(i = 1;i < `RSNum;i = i + 1) begin
                    if (occupied[i] == 1'b1) begin
                        if (rs1_valid[i] == 1'b0 && rs1_nick[i] == iEX_nick) begin
                            rs1_valid[i] <= 1'b1;
                            rs1_nick[i]  <= 0;
                            rs1_dt[i]    <= iEX_dt;
                        end
                        if (rs2_valid[i] == 1'b0 && rs2_nick[i] == iEX_nick) begin
                            rs2_valid[i] <= 1'b1;
                                rs2_nick[i]  <= 0;
                                rs2_dt[i]    <= iEX_dt;
                        end
                    end
                end
            end
                if (iSLB_en) begin
                    for (i = 1;i < `RSNum ; i = i + 1) begin
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
                        
                    end
                    default:begin
                        occupied[idx] <= 1'b1;
                        op[idx]       <= iDP_op;
                        pc[idx]       <= iDP_pc;
                        imm[idx]      <= iDP_imm;
                        rs1_nick[idx] <= iDP_rs1_nick;
                        rs2_nick[idx] <= iDP_rs2_nick;
                        rs1_dt[idx]   <= iDP_rs1_dt;
                        rs2_dt[idx]   <= iDP_rs2_dt;
                        rs1_valid[idx]<= (iDP_rs1_nick == 0)?1'b1:1'b0;
                        rs2_valid[idx]<= (iDP_rs2_nick == 0)?1'b1:1'b0;
                    end
                endcase
            end
            
            if (valid) begin
                oEX_en <= 1'b1;
                for(i = 1;i < `RSNum;i = i + 1)begin
                    if (occupied[i]&rs1_valid[i]&rs2_valid[i])begin
                        oEX_imm     <= imm[i];
                        oEX_op      <= op[i];
                        oEX_pc      <= pc[i];
                        oEX_rd_nick <= i[`NickBus];
                        oEX_rs1_dt  <= rs1_dt[i];
                        oEX_rs2_dt  <= rs2_dt[i];
                    end
                end
                occupied[oEX_rd_nick] <= 1'b0;
            end
            else oEX_en <= 1'b0;
        end else begin
            //output
            oINF_full   <= 1'b0;
            oEX_en      <= 1'b0;
            oEX_op      <= 0;
            oEX_pc      <= 0;
            oEX_imm     <= 0;
            oEX_rd_nick <= 0;
            oEX_rs1_dt  <= 0;
            oEX_rs2_dt  <= 0;
        end
    end
endmodule
