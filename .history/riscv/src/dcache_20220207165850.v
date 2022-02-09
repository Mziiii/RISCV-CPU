`include "config.v"

module dcache (
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire clr,

    //memctrl
    input wire            iMC_done,
    input wire [`DataBus] iMC_dt,
    
    output reg            oMC_en,
    output reg            oMC_ls,
    output reg [`AddrBus] oMC_pc,
    output reg [`DataBus] oMC_dt,
    output reg [`LenBus]  oMC_len,

    output reg            oSLB_en,
    //slb
    input wire            iSLB_en,
    input wire            iSLB_ls,
    input wire [`AddrBus] iSLB_pc,
    input wire [`DataBus] iSLB_dt,
    input wire [`LenBus]  iSLB_len,
    input wire [`NickBus] iSLB_nick,
    input wire [`OpBus]   iSLB_op,
    output reg            oSLB_done,
    output reg [`DataBus] oSLB_dt,
    output reg [`NickBus] oSLB_nick
);
reg [`NickBus] nick;
reg occupied;
reg ls;
reg [`AddrBus] pc;
reg [`DataBus] dt;
reg [`LenBus] len;
reg [`OpBus] op;

    always @(*) begin
        if(rst||clr) begin
            oSLB_en = 1'b1;
        end else if(rdy) begin
            oSLB_en = ~occupied;
        end else begin
            oSLB_en = 1'b0;
        end
    end
    
    always @(*) begin
        if(rst||clr) begin
            oMC_en    = 1'b0;
            oMC_pc    = 0;
            oMC_ls    = 1'b0;
            oMC_len   = 0;
            oMC_dt    = 0;
        end else if(rdy) begin
            if(occupied) begin
                oMC_en = 1'b1;
                oMC_dt = dt;
                oMC_len = len;
                oMC_pc = pc;
                oMC_ls = ls;
            end else begin
                oMC_en = 1'b0;
            end
        end
    end

    always @(*) begin
        if(rst||clr) begin
            oSLB_done = 1'b0;
            oSLB_dt   = 0;
            oSLB_nick = 0;  
        end else if(rdy) begin
            if (iMC_done) begin
                oSLB_done = 1'b1;
                case (op)
                `LBU: oSLB_dt = {{24{1'b0}},iMC_dt[7:0]};
                `LB: oSLB_dt = {{24{iMC_dt[7]}},iMC_dt[7:0]};
                `LHU: oSLB_dt = {{16{1'b0}},iMC_dt[15:0]};
                `LH: oSLB_dt = {{16{iMC_dt[7]}},iMC_dt[15:0]};
                `LW: oSLB_dt = iMC_dt;
                default: oSLB_dt = iMC_dt;
                endcase
                oSLB_nick = nick;
            end 
            else begin
                oSLB_done = 1'b0;
                oSLB_dt   = 0;
                oSLB_nick = 0;
            end
        end
    end

    always @(posedge clk) begin
        if (rst||clr) begin
            nick      <= 0;
            occupied  <= 1'b0;
            ls        <= 1'b0;
            len       <= 0;
            pc        <= 0;
            dt        <= 0;
            op        <= 0;
        end
        else if (rdy) begin
            if (iMC_done) begin
                occupied  <= 1'b0;
                nick      <= 0;
                ls        <= 1'b0;
                len       <= 0;
                pc        <= 0;
                dt        <= 0;
                op        <= 0;
            end 

            if (iSLB_en) begin
                ls   <= iSLB_ls;
                len  <= iSLB_len;
                pc   <= iSLB_pc;
                dt   <= iSLB_dt;
                nick <= iSLB_nick;
                op   <= iSLB_op;
                occupied <= 1'b1;
            end
        end
    end
            
endmodule
