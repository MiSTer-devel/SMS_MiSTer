//============================================================================
//  SMS replica
// 
//  Port to MiSTer
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

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [44:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	output  [7:0] VIDEO_ARX,
	output  [7:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S, // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)
	input         TAPE_IN,

	// SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE
);

assign {SD_SCK, SD_MOSI, SD_CS} = '1;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = '0;

assign LED_USER  = 0;
assign LED_DISK  = 0;
assign LED_POWER = 0;

assign VIDEO_ARX = status[9] ? 8'd16 : 8'd4;
assign VIDEO_ARY = status[9] ? 8'd9  : 8'd3;

`include "build_id.v"
localparam CONF_STR = {
	"SMS;;",
	"-;",
	"F,SMS,Load ROM;",
	"-;",
	"O9,Aspect ratio,4:3,16:9;",
	"O2,TV System,NTSC,PAL;",
	"-;",
	"O1,Swap joysticks,No,Yes;",
	"-;",
	"TA,Reset;",
	"J1,Fire 1,Fire 2,Pause;",
	"V,v1.0.",`BUILD_DATE
};


////////////////////   CLOCKS   ///////////////////

wire locked;
wire clk_sys = clk_cpu;
wire clk_mem;
wire clk_cpu;
wire clk_vid;

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_mem),
	.outclk_1(SDRAM_CLK),
	.outclk_2(clk_cpu),
	.outclk_3(clk_vid),
	.locked(locked)
);

wire cold_reset = RESET | status[0] | ~initReset_n;
wire reset = cold_reset | buttons[1] | status[10] | ioctl_download;

reg initReset_n = 0;
always @(posedge clk_sys) begin
	integer timeout = 0;
	
	if(timeout < 5000000) timeout <= timeout + 1;
	else initReset_n <= 1;
end

//////////////////   HPS I/O   ///////////////////
wire [15:0] joy_0;
wire [15:0] joy_1;
wire  [1:0] buttons;
wire [31:0] status;

wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire        ioctl_download;
wire  [7:0] ioctl_index;

hps_io #(.STRLEN($size(CONF_STR)>>3)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.conf_str(CONF_STR),

	.joystick_0(joy_0),
	.joystick_1(joy_1),

	.buttons(buttons),
	.status(status),

	.ps2_kbd_led_use(0),
	.ps2_kbd_led_status(0),

	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_download(ioctl_download),
	.ioctl_index(ioctl_index),

	.sd_lba(0),
	.sd_rd(0),
	.sd_wr(0),
	.sd_conf(0),
	.sd_buff_din(0),
	.ioctl_wait(0)
);

wire [21:0] ram_addr;
wire  [7:0] ram_dout;
wire        ram_rd;

sdram ram
(
	.*,
	.init(~locked),
	.clk(clk_mem),
	.dout(ram_dout),
	.din (ioctl_dout),
	.addr(ioctl_download ? ioctl_addr : {ram_addr[21:14] & cart_sz, ram_addr[13:0]}),
	.wtbt(0),
	.we(ioctl_wr),
	.rd(ram_rd),
	.ready()
);

assign CLK_VIDEO = clk_vid;
assign CE_PIXEL = ce_pix;

wire [5:0] audio;

assign AUDIO_L = {audio, audio, audio[5:3]};
assign AUDIO_R = AUDIO_L;
assign AUDIO_S = 0;
assign AUDIO_MIX = 0;

wire [6:0] joya = status[1] ? ~joy_1[6:0] : ~joy_0[6:0];
wire [6:0] joyb = status[1] ? ~joy_0[6:0] : ~joy_1[6:0];

reg  dbr = 0;
always @(posedge clk_sys) begin
	if(ioctl_download) dbr <= 1;
end

wire [7:0] cart_sz = ioctl_addr[21:14]-1'd1;

system system
(
	.clk_cpu(clk_cpu),
	.clk_vdp(clk_cpu),

	.rom_rd(ram_rd),
	.rom_a(ram_addr),
	.rom_do(ram_dout),

	.j1_up(joya[3]),
	.j1_down(joya[2]),
	.j1_left(joya[1]),
	.j1_right(joya[0]),
	.j1_tl(joya[4]),
	.j1_tr(joya[5]),
	.j2_up(joyb[3]),
	.j2_down(joyb[2]),
	.j2_left(joyb[1]),
	.j2_right(joyb[0]),
	.j2_tl(joyb[4]),
	.j2_tr(joyb[5]),
	.reset(~reset),
	.pause(joya[6]&joyb[6]),

	.x(x),
	.y(y),
	.color(color),
	.audio(audio),

	.dbr(dbr)
);

wire [8:0] x;
wire [7:0] y;
wire [5:0] color;
assign {VGA_R, VGA_G, VGA_B} = {{4{color[1:0]}}, {4{color[3:2]}}, {4{color[5:4]}}};

video video
(
	.clk8(clk_cpu),
	.pal(status[2]),
	.x(x),
	.y(y),

	.hsync(VGA_HS),
	.vsync(VGA_VS),
	.de(VGA_DE)
);

reg ce_pix;
always @(posedge clk_vid) begin
	reg old_clk;
	
	old_clk <= clk_cpu;
	ce_pix <= ~old_clk & clk_cpu;
end

endmodule
