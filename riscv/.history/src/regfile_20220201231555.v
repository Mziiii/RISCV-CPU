`include "config.v"

module regfile(
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire clr,

    input wire            iIND_en,
    input wire [`NameBus] iIND_rs1_regnm,
    input wire [`NameBus] iIND_rs2_regnm,
    output reg [`NickBus] oDP_rs1_nick,
    output reg [`NickBus] oDP_rs2_nick,
    output reg [`DataBus] oDP_rs1_dt,
    output reg [`DataBus] oDP_rs2_dt,
    //when iIND_en they can be taken to dispatch as well
    input wire [`NameBus] iIND_rd_regnm,
    input wire [`OpBus]   iIND_op,
    input wire [`AddrBus] iIND_pc,
    input wire [`ImmBus]  iIND_imm,
    input wire            iIND_pd,
    output reg            oDP_en,
    output reg [`NameBus] oDP_rd_regnm,
    output reg [`OpBus]   oDP_op,
    output reg [`AddrBus] oDP_pc,
    output reg [`ImmBus]  oDP_imm,
    output reg            oDP_pd,

    //in the progress of dispatch
    input wire            iROB_nick_en,
    input wire [`NameBus] iROB_nick_regnm,
    input wire [`NickBus] iROB_nick,   

    //in the progress of commit
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
    wire [`DataBus] ra_reg_data=reg_dt[1];
    wire [`NickBus] ra_reg_nick=reg_nick[1];
    
    integer i;

    always @(*) begin
        if(rst) begin
            oDP_en       = 1'b0;
            oDP_rs1_dt   = 0;
            oDP_rs2_dt   = 0;
            oDP_rs1_nick = 0;
            oDP_rs2_nick = 0;
            oDP_imm      = 0;
            oDP_op       = 0;
            oDP_pc       = 0;
            oDP_pd       = 0;
            oDP_rd_regnm = 0;
        end else if(rdy) begin
            
        end else begin
            oDP_en       = 1'b0;
            oDP_rs1_dt   = 0;
            oDP_rs2_dt   = 0;
            oDP_rs1_nick = 0;
            oDP_rs2_nick = 0;
            oDP_imm      = 0;
            oDP_op       = 0;
            oDP_pc       = 0;
            oDP_pd       = 0;
            oDP_rd_regnm = 0;
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
            if (iROB_nick_en) begin
                reg_nick[iROB_nick_regnm] = iROB_nick;
            end
        end
    end
endmodule
