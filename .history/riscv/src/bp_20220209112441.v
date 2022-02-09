`include "config.v"

module bp (
    input wire clk,
    input wire rst,
    input wire rdy,

    //iCache
    input wire           iMC_en,
    input wire[`InstBus] iMC_inst,

    //rob
    //input wire iROB_commit_en,
    //input wire iROB_wrong,
    //input wire [`AddtBus] iROB_pc,

    //inf
    output reg oINF_pd
);
    wire [6:0] opcode = iMC_inst[6:0];
    
    always @(*) begin
        if (rst) begin
            oINF_pd = `NotJump;
        end
        else if (rdy) begin
            if (iMC_en) begin
                case (opcode)
                    7'b1101111: oINF_pd = `Jump;//JAL
                    7'b1100111: oINF_pd = `NotJump;//JALR
                    7'b1100011://Branch
                    begin
                        //if (iROB_commit_en_wrong) begin
                            //case ()
                            //endcase
                        // end
                        oINF_pd = `NotJump;
                    end
                    default: oINF_pd = `NotJump;
                endcase
            end
            else oINF_pd = `NotJump;
        end else begin
            oINF_pd = `NotJump
        end
    end
endmodule
//todo:JALR must be predicted with a wrong result