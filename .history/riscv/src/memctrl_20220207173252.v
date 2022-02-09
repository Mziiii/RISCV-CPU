`include "config.v"

module memctrl (
    input wire clk,
    input wire rst, 
    input wire rdy,

    input wire clr,

    input wire iIO_buffer_full,
    
    //ram 
    input wire [`MemDataBus] iMEM_dt,
    output reg               oMEM_rw,
    output reg [`AddrBus]    oMEM_addr,
    output reg [`MemDataBus] oMEM_dt,

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
    reg [`DataBus] data;
    reg [`AddrBus] addr;
    reg [`LenBus] len;
    
    reg [`DataBus] o_data;
    reg [`LenBus] stage;
    reg [`CaseBus] id_case;

    always @(*) begin
        if(rst||clr) begin
            oINF_done = 1'b0;
            oBP_en = 1'b0;
            oINF_inst = 0;
            oBP_inst = 0;
        // end
        // else if (iIO_buffer_full) begin
        //     oINF_done = 1'b0;
        //     oBP_en = 1'b0;
        //     oINF_inst = 0;
        //     oBP_inst = 0;
        end else if (rdy) begin
            case(id_case) 
            `RInst:begin
                case (stage)
                `Four:begin
                    oINF_done = 1'b1;
                    oBP_en = 1'b1;
                    oINF_inst = {iMEM_dt, o_data[23:0]};
                    oBP_inst = {iMEM_dt, o_data[23:0]};
                end
                default:begin
                    oINF_done = 1'b0;
                    oBP_en = 1'b0;
                    oINF_inst = 0;
                    oBP_inst = 0;
                end
                endcase
            end
            default:begin
                oINF_done = 1'b0;
                oBP_en = 1'b0;
                oINF_inst = 0;
                oBP_inst = 0;
            end
            endcase
        end else begin
            oINF_done = 1'b0;
            oBP_en = 1'b0;
            oINF_inst = 0;
            oBP_inst = 0;
        end
    end

    always @(*) begin
        if (rst||clr) begin
            oDC_done = 1'b0;
            oDC_dt = 0;
        end else if (iIO_buffer_full) begin
            oDC_done = 1'b0;
            oDC_dt = 0;
        end else if (rdy) begin
            case(id_case)
            `RData:begin
                case (stage)
                `OneDone:begin
                    oDC_done = 1'b1;
                    oDC_dt = {{24{1'b0}},iMEM_dt};
                end
                `TwoDone:begin
                    oDC_done = 1'b1;
                    oDC_dt = {{16{1'b0}},iMEM_dt,o_data[7:0]};
                end
                `FourDone:begin
                    oDC_done = 1'b1;
                    oDC_dt = {iMEM_dt,o_data[23:0]};
                end
                default:begin
                    oDC_done = 1'b0;
                    oDC_dt = 0;
                end
                endcase
            end
            `WData:begin
                if (len == stage + `One) begin
                    oDC_done = 1'b1;
                end 
            end
            default begin
                oDC_done = 1'b0;
                oDC_dt = 0;
            end
            endcase
        end else begin
            oDC_done = 1'b0;
            oDC_dt = 0;
        end
    end

    always @(*) begin
        if (rst||clr) begin
            oMEM_rw = `Read;
            oMEM_dt = 0;
            oMEM_addr = 0;
        end else if (iIO_buffer_full) begin
            oMEM_rw = `Read;
        end else if(rdy) begin
            case (id_case) 
            `Idle:begin
                oMEM_rw = `Read;
                oMEM_dt = 0;
                oMEM_addr = 0;
            end
            `RInst,
            `RData:begin
                oMEM_rw = `Read;
                oMEM_dt = 0;
                case (stage)
                `Zero,
                `One,
                `Two,
                `Three: oMEM_addr = addr + `PCStep * stage;
                default: oMEM_addr = 0;
                endcase
            end
            `WData:begin
                case (stage)
                `Zero: begin
                    oMEM_rw = `Write;
                    oMEM_addr = addr + `PCStep * stage;
                    oMEM_dt = data[7:0];
                end
                `One: begin
                    oMEM_rw = `Write;
                    oMEM_addr = addr + `PCStep * stage;
                    oMEM_dt = data[15:8];
                end
                `Two: begin
                    oMEM_rw = `Write;
                    oMEM_addr = addr + `PCStep * stage;
                    oMEM_dt = data[23:16];
                end
                `Three: begin
                    oMEM_rw = `Write;
                    oMEM_addr = addr + `PCStep * stage;
                    oMEM_dt = data[31:24];
                end
                default: begin
                    oMEM_rw = `Read;
                    oMEM_dt = 0;
                    oMEM_addr = 0;
                end
                endcase
            end
            endcase
        end else begin
            oMEM_rw = `Read;
            oMEM_dt = 0;
            oMEM_addr = 0;
        end
    end

    always @(posedge clk) begin
        if (rst||clr) begin
            //
            stage     <= `Zero;
            o_data      <= 0;
            id_case   <= `Idle;

            data <= 0;
            len <= 0;
            addr <= 0;
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
                    case (stage)
                    `Zero:begin//if stall
                        stage <= `One;
                    end
                    `One:begin
                        stage <= `Two;
                        o_data[7:0] <= iMEM_dt;
                    end
                    `Two:begin
                        stage <= `Three;
                        o_data[15:8] <= iMEM_dt;
                    end
                    `Three:begin
                        stage <= `Four;
                        o_data[23:16] <= iMEM_dt;
                    end
                    `Four:begin
                        stage <= `Zero;
                        id_case <= `Idle;
                    end
                    default;
                    endcase
                end
                `RData:begin
                    case (stage)
                    `Zero:begin//if stall
                        if (len == `One) stage <= `OneDone;
                        else stage <= `One;
                    end
                    `One:begin
                        if (len == `Two) stage <= `TwoDone;
                        else begin 
                            stage <= `Two;
                            o_data[7:0] <= iMEM_dt;
                        end
                    end
                    `Two:begin
                        stage <= `Three;
                        o_data[15:8] <= iMEM_dt;
                    end
                    `Three:begin
                        stage <= `FourDone;
                        o_data[23:16] <= iMEM_dt;
                    end
                    `OneDone,
                    `TwoDone,
                    `FourDone:begin
                        stage <= `Zero;
                        id_case <= `Idle;
                    end
                    default;
                    endcase
                end
                `WData:begin
                    if (len == stage + `One) begin
                        stage <= `Zero;
                        id_case <= `Idle;
                    end
                    else begin
                    case (stage) 
                        `Zero:begin
                            stage <= `One;
                        end
                        `One:begin
                            stage <= `Two;
                        end
                        `Two:begin
                            stage <= `Three;
                        end
                    default;
                    endcase
                    end
                end
                default;
                endcase
            end
        end else begin
            stage     <= `Zero;
            o_data      <= 0;
            id_case   <= `Idle;

            data <= 0;
            len <= 0;
            addr <= 0;
        end
    end

endmodule
