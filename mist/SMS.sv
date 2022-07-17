//============================================================================
//  SMS replica
//
//  Port to MiST
//  Szombathelyi György
//
//  Based on the MiSTer top-level
//  Copyright (C) 2017,2018 Sorgelig
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

module SMS
(
   input         CLOCK_27[0],   // Input clock 27 MHz

   output  [5:0] VGA_R,
   output  [5:0] VGA_G,
   output  [5:0] VGA_B,
   output        VGA_HS,
   output        VGA_VS,

   output        LED,

   output        AUDIO_L,
   output        AUDIO_R,

   input         UART_RX,

   input         SPI_SCK,
   output        SPI_DO,
   input         SPI_DI,
   input         SPI_SS2,
   input         SPI_SS3,
   input         CONF_DATA0,

   output [12:0] SDRAM_A,
   inout  [15:0] SDRAM_DQ,
   output        SDRAM_DQML,
   output        SDRAM_DQMH,
   output        SDRAM_nWE,
   output        SDRAM_nCAS,
   output        SDRAM_nRAS,
   output        SDRAM_nCS,
   output  [1:0] SDRAM_BA,
   output        SDRAM_CLK,
   output        SDRAM_CKE
);

assign LED  = ~ioctl_download & ~bk_ena;

`define USE_SP64

`ifdef USE_SP64
localparam MAX_SPPL = 63;
localparam SP64     = 1'b1;
`else
localparam MAX_SPPL = 7;
localparam SP64     = 1'b0;
`endif

`include "build_id.v"
parameter CONF_STR = {
	"SMS;;",
	"F,BINSMSGG SG ,Load;",
	"S,SAV,Mount;",
	"T7,Write Save RAM;",
	"P1,Video & Audio;",
	"P2,Controls;",
	"P3,System;",
	"P1O34,Scandoubler Fx,None,CRT 25%,CRT 50%,CRT 75%;",
	"P1O2,TV System,NTSC,PAL;",
	"P1OC,FM sound,Enable,Disable;",
	"P2O1,Swap joysticks,No,Yes;",
	"P2O6,Multitap,Disable,Port1;",
	"P2ODE,Lightgun,Disable,Port 1, Port 2;",
	"P3OA,Region,US/UE,Japan;",
`ifdef USE_SP64
	"P3O8,Sprites per line,Std(8),All(64);",
`endif
	"P3O5,BIOS,Enable,Disable;",
	"P3OF,Lock mappers,No,Yes;",
	"T0,Reset;",
	"V,v1.0.",`BUILD_DATE
};

wire       joyswap = status[1];
wire       palmode = status[2];
wire [1:0] scanlines = status[4:3];
wire       enable_bios_n = status[5];
wire       multitap = status[6];
wire       save_ram = status[7];
wire       sprites64 = status[8];
wire       region = status[10];
wire       enable_fm_n = status[12];
wire [1:0] lightgun = status[14:13];
wire       lockmappers = status[15];

////////////////////   CLOCKS   ///////////////////

wire locked;
wire clk_sys;

pll pll
(
	.inclk0(CLOCK_27[0]),
	.c0(clk_sys),
	.locked(locked)
);

assign SDRAM_CLK = clk_sys;

//////////////////   MiST I/O   ///////////////////
wire  [6:0] joy_0;
wire  [6:0] joy_1;
wire  [6:0] joy[4];
wire  [1:0] buttons;
wire [31:0] status;
wire        ypbpr;
wire        no_csync;
wire        scandoubler_disable;

wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire        ioctl_download;
wire  [7:0] ioctl_index;
wire        ioctl_wait;

wire  [8:0] mouse_x;
wire  [8:0] mouse_y;
wire  [7:0] mouse_flags;
wire        mouse_strobe;

reg  [31:0] sd_lba;
reg         sd_rd = 0;
reg         sd_wr = 0;
wire        sd_ack;
wire  [8:0] sd_buff_addr;
wire  [7:0] sd_buff_dout;
wire  [7:0] sd_buff_din;
wire        sd_buff_wr;
wire        img_mounted;
wire [31:0] img_size;

user_io #(.STRLEN($size(CONF_STR)>>3)) user_io
(
		.clk_sys(clk_sys),
		.clk_sd(clk_sys),
		.SPI_SS_IO(CONF_DATA0),
		.SPI_CLK(SPI_SCK),
		.SPI_MOSI(SPI_DI),
		.SPI_MISO(SPI_DO),

		.conf_str(CONF_STR),

		.status(status),
		.scandoubler_disable(scandoubler_disable),
		.ypbpr(ypbpr),
		.no_csync(no_csync),
		.buttons(buttons),
		.joystick_0(joy_0),
		.joystick_1(joy_1),
		.joystick_2(joy[2]),
		.joystick_3(joy[3]),

		.mouse_x(mouse_x),
		.mouse_y(mouse_y),
		.mouse_flags(mouse_flags),
		.mouse_strobe(mouse_strobe),

		.sd_conf(0),
		.sd_sdhc(1),
		.sd_lba(sd_lba),
		.sd_rd(sd_rd),
		.sd_wr(sd_wr),
		.sd_ack(sd_ack),
		.sd_buff_addr(sd_buff_addr),
		.sd_dout(sd_buff_dout),
		.sd_din(sd_buff_din),
		.sd_dout_strobe(sd_buff_wr),
		.img_mounted(img_mounted),
		.img_size(img_size)
);

data_io data_io
(
	.clk_sys(clk_sys),
	.SPI_SCK(SPI_SCK),
	.SPI_DI(SPI_DI),
	.SPI_SS2(SPI_SS2),

	.clkref_n(ioctl_wait),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_download(ioctl_download),
	.ioctl_index(ioctl_index)
);

wire [21:0] ram_addr;
wire  [7:0] ram_dout;
wire        ram_rd;

sdram ram
(
	.*,

	.init(~locked),
	.clk(clk_sys),
	.clkref(ce_cpu_p),

	.waddr(ioctl_addr),
	.din(ioctl_dout),
	.we(rom_wr),
	.we_ack(sd_wrack),

	.raddr((ram_addr[21:0] & cart_mask) + (romhdr ? 10'd512 : 0)),
	.dout(ram_dout),
	.rd(ram_rd),
	.rd_rdy()
);

reg  rom_wr = 0;
wire sd_wrack;
reg  [21:0] cart_mask;
reg  reset;

always @(posedge clk_sys) begin
	reg old_download, old_reset;

	reset <= status[0] | buttons[1] | ioctl_download | bk_reset;

	old_download <= ioctl_download;
	old_reset <= reset;

	if(~old_download && ioctl_download) begin
		cart_mask <= 0;
		ioctl_wait <= 0;
	end else begin
		if(ioctl_wr) begin
			ioctl_wait <= 1;
			rom_wr <= ~rom_wr;
			cart_mask <= cart_mask | ioctl_addr[21:0];
		end else if(ioctl_wait && (rom_wr == sd_wrack)) begin
			ioctl_wait <= 0;
		end
	end
end

wire [15:0] audioL, audioR;

wire       romhdr = ioctl_addr[9:0] == 10'h1FF; // has 512 byte header
wire       gg = ioctl_index[7:6] == 2'd2;

wire [12:0] ram_a;
wire        ram_we;
wire  [7:0] ram_d;
wire  [7:0] ram_q;

wire [14:0] nvram_a;
wire        nvram_we;
wire  [7:0] nvram_d;
wire  [7:0] nvram_q;

system #(MAX_SPPL, "../") system
(
	.clk_sys(clk_sys),
	.ce_cpu(ce_cpu_p),
//	.ce_cpu_p(ce_cpu_p),
//	.ce_cpu_n(ce_cpu_n),
	.ce_vdp(ce_vdp),
	.ce_pix(ce_pix),
	.ce_sp(ce_sp),
	.pal(palmode),
	.gg(gg),
	.region(region),
	.bios_en(~enable_bios_n),

	.RESET_n(~reset),

	.rom_rd(ram_rd),
	.rom_a(ram_addr),
	.rom_do(ram_dout),

	.j1_up(joya[3]),
	.j1_down(joya[2]),
	.j1_left(joya[1]),
	.j1_right(joya[0]),
	.j1_tl(joya[4]),
	.j1_tr(joya[5]),
	.j1_th(joya_th),
	.j2_up(joyb[3]),
	.j2_down(joyb[2]),
	.j2_left(joyb[1]),
	.j2_right(joyb[0]),
	.j2_tl(joyb[4]),
	.j2_tr(joyb[5]),
	.j2_th(joyb_th),
	.pause(joya[6]&joyb[6]),

	.j1_tr_out(joya_tr_out),
	.j1_th_out(joya_th_out),
	.j2_tr_out(joyb_tr_out),
	.j2_th_out(joyb_th_out),

	.x(x),
	.y(y),
	.color(color),
	.mask_column(mask_column),
	.smode_M1(smode_M1),
	.smode_M2(smode_M2),	
	.smode_M3(smode_M3),	
	.mapper_lock(lockmappers),
	.fm_ena(~enable_fm_n),
	.audioL(audioL),
	.audioR(audioR),

	.sp64(sprites64 & SP64),

	.ram_a(ram_a),
	.ram_we(ram_we),
	.ram_d(ram_d),
	.ram_q(ram_q),

	.nvram_a(nvram_a),
	.nvram_we(nvram_we),
	.nvram_d(nvram_d),
	.nvram_q(nvram_q)
);

spram #(.widthad_a(13)) ram_inst
(
	.clock     (clk_sys),
	.address   (ram_a),
	.wren      (ram_we),
	.data      (ram_d),
	.q         (ram_q)
);

wire [8:0] x;
wire [8:0] y;
wire [11:0] color;
wire mask_column;
wire HSync, VSync, HBlank, VBlank;
wire smode_M1, smode_M2, smode_M3;

video video
(
	.clk(clk_sys),
	.ce_pix(ce_pix),
	.pal(palmode),
	.ggres(gg),
	.border(~gg),
	.mask_column(mask_column),
	.x(x),
	.y(y),
   .smode_M1(smode_M1),
	.smode_M3(smode_M3),
	
	.hsync(HSync),
	.vsync(VSync),
	.hblank(HBlank),
	.vblank(VBlank)
);

reg ce_cpu_p;
reg ce_cpu_n;
reg ce_vdp;
reg ce_pix;
reg ce_sp;
always @(negedge clk_sys) begin
	reg [4:0] clkd;

	ce_sp <= clkd[0];
	ce_vdp <= 0;//div5
	ce_pix <= 0;//div10
	ce_cpu_p <= 0;//div15
	ce_cpu_n <= 0;//div15
	clkd <= clkd + 1'd1;
	if (clkd==29) begin
		clkd <= 0;
		ce_vdp <= 1;
		ce_pix <= 1;
	end else if (clkd==24) begin
		ce_vdp <= 1;
		ce_cpu_p <= 1;
	end else if (clkd==19) begin
		ce_vdp <= 1;
		ce_pix <= 1;
	end else if (clkd==17) begin
		ce_cpu_n <= 1;
	end else if (clkd==14) begin
		ce_vdp <= 1;
	end else if (clkd==9) begin
		ce_cpu_p <= 1;
		ce_vdp <= 1;
		ce_pix <= 1;
	end else if (clkd==4) begin
		ce_vdp <= 1;
	end else if (clkd==2) begin
		ce_cpu_n <= 1;
	end
end

/////////////////// CONTROLS //////////////////
wire       joya_tr_out;
wire       joya_th_out;
wire       joyb_tr_out;
wire       joyb_th_out;
wire       joya_th;
wire       joyb_th;
wire       joyser_th;
wire [6:0] joya, joyb;
reg  [1:0] jcnt = 0;

assign joy[0] = joyswap ? joy_1[6:0] : joy_0[6:0];
assign joy[1] = joyswap ? joy_0[6:0] : joy_1[6:0];

always @(posedge clk_sys) begin

	reg old_th;
	reg [15:0] tmr;

	joya <= ~joy[jcnt];
	joyb <= multitap ? 7'h7F : ~joy[1];
	joya_th <=  1'b1;
	joyb_th <=  1'b1;

	if(ce_cpu_p) begin
		if(tmr > 57000) jcnt <= 0;
		else if(joya_th) tmr <= tmr + 1'd1;

		old_th <= joya_th;
		if(old_th & ~joya_th) begin
			tmr <= 0;
			//first clock doesn't count as capacitor has not discharged yet
			if(tmr < 57000) jcnt <= jcnt + 1'd1;
		end
	end

	if(reset | ~multitap) jcnt <= 0;

	if(gun_en) begin
		if(lightgun == 2'b10) begin
			joyb_th <= ~gun_sensor;
			joyb <= {2'b11, ~gun_trigger ,4'b1111};
		end else begin
			joya_th <= ~gun_sensor;
			joya <= {2'b11, ~gun_trigger ,4'b1111};
			joyb <= ~joy[0];
			joyb_th <= 1'b1;
		end
	end
end

wire        gun_en = lightgun && !gg;
wire        gun_target;
wire        gun_sensor;
wire        gun_trigger;
wire [24:0] ps2_mouse = { mouse_strobe_level, mouse_y[7:0], mouse_x[7:0], mouse_flags };
reg         mouse_strobe_level;

always @(posedge clk_sys) if (mouse_strobe) mouse_strobe_level <= ~mouse_strobe_level;

lightgun lightgun_instance
(
	.CLK(clk_sys),
	.RESET(reset),

	.MOUSE(ps2_mouse),
	.MOUSE_XY(1'b1),

	.JOY_X(),
	.JOY_Y(),
	.JOY(),

	.HDE(~HBlank),
	.VDE(~VBlank),
	.CE_PIX(ce_pix),

	.BTN_MODE(1'b1),
	.SIZE(2'b01),
	.SENSOR_DELAY(34),

	.TARGET(gun_target),
	.SENSOR(gun_sensor),
	.TRIGGER(gun_trigger)
);

//////////////////   VIDEO   //////////////////
wire  [3:0] VGA_R_O = HBlank | VBlank ? 4'h0 : (gun_en & gun_target) ? 4'hf : color[3:0];
wire  [3:0] VGA_G_O = HBlank | VBlank ? 4'h0 : (gun_en & gun_target) ? 4'h0 : color[7:4];
wire  [3:0] VGA_B_O = HBlank | VBlank ? 4'h0 : (gun_en & gun_target) ? 4'h0 : color[11:8];

mist_video #(.SD_HCNT_WIDTH(10), .COLOR_DEPTH(4)) mist_video
(
	.clk_sys(clk_sys),
	.scanlines(scanlines),
	.scandoubler_disable(scandoubler_disable),
	.ypbpr(ypbpr),
	.no_csync(no_csync),
	.rotate(2'b00),
	.SPI_DI(SPI_DI),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.HSync(~HSync),
	.VSync(~VSync),
	.R(VGA_R_O),
	.G(VGA_G_O),
	.B(VGA_B_O),
	.VGA_HS(VGA_HS),
	.VGA_VS(VGA_VS),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B)
);


//////////////////   AUDIO   //////////////////

hybrid_pwm_sd dac
(
	.clk(clk_sys),
	.terminate(1'b0),
	.d_l({~audioL[15], audioL[14:0]}),
	.q_l(AUDIO_L),
	.d_r({~audioR[15], audioR[14:0]}),
	.q_r(AUDIO_R)
);


/////////////////////////  STATE SAVE/LOAD  /////////////////////////////
// 8k auxilary RAM - 32k doesn't fit
dpram #(.widthad_a(13)) nvram_inst
(
	.clock_a     (clk_sys),
	.address_a   (nvram_a[12:0]),
	.wren_a      (nvram_we),
	.data_a      (nvram_d),
	.q_a         (nvram_q),
	.clock_b     (clk_sys),
	.address_b   ({sd_lba[3:0],sd_buff_addr}),
	.wren_b      (sd_buff_wr & sd_ack),
	.data_b      (sd_buff_dout),
	.q_b         (sd_buff_din)
);

reg  bk_ena     = 0;
reg  bk_load    = 0;
wire bk_save    = save_ram;
reg  bk_reset   = 0;

always @(posedge clk_sys) begin
	reg  old_load = 0, old_save = 0, old_ack, old_mounted = 0, old_download = 0;
	reg  bk_state = 0;

	bk_reset <= 0;

	old_download <= ioctl_download;
	if (~old_download & ioctl_download) bk_ena <= 0;

	old_mounted <= img_mounted;
	if(~old_mounted && img_mounted && img_size) begin
		bk_ena <= 1;
		bk_load <= 1;
	end

	old_load <= bk_load;
	old_save <= bk_save;
	old_ack  <= sd_ack;

	if(~old_ack & sd_ack) {sd_rd, sd_wr} <= 0;

	if(!bk_state) begin
		if(bk_ena & ((~old_load & bk_load) | (~old_save & bk_save))) begin
			bk_state <= 1;
			sd_lba <= 0;
			sd_rd <=  bk_load;
			sd_wr <= ~bk_load;
		end
	end else begin
		if(old_ack & ~sd_ack) begin
			if(&sd_lba[3:0]) begin
				if (bk_load) bk_reset <= 1;
				bk_load <= 0;
				bk_state <= 0;
			end else begin
				sd_lba <= sd_lba + 1'd1;
				sd_rd  <=  bk_load;
				sd_wr  <= ~bk_load;
			end
		end
	end
end

endmodule
