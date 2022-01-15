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
	
	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
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
    wire ic_bp_en;
    wire bp_inf_en;
    wire inf_bp_en;
    wire [`InstBus] ic_bp_inst;
    wire [`AddrBus] inf_bp_pc;
    wire [`AddrBus] bp_inf_ppc;
    
    wire mc_dc_en;
    wire [`DataBus] mc_dc_dt;
    wire dc_mc_en;
    wire dc_mc_ls;
    wire [`AddrBus] dc_mc_pc;
    wire [`DataBus] dc_mc_dt;
    wire [`LenBus] dc_mc_len;
    wire slb_dc_en;
    wire slb_dc_ls;
    wire [`AddrBus] slb_dc_pc;
    wire [`DataBus] slb_dc_dt;
    wire [`LenBus] slb_dc_len;
    wire [`NickBus] slb_dc_nick;
    wire dc_slb_en;
    wire [`DataBus] dc_slb_dt;
    wire [`NickBus] dc_slb_nick;
    
    wire rs_ex_en;
    wire [`AddrBus] rs_ex_pc;
    wire [`OpBus] rs_ex_op;
    wire [`ImmBus] rs_ex_imm;
    wire [`NickBus] rs_ex_rd_nick;
    wire [`DataBus] rs_ex_rs1_dt;
    wire [`DataBus] rs_ex_rs2_dt;
    wire ex_rs_en;
    wire [`NickBus] ex_rs_nick;
    wire [`DataBus] ex_rs_dt;
    wire ex_slb_en;
    wire [`NickBus] ex_slb_nick;
    wire [`DataBus] ex_slb_dt;
    wire ex_rob_en;
    wire [`NickBus] ex_rob_nick;
    wire [`DataBus] ex_rob_dt;
    wire ex_rob_isBJ;
    wire [`AddrBus] ex_rob_j_pc;
    
    wire mc_ic_en;
    wire [`InstBus] mc_ic_inst;
    wire ic_mc_en;
    wire [`AddrBus] ic_mc_pc;
    wire inf_ic_en;
    wire [`AddrBus] inf_ic_pc;
    wire ic_inf_en;
    wire [`InstBus] ic_inf_inst;
    
    wire inf_is_en;
    wire [`AddrBus] inf_is_pc;
    wire [`InstBus] inf_is_inst;
    wire rob_inf_full;
    
    wire is_reg_en;
    wire [`NameBus] is_reg_rs1_regnm;
    wire [`NameBus] is_reg_rs2_regnm;
    wire [`NameBus] is_reg_rd_regnm;
    wire [`OpBus] is_reg_op;
    wire [`AddrBus] is_reg_pc;
    wire [`ImmBus] is_reg_imm;
    wire is_rs_en;
    wire [`OpBus] is_rs_op;
    wire [`AddrBus] is_rs_pc;
    wire [`ImmBus] is_rs_imm;
    wire is_rob_en;
    wire [`NameBus] is_rob_rd_regnm;
    wire [`AddrBus] is_rob_pc;
    
    wire mc_ram_en;
    wire mc_ram_rw;
    wire [`AddrBus] mc_ram_addr;
    wire [`MemDataBus] mc_ram_dt;
    wire [`MemDataBus] ram_mc_dt;
    
    wire rob_rf_nick_en;
    wire [`NameBus] rob_rf_nick_l;
    wire rob_rf_en;
    wire [`NameBus] rob_rf_rd_regnm;
    wire [`DataBus] rob_rf_rd_dt;
    wire [`NickBus] rob_rf_rd_nick;
    wire rob_rf_wrong;
    wire rf_rob_en;
    wire [`OpBus] rf_rob_op;
    wire [`AddrBus] rf_rob_pc;
    wire [`ImmBus] rf_rob_imm;
    wire [`NickBus] rf_rob_rd_nick;
    wire [`NickBus] rf_rob_rs1_nick;
    wire [`DataBus] rf_rob_rs1_dt;
    wire [`NickBus] rf_rob_rs2_nick;
    wire [`DataBus] rf_rob_rs2_dt;
    
    wire rob_rs_en;
    wire [`OpBus] rob_rs_op;
    wire [`AddrBus] rob_rs_pc;
    wire [`ImmBus] rob_rs_imm;
    wire [`NickBus] rob_rs_rd_nick;
    wire [`NickBus] rob_rs_rs1_nick;
    wire [`DataBus] rob_rs_rs1_dt;
    wire [`NickBus] rob_rs_rs2_nick;
    wire [`DataBus] rob_rs_rs2_dt;
    
    wire rob_slb_en;
    wire [`OpBus] rob_slb_op;
    wire [`AddrBus] rob_slb_pc;
    wire [`ImmBus] rob_slb_imm;
    wire [`NickBus] rob_slb_rd_nick;
    wire [`NickBus] rob_slb_rs1_nick;
    wire [`DataBus] rob_slb_rs1_dt;
    wire [`NickBus] rob_slb_rs2_nick;
    wire [`DataBus] rob_slb_rs2_dt;
    
    wire slb_rob_en;
    wire [`NickBus] slb_rob_nick;
    wire [`DataBus] slb_rob_dt;
    
    wire rob_slb_commit_en;
    wire [`NickBus] rob_slb_commit_nick;
    
    wire slb_rs_en;
    wire [`NickBus] slb_rs_nick;
    wire [`DataBus] slb_rs_dt;
    
    wire slb_slb_en;
    wire [`NickBus] slb_slb_nick;
    wire [`DataBus] slb_slb_dt;
    
    wire rob_slb_wrong;
    //bp
    bp bp(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    
    .iIC_en(ic_bp_en),
    .iIC_inst(ic_bp_inst),
    
    .iINF_en(inf_bp_en),
    .iINF_pc(inf_bp_pc),
    .oINF_en(bp_inf_en),
    .oINF_ppc(bp_inf_ppc));
    //dcache
    dcache dcache(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    
    .iMC_en(mc_dc_en),
    .iMC_dt(mc_dc_dt),
    .oMC_en(dc_mc_en),
    .oMC_ls(dc_mc_ls),
    .oMC_pc(dc_mc_pc),
    .oMC_dt(dc_mc_dt),
    .oMC_len(dc_mc_len),
    
    .iSLB_en(slb_dc_en),
    .iSLB_ls(slb_dc_ls),
    .iSLB_pc(slb_dc_pc),
    .iSLB_dt(slb_dc_dt),
    .iSLB_len(slb_dc_len),
    .iSLB_nick(slb_dc_nick),
    .oSLB_en(dc_slb_en),
    .oSLB_dt(dc_slb_dt),
    .oSLB_nick(dc_slb_nick)
    );
    
    //ex
    ex ex(
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
    
    .oRS_en(ex_rs_en),
    .oRS_nick(ex_rs_nick),
    .oRS_dt(ex_rs_dt),
    .oSLB_en(ex_slb_en),
    .oSLB_nick(ex_slb_nick),
    .oSLB_dt(ex_slb_dt),
    .oROB_en(ex_rob_en),
    .oROB_nick(ex_rob_nick),
    .oROB_dt(ex_rob_dt),
    .oROB_isBJ(ex_rob_isBJ),
    .oROB_j_pc(ex_rob_j_pc)
    );
    //icache
    icache icache(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    
    .iMC_en(mc_ic_en),
    .iMC_inst(mc_ic_inst),
    .oMC_en(ic_mc_en),
    .oMC_pc(ic_mc_pc),
    
    .iINF_en(inf_ic_en),
    .iINF_pc(inf_ic_pc),
    .oINF_en(ic_inf_en),
    .oINF_inst(ic_inf_inst)
    );
    //inf
    inf inf(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    
    .oIC_en(inf_ic_en),
    .oIC_pc(inf_ic_pc),
    
    .iIC_en(ic_inf_en),
    .iIC_inst(ic_inf_inst),
    .oIS_en(inf_is_en),
    .oIS_pc(inf_is_pc),
    .oIS_inst(inf_is_inst),
    
    .iROB_full(rob_inf_full),
    
    .oBP_en(inf_bp_en),
    .oBP_pc(inf_bp_pc),
    .iBP_en(bp_inf_en),
    .iBP_nxpc(bp_inf_ppc)
    );
    
    //is
    is is(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    
    .iINF_en(inf_is_en),
    .iINF_inst(inf_is_inst),
    .iINF_pc(inf_is_pc),
    
    .oREG_en(is_reg_en),
    .oREG_rs1_regnm(is_reg_rs1_regnm),
    .oREG_rs2_regnm(is_reg_rs2_regnm),
    .oREG_rd_regnm(is_reg_rd_regnm),
    .oREG_op(is_reg_op),
    .oREG_pc(is_reg_pc),
    .oREG_imm(is_reg_imm),
    
    .oRS_en(is_rs_en),
    .oRS_op(is_rs_op),
    .oRS_pc(is_rs_pc),
    .oRS_imm(is_rs_imm),
    
    .oROB_en(is_rob_en),
    .oROB_rd_regnm(is_rob_rd_regnm),
    .oROB_pc(is_rob_pc)
    );
    //mc
    mc mc(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    
    .iRAM_dt(ram_mc_dt),
    .oRAM_en(mc_ram_en),
    .oRAM_rw(mc_ram_rw),
    .oRAM_addr(mc_ram_addr),
    .oRAM_dt(mc_ram_dt),
    
    .iIC_en(ic_mc_en),
    .iIC_pc(ic_mc_pc),
    .oIC_en(mc_ic_en),
    .oIC_inst(mc_ic_inst),
    
    .iDC_en(dc_mc_en),
    .iDC_ls(dc_mc_ls),
    .iDC_len(dc_mc_len),
    .iDC_addr(dc_mc_pc),
    .iDC_dt(dc_mc_dt),
    .oDC_en(mc_dc_en),
    .oDC_dt(mc_dc_dt)
    );
    
    //ram
    ram ram(
    .clk_in(clk_in),
    .en_in(mc_ram_en),
    .r_nw_in(mc_ram_rw),
    .a_in(mc_ram_addr),
    .d_in(mc_ram_dt),
    .d_out(ram_mc_dt)
    );
    
    //regfile
    regfile regfile(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    
    .iIS_en(is_reg_en),
    .iIS_rs1_regnm(is_reg_rs1_regnm),
    .iIS_rs2_regnm(is_reg_rs2_regnm),
    .iIS_rd_regnm(is_reg_rd_regnm),
    .iIS_op(is_reg_op),
    .iIS_pc(is_reg_pc),
    .iIS_imm(is_reg_imm),
    
    .iROB_nick_en(rob_rf_nick_en),
    .iROB_nick_latest(rob_rf_nick_l),
    .iROB_en(rob_rf_en),
    .iROB_rd_regnm(rob_rf_rd_regnm),
    .iROB_rd_dt(rob_rf_rd_dt),
    .iROB_rd_nick(rob_rf_rd_nick),
    
    .iROB_wrong(rob_rf_wrong),
    
    .oROB_en(rf_rob_en),
    .oROB_op(rf_rob_op),
    .oROB_pc(rf_rob_pc),
    .oROB_imm(rf_rob_imm),
    .oROB_rd_nick(rf_rob_rd_nick),
    .oROB_rs1_nick(rf_rob_rs1_nick),
    .oROB_rs1_dt(rf_rob_rs1_dt),
    .oROB_rs2_nick(rf_rob_rs2_nick),
    .oROB_rs2_dt(rf_rob_rs2_dt)
    );
    //rob
    rob rob(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    
    .oRF_nick_en(rob_rf_nick_en),
    .oRF_nick_latest(rob_rf_nick_l),
    .iRF_en(rf_rob_en),
    .iRF_op(rf_rob_op),
    .iRF_pc(rf_rob_pc),
    .iRF_imm(rf_rob_imm),
    .iRF_rd_nick(rf_rob_rd_nick),
    .iRF_rs1_nick(rf_rob_rs1_nick),
    .iRF_rs1_dt(rf_rob_rs1_dt),
    .iRF_rs2_nick(rf_rob_rs2_nick),
    .iRF_rs2_dt(rf_rob_rs2_dt),
    
    .oRS_en(rob_rs_en),
    .oRS_op(rob_rs_op),
    .oRS_pc(rob_rs_pc),
    .oRS_imm(rob_rs_imm),
    .oRS_rd_nick(rob_rs_rd_nick),
    .oRS_rs1_nick(rob_rs_rs1_nick),
    .oRS_rs1_dt(rob_rs_rs1_dt),
    .oRS_rs2_nick(rob_rs_rs2_nick),
    .oRS_rs2_dt(rob_rs_rs2_dt),
    
    .oSLB_en(rob_slb_en),
    .oSLB_op(rob_slb_op),
    .oSLB_pc(rob_slb_pc),
    .oSLB_imm(rob_slb_imm),
    .oSLB_rd_nick(rob_slb_rd_nick),
    .oSLB_rs1_nick(rob_slb_rs1_nick),
    .oSLB_rs1_dt(rob_slb_rs1_dt),
    .oSLB_rs2_nick(rob_slb_rs2_nick),
    .oSLB_rs2_dt(rob_slb_rs2_dt),
    
    .iEX_en(ex_rob_en),
    .iEX_nick(ex_rob_nick),
    .iEX_dt(ex_rob_dt),
    .iEX_isBJ(ex_rob_isBJ),
    .iEX_j_pc(ex_rob_j_pc),
    
    .iSLB_en(slb_rob_en),
    .iSLB_nick(slb_rob_nick),
    .iSLB_dt(slb_rob_dt),
    
    .oSLB_commit_en(rob_slb_commit_en),
    .oSLB_commit_nick(rob_slb_commit_nick),
    
    .oRF_en(rob_rf_en),
    .oRF_rd_regnm(rob_rf_rd_regnm),
    .oRF_rd_dt(rob_rf_rd_dt),
    .oRF_rd_nick(rob_rf_rd_nick),
    
    .oINF_full(rob_inf_full),
    .oSLB_wrong(rob_slb_wrong),
    .oRF_wrong(rob_rf_wrong)
    );
    //rs
    rs rs(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    
    .iROB_en(rob_rs_en),
    .iROB_op(rob_rs_op),
    .iROB_pc(rob_rs_pc),
    .iROB_imm(rob_rs_pc),
    .iROB_rd_nick(rob_rs_rd_nick),
    .iROB_rs1_nick(rob_rs_rs1_nick),
    .iROB_rs1_dt(rob_rs_rs1_dt),
    .iROB_rs2_nick(rob_rs_rs2_nick),
    .iROB_rs2_dt(rob_rs_rs2_dt),
    
    .iEX_en(ex_rs_en),
    .iEX_nick(ex_rs_nick),
    .iEX_dt(ex_rs_dt),
    .iSLB_en(slb_rs_en),
    .iSLB_nick(slb_rs_nick),
    .iSLB_dt(slb_rs_dt),
    
    .oEX_en(rs_ex_en),
    .oEX_pc(rs_ex_pc),
    .oEX_op(rs_ex_op),
    .oEX_imm(rs_ex_imm),
    .oEX_rd_nick(rs_ex_rd_nick),
    .oEX_rs1_dt(rs_ex_rs1_dt),
    .oEX_rs2_dt(rs_ex_rs2_dt)
    );
    //slb
    slb slb(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    
    .iROB_en(rob_slb_en),
    .iROB_op(rob_slb_op),
    .iROB_pc(rob_slb_pc),
    .iROB_imm(rob_slb_imm),
    .iROB_rd_nick(rob_slb_rd_nick),
    .iROB_rs1_nick(rob_slb_rs1_nick),
    .iROB_rs1_dt(rob_slb_rs1_dt),
    .iROB_rs2_nick(rob_slb_rs2_nick),
    .iROB_rs2_dt(rob_slb_rs2_dt),
    
    .iEX_en(ex_slb_en),
    .iEX_nick(ex_slb_nick),
    .iEX_dt(ex_slb_dt),
    .iSLB_en(slb_slb_en),
    .iSLB_nick(slb_slb_nick),
    .iSLB_dt(slb_slb_dt),
    .oRS_en(slb_rs_en),
    .oRS_nick(slb_rs_nick),
    .oRS_dt(slb_rs_dt),
    .oSLB_en(slb_slb_en),
    .oSLB_nick(slb_slb_nick),
    .oSLB_dt(slb_slb_dt),
    .oROB_en(slb_rob_en),
    .oROB_nick(slb_rob_nick),
    .oROB_dt(slb_rob_dt),
    
    .iROB_wrong(rob_slb_wrong),
    
    .iROB_commit_en(rob_slb_commit_en),
    .iROB_commit_nick(rob_slb_commit_nick),
    .oDC_en(slb_dc_en),
    .oDC_ls(slb_dc_ls),
    .oDC_nick(slb_dc_nick),
    .oDC_len(slb_dc_len),
    .oDC_addr(slb_dc_pc),
    .oDC_dt(slb_dc_dt),
    
    .iDC_en(dc_slb_en),
    .iDC_nick(dc_slb_nick),
    .iDC_dt(dc_slb_dt)
    );
    
endmodule
