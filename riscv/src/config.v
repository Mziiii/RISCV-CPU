`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Gabriel
//
// Create Date: 10/24/2019 11:41:47 PM
// Design Name:
// Module Name: config
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
//todo:delete extra ones

`define ZERO_WORD 32'h00000000
`define ONE_WORD  32'hffffffff
`define NEXT_PC   32'h00000004

`define InstLen    32
`define AddrLen    32
`define RegAddrLen 5
`define RegLen     32
`define RegNum     32

//ram
`define MemAddrBus 16:0
`define MemDataBus 7:0
`define DataC      1'b1
`define InstC      1'b0
`define Write      1'b1
`define Read       1'b0
//reg
`define RegNumBus `RegNum-1:0

//iCahche
`define ICacheNum    9
`define ICacheNumBus `ICacheNum-1:0 
`define ICacheBus    2**`ICacheNum-1:0
`define ICacheIdxBus 10:2
`define ICacheTagBus 17:11
`define ICacheTag    6:0

//Rob
`define RobNum     32 //NickBus
`define RobBus     `RobNum-1:0

//Bus
`define InstBus    31:0
`define AddrBus    31:0
`define RegAddrBus 4:0
`define RegBus     31:0

`define DataBus    31:0
`define ImmBus     31:0
`define NameBus    4:0 //RegName
`define NickBus    4:0 //RegNickName

//inf
`define FIFOBus 4:0
`define FIFOLen 32

//slb
`define SLBNum 32 // the same with ROB to avoid full:)
`define SLBNumBus `SLBNum-1:0
`define SLBBus 4:0
`define LenBus 2:0 //store & load W/H/B...->1/2/4
`define Store 1'b1
`define Load  1'b0

//rs 
`define RSNum 32 // the same with ROB to avoid full:)
`define RSNumBus `RSNum-1:0
`define RSBus 4:0

//regfile 
`define VALID 1'b1
`define INVALID 1'b0

`define ResetEnable  1'b1
`define ResetDisable 1'b0
`define ChipEnable   1'b1
`define ChipDisable  1'b0
`define WriteEnable  1'b1
`define WriteDisable 1'b0
`define ReadEnable   1'b1
`define ReadDisable  1'b0

`define RAM_SIZE 100
`define RAM_SIZELOG2 17

//OPCODE
`define OpLen      7
`define INST_LUI   7'b0110111
`define INST_AUIPC 7'b0010111
`define INST_JAL   7'b1101111
`define INST_JAIR  7'b1100111
`define INST_BOP   7'b1100011
`define INST_LOP   7'b0000011
`define INST_SOP   7'b0100011
`define INST_IOP   7'b0010011
`define INST_ROP   7'b0110011

//BOP
`define BOpLen      3
`define INST_BEQ    3'b000
`define INST_BNE    3'b001
`define INST_BLT    3'b100
`define INST_BGE    3'b101
`define INST_BLTU   3'b110
`define INST_BGEU   3'b111

//LOP
`define LOpLen      3
`define INST_LB     3'b000
`define INST_LH     3'b001
`define INST_LW     3'b010
`define INST_LBU    3'b100
`define INST_LHU    3'b101

//SOP
`define SOpLen      3
`define INST_SB     3'b000
`define INST_SH     3'b001
`define INST_SW     3'b010

//IOP
`define IOpLen      4
`define INST_ADDI   4'b0000
`define INST_SLTI   4'b0010
`define INST_SLTIU  4'b0011
`define INST_XORI   4'b0100
`define INST_ORI    4'b0110
`define INST_ANDI   4'b0111
`define INST_SLLI   4'b0001
`define INST_SRLI   4'b0101
`define INST_SRAI   4'b1101

//ROP
`define ROpLen      4
`define INST_ADD    4'b0000
`define INST_SUB    4'b1000
`define INST_SLL    4'b0001
`define INST_SLT    4'b0010
`define INST_SLTU   4'b0011
`define INST_XOR    4'b0100
`define INST_SRL    4'b0101
`define INST_SRA    4'b1101
`define INST_OR     4'b0110
`define INST_AND    4'b0111

//AluOP
`define OpCodeLen 4
`define EXE_OR    4'b0110

//AluSelect
`define OpSelLen 3
`define LOGIC_OP 3'b001

//OP
`define OpBus      5:0
`define NOP        6'b000000
`define LUI        6'b000001
`define AUIPC      6'b000010
`define JAL        6'b000011
`define JALR       6'b000100
`define BEQ        6'b000101
`define BNE        6'b000110
`define BLT        6'b000111
`define BGE        6'b001000
`define BLTU       6'b001001
`define BGEU       6'b001011
`define LH         6'b001100
`define LW         6'b001010
`define LB         6'b001101
`define LBU        6'b001110
`define LHU        6'b001111
`define SB         6'b010000
`define SH         6'b010001
`define SW         6'b010010
`define ADDI       6'b010011
`define SLTI       6'b010100
`define SLTIU      6'b010101
`define XORI       6'b010110
`define ORI        6'b010111
`define ANDI       6'b011000
`define SLLI       6'b011001
`define SRLI       6'b011010
`define SRAI       6'b011011
`define ADD        6'b011100
`define SUB        6'b011101
`define SLL        6'b011110
`define SLT        6'b011111
`define SLTU       6'b100000
`define XOR        6'b100001
`define SRL        6'b100010
`define SRA        6'b100011
`define OR         6'b100100
`define AND        6'b100101
