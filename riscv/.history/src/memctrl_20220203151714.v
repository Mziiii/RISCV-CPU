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
    reg [`DataBus] data;
    reg [`AddrBus] addr;
    reg [`LenBus] len;
    
    reg [`LenBus] stage;
    reg [`CaseBus] id_case;

    always @(*) begin
        if(rst) begin
            oINF_done = 1'b0;
            oBP_en = 1'b0;
            oINF_inst = 0;
            oBP_inst = 0;
        end
        else if (iIO_buffer_full) begin
            oINF_done = 1'b0;
            oBP_en = 1'b0;
            oINF_inst = 0;
            oBP_inst = 0;
        end else if (rdy) begin
            case(id_case) 
            `RInst:begin
                case (stage)
                `Four:begin
                    oINF_done = 1'b1;
                    oBP_en = 1'b1;
                    oINF_inst = {iMEM_dt, data[23:0]};
                    oBP_inst = {iMEM_dt, data[23:0]};
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
        if (rst) begin
            oDC_done = 1'b0;
            oDC_dt = 0;
        end else if(iIO)
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
                    case (stage)
                    `Zero:begin//if stall
                        stage <= `One;
                    end
                    `One:begin
                        stage <= `Two;
                        data[7:0] <= iMEM_dt;
                    end
                    `Two:begin
                        stage <= `Three;
                        data[15:8] <= iMEM_dt;
                    end
                    `Three:begin
                        stage <= `Four;
                        data[23:16] <= iMEM_dt;
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
                        stage <= `One;
                    end
                    `One:begin
                        if (len == `Two) stage <= `TwoDone;
                        stage <= `Two;
                        data[7:0] <= iMEM_dt;
                    end
                    `Two:begin
                        stage <= `Three;
                        data[15:8] <= iMEM_dt;
                    end
                    `Three:begin
                        stage <= `FourDone;
                        data[23:16] <= iMEM_dt;
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
        end
    end
    
    always @(posedge clk) begin
        if (rst) begin
            //
            stage     <= `Zero;
            data      <= 0;
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
                    data[7:0] <= iMEM_dt;
                end
                `Two:begin
                    stage      <= `Three;
                    data[15:8] <= iMEM_dt;
                end
                `Three:begin
                    stage       <= `Four;
                    data[23:16] <= iMEM_dt;
                end
                `Four:begin
                    stage     <= `Zero;
                    data      <= 0;
                end
                default;
                endcase
            end else begin
                //same with rst    
                //
                stage     <= `Zero;
                data      <= 0;
                data      <= 0;
            end
        end
    end
endmodule
