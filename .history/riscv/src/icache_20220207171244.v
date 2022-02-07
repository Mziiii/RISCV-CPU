`include "config.v"

module icache (
    input wire clk,
    input wire rst,
    input wire rdy,

    //memctrl
    input wire iMC_en,
    input wire [`InstBus] iMC_inst,
    output reg oMC_en,
    output reg [`AddrBus] oMC_pc,

    //inf
    input wire iINF_en,
    input wire [`AddrBus] iINF_pc,
    output reg oINF_en,
    output reg [`InstBus] oINF_inst
);
    //contents in iCache
    reg [`InstBus] inst[`ICacheBus];
    reg [`ICacheTag] tag[`ICacheBus];
    reg valid[`ICacheBus];
    
    //
    wire [`ICacheNumBus] idx = iINF_pc[`ICacheIdxBus];
    
    always @(posedge clk) begin
        if (rst) begin
            oMC_en    <= 1'b0;
            oINF_en   <= 1'b0;
            oINF_inst <= 0;
            oMC_pc    <= 0;
        end
        else if (rdy) begin
            if (iMC_en) begin
                tag[idx]   <= iINF_pc[`ICacheTagBus];
                inst[idx]  <= iMC_inst;
                valid[idx] <= 1'b1;
            end
                if (iINF_en) begin
                    if (valid[idx]&&tag[idx] == iINF_pc[`ICacheTagBus])begin
                        oINF_en   <= 1'b1;
                        oINF_inst <= inst[idx];
                        oMC_en    <= 1'b0;
                    end
                    else if (iMC_en) begin
                        oINF_en   <= 1'b1;
                        oINF_inst <= iMC_inst;
                        oMC_en    <= 1'b0;
                    end
                    else begin
                        oINF_en <= 1'b0;
                        oMC_en  <= 1'b1;
                        oMC_pc  <= iINF_pc;
                    end
                end
        end
    end
            
endmodule
