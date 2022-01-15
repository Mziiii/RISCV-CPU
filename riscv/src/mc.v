`include "config.v"

module mc (
    input wire clk,
    input wire rst,
    input wire rdy,

    //ram
    input wire [`MemDataBus] iRAM_dt,
    output reg               oRAM_en,
    output reg               oRAM_rw,
    output reg [`AddrBus]    oRAM_addr,
    output reg [`MemDataBus] oRAM_dt,

    //iCache
    input wire            iIC_en,
    input wire [`AddrBus] iIC_pc,
    output reg            oIC_en,
    output reg [`InstBus] oIC_inst,

    //dc
    input wire            iDC_en,
    input wire            iDC_ls,
    input wire [`LenBus]  iDC_len,
    input wire [`AddrBus] iDC_addr,
    input wire [`DataBus] iDC_dt,
    output reg            oDC_en,
    output reg [`DataBus] oDC_dt
);
    reg id_case;
    reg [`AddrBus] in_addr;
    reg [`AddrBus] dt_addr;
    //
    reg rw;
    //
    reg [2:0] dt_stage;
    reg [2:0] in_stage;
    reg [`LenBus] len;
    reg in_en,dt_en;
    
    always @(posedge clk) begin
        if (rst) begin
            id_case  <= 0;
            in_addr  <= 0;
            dt_addr  <= 0;
            rw       <= 0;
            dt_stage <= 0;
            in_stage <= 0;
            len      <= 0;
            in_en    <= 0;
            dt_en    <= 0;
            oDC_en   <= 0;
            oIC_en   <= 0;
            oRAM_en  <= 0;
        end
        else if (rdy) begin
            case(id_case)
                `InstC: if (in_en) begin
                    in_stage <= in_stage+1;
                    in_addr  <= in_addr+1;
                end
                `DataC:if(dt_en) begin
                    dt_stage <= dt_stage+1;
                    dt_addr  <= dt_addr+1;
                end
            endcase
            
            case (id_case)
                `InstC:begin
                    case (in_stage)
                        1: oIC_inst[7:0]   <= iRAM_dt;
                        2: oIC_inst[15:8]  <= iRAM_dt;
                        3: oIC_inst[23:16] <= iRAM_dt;
                        4: oIC_inst[31:24] <= iRAM_dt;
                        default;
                    endcase
                end
                `DataC:begin
                    case(rw)
                        `Read: case (dt_stage)
                        1: oDC_dt[7:0]   <= iRAM_dt;
                        2: oDC_dt[15:8]  <= iRAM_dt;
                        3: oDC_dt[23:16] <= iRAM_dt;
                        4: oDC_dt[31:24] <= iRAM_dt;
                        default;
                    endcase
                    `Write: case (dt_stage)
                    0: oRAM_dt <= iDC_dt[15:8];
                    1: oRAM_dt <= iDC_dt[23:16];
                    2: oRAM_dt <= iDC_dt[31:24];
                    default;
            endcase
            endcase
        end
    endcase
            
            if (dt_en) begin
                if (dt_stage == len&&(len != 0||id_case)) begin
                    dt_stage <= 0;
                    dt_en    <= 1'b0;
                    oDC_en   <= 1'b1;
                    id_case  <= `InstC;
                end
                else begin
                    oDC_en <= 1'b0;
                end
                end else begin
                oDC_en <= 1'b0;
            end
            
            if (in_en) begin
                if (in_stage == 4) begin
                    in_stage                   <= 0;
                    in_en                      <= 1'b0;
                    oIC_en                     <= 1'b1;
                    if (dt_en||iDC_en) id_case <= `DataC;
                    end else begin
                    oIC_en <= 1'b0;
                end
                end else begin
                oIC_en <= 1'b0;
            end
            
            if (iIC_en) begin
                if (!dt_en) id_case <= `InstC;
                in_en               <= 1'b1;
                in_stage            <= 0;
                in_addr             <= iIC_pc;
            end
            
            if (iDC_en) begin
                if (!in_en) id_case <= `DataC;
                dt_en               <= 1'b1;
                dt_stage            <= 0;
                dt_addr             <= iDC_addr;
                rw                  <= oRAM_rw;
                len                 <= iDC_len-{2'b0,iDC_ls};
                oRAM_dt             <= iDC_dt[7:0];
            end
            
            oRAM_rw   <= id_case?rw:`Read;
            oRAM_addr <= id_case?dt_addr:in_addr;
            
        end
    end
            
endmodule
