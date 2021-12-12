`include "config.v"

module ex (   
    input wire clk,
    input wire rst,
    input wire rdy,

    //rs
    input wire iRS_en,
    input wire [`AddrBus] iRS_pc,
    input wire [`OpBus] iRS_op,
    input wire [`ImmBus] iRS_imm,
    input wire [`NickBus] iRS_rd_nick,
    input wire [`DataBus] iRS_rs1_dt,
    input wire [`DataBus] iRS_rs2_dt,

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
    output wire            oROB_isBJ,
    output wire [`AddrBus] oROB_j_pc
);
    
    reg [`DataBus] dt;
    reg [`NickBus] nick;
    reg en;
    reg [`AddrBus] pc;
    reg has_j;
    assign oROB_dt   = dt;
    assign oSLB_dt   = dt;
    assign oRS_dt    = dt;
    assign oROB_j_pc = pc;
    assign oRS_en    = en;
    assign oROB_en   = en;
    assign oSLB_en   = en;
    assign oRS_nick  = iRS_rd_nick;
    assign oSLB_nick = iRS_rd_nick;
    assign oROB_nick = iRS_rd_nick;
    assign oROB_isBJ = has_j;
    
    always @(*) begin
        has_j = 0;
        if (rst) ;
        else if (rdy) begin
        
        if (iRS_en) begin
            en = 1'b1;
            case(iRS_op)
                `LUI:dt   = iRS_imm;
                `AUIPC:dt = iRS_imm + iRS_pc;
                
                `BEQ:if(iRS_rs1_dt==iRS_rs2_dt) has_j = 1;
                `BNE:if(iRS_rs1_dt!=iRS_rs2_dt) has_j = 1;
                `BLT:if($signed(iRS_rs1_dt)<$signed(iRS_rs2_dt)) has_j = 1;
                `BLTU:if(iRS_rs1_dt<iRS_rs2_dt) has_j = 1;
                `BGE:if($signed(iRS_rs1_dt)>=$signed(iRS_rs2_dt)) has_j = 1;
                `BGEU:if(iRS_rs1_dt>=iRS_rs2_dt) has_j = 1;
                `JALR:begin
                    dt = iRS_pc+4;
                    pc = iRS_rs1_dt + iRS_imm;
                end
                
                `ADDI:dt  = iRS_rs1_dt + iRS_imm;
                `SLLI:dt  = iRS_rs1_dt << iRS_imm[5:0];
                `SLTI:dt  = {{31{1'b0}},$signed(iRS_rs1_dt) < $signed(iRS_imm)};
                `SLTIU:dt = {{31{1'b0}},iRS_rs1_dt < iRS_imm};
                `XORI:dt  = iRS_rs1_dt ^ iRS_imm;
                `SRLI:dt  = iRS_rs1_dt >> iRS_imm[5:0];
                `SRAI:dt  = $signed(iRS_rs1_dt) >> iRS_imm[5:0];
                `ORI:dt   = iRS_rs1_dt | iRS_imm;
                `ANDI:dt  = iRS_rs1_dt & iRS_imm;
                
                `ADD:dt  = iRS_rs1_dt + iRS_rs2_dt;
                `SUB:dt  = iRS_rs1_dt - iRS_rs2_dt;
                `SLL:dt  = iRS_rs1_dt << iRS_rs2_dt[5:0];
                `SLT:dt  = {{31{1'b0}},$signed (iRS_rs1_dt) < $signed (iRS_rs2_dt)};
                `SLTU:dt = {{31{1'b0}},iRS_rs1_dt < iRS_rs2_dt};
                `XOR:dt  = iRS_rs1_dt ^ iRS_rs2_dt;
                `SRL:dt  = iRS_rs1_dt >> iRS_rs2_dt[5:0];
                `SRA:dt  = $signed(iRS_rs1_dt) >> iRS_rs2_dt[5:0];
                `OR:dt   = iRS_rs1_dt | iRS_rs2_dt;
                `AND:dt  = iRS_rs1_dt & iRS_rs2_dt;
                default;
            endcase
            if (has_j) begin
                pc = iRS_pc+iRS_imm;
            end
            if (iRS_op == `JALR) has_j = 1;
        end
    end
    end
endmodule
