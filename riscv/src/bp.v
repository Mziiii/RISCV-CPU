`include "config.v"

module bp (
    input wire clk,
    input wire rst,
    input wire rdy,

    //iCache
    input wire           iIC_en,
    input wire[`InstBus] iIC_inst,

    //inf
    input wire           iINF_en,
    input wire[`AddrBus] iINF_pc,
    output reg           oINF_en,
    output reg[`AddrBus] oINF_ppc
    );
    
    always @(posedge clk) begin
        if (rst) begin
            oINF_ppc     <= 0;
            oINF_en <= 1'b0;
        end
        else if (rdy) begin
            if (iIC_en) begin
                oINF_ppc     <= iINF_pc + 4;
                oINF_en <= 1'b1;
            end
            else oINF_en <= 1'b0;
        end
    end
endmodule
