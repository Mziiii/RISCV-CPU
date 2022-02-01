`include "config.v"

module decoder (//ind
    input wire clk,
    input wire rst,
    input wire rdy,

    //inf
    input wire            iINF_en,
    input wire [`InstBus] iINF_inst,
    input wire [`AddrBus] iINF_pc,
    input wire            iINF_pd,

    //rob ->to send 
    output reg            oROB_en,
    output reg [`NameBus] oROB_rd_regnm,

    //regfile -> to send rs1_regnick & rs2_regnick
    output reg            oRF_en,
    output reg [`NameBus] oRF_rs1_regnm,
    output reg [`NameBus] oRF_rs2_regnm,
    output reg [`NameBus] oRF_rd_regnm,
    output reg [`OpBus]   oRF_op,
    output reg [`AddrBus] oRF_pc,
    output reg [`ImmBus]  oRF_imm,
    output reg            oRF_pd
);
    
    wire [6:0] opcode = iINF_inst[6:0];
    wire [2:0] funct3 = iINF_inst[14:12];
    wire [3:0] funct  = {iINF_inst[30],iINF_inst[14:12]};
    
    always @(*) begin
        if (rst) begin
            oROB_en       = 1'b0;
            oROB_rd_regnm = 0;
            oRF_en        = 1'b0;
            oRF_imm       = 0;
            oRF_rs1_regnm = 0;
            oRF_rs2_regnm = 0;
            oRF_rd_regnm  = 0;
            oRF_pd        = `NotJump;
        end
        else if(rdy && iINF_en) begin
            oROB_en       = 1'b1;
            oRF_pc        = iINF_pc;
            oRF_en        = 1'b1;
            oRF_rs1_regnm = iINF_inst[19:15];
            oRF_rs2_regnm = iINF_inst[24:20];
            oRF_rd_regnm  = iINF_inst[11:7];
            oROB_rd_regnm = iINF_inst[11:7];
            oRF_pd        = iINF_pd;
            case (opcode)
                7'b0110111,
                7'b0010111:begin
                    oRF_imm[31:12] = iINF_inst[31:12];
                end
                7'b1101111:begin
                    oRF_imm = {{12{iINF_inst[31]}},iINF_inst[19:12],iINF_inst[20],iINF_inst[30:21],1'b0};
                end
                7'b1100011:begin
                    oRF_imm = {{20{iINF_inst[31]}},iINF_inst[7],iINF_inst[30:25],iINF_inst[11:8],1'b0};
                end
                7'b1100111,
                7'b0010011,
                7'b0000011:begin
                    oRF_imm = {{21{iINF_inst[31]}},iINF_inst[30:20]};
                end
                7'b0100011:begin
                    oRF_imm = {{21{iINF_inst[31]}},iINF_inst[30:25],iINF_inst[11:7]};
                end
                default;
            endcase
            case (opcode)
                7'b0110111:begin
                    oRF_op = `LUI;
                end
                7'b0010111:begin
                    oRF_op = `AUIPC;
                end
                7'b1101111:begin
                    oRF_op = `JAL;
                end
                7'b1100111:begin
                    oRF_op = `JALR;
                end
                7'b1100011:begin
                    case (funct3)
                        3'b000:begin
                            oRF_op = `BEQ;
                        end
                        3'b001:begin
                            oRF_op = `BNE;
                        end
                        3'b100:begin
                            oRF_op = `BLT;
                        end
                        3'b101:begin
                            oRF_op = `BGE;
                        end
                        3'b110:begin
                            oRF_op = `BLTU;
                        end
                        3'b111:begin
                            oRF_op = `BGEU;
                        end
                        default:begin
                            oRF_op = `NOP;
                        end
                    endcase
                end
                7'b0000011:begin
                    case(funct3)
                        3'b000:begin
                            oRF_op = `LB;
                        end
                        3'b001:begin
                            oRF_op = `LH;
                        end
                        3'b010:begin
                            oRF_op = `LW;
                        end
                        3'b100:begin
                            oRF_op = `LBU;
                        end
                        3'b101:begin
                            oRF_op = `LHU;
                        end
                        default:begin
                            oRF_op = `NOP;
                        end
                    endcase
                end
                7'b0100011:begin
                    case(funct3)
                        3'b000:begin
                            oRF_op = `SB;
                        end
                        3'b001:begin
                            oRF_op = `SH;
                        end
                        3'b010:begin
                            oRF_op = `SW;
                        end
                        default:begin
                            oRF_op = `NOP;
                        end
                    endcase
                end
                7'b0010011:begin
                    case(funct)
                        4'b0000,
                        4'b1000:begin
                            oRF_op = `ADDI;
                        end
                        4'b0010,
                        4'b1010:begin
                            oRF_op = `SLTI;
                        end
                        4'b0011,
                        4'b1011:begin
                            oRF_op = `SLTIU;
                        end
                        4'b0100,
                        4'b1100:begin
                            oRF_op = `XORI;
                        end
                        4'b0110,
                        4'b1110:begin
                            oRF_op = `ORI;
                        end
                        4'b0111,
                        4'b1111:begin
                            oRF_op = `ANDI;
                        end
                        4'b0001:begin
                            oRF_op = `SLLI;
                        end
                        4'b0101:begin
                            oRF_op = `SRLI;
                        end
                        4'b1101:begin
                            oRF_op = `SRAI;
                        end
                    endcase
                end
                7'b0110011:begin
                    case(funct)
                        4'b0000:begin
                            oRF_op = `ADD;
                        end
                        4'b1000:begin
                            oRF_op = `SUB;
                        end
                        4'b0001:begin
                            oRF_op = `SLL;
                        end
                        4'b0010:begin
                            oRF_op = `SLT;
                        end
                        4'b0011:begin
                            oRF_op = `SLTU;
                        end
                        4'b0100:begin
                            oRF_op = `XOR;
                        end
                        4'b0101:begin
                            oRF_op = `SRL;
                        end
                        4'b1101:begin
                            oRF_op = `SRA;
                        end
                        4'b0110:begin
                            oRF_op = `OR;
                        end
                        4'b0111:begin
                            oRF_op = `AND;
                        end
                        default:begin
                            oRF_op = `NOP;
                        end
                    endcase
                end
                default:begin
                    oRF_op = `NOP;
                end
            endcase
        end else begin
            oRF_en = 1'b0;
        end
    end
    
endmodule
