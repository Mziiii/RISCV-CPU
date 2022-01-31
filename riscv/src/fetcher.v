`include "config.v"

module fetcher (
    input wire clk,
    input wire rdy,
    input wire rst,

    input wire clr,
    input wire [`AddrBus] iROB_j_pc,

    input wire [`WaitBus] iMC_wait, 

    //icache
    input wire            iIC_done,
    input wire [`InstBus] iIC_inst,
    //icache
    output reg            oIC_en,
    output reg [`AddrBus] oIC_pc,
    
    //rob if rob is full then stall
    input wire iROB_full,
    input wire iSLB_full,
    input wire iRS_full,

    //bp
    input wire iBP_pd,

    //decoder
    output reg            oIND_en,
    output reg [`InstBus] oIND_inst,
    output reg [`AddrBus] oIND_pc,
    output reg            oIND_pd
);
    reg [`AddrBus] PC;
    
    reg [`InstBus] inst[`FIFOLenBus];
    reg [`AddrBus] pc[`FIFOLenBus];
    reg pd[`FIFOLenBus];
    reg [`FIFOBus] wt_ptr;
    reg [`FIFOBus] rd_ptr;
    wire [`FIFOBus] wt_nx_ptr;
    wire [`FIFOBus] rd_nx_ptr;
    reg [`FIFOLenBus] occupied;
    
    wire full  = &occupied;
    wire empty = !(|occupied);
    
    assign wt_nx_ptr = (wt_ptr == 5'b11111)?0:wt_ptr+5'b1;
    assign rd_nx_ptr = (rd_ptr == 5'b11111)?0:rd_ptr+5'b1;
    
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0 ; i<2**`FIFOLen; i = i + 1) begin
                inst[i] <= 0;
                pc[i]   <= 0;
                pd[i]   <= `NotJump;
            end
            PC <= 0;
            
            wt_ptr   <= 0;
            rd_ptr   <= 0;
            occupied <= 0;
            
            //output
            oIC_en   <= 1'b0;
            oIC_pc   <= 0;
            oIND_en   <= 1'b0;
            oIND_inst <= 0;
            oIND_pc   <= 0;
        end
        else if (clr) begin
            for (i = 0 ; i<2**`FIFOLen; i = i + 1) begin
                inst[i] <= 0;
                pc[i]   <= 0;
                pd[i]   <= `NotJump;
            end
            PC <= iROB_j_pc;
            
            wt_ptr   <= 0;
            rd_ptr   <= 0;
            occupied <= 0;
            
            //output
            oIC_en   <= 1'b0;
            oIC_pc   <= 0;
            oIND_en   <= 1'b0;
            oIND_inst <= 0;
            oIND_pc   <= 0;
        end
        else if (rdy) begin
            
            if (iIC_done) begin
                oIC_en <= 1'b0;
                oIC_pc <= 0;
                if (iIC_inst[6:0] == 7'b1101111) begin  // JAL
                    PC <= PC + {{12{iIC_inst[31]}},
                    iIC_inst[19: 12],
                    iIC_inst[20],
                    iIC_inst[30: 21],
                    1'b0};
                    pd[wt_ptr]       <= iBP_pd;
                    pc[wt_ptr]       <= PC;
                    inst[wt_ptr]     <= iIC_inst;
                    wt_ptr           <= wt_nx_ptr;
                    occupied[wt_ptr] <= 1'b1;
                end
                else begin
                    pd[wt_ptr]       <= iBP_pd;
                    pc[wt_ptr]       <= PC;
                    inst[wt_ptr]     <= iIC_inst;
                    wt_ptr           <= wt_nx_ptr;
                    occupied[wt_ptr] <= 1'b1;
                    if (iBP_pd == `Jump)
                        PC <= PC + {{20{iIC_inst[31]}},
                        iIC_inst[7],
                        iIC_inst[30:25],
                        iIC_inst[11:8],
                        1'b0};
                        else PC <= PC + `NEXT_PC;
                    end
            end else
                if (iMC_wait[0] == 1'b1)begin
                    oIC_en <= 1'b0;
                    oIC_pc <= PC;
                end
            else if (iMC_wait[0] == 1'b0) begin
                if (!full)
                begin
                    oIC_en <= 1'b1;
                    oIC_pc <= PC;
                end else
                begin
                    oIC_en <= 1'b0;
                end
            end
                            
            if (!empty&&!iROB_full&&!iSLB_full&&!iRS_full) begin
                oIND_en           <= 1'b1;
                oIND_inst         <= inst[rd_ptr];
                oIND_pc           <= pc[rd_ptr];
                oIND_pd           <= pd[rd_ptr];
                rd_ptr           <= rd_nx_ptr;
                occupied[rd_ptr] <= 1'b0;
            end
            else begin
                oIND_en   <= 1'b0;
                oIND_inst <= 0;
                oIND_pc   <= 0;
                oIND_pd   <= `NotJump;
            end
                            
        end
    end
                            
endmodule
