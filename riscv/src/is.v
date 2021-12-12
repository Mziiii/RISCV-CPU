`include "config.v"

module is (
    input wire clk,
    input wire rst,
    input wire rdy,

    //inf
    input wire            iINF_en,
    input wire [`InstBus] iINF_inst,
    input wire [`AddrBus] iINF_pc,

    //regfile
    output reg             oREG_en,
    output wire [`NameBus] oREG_rs1_regnm,
    output wire [`NameBus] oREG_rs2_regnm,
    output wire [`NameBus] oREG_rd_regnm,
    output wire [`OpBus]   oREG_op,
    output wire [`AddrBus] oREG_pc,
    output wire [`ImmBus]  oREG_imm,

    //rs
    output reg             oRS_en,
    output wire [`OpBus]   oRS_op,
    output wire [`AddrBus] oRS_pc,
    output wire [`ImmBus]  oRS_imm,

    //rob
    output reg             oROB_en,
    output wire [`NameBus] oROB_rd_regnm,
    output wire [`AddrBus] oROB_pc
);
    
    //save
    reg [`OpBus]   m_op;
    reg [`NameBus] m_rs1,m_rs2,m_rd;
    reg [`ImmBus]  m_imm;
    
    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [3:0] funct;
    wire stall;
    
    assign opcode = iINF_inst[6:0];
    assign funct3 = iINF_inst[14:12];
    assign funct  = {iINF_inst[30],iINF_inst[14:12]};
    assign stall  = rst || !rdy || !iINF_en;
    
    assign oREG_op        = m_op;
    assign oRS_op         = m_op;
    assign oREG_pc        = iINF_pc;
    assign oROB_pc        = iINF_pc;
    assign oRS_pc         = iINF_pc;
    assign oREG_rs1_regnm = m_rs1;
    assign oREG_rs2_regnm = m_rs2;
    assign oREG_rd_regnm  = m_rd;
    assign oROB_rd_regnm  = m_rd;
    assign oRS_imm        = m_imm;
    assign oREG_imm       = m_imm;
    
    
    always @(posedge clk) begin
        if (stall) begin
            oREG_en <= 1'b0;
            oROB_en <= 1'b0;
            oRS_en  <= 1'b0;
            m_imm   <= 0;
            m_rs1   <= 0;
            m_rs2   <= 0;
            m_rd    <= 0;
        end
        else begin
            oREG_en <= 1'b1;
            oROB_en <= 1'b1;
            oRS_en  <= 1'b1;
            m_rs1   <= iINF_inst[19:15];
            m_rs2   <= iINF_inst[24:20];
            m_rd    <= iINF_inst[11:7];
            case (opcode)
                7'b0110111,
                7'b0010111:begin
                    m_imm[31:12] <= iINF_inst[31:12];
                end
                7'b1101111:begin
                    m_imm <= {{12{iINF_inst[31]}},iINF_inst[19:12],iINF_inst[20],iINF_inst[30:21],1'b0};
                end
                7'b1100011:begin
                    m_imm <= {{20{iINF_inst[31]}},iINF_inst[7],iINF_inst[30:25],iINF_inst[11:8],1'b0};
                end
                7'b1100111,
                7'b0010011,
                7'b0000011:begin
                    m_imm <= {{21{iINF_inst[31]}},iINF_inst[30:20]};
                end
                7'b0100011:begin
                    m_imm <= {{21{iINF_inst[31]}},iINF_inst[30:25],iINF_inst[11:7]};
                end
                default;
            endcase
            case (opcode)
                7'b0110111:begin
                    m_op <= `LUI;
                end
                7'b0010111:begin
                    m_op <= `AUIPC;
                end
                7'b1101111:begin
                    m_op <= `JAL;
                end
                7'b1100111:begin
                    m_op <= `JALR;
                end
                7'b1100011:begin
                    case (funct3)
                        3'b000:m_op  <= `BEQ;
                        3'b001:m_op  <= `BNE;
                        3'b100:m_op  <= `BLT;
                        3'b101:m_op  <= `BGE;
                        3'b110:m_op  <= `BLTU;
                        3'b111:m_op  <= `BGEU;
                        default:m_op <= `NOP;
                    endcase
                end
                7'b0000011:begin
                    case(funct3)
                        3'b000:m_op  <= `LB;
                        3'b001:m_op  <= `LH;
                        3'b010:m_op  <= `LW;
                        3'b100:m_op  <= `LBU;
                        3'b101:m_op  <= `LHU;
                        default:m_op <= `NOP;
                    endcase
                end
                7'b0100011:begin
                    case(funct3)
                        3'b000:m_op  <= `SB;
                        3'b001:m_op  <= `SH;
                        3'b010:m_op  <= `SW;
                        default:m_op <= `NOP;
                    endcase
                end
                7'b0010011:begin
                    case(funct)
                        4'b0000:m_op <= `ADDI;
                        4'b0010:m_op <= `SLTI;
                        4'b0011:m_op <= `SLTIU;
                        4'b0100:m_op <= `XORI;
                        4'b0110:m_op <= `ORI;
                        4'b0111:m_op <= `ANDI;
                        4'b0101:m_op <= `SRLI;
                        4'b1101:m_op <= `SRAI;
                        default:m_op <= `NOP;
                    endcase
                end
                7'b0110011:begin
                    case(funct)
                        4'b0000:m_op <= `ADD;
                        4'b1000:m_op <= `SUB;
                        4'b0001:m_op <= `SLL;
                        4'b0010:m_op <= `SLT;
                        4'b0011:m_op <= `SLTU;
                        4'b0100:m_op <= `XOR;
                        4'b0101:m_op <= `SRL;
                        4'b1101:m_op <= `SRA;
                        4'b0110:m_op <= `OR;
                        4'b0111:m_op <= `AND;
                        default:m_op <= `NOP;
                    endcase
                end
                default:begin
                    m_op <= `NOP;
                end
            endcase
        end
    end
    
endmodule
