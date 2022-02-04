// RISCV32I CPU top module
// port modification allowed for debugging purposes
`include "config.v"

module cpu(
  input  wire                 clk_in,			// system clock signal
  input  wire                 rst_in,			// reset signal
	input  wire					        rdy_in,			// ready signal, pause cpu when low

  input  wire [ 7:0]          mem_din,		// data input bus
  output wire [ 7:0]          mem_dout,		// data output bus
  output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
  output wire                 mem_wr,			// write/read signal (1 for write)
	
	input  wire                 io_buffer_full, // 1 if uart buffer is full
	
	output wire [31:0]			    dbgreg_dout		// cpu register output (debugging demo)
);

    // implementation goes here
    
    // Specifications:
    // - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
    // - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
    // - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
    // - I/O port is mapped to address higher than 0x30000 (mem_a[17:16] == 2'b11)
    // - 0x30000 read: read a byte from input
    // - 0x30000 write: write a byte to output (write 0x00 is ignored)
    // - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
    // - 0x30004 write: indicates program stop (will output '\0' through uart tx)
    
    // always @(posedge clk_in)
    //   begin
    //     if (rst_in)
    //       begin
    
    //       end
    //     else if (!rdy_in)
    //       begin
    
    //       end
    //     else
    //       begin
    
    //       end
    //   end
    wire clr;

    wire mc_bp_en;
    wire [`InstBus] mc_bp_inst;
    wire bp_inf_pd;
    
    wire mc_dc_done;
    wire [`DataBus] mc_dc_dt;
    wire dc_mc_en;
    wire dc_mc_ls;
    wire [`AddrBus] dc_mc_pc;
    wire [`DataBus] dc_mc_dt;
    wire [`LenBus] dc_mc_len;

    wire dc_slb_en;
    wire slb_dc_en;
    wire slb_dc_ls;
    wire [`AddrBus] slb_dc_pc;
    wire [`DataBus] slb_dc_dt;
    wire [`LenBus] slb_dc_len;
    wire [`NickBus] slb_dc_nick;
    wire dc_slb_done;
    wire [`DataBus] dc_slb_dt;
    wire [`NickBus] dc_slb_nick;
    
    wire rs_ex_en;
    wire [`AddrBus] rs_ex_pc;
    wire [`OpBus] rs_ex_op;
    wire [`ImmBus] rs_ex_imm;
    wire [`NickBus] rs_ex_rd_nick;
    wire [`DataBus] rs_ex_rs1_dt;
    wire [`DataBus] rs_ex_rs2_dt;

    wire ex_cdb_en;
    wire [`NickBus] ex_cdb_nick;
    wire [`DataBus] ex_cdb_dt;
    wire ex_cdb_ac;
    wire [`AddrBus] ex_cdb_j_pc;

    wire [`AddrBus] rob_inf_j_pc;

    wire rob_inf_full;
    wire slb_inf_full;
    wire rs_inf_full;

    wire mc_inf_done;
    wire [`InstBus] mc_inf_inst;
    wire inf_mc_en;
    wire [`AddrBus] inf_mc_pc;

    wire inf_ind_en;
    wire [`InstBus] inf_ind_inst;
    wire [`AddrBus] inf_ind_pc;
    wire inf_ind_pd;

    wire ind_rob_en;
    wire [`NameBus] ind_rob_rd_regnm;

    wire rob_nick_en;
    wire [`NickBus] rob_nick;
    wire [`NameBus] rob_nick_regnm;
       
    wire ind_rf_en;
    wire [`NameBus] ind_rf_rs1_regnm;
    wire [`NameBus] ind_rf_rs2_regnm;
    wire [`NameBus] ind_rf_rd_regnm;
    wire [`OpBus] ind_rf_op;
    wire [`AddrBus] ind_rf_pc;
    wire [`ImmBus] ind_rf_imm;
    wire ind_rf_pd;

    wire [`NickBus] rf_dp_rs1_nick;
    wire [`NickBus] rf_dp_rs2_nick;
    wire [`DataBus] rf_dp_rs1_dt;
    wire [`DataBus] rf_dp_rs2_dt;
    wire rf_dp_en;
    wire [`NameBus] rf_dp_rd_regnm;
    wire [`OpBus] rf_dp_op;
    wire [`AddrBus] rf_dp_pc;
    wire [`ImmBus] rf_dp_imm;
    wire rf_dp_pd;

    wire dp_en;
    wire [`OpBus] dp_op;
    wire [`AddrBus] dp_pc;
    wire [`ImmBus] dp_imm;
    wire [`NickBus] dp_rd_nick;
    wire [`NickBus] dp_rs1_nick;
    wire [`NickBus] dp_rs2_nick;
    wire [`DataBus] dp_rs1_dt;
    wire [`DataBus] dp_rs2_dt;
    wire dp_pd;
    wire [`NameBus] dp_rd_regnm;

    wire rob_rf_en;
    wire [`NameBus] rob_rf_rd_regnm;
    wire [`DataBus] rob_rf_rd_dt;
    wire [`NickBus] rob_rf_rd_nick;
    
    wire rob_slb_store_en;
    wire [`NickBus] rob_slb_store_nick;
    
    wire slb_cdb_en;
    wire [`NickBus] slb_cdb_nick;
    wire [`DataBus] slb_cdb_dt;
    
    //bp
    bp bp(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    
    .iMC_en(mc_bp_en),
    .iMC_inst(mc_bp_inst),
    
    .oINF_pd(bp_inf_pd)
    );

    //dc
    dcache dcache(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    
    .iMC_done(mc_dc_done),
    .iMC_dt(mc_dc_dt),

    .oMC_en(dc_mc_en),
    .oMC_ls(dc_mc_ls),
    .oMC_pc(dc_mc_pc),
    .oMC_dt(dc_mc_dt),
    .oMC_len(dc_mc_len),
    
    .oSLB_en(dc_slb_en),
    .iSLB_en(slb_dc_en),
    .iSLB_ls(slb_dc_ls),
    .iSLB_pc(slb_dc_pc),
    .iSLB_dt(slb_dc_dt),
    .iSLB_len(slb_dc_len),
    .iSLB_nick(slb_dc_nick),
    .oSLB_done(dc_slb_done),
    .oSLB_dt(dc_slb_dt),
    .oSLB_nick(dc_slb_nick)
    );
    
    //ex
    execute execute(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    
    .iRS_en(rs_ex_en),
    .iRS_pc(rs_ex_pc),
    .iRS_op(rs_ex_op),
    .iRS_imm(rs_ex_imm),
    .iRS_rd_nick(rs_ex_rd_nick),
    .iRS_rs1_dt(rs_ex_rs1_dt),
    .iRS_rs2_dt(rs_ex_rs2_dt),
    
    .oRS_en(ex_cdb_en),
    .oRS_nick(ex_cdb_nick),
    .oRS_dt(ex_cdb_dt),
    .oSLB_en(ex_cdb_en),
    .oSLB_nick(ex_cdb_nick),
    .oSLB_dt(ex_cdb_dt),
    .oEX_en(ex_cdb_en),
    .oROB_nick(ex_cdb_nick),
    .oROB_dt(ex_cdb_dt),
    .oROB_ac(ex_cdb_ac),
    .oROB_j_pc(ex_cdb_j_pc)
    );

    //ic
    // icache icache(
    // .clk(clk_in),
    // .rst(rst_in),
    // .rdy(rdy_in),
    
    // .iMC_en(mc_ic_en),
    // .iMC_inst(mc_ic_inst),
    // .oMC_en(ic_mc_en),
    // .oMC_pc(ic_mc_pc),
    
    // .iINF_en(inf_ic_en),
    // .iINF_pc(inf_ic_pc),
    // .oINF_en(ic_inf_en),
    // .oINF_inst(ic_inf_inst)
    // );

    //inf
    fetcher fetcher(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),

    .clr(clr),
    .iROB_j_pc(rob_inf_j_pc),
    
    .oIC_en(inf_mc_en),
    .oIC_pc(inf_mc_pc),
    
    .iIC_done(mc_inf_done),
    .iIC_inst(mc_inf_inst),
    
    .iROB_full(rob_inf_full),
    .iSLB_full(slb_inf_full),
    .iRS_full(rs_inf_full),

    .iBP_pd(bp_inf_pd),

    .oIND_en(inf_ind_en),
    .oIND_inst(inf_ind_inst),
    .oIND_pc(inf_ind_pc),
    .oIND_pd(inf_ind_pd)
    );
    
    //ind
    decoder decoder(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    
    .iINF_en(inf_ind_en),
    .iINF_inst(inf_ind_inst),
    .iINF_pc(inf_ind_pc),
    .iINF_pd(inf_ind_pd),

    .oROB_en(ind_rob_en),
    .oROB_rd_regnm(ind_rob_rd_regnm),
    
    .oRF_en(ind_rf_en),
    .oRF_rs1_regnm(ind_rf_rs1_regnm),
    .oRF_rs2_regnm(ind_rf_rs2_regnm),
    .oRF_rd_regnm(ind_rf_rd_regnm),
    .oRF_op(ind_rf_op),
    .oRF_pc(ind_rf_pc),
    .oRF_imm(ind_rf_imm),
    .oRF_pd(ind_rf_pd)
    );

    //mc
    memctrl memctrl(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),

    .clr(clr),

    .iIO_buffer_full(io_buffer_full),
    
    .iMEM_dt(mem_din),
    .oMEM_rw(mem_wr),
    .oMEM_addr(mem_a),
    .oMEM_dt(mem_dout),

    .iINF_en(inf_mc_en),
    .iINF_addr(inf_mc_pc),
    .oINF_done(mc_inf_done),
    .oINF_inst(mc_inf_inst),
    
    .oBP_en(mc_bp_en),
    .oBP_inst(mc_bp_inst),
    
    .iDC_en(dc_mc_en),
    .iDC_ls(dc_mc_ls),
    .iDC_len(dc_mc_len),
    .iDC_addr(dc_mc_pc),
    .iDC_dt(dc_mc_dt),

    .oDC_done(mc_dc_done),
    .oDC_dt(mc_dc_dt)
    );

    //dp
    dispatch dispatch(
      .clk(clk_in),
      .rst(rst_in),
      .rdy(rdy_in),

      .iROB_nick_en(rob_nick_en),
      .iROB_nick(rob_nick),

      .iRF_en(rf_dp_en),
      .iRF_rs1_nick(rf_dp_rs1_nick),
      .iRF_rs2_nick(rf_dp_rs2_nick),
      .iRF_rs1_dt(rf_dp_rs1_dt),
      .iRF_rs2_dt(rf_dp_rs2_dt),
      .iRF_op(rf_dp_op),
      .iRF_pc(rf_dp_pc),
      .iRF_imm(rf_dp_imm),
      .iRF_pd(rf_dp_pd),
      .iRF_rd_regnm(rf_dp_rd_regnm),

      .oDP_en(dp_en),
      .oDP_op(dp_op),
      .oDP_pc(dp_pc),
      .oDP_imm(dp_imm),
      .oDP_rd_nick(dp_rd_nick),
      .oDP_rd_regnm(dp_rd_regnm),
      .oDP_rs1_nick(dp_rs1_nick),
      .oDP_rs2_nick(dp_rs2_nick),
      .oDP_rs1_dt(dp_rs1_dt),
      .oDP_rs2_dt(dp_rs2_dt),
      .oDP_pd(dp_pd)
    );
    
    //rf
    regfile regfile(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),

    .clr(clr),
    
    .iIND_en(ind_rf_en),
    .iIND_rs1_regnm(ind_rf_rs1_regnm),
    .iIND_rs2_regnm(ind_rf_rs2_regnm),
    .oDP_rs1_nick(rf_dp_rs1_nick),
    .oDP_rs1_dt(rf_dp_rs1_dt),
    .oDP_rs2_nick(rf_dp_rs2_nick),
    .oDP_rs2_dt(rf_dp_rs2_dt),

    .iIND_rd_regnm(ind_rf_rd_regnm),
    .iIND_op(ind_rf_op),
    .iIND_pc(ind_rf_pc),
    .iIND_imm(ind_rf_imm),
    .iIND_pd(ind_rf_pd),
    .oDP_en(rf_dp_en),
    .oDP_rd_regnm(rf_dp_rd_regnm),
    .oDP_op(rf_dp_op),
    .oDP_pc(rf_dp_pc),
    .oDP_imm(rf_dp_imm),
    .oDP_pd(rf_dp_pd),

    .iROB_nick_en(rob_nick_en),
    .iROB_nick_regnm(rob_nick_regnm),
    .iROB_nick(rob_nick),

    .iROB_en(rob_rf_en),
    .iROB_rd_regnm(rob_rf_rd_regnm),
    .iROB_rd_dt(rob_rf_rd_dt),
    .iROB_rd_nick(rob_rf_rd_nick)
    );

    //rob
    rob rob(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),

    .clr(clr),
    .oINF_j_pc(rob_inf_j_pc),

    .iclr(clr),
    
    .oINF_full(rob_inf_full),

    .iIND_en(ind_rob_en),
    .iIND_rd_regnm(ind_rob_rd_regnm),
    .oROB_nick_en(rob_nick_en),
    .oROB_nick(rob_nick),
    .oROB_nick_regnm(rob_nick_regnm),

    .iDP_en(dp_en),
    .iDP_op(dp_op),
    .iDP_pd(dp_pd),
    .iDP_rd_nick(dp_rd_nick),
    .iDP_rd_regnm(dp_rd_regnm),
    
    .iEX_en(ex_cdb_en),
    .iEX_nick(ex_cdb_nick),
    .iEX_dt(ex_cdb_dt),
    .iEX_ac(ex_cdb_ac),
    .iEX_j_pc(ex_cdb_j_pc),
    
    .iSLB_en(slb_cdb_en),
    .iSLB_nick(slb_cdb_nick),
    .iSLB_dt(slb_cdb_dt),
    
    .oSLB_store_en(rob_slb_store_en),
    .oSLB_store_nick(rob_slb_store_nick),
    
    .oRF_en(rob_rf_en),
    .oRF_rd_regnm(rob_rf_rd_regnm),
    .oRF_rd_dt(rob_rf_rd_dt),
    .oRF_rd_nick(rob_rf_rd_nick)
    );
    //rs
    rs rs(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),

    .clr(clr),
    
    .iDP_en(dp_en),
    .iDP_op(dp_op),
    .iDP_pc(dp_pc),
    .iDP_imm(dp_imm),
    .iDP_rd_nick(dp_rd_nick),
    .iDP_rs1_nick(dp_rs1_nick),
    .iDP_rs1_dt(dp_rs1_dt),
    .iDP_rs2_nick(dp_rs2_nick),
    .iDP_rs2_dt(dp_rs2_dt),
    
    .iEX_en(ex_cdb_en),
    .iEX_nick(ex_cdb_nick),
    .iEX_dt(ex_cdb_dt),
    .iSLB_en(slb_cdb_en),
    .iSLB_nick(slb_cdb_nick),
    .iSLB_dt(slb_cdb_dt),
    
    .oEX_en(rs_ex_en),
    .oEX_pc(rs_ex_pc),
    .oEX_op(rs_ex_op),
    .oEX_imm(rs_ex_imm),
    .oEX_rd_nick(rs_ex_rd_nick),
    .oEX_rs1_dt(rs_ex_rs1_dt),
    .oEX_rs2_dt(rs_ex_rs2_dt),

    .oINF_full(rs_inf_full)
    );
    
    //slb
    slb slb(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),

    .clr(clr),
    
    .iDP_en(dp_en),
    .iDP_op(dp_op),
    .iDP_pc(dp_pc),
    .iDP_imm(dp_imm),
    .iDP_rd_nick(dp_rd_nick),
    .iDP_rs1_nick(dp_rs1_nick),
    .iDP_rs1_dt(dp_rs1_dt),
    .iDP_rs2_nick(dp_rs2_nick),
    .iDP_rs2_dt(dp_rs2_dt),
    
    .iEX_en(ex_cdb_en),
    .iEX_nick(ex_cdb_nick),
    .iEX_dt(ex_cdb_dt),
    .iSLB_en(slb_cdb_en),
    .iSLB_nick(slb_cdb_nick),
    .iSLB_dt(slb_cdb_dt),
    .oSLB_en(slb_cdb_en),
    .oSLB_nick(slb_cdb_nick),
    .oSLB_dt(slb_cdb_dt),
    
    .iROB_store_en(rob_slb_store_en),
    .iROB_store_nick(rob_slb_store_nick),

    .iDC_en(dc_slb_en),
    .oDC_en(slb_dc_en),
    .oDC_ls(slb_dc_ls),
    .oDC_nick(slb_dc_nick),
    .oDC_len(slb_dc_len),
    .oDC_addr(slb_dc_pc),
    .oDC_dt(slb_dc_dt),
    
    .iDC_done(dc_slb_done),
    .iDC_nick(dc_slb_nick),
    .iDC_dt(dc_slb_dt),

    .oINF_full(slb_inf_full)
    );
    
endmodule
