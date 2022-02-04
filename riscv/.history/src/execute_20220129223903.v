`include "config.v"

module execute (   
    input wire clk,
    input wire rst,
    input wire rdy,

    //rs
    input wire            iRS_en,
    input wire [`AddrBus] iRS_pc,
    input wire [`OpBus]   iRS_op,
    input wire [`ImmBus]  iRS_imm,
    input wire [`NickBus] iRS_rd_nick,
    input wire [`DataBus] iRS_rs1_dt,
    input wire [`DataBus] iRS_rs2_dt,

    //check update
    //-> rs
    output reg            oRS_en,
    output reg [`NickBus] oRS_nick,
    output reg [`DataBus] oRS_dt,
    //-> slb
    output reg            oSLB_en,
    output reg [`NickBus] oSLB_nick,
    output reg [`DataBus] oSLB_dt,
    //-> rob
    output reg            oROB_en,
    output reg [`NickBus] oROB_nick,
    output reg [`DataBus] oROB_dt,
    output reg            oROB_ac,
    output reg [`AddrBus] oROB_j_pc
);
  
    always @(posedge clk) begin
        if (rst) begin
            oRS_en <= 1'b0;
            oROB_en <= 1'b0;
            oSLB_en <= 1'b0;
        end
        else if (rdy) begin
        
        if (iRS_en) begin
            oRS_en  <= 1'b1;
            oSLB_en <= 1'b1;
            oROB_en <= 1'b1;
            oRS_nick  <= iRS_rd_nick;
            oSLB_nick <= iRS_rd_nick;
            oROB_nick <= iRS_rd_nick;
            case(iRS_op)
                `LUI:begin
                    oRS_dt    <= iRS_imm;
                    oROB_dt   <= iRS_imm;
                    oSLB_dt   <= iRS_imm;
                    oROB_ac   <= `NotJump;
                end
                `AUIPC:begin
                    oRS_dt    <= iRS_imm + iRS_pc;
                    oROB_dt   <= iRS_imm + iRS_pc;
                    oSLB_dt   <= iRS_imm + iRS_pc;
                    oROB_ac   <= `NotJump;
                end
                
                `BEQ:if(iRS_rs1_dt==iRS_rs2_dt) begin
                    oROB_ac   <= `Jump;
                    oROB_j_pc <= iRS_pc + iRS_imm;
                end
                `BNE:if(iRS_rs1_dt!=iRS_rs2_dt) begin
                    oROB_ac   <= `Jump;
                    oROB_j_pc <= iRS_pc + iRS_imm;
                end
                `BLT:if($signed(iRS_rs1_dt)<$signed(iRS_rs2_dt)) begin
                    oROB_ac   <= `Jump;
                    oROB_j_pc <= iRS_pc + iRS_imm;
                end
                `BLTU:if(iRS_rs1_dt<iRS_rs2_dt) begin
                    oROB_ac   <= `Jump;
                    oROB_j_pc <= iRS_pc + iRS_imm;
                end
                `BGE:if($signed(iRS_rs1_dt)>=$signed(iRS_rs2_dt)) begin
                    oROB_ac   <= `Jump;
                    oROB_j_pc <= iRS_pc + iRS_imm;
                end
                `BGEU:if(iRS_rs1_dt>=iRS_rs2_dt) begin
                    oROB_ac   <= `Jump;
                    oROB_j_pc <= iRS_pc + iRS_imm;
                end
                `JALR:begin
                    oROB_ac   <= `Jump;
                    oRS_dt    <= iRS_pc + 4;
                    oROB_dt   <= iRS_pc + 4;
                    oSLB_dt   <= iRS_pc + 4;
                    oROB_j_pc <= iRS_rs1_dt + iRS_imm;
                end
                `JAL:begin
                    oROB_ac  <= `Jump;
                    oRS_dt    <= iRS_pc + 4;
                    oROB_dt   <= iRS_pc + 4;
                    oSLB_dt   <= iRS_pc + 4;
                end
                
                `ADDI:begin
                    oRS_dt    <= iRS_rs1_dt + iRS_imm;
                    oROB_dt   <= iRS_rs1_dt + iRS_imm;
                    oSLB_dt   <= iRS_rs1_dt + iRS_imm;
                    oROB_ac   <= `NotJump;
                end
                `SLLI:begin
                    oRS_dt    <= iRS_rs1_dt << iRS_imm[5:0];
                    oROB_dt   <= iRS_rs1_dt << iRS_imm[5:0];
                    oSLB_dt   <= iRS_rs1_dt << iRS_imm[5:0];
                    oROB_ac   <= `NotJump;
                end
                `SLTI:begin
                    oRS_dt    <= {{31{1'b0}},$signed(iRS_rs1_dt) < $signed(iRS_imm)};
                    oROB_dt   <= {{31{1'b0}},$signed(iRS_rs1_dt) < $signed(iRS_imm)};
                    oSLB_dt   <= {{31{1'b0}},$signed(iRS_rs1_dt) < $signed(iRS_imm)};
                    oROB_ac   <= `NotJump;
                end
                `SLTIU:begin
                    oRS_dt    <= {{31{1'b0}},iRS_rs1_dt < iRS_imm};
                    oROB_dt   <= {{31{1'b0}},iRS_rs1_dt < iRS_imm};
                    oSLB_dt   <= {{31{1'b0}},iRS_rs1_dt < iRS_imm};
                    oROB_ac   <= `NotJump;
                end
                `XORI:begin
                    oRS_dt    <= iRS_rs1_dt ^ iRS_imm;
                    oROB_dt   <= iRS_rs1_dt ^ iRS_imm;
                    oSLB_dt   <= iRS_rs1_dt ^ iRS_imm;
                    oROB_ac   <= `NotJump;
                end
                `SRLI:begin
                    oRS_dt    <= iRS_rs1_dt >> iRS_imm[5:0];
                    oROB_dt   <= iRS_rs1_dt >> iRS_imm[5:0];
                    oSLB_dt   <= iRS_rs1_dt >> iRS_imm[5:0];
                    oROB_ac   <= `NotJump;
                end
                `SRAI:begin
                    oRS_dt    <= $signed(iRS_rs1_dt) >> iRS_imm[5:0];
                    oROB_dt   <= $signed(iRS_rs1_dt) >> iRS_imm[5:0];
                    oSLB_dt   <= $signed(iRS_rs1_dt) >> iRS_imm[5:0];
                    oROB_ac   <= `NotJump;
                end
                `ORI:begin
                    oRS_dt    <= iRS_rs1_dt | iRS_imm;
                    oROB_dt   <= iRS_rs1_dt | iRS_imm;
                    oSLB_dt   <= iRS_rs1_dt | iRS_imm;
                    oROB_ac   <= `NotJump;
                end
                `ANDI:begin
                    oRS_dt    <= iRS_rs1_dt & iRS_imm;
                    oROB_dt   <= iRS_rs1_dt & iRS_imm;
                    oSLB_dt   <= iRS_rs1_dt & iRS_imm;
                    oROB_ac   <= `NotJump;
                end
                
                `ADD:begin
                    oRS_dt    <= iRS_rs1_dt + iRS_rs2_dt;
                    oROB_dt   <= iRS_rs1_dt + iRS_rs2_dt;
                    oSLB_dt   <= iRS_rs1_dt + iRS_rs2_dt;
                    oROB_ac   <= `NotJump;
                end
                `SUB:begin
                    oRS_dt    <= iRS_rs1_dt - iRS_rs2_dt;
                    oROB_dt   <= iRS_rs1_dt - iRS_rs2_dt;
                    oSLB_dt   <= iRS_rs1_dt - iRS_rs2_dt;
                    oROB_ac   <= `NotJump;
                end
                `SLL:begin
                    oRS_dt    <= iRS_rs1_dt << iRS_rs2_dt[5:0];
                    oROB_dt   <= iRS_rs1_dt << iRS_rs2_dt[5:0];
                    oSLB_dt   <= iRS_rs1_dt << iRS_rs2_dt[5:0];
                    oROB_ac   <= `NotJump;
                end
                `SLT:begin
                    oRS_dt    <= {{31{1'b0}},$signed (iRS_rs1_dt) < $signed (iRS_rs2_dt)};
                    oROB_dt   <= {{31{1'b0}},$signed (iRS_rs1_dt) < $signed (iRS_rs2_dt)};
                    oSLB_dt   <= {{31{1'b0}},$signed (iRS_rs1_dt) < $signed (iRS_rs2_dt)};
                    oROB_ac   <= `NotJump;
                end
                `SLTU:begin
                    oRS_dt    <= {{31{1'b0}},iRS_rs1_dt < iRS_rs2_dt};
                    oROB_dt   <= {{31{1'b0}},iRS_rs1_dt < iRS_rs2_dt};
                    oSLB_dt   <= {{31{1'b0}},iRS_rs1_dt < iRS_rs2_dt};
                    oROB_ac   <= `NotJump;
                end
                `XOR:begin
                    oRS_dt    <= iRS_rs1_dt ^ iRS_rs2_dt;
                    oROB_dt   <= iRS_rs1_dt ^ iRS_rs2_dt;
                    oSLB_dt   <= iRS_rs1_dt ^ iRS_rs2_dt;
                    oROB_ac   <= `NotJump;
                end
                `SRL:begin
                    oRS_dt    <= iRS_rs1_dt >> iRS_rs2_dt[5:0];
                    oROB_dt   <= iRS_rs1_dt >> iRS_rs2_dt[5:0];
                    oSLB_dt   <= iRS_rs1_dt >> iRS_rs2_dt[5:0];
                    oROB_ac   <= `NotJump;
                end
                `SRA:begin
                    oRS_dt    <= $signed(iRS_rs1_dt) >> iRS_rs2_dt[5:0];
                    oROB_dt   <= $signed(iRS_rs1_dt) >> iRS_rs2_dt[5:0];
                    oSLB_dt   <= $signed(iRS_rs1_dt) >> iRS_rs2_dt[5:0];
                    oROB_ac   <= `NotJump;
                end
                `OR:begin
                    oRS_dt    <= iRS_rs1_dt | iRS_rs2_dt;
                    oROB_dt   <= iRS_rs1_dt | iRS_rs2_dt;
                    oSLB_dt   <= iRS_rs1_dt | iRS_rs2_dt;
                    oROB_ac   <= `NotJump;
                end
                `AND:begin
                    oRS_dt    <= iRS_rs1_dt & iRS_rs2_dt;
                    oROB_dt   <= iRS_rs1_dt & iRS_rs2_dt;
                    oSLB_dt   <= iRS_rs1_dt & iRS_rs2_dt;
                    oROB_ac   <= `NotJump;
                end
                default;
            endcase
        end
    end
    end
endmodule
