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
    //-> rs/slb/rob(cdb)
    output reg            oEX_en,
    output reg [`NickBus] oEX_nick,
    output reg [`DataBus] oEX_dt,
    //only for rob
    output reg            oEX_ac,
    output reg [`AddrBus] oEX_j_pc
);
  
    always @(posedge clk) begin
        if (rst) begin
            oEX_en <= 1'b0;
        end
        else if (rdy) begin
        
        if (iRS_en) begin
            oEX_en <= 1'b1;
            oEX_nick <= iRS_rd_nick;
            case(iRS_op)
                `LUI:begin
                    oEX_dt   <= iRS_imm;
                    oEX_ac   <= `NotJump;
                    oEX_j_pc <= iRS_pc + 4;     
                end
                `AUIPC:begin
                    oEX_dt   <= iRS_imm + iRS_pc;
                    oEX_ac   <= `NotJump;
                    oEX_j_pc <= iRS_pc + 4;     
                end
                
                `BEQ:begin
                    oEX_dt   <= 0;
                    if(iRS_rs1_dt==iRS_rs2_dt) begin
                    oEX_ac   <= `Jump;
                    oEX_j_pc <= iRS_pc + iRS_imm;
                    end else begin
                    oEX_ac   <= `NotJump;
                    oEX_j_pc <= iRS_pc + 4;     
                    end
                end
                `BNE:begin
                    oEX_dt   <= 0;
                    if(iRS_rs1_dt!=iRS_rs2_dt) begin
                    oEX_ac   <= `Jump;
                    oEX_j_pc <= iRS_pc + iRS_imm;
                end else begin
                    oEX_ac   <= `NotJump;
                    oEX_j_pc <= iRS_pc + 4;     
                    end
                end
                `BLT:begin 
                    oEX_dt   <= 0;
                    if($signed(iRS_rs1_dt)<$signed(iRS_rs2_dt)) begin
                    oEX_ac   <= `Jump;
                    oEX_j_pc <= iRS_pc + iRS_imm;
                end else begin
                    oEX_ac   <= `NotJump;
                    oEX_j_pc <= iRS_pc + 4;     
                    end
                end
                `BLTU:begin 
                    oEX_dt   <= 0;
                    if(iRS_rs1_dt<iRS_rs2_dt) begin
                    oEX_ac   <= `Jump;
                    oEX_j_pc <= iRS_pc + iRS_imm;
                end else begin
                    oEX_ac   <= `NotJump;
                    oEX_j_pc <= iRS_pc + 4;     
                    end
                end
                `BGE:begin 
                    oEX_dt   <= 0;
                    if($signed(iRS_rs1_dt)>=$signed(iRS_rs2_dt)) begin
                    oEX_ac   <= `Jump;
                    oEX_j_pc <= iRS_pc + iRS_imm;
                end else begin
                    oEX_ac   <= `NotJump;
                    oEX_j_pc <= iRS_pc + 4;     
                    end
                end
                `BGEU:begin if(iRS_rs1_dt>=iRS_rs2_dt) begin
                    oEX_ac   <= `Jump;
                    oEX_j_pc <= iRS_pc + iRS_imm;
                end else begin
                    oEX_ac   <= `NotJump;
                    oEX_j_pc <= iRS_pc + 4;     
                    end
                end
                `JALR:begin
                    oEX_ac   <= `Jump;
                    oEX_dt   <= iRS_pc + 4;
                    oEX_j_pc <= iRS_rs1_dt + iRS_imm;
                end
                `JAL:begin
                    oEX_ac   <= `Jump;
                    oEX_j_pc <= iRS_pc + 4;     
                    oEX_dt   <= iRS_pc + 4;
                end
                
                `ADDI:begin
                    oEX_dt   <= iRS_rs1_dt + iRS_imm;
                    oEX_ac   <= `NotJump;
                    oEX_j_pc <= iRS_pc + 4;     
                end
                `SLLI:begin
                    oEX_dt   <= iRS_rs1_dt << iRS_imm[5:0];
                    oEX_ac   <= `NotJump;
                    oEX_j_pc <= iRS_pc + 4;     
                end
                `SLTI:begin
                    oEX_dt   <= {{31{1'b0}},$signed(iRS_rs1_dt) < $signed(iRS_imm)};
                    oEX_ac   <= `NotJump;
                    oEX_j_pc <= iRS_pc + 4;     
                end
                `SLTIU:begin
                    oEX_dt   <= {{31{1'b0}},iRS_rs1_dt < iRS_imm};
                    oEX_ac   <= `NotJump;
                    oEX_j_pc <= iRS_pc + 4;     
                end
                `XORI:begin
                    oEX_dt   <= iRS_rs1_dt ^ iRS_imm;
                    oEX_ac   <= `NotJump;
                    oEX_j_pc <= iRS_pc + 4;     
                end
                `SRLI:begin
                    oEX_dt   <= iRS_rs1_dt >> iRS_imm[5:0];
                    oEX_ac   <= `NotJump;
                    oEX_j_pc <= iRS_pc + 4;     
                end
                `SRAI:begin
                    oEX_dt   <= $signed(iRS_rs1_dt) >> iRS_imm[5:0];
                    oEX_ac   <= `NotJump;
                    oEX_j_pc <= iRS_pc + 4;     
                end
                `ORI:begin
                    oEX_dt   <= iRS_rs1_dt | iRS_imm;
                    oEX_ac   <= `NotJump;
                    oEX_j_pc <= iRS_pc + 4;     
                end
                `ANDI:begin
                    oEX_dt   <= iRS_rs1_dt & iRS_imm;
                    oEX_ac   <= `NotJump;
                    oEX_j_pc <= iRS_pc + 4;     
                end
                
                `ADD:begin
                    oEX_dt   <= iRS_rs1_dt + iRS_rs2_dt;
                    oEX_ac   <= `NotJump;
                    oEX_j_pc <= iRS_pc + 4;     
                end
                `SUB:begin
                    oEX_dt   <= iRS_rs1_dt - iRS_rs2_dt;
                    oEX_ac   <= `NotJump;
                    oEX_j_pc <= iRS_pc + 4;     
                end
                `SLL:begin
                    oEX_dt   <= iRS_rs1_dt << iRS_rs2_dt[5:0];
                    oEX_ac   <= `NotJump;
                    oEX_j_pc <= iRS_pc + 4;     
                end
                `SLT:begin
                    oEX_dt   <= {{31{1'b0}},$signed (iRS_rs1_dt) < $signed (iRS_rs2_dt)};
                    oEX_ac   <= `NotJump;
                    oEX_j_pc <= iRS_pc + 4;     
                end
                `SLTU:begin
                    oEX_dt   <= {{31{1'b0}},iRS_rs1_dt < iRS_rs2_dt};
                    oEX_ac   <= `NotJump;
                    oEX_j_pc <= iRS_pc + 4;     
                end
                `XOR:begin
                    oEX_dt   <= iRS_rs1_dt ^ iRS_rs2_dt;
                    oEX_ac   <= `NotJump;
                    oEX_j_pc <= iRS_pc + 4;     
                end
                `SRL:begin
                    oEX_dt   <= iRS_rs1_dt >> iRS_rs2_dt[5:0];
                    oEX_ac   <= `NotJump;
                    oEX_j_pc <= iRS_pc + 4;     
                end
                `SRA:begin
                    oEX_dt   <= $signed(iRS_rs1_dt) >> iRS_rs2_dt[5:0];
                    oEX_ac   <= `NotJump;
                    oEX_j_pc <= iRS_pc + 4;     
                end
                `OR:begin
                    oEX_dt   <= iRS_rs1_dt | iRS_rs2_dt;
                    oEX_ac   <= `NotJump;
                    oEX_j_pc <= iRS_pc + 4;     
                end
                `AND:begin
                    oEX_dt   <= iRS_rs1_dt & iRS_rs2_dt;
                    oEX_ac   <= `NotJump;
                    oEX_j_pc <= iRS_pc + 4;     
                end
                default;
            endcase
        end
    end
    end
endmodule
