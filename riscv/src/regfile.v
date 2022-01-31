`include "config.v"

module regfile(
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire clr,

    input wire            iDP_en,
    input wire [`NameBus] iDP_rs1_regnm,
    input wire [`NameBus] iDP_rs2_regnm,
    output reg [`NickBus] oDP_rs1_nick,
    output reg [`NickBus] oDP_rs2_nick,
    output reg [`DataBus] oDP_rs1_dt,
    output reg [`DataBus] oDP_rs2_dt,

    //rob
    input wire            iROB_en,
    input wire [`NameBus] iROB_rd_regnm,
    input wire [`DataBus] iROB_rd_dt,
    input wire [`NickBus] iROB_rd_nick
);
    
    reg [`DataBus] reg_dt[`RegNumBus];
    reg [`NickBus] reg_nick[`RegNumBus];

//todo:debug!
    wire [`DataBus] sp_reg_data=reg_dt[2];
    wire [`DataBus] a4_reg_data=reg_dt[14];
    wire [`DataBus] a5_reg_data=reg_dt[15];
    wire [`NickBus] sp_reg_nick=reg_nick[2];
    wire [`NickBus] a4_reg_nick=reg_nick[14];
    wire [`NickBus] a5_reg_nick=reg_nick[15];
    
    integer i;

    always @(*) begin
        if(rst) begin
            oDP_rs1_dt = 0;
            oDP_rs2_dt = 0;
            oDP_rs1_nick = 0;
            oDP_rs2_nick = 0;
        end else if(rdy) begin
            if(iDP_en) begin
                oDP_rs1_dt   = reg_dt[iDP_rs1_regnm];
                oDP_rs2_dt   = reg_dt[iDP_rs2_regnm];
                oDP_rs1_nick = reg_nick[iDP_rs1_regnm];
                oDP_rs2_nick = reg_nick[iDP_rs2_regnm];
            end else begin
                oDP_rs1_dt = 0;
                oDP_rs2_dt = 0;
                oDP_rs1_nick = 0;
                oDP_rs2_nick = 0;
            end
        end else begin
            oDP_rs1_dt = 0;
            oDP_rs2_dt = 0;
            oDP_rs1_nick = 0;
            oDP_rs2_nick = 0;
        end
    end

    always @(*) begin
        if (rst) begin
            for (i = 0 ;i<`RegNum ;i = i+1) begin
                reg_dt[i]   = 0;
                reg_nick[i] = 0;
            end
        end
        else if (clr) begin
            reg_dt[iROB_rd_regnm] = iROB_rd_dt;
            for (i = 0 ;i<`RegNum ;i = i+1) begin
                reg_nick[i] = 0;
            end
        end
        else if (rdy) 
            begin
            if (iROB_en) begin
                if (reg_nick[iROB_rd_regnm] == iROB_rd_nick) begin
                    reg_nick[iROB_rd_regnm] = 0;
                    reg_dt[iROB_rd_regnm]   = iROB_rd_dt;
                end
            end
        end
    end
endmodule
