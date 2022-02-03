`include "config.v"

module memctrl (
    input wire clk,
    input wire rst, 
    input wire rdy,

    input wire iIO_buffer_full,
    
    //ram 
    input wire [`MemDataBus] iMEM_dt,
    output reg               oMEM_rw,
    output wire [`AddrBus]   oMEM_addr,
    output reg [`MemDataBus] oMEM_dt,

    //occupied
    output reg [`WaitBus] oINF_wait,
    output reg [`WaitBus] oDC_wait,

    //inf
    input wire            iINF_en,
    input wire [`AddrBus] iINF_addr,
    output reg            oINF_done,
    output reg [`InstBus] oINF_inst,

    output reg            oBP_en,
    output reg [`InstBus] oBP_inst,

    //dc
    input wire            iDC_en,
    input wire            iDC_ls,
    input wire [`LenBus]  iDC_len,
    input wire [`DataBus] iDC_dt,
    input wire [`AddrBus] iDC_addr,

    output reg            oDC_done,
    output reg [`DataBus] oDC_dt
);
    reg [`InstBus] inst;
    reg [`DataBus] data;
    reg [`AddrBus] addr;
    reg [`LenBus] len;
    
    reg [`LenBus] stage;
    reg [`CaseBus] id_case;

    always @(*) begin
        if(rst) begin
        end
        else if (iIO_buffer_full) begin
            
        end else if (rdy) begin
            case(id_case) 
            `Idle:begin
                
            end
            `RInst:begin
                
            end
            `RData:begin
                
            end
            `WData:begin
                
            end
            endcase
        end
    end

    //reach to ram 
    always @(*) begin
        if(rst) begin
            //output
            oDC_done  = 1'b0;
            oBP_en    = 1'b0;
            oINF_done = 1'b0;
            oMEM_dt   = 0;
            oMEM_rw   = `Read;
            oINF_wait = 2'b00;
            oDC_wait  = 2'b00;
        end else if(iIO_buffer_full) begin
            
        end else if(rdy) begin
            if (iDC_en) begin

                if (iDC_ls == `Load) begin
                    oMEM_rw   = `Read;
                    oINF_inst = 0;
                    oINF_done = 1'b0;
                    oBP_en    = 1'b0;
                    oBP_inst  = 0;
                    case(stage)
                    `Zero: begin
                        oMEM_addr = addr;
                        oDC_done  = 1'b0;
                        oDC_wait  = 2'b01;
                        oINF_wait = 2'b01;
                    end
                    `One:begin
                        if(iDC_len == stage) begin
                            oDC_done  = 1'b1;
                            oDC_dt    = {{24{1'b0}},iMEM_dt};
                            oDC_wait  = 2'b00;
                            oINF_wait = 2'b00;
                        end else begin
                            oMEM_addr = addr + `PCStep * stage;
                            oDC_done  = 1'b0;
                            oDC_wait  = 2'b01;
                            oINF_wait = 2'b01;
                        end
                    end
                    `Two:begin
                        if(iDC_len == stage) begin
                            oDC_done  = 1'b1;
                            oDC_dt    = {{16{1'b0}},iMEM_dt,data[7:0]};
                            oDC_wait  = 2'b00;
                            oINF_wait = 2'b00;
                        end else begin
                            oMEM_addr = addr + `PCStep * stage;
                            oDC_done   = 1'b0;
                            oDC_wait   = 2'b01;
                            oINF_wait  = 2'b01;
                        end
                    end
                    `Three:begin
                        oMEM_addr = addr + `PCStep * stage;
                        oDC_done    = 1'b0;
                        oDC_wait    = 2'b01;
                        oINF_wait   = 2'b01;
                    end
                    `Four:begin
                        if(iDC_len == stage) begin
                            oDC_done    = 1'b1;
                            oDC_dt      = {iMEM_dt,data[23:0]};
                            oDC_wait    = 2'b00;
                            oINF_wait   = 2'b00;
                        end else begin
                            //unavailable
                            oDC_done    = 1'b0;
                            oDC_wait    = 2'b01;
                            oINF_wait   = 2'b01;
                        end
                    end
                    default;
                    endcase
                end

                else if (iDC_ls == `Store)
                begin
                oMEM_rw   = `Write;
                oINF_done = 1'b0;
                oINF_inst = 0;
                oBP_en    = 1'b0;
                oBP_inst  = 0;
                    case(stage)
                        `Zero:begin
                            oDC_done  = 1'b0;
                            oDC_wait  = 2'b01;
                            oINF_wait = 2'b01;
                            oMEM_dt   = iDC_dt[7:0];
                        end
                        `One:begin
                            if(iDC_len == stage) begin
                                oDC_done  = 1'b1;
                                oDC_wait  = 2'b00;
                                oINF_wait = 2'b00;
                                oMEM_dt   = 0;
                                oMEM_rw   = `Read;
                            end else begin
                            oDC_done  = 1'b0;
                            oDC_wait  = 2'b01;
                            oINF_wait = 2'b01;
                            oMEM_dt   = iDC_dt[15:8];
                            end
                        end
                        `Two:begin
                            if(iDC_len == stage) begin
                                oDC_done  = 1'b1;
                                oDC_wait  = 2'b00;
                                oINF_wait = 2'b00;
                                oMEM_dt   = 0;
                                oMEM_rw   = `Read;
                            end else begin
                            oDC_done  = 1'b0;
                            oDC_wait  = 2'b01;
                            oINF_wait = 2'b01;
                            oMEM_dt   = iDC_dt[23:16];
                            end
                        end
                        `Three:begin
                            oDC_done  = 1'b1;
                            oDC_wait  = 2'b00;
                            oINF_wait = 2'b00;
                            oMEM_dt   = iDC_dt[31:24];
                        end
                        default;
                    endcase
                end
            end

            else if (iINF_en) begin

                oMEM_rw  = `Read;
                oDC_done = 1'b0;
                oDC_dt   = 0;
                case(stage)
                `Zero:begin
                    oINF_done = 1'b0;
                    oBP_en    = 1'b0;
                    oINF_wait = 2'b10;
                    oDC_wait  = 2'b10;
                end
                `One:begin
                    oINF_done = 1'b0;
                    oBP_en    = 1'b0;
                    oINF_wait = 2'b10;
                    oDC_wait  = 2'b10;
                end
                `Two:begin
                    oINF_done  = 1'b0;
                    oBP_en     = 1'b0;
                    oINF_wait  = 2'b10;
                    oDC_wait   = 2'b10;
                end
                `Three:begin
                    oINF_done   = 1'b0;
                    oBP_en      = 1'b0;
                    oINF_wait   = 2'b10;
                    oDC_wait    = 2'b10;
                end
                `Four:begin
                    oINF_done = 1'b1;
                    oBP_en    = 1'b1;
                    oINF_wait = 2'b00;
                    oDC_wait  = 2'b00;
                    oBP_inst  = {iMEM_dt,inst[23:0]};
                    oINF_inst = {iMEM_dt,inst[23:0]};
                end
                default;
                endcase
            end else begin
                // output
                oDC_done  = 1'b0;
                oBP_en    = 1'b0;
                oINF_done = 1'b0;
                oMEM_rw   = `Read;
                oMEM_dt   = 0;
                oINF_wait = 2'b00;
                oDC_wait  = 2'b00;
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            
        end 
        else if (iIO_buffer_full) begin
            
        end 
        else if (rdy) begin
            if (id_case == `Idle) begin
                if (iDC_en) begin
                if (iDC_ls == `Store) begin
                    id_case <= `WData;
                    addr <= iDC_addr;
                    data <= iDC_dt;
                    len <= iDC_len;
                    stage <= `Zero;
                end else if(iDC_ls == `Load) begin
                    id_case <= `RData;
                    addr <= iDC_addr;
                    len <= iDC_len;
                    stage <= `Zero;
                end
                end else if (iINF_en) begin
                    id_case <= `RInst;
                    addr <= iINF_addr;
                    stage <= `Zero;
                end else begin
                    id_case <= `Idle;
                end
            end else begin
                case (id_case) 
                `RInst:begin

                end
                `RData:begin
                    
                end
                `WData:begin
                    
                end
                defaul
                endcase
            end
        end
    end
    
    always @(posedge clk) begin
        if (rst) begin
            //
            stage     <= `Zero;
            inst      <= 0;
            data      <= 0;
        end
        else if (iIO_buffer_full) begin
            
        end
        else if (rdy) begin

            if (iDC_en) begin

                if (iDC_ls == `Load) begin
                    case(stage)
                    `Zero: begin
                        stage     <= `One;
                    end
                    `One:begin
                        if(iDC_len == stage) begin
                            stage     <= `Zero;
                            data      <= 0;
                        end else begin
                            stage     <= `Two;
                            data[7:0] <= iMEM_dt;
                        end
                    end
                    `Two:begin
                        if(iDC_len == stage) begin
                            stage     <= `Zero;
                            data      <= 0;
                        end else begin
                            stage      <= `Three;
                            data[15:8] <= iMEM_dt;
                        end
                    end
                    `Three:begin
                        stage       <= `Four;
                        data[23:16] <= iMEM_dt;
                    end
                    `Four:begin
                        if(iDC_len == stage) begin
                            stage       <= `Zero;
                            data        <= 0;
                        end else begin
                            //unavailable
                            stage       <= `Four;
                            data[31:24] <= iMEM_dt;
                        end
                    end
                    default;
                    endcase
                end

                else if (iDC_ls == `Store)
                begin
                    case(stage)
                        `Zero:begin
                            stage     <= `One;
                        end
                        `One:begin
                            if(iDC_len == stage) begin
                                stage     <= `Zero;
                            end else begin
                            stage     <= `Two;
                            end
                        end
                        `Two:begin
                            if(iDC_len == stage) begin
                                stage     <= `Zero;
                            end else begin
                            stage     <= `Three;
                            end
                        end
                        `Three:begin
                            stage     <= `Zero;
                        end
                        default;
                    endcase
                end
            end

            else if (iINF_en) begin

                case(stage)
                `Zero:begin
                    stage     <= `One;
                end
                `One:begin
                    stage     <= `Two;
                    inst[7:0] <= iMEM_dt;
                end
                `Two:begin
                    stage      <= `Three;
                    inst[15:8] <= iMEM_dt;
                end
                `Three:begin
                    stage       <= `Four;
                    inst[23:16] <= iMEM_dt;
                end
                `Four:begin
                    stage     <= `Zero;
                    inst      <= 0;
                end
                default;
                endcase
            end else begin
                //same with rst    
                //
                stage     <= `Zero;
                inst      <= 0;
                data      <= 0;
            end
        end
    end
endmodule
