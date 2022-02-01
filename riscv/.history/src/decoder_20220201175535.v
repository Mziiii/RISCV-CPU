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

    //regfile
    output reg            oRF_en,
    output reg [`NameBus] oRF_rs1_regnm,
    output reg [`NameBus] oDP_rs2_regnm,
    output reg [`NameBus] oDP_rd_regnm,
    output reg [`OpBus]   oDP_op,
    output reg [`AddrBus] oDP_pc,
    output reg [`ImmBus]  oDP_imm,
    output reg            oDP_pd
);
    
    wire [6:0] opcode = iINF_inst[6:0];
    wire [2:0] funct3 = iINF_inst[14:12];
    wire [3:0] funct  = {iINF_inst[30],iINF_inst[14:12]};
    
    always @(*) begin
        if (rst) begin
            oRF_en        = 1'b0;
            oDP_imm       = 0;
            oRF_rs1_regnm = 0;
            oDP_rs2_regnm = 0;
            oDP_rd_regnm  = 0;
            oDP_pd        = `NotJump;
        end
        else if(rdy && iINF_en) begin
            oDP_pc        = iINF_pc;
            oRF_en        = 1'b1;
            oRF_rs1_regnm = iINF_inst[19:15];
            oDP_rs2_regnm = iINF_inst[24:20];
            oDP_rd_regnm  = iINF_inst[11:7];
            oDP_pd        = iINF_pd;
            case (iINF_inst[6:0])
                7'b0110111,
                7'b0010111:begin
                    oDP_imm[31:12] = iINF_inst[31:12];
                end
                7'b1101111:begin
                    oDP_imm = {{12{iINF_inst[31]}},iINF_inst[19:12],iINF_inst[20],iINF_inst[30:21],1'b0};
                end
                7'b1100011:begin
                    oDP_imm = {{20{iINF_inst[31]}},iINF_inst[7],iINF_inst[30:25],iINF_inst[11:8],1'b0};
                end
                7'b1100111,
                7'b0010011,
                7'b0000011:begin
                    oDP_imm = {{21{iINF_inst[31]}},iINF_inst[30:20]};
                end
                7'b0100011:begin
                    oDP_imm = {{21{iINF_inst[31]}},iINF_inst[30:25],iINF_inst[11:7]};
                end
                default;
            endcase
            case (opcode)
                7'b0110111:begin
                    oDP_op = `LUI;
                end
                7'b0010111:begin
                    oDP_op = `AUIPC;
                end
                7'b1101111:begin
                    oDP_op = `JAL;
                end
                7'b1100111:begin
                    oDP_op = `JALR;
                end
                7'b1100011:begin
                    case (funct3)
                        3'b000:begin
                            oDP_op = `BEQ;
                        end
                        3'b001:begin
                            oDP_op = `BNE;
                        end
                        3'b100:begin
                            oDP_op = `BLT;
                        end
                        3'b101:begin
                            oDP_op = `BGE;
                        end
                        3'b110:begin
                            oDP_op = `BLTU;
                        end
                        3'b111:begin
                            oDP_op = `BGEU;
                        end
                        default:begin
                            oDP_op = `NOP;
                        end
                    endcase
                end
                7'b0000011:begin
                    case(funct3)
                        3'b000:begin
                            oDP_op = `LB;
                        end
                        3'b001:begin
                            oDP_op = `LH;
                        end
                        3'b010:begin
                            oDP_op = `LW;
                        end
                        3'b100:begin
                            oDP_op = `LBU;
                        end
                        3'b101:begin
                            oDP_op = `LHU;
                        end
                        default:begin
                            oDP_op = `NOP;
                        end
                    endcase
                end
                7'b0100011:begin
                    case(funct3)
                        3'b000:begin
                            oDP_op = `SB;
                        end
                        3'b001:begin
                            oDP_op = `SH;
                        end
                        3'b010:begin
                            oDP_op = `SW;
                        end
                        default:begin
                            oDP_op = `NOP;
                        end
                    endcase
                end
                7'b0010011:begin
                    case(funct)
                        4'b0000:begin
                            oDP_op = `ADDI;
                        end
                        4'b0010:begin
                            oDP_op = `SLTI;
                        end
                        4'b0011:begin
                            oDP_op = `SLTIU;
                        end
                        4'b0100:begin
                            oDP_op = `XORI;
                        end
                        4'b0110:begin
                            oDP_op = `ORI;
                        end
                        4'b0111:begin
                            oDP_op = `ANDI;
                        end
                        4'b0101:begin
                            oDP_op = `SRLI;
                        end
                        4'b1101:begin
                            oDP_op = `SRAI;
                        end
                        default:begin
                            oDP_op = `NOP;
                        end
                    endcase
                end
                7'b0110011:begin
                    case(funct)
                        4'b0000:begin
                            oDP_op = `ADD;
                        end
                        4'b1000:begin
                            oDP_op = `SUB;
                        end
                        4'b0001:begin
                            oDP_op = `SLL;
                        end
                        4'b0010:begin
                            oDP_op = `SLT;
                        end
                        4'b0011:begin
                            oDP_op = `SLTU;
                        end
                        4'b0100:begin
                            oDP_op = `XOR;
                        end
                        4'b0101:begin
                            oDP_op = `SRL;
                        end
                        4'b1101:begin
                            oDP_op = `SRA;
                        end
                        4'b0110:begin
                            oDP_op = `OR;
                        end
                        4'b0111:begin
                            oDP_op = `AND;
                        end
                        default:begin
                            oDP_op = `NOP;
                        end
                    endcase
                end
                default:begin
                    oDP_op = `NOP;
                end
            endcase
        end
    end
    
endmodule
