//============================================================================
//  SMS replica
// 
//  Port to MiSTer
//  Copyright (C) 2017-2019 Sorgelig
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
	inout  [45:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,

`ifdef USE_FB
	// Use framebuffer in DDRAM (USE_FB=1 in qsf)
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

`ifdef USE_DDRAM
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
`endif

`ifdef USE_SDRAM
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
	output        SDRAM_nWE,
`endif

`ifdef DUAL_SDRAM
	//Secondary SDRAM
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

assign ADC_BUS  = 'Z;
assign VGA_F1 = 0;

assign {UART_RTS, UART_TXD, UART_DTR} = 0;

assign {SD_SCK, SD_MOSI, SD_CS} = '1;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = '0;

assign LED_USER  = cart_download | bk_state | (status[25] & bk_pending);
assign LED_DISK  = 0;
assign LED_POWER = 0;
assign BUTTONS   = 0;
assign VGA_SCALER= 0;

reg en216p;
always @(posedge CLK_VIDEO) en216p <= ((HDMI_WIDTH == 1920) && (HDMI_HEIGHT == 1080) && !forced_scandoubler && !scale);

wire [1:0] ar = status[27:26];
wire vga_de;
video_freak video_freak
(
	.*,
	.VGA_DE_IN(vga_de),
	.ARX((!ar) ? (border ? 12'd47 : 12'd32) : (ar - 1'd1)),
	.ARY((!ar) ? (border ? 12'd35 : 12'd21) : 12'd0),
	.CROP_SIZE(en216p ? 10'd216 : 10'd0),
	.CROP_OFF(0),
	.SCALE(status[31:30])
);


// Status Bit Map:
//             Upper                             Lower              
// 0         1         2         3          4         5         6   
// 01234567890123456789012345678901 23456789012345678901234567890123
// 0123456789ABCDEFGHIJKLMNOPQRSTUV 0123456789ABCDEFGHIJKLMNOPQRSTUV
// XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

`include "build_id.v"
parameter CONF_STR = {
	"SMS;;",
	"-;",
	"FS1,SMSSG;",
	"FS2,GG;",
	"-;",
	"C,Cheats;",
	"H1OO,Cheats enabled,ON,OFF;",
	"-;",
	"D0R6,Load Backup RAM;",
	"D0R7,Save Backup RAM;",
	"D0OP,Autosave,OFF,ON;",
	"-;",

	"OA,Region,US/UE,Japan;",
	"OB,BIOS,Enable,Disable;",
	"OF,Disable mapper,No,Yes;",
	"-;",

	"P1,Audio & Video;",
	"P1-;",
	"P1O2,TV System,NTSC,PAL;",
	"P1OQR,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"P1O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"P1-;",
	"P1OUV,Scale,Normal,V-Integer,Narrower HV-Integer,Wider HV-Integer;",
	"P1-;",
	"P1OD,Border,No,Yes;",
	"D5P1OST,Masked left column,BG,Black,Cut;",
	"P1O8,Sprites per line,Standard,All;",
	"P1-;",
	"D2P1OC,SMS FM sound,Enable,Disable;",

	"P2,Input;",
	"P2-;",
	"P2O1,Swap joysticks,No,Yes;",
	"P2OE,Multitap,Disabled,Port1;",
	"D3P2OH,Pause Btn Combo,No,Yes;",
	"P2-;",
	"P2OG,Serial,OFF,SNAC;",
	"P2-;",
	"D2P2OIJ,Gun Control,Disabled,Joy1,Joy2,Mouse;",
	"D4P2OK,Gun Fire,Joy,Mouse;",
	"D4P2OL,Gun Port,Port1,Port2;",
	"D4P2OMN,Cross,Small,Medium,Big,None;",
	"P2-;",
	"P2o0,Paddle,Disabled,Enabled;",

	"-;",
	"R0,Reset;",
	"J1,Fire 1,Fire 2,Pause;",
	"jn,A|P,B,Start;",
	"jp,Y|P,A,Start;",
	"V,v",`BUILD_DATE
};


////////////////////   CLOCKS   ///////////////////

wire locked;
wire clk_sys;

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_sys),
	.locked(locked)
);

wire reset = RESET | status[0] | buttons[1] | cart_download | bk_loading;

//////////////////   HPS I/O   ///////////////////
wire  [6:0] joy[4], joy_0, joy_1;
wire  [7:0] joy0_x,joy0_y,joy1_x,joy1_y;
wire  [7:0] paddle_0, paddle_1;
wire  [1:0] buttons;
wire [63:0] status;

wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire        ioctl_download;
wire  [7:0] ioctl_index;
wire        ioctl_wait;

reg  [31:0] sd_lba;
reg         sd_rd = 0;
reg         sd_wr = 0;
wire        sd_ack;
wire  [8:0] sd_buff_addr;
wire  [7:0] sd_buff_dout;
wire  [7:0] sd_buff_din;
wire        sd_buff_wr;
wire        img_mounted;
wire        img_readonly;
wire [63:0] img_size;

wire        forced_scandoubler;
wire [21:0] gamma_bus;

wire [24:0] ps2_mouse;

hps_io #(.STRLEN($size(CONF_STR)>>3), .WIDE(0)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.conf_str(CONF_STR),

	.joystick_0(joy_0),
	.joystick_1(joy_1),
	.joystick_2(joy[2]),
	.joystick_3(joy[3]),
	.joystick_analog_0({joy0_y, joy0_x}),
	.joystick_analog_1({joy1_y, joy1_x}),
	.paddle_0(paddle_0),
	.paddle_1(paddle_1),

	.buttons(buttons),
	.status(status),
	.status_menumask({en216p,status[13],~gun_en,~raw_serial,gg,~gg_avail,~bk_ena}),
	.forced_scandoubler(forced_scandoubler),
	.new_vmode(pal),
	.gamma_bus(gamma_bus),

	.ps2_kbd_led_use(0),
	.ps2_kbd_led_status(0),

	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_download(ioctl_download),
	.ioctl_index(ioctl_index),

	.sd_conf(0),
	.ioctl_wait(ioctl_wait),
	
	.sd_lba(sd_lba),
	.sd_rd(sd_rd),
	.sd_wr(sd_wr),
	.sd_ack(sd_ack),
	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din(sd_buff_din),
	.sd_buff_wr(sd_buff_wr),
	.img_mounted(img_mounted),
	.img_readonly(img_readonly),
	.img_size(img_size),
	
	.ps2_mouse(ps2_mouse)
);

wire [21:0] ram_addr;
wire  [7:0] ram_dout;
wire        ram_rd;

wire code_index = &ioctl_index;
wire code_download = ioctl_download & code_index;
wire cart_download = ioctl_download & ~code_index;

sdram ram
(
	.*,

	.init(~locked),
	.clk(clk_sys),
	.clkref(ce_cpu),

	.waddr(romwr_a),
	.din(ioctl_dout),
	.we(rom_wr),
	.we_ack(sd_wrack),

	.raddr(cart_sz512 ? (ram_addr + 10'd512) & cart_mask512 : ram_addr & cart_mask),
	.dout(ram_dout),
	.rd(ram_rd),
	.rd_rdy()
);

altddio_out
#(
	.extend_oe_disable("OFF"),
	.intended_device_family("Cyclone V"),
	.invert_output("OFF"),
	.lpm_hint("UNUSED"),
	.lpm_type("altddio_out"),
	.oe_reg("UNREGISTERED"),
	.power_up_high("OFF"),
	.width(1)
)
sdramclk_ddr
(
	.datain_h(1'b0),
	.datain_l(1'b1),
	.outclock(clk_sys),
	.dataout(SDRAM_CLK),
	.aclr(1'b0),
	.aset(1'b0),
	.oe(1'b1),
	.outclocken(1'b1),
	.sclr(1'b0),
	.sset(1'b0)
);

reg  rom_wr = 0;
wire sd_wrack;
reg  [23:0] romwr_a;

always @(posedge clk_sys) begin
	reg old_download, old_reset;

	old_download <= cart_download;
	old_reset <= reset;

	if(~old_reset && reset) ioctl_wait <= 0;
	if(~old_download && cart_download) romwr_a <= 0;
	else begin
		if(ioctl_wr & cart_download) begin
			ioctl_wait <= 1;
			rom_wr <= ~rom_wr;
		end else if(ioctl_wait && (rom_wr == sd_wrack)) begin
			ioctl_wait <= 0;
			romwr_a <= romwr_a + 1'd1;
		end
	end
end

assign AUDIO_S = 1;
assign AUDIO_MIX = 1;

reg [128:0] gg_code;
wire gg_avail;

// Code layout:
// {clock bit, code flags,     32'b address, 32'b compare, 32'b replace}
//  128        127:96          95:64         63:32         31:0
// Integer values are in BIG endian byte order, so it up to the loader
// or generator of the code to re-arrange them correctly.

always_ff @(posedge clk_sys) begin
	gg_code[128] <= 1'b0;

	if (code_download & ioctl_wr) begin
		case (ioctl_addr[3:0])
			0:  gg_code[111:96]  <= ioctl_dout; // Flags Bottom Word
			1:  gg_code[119:112]  <= ioctl_dout; // Flags Bottom Word
			2:  gg_code[127:120] <= ioctl_dout; // Flags Top Word
			3:  gg_code[127:112] <= ioctl_dout; // Flags Top Word
			4:  gg_code[71:64]   <= ioctl_dout; // Address Bottom Word
			5:  gg_code[79:72]   <= ioctl_dout; // Address Bottom Word
			6:  gg_code[87:80]   <= ioctl_dout; // Address Top Word
			7:  gg_code[95:88]   <= ioctl_dout; // Address Top Word
			8:  gg_code[39:32]   <= ioctl_dout; // Compare Bottom Word
			9:  gg_code[47:40]   <= ioctl_dout; // Compare Bottom Word
			10: gg_code[55:48]   <= ioctl_dout; // Compare top Word
			11: gg_code[63:56]   <= ioctl_dout; // Compare top Word
			12: gg_code[7:0]    <= ioctl_dout; // Replace Bottom Word
			13: gg_code[15:8]    <= ioctl_dout; // Replace Bottom Word
			14: gg_code[23:16]   <= ioctl_dout; // Replace Top Word
			15: begin
				gg_code[31:24]   <= ioctl_dout; // Replace Top Word
				gg_code[128]     <=  1'b1;      // Clock it in
			end
		endcase
	end
end


reg  dbr = 0;
always @(posedge clk_sys) begin
	if(cart_download || bk_loading) dbr <= 1;
end

reg gg = 0;
reg [21:0] cart_mask, cart_mask512;
reg cart_sz512;

always @(posedge clk_sys) begin
	reg old_download;
	old_download <= cart_download;

	if(ioctl_wr & cart_download) begin
		cart_mask <= cart_mask | ioctl_addr[21:0];
		cart_mask512 <= cart_mask512 | (ioctl_addr[21:0] - 10'd512);
		if(!ioctl_addr) cart_mask <= 0;
		if(ioctl_addr == 512) cart_mask512 <= 0;
		gg <= ioctl_index[4:0] == 2;	
	end;
	if (old_download & ~cart_download) begin
		cart_sz512 <= ioctl_addr[9];
	end;
end

wire [12:0] ram_a;
wire        ram_we;
wire  [7:0] ram_d;
wire  [7:0] ram_q;

wire [14:0] nvram_a;
wire        nvram_we;
wire  [7:0] nvram_d;
wire  [7:0] nvram_q;

system #(63) system
(
	.clk_sys(clk_sys),
	.ce_cpu(ce_cpu),
	.ce_vdp(ce_vdp),
	.ce_pix(ce_pix),
	.ce_sp(ce_sp),
	.gg(gg),
	.bios_en(~status[11]),

	.RESET_n(~reset),

	.GG_RESET(ioctl_download && ioctl_wr && !ioctl_addr),
	.GG_EN(status[24]),
	.GG_CODE(gg_code),
	.GG_AVAIL(gg_avail),

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
	.black_column(status[28] && ~status[13]),
	.smode_M1(smode_M1),
	.smode_M2(smode_M2),
	.smode_M3(smode_M3),
	.pal(pal),
	.region(status[10]),
	.mapper_lock(status[15]),

	.fm_ena(~status[12] | gg),
	.audioL(audio_l),
	.audioR(audio_r),

	.dbr(dbr),
	.sp64(status[8]),

	.ram_a(ram_a),
	.ram_we(ram_we),
	.ram_d(ram_d),
	.ram_q(ram_q),

	.nvram_a(nvram_a),
	.nvram_we(nvram_we),
	.nvram_d(nvram_d),
	.nvram_q(nvram_q)
);

assign joy[0] = status[1] ? joy_1 : joy_0;
assign joy[1] = status[1] ? joy_0 : joy_1;

wire raw_serial = status[16];
wire pause_combo = status[17];
wire swap = status[1];

wire [6:0] joya;	
wire [6:0] joyb;
wire [6:0] joyser;

wire      joya_tr_out;
wire      joya_th_out;
wire      joyb_tr_out;
wire      joyb_th_out;
wire      joya_th;
wire      joyb_th;
wire      joyser_th;
reg [1:0] jcnt = 0;

always @(posedge clk_sys) begin
	reg old_th;
	reg [15:0] tmr;

	if (raw_serial) begin
		joyser[3] <= USER_IN[1];//up
		joyser[2] <= USER_IN[0];//down	
		joyser[1] <= USER_IN[5];//left
		joyser[0] <= USER_IN[3];//right	
		joyser[4] <= USER_IN[2];//trigger / button1
		joyser[5] <= USER_IN[6];//button2
		joyser_th <= USER_IN[4];//sensor
		
		if (tmr) tmr <= tmr - 1'd1;
		if (!USER_IN[0] & !USER_IN[2] & !USER_IN[6] & pause_combo) begin //D 1 2 combo
			tmr <= 57000;
		end
		joyser[6] <= !tmr;
		
		joya <= swap ? ~joy[1] : joyser;
		joyb <= swap ? joyser : ~joy[0];	
		joya_th <=  swap ? 1'b1 : joyser_th;
		joyb_th <=  swap ? joyser_th : 1'b1;

		USER_OUT <= {swap ? joyb_tr_out : joya_tr_out, 1'b1, swap ? joyb_th_out : joya_th_out, 4'b1111, };

	end else begin
		joya <= ~joy[jcnt];
		joyb <= status[14] ? 7'h7F : ~joy[1];
		joya_th <=  1'b1;
		joyb_th <=  1'b1;
				

		if(ce_cpu) begin
			if(tmr > 57000) jcnt <= 0;
			else if(joya_th) tmr <= tmr + 1'd1;

			old_th <= joya_th;
			if(old_th & ~joya_th) begin
				tmr <= 0;
			//first clock doesn't count as capacitor has not discharged yet
			if(tmr < 57000) jcnt <= jcnt + 1'd1;
			end
		end

		if(reset | ~status[14]) jcnt <= 0;
	
		USER_OUT <= 7'b1111111;
	end
	
	if(gun_en) begin
		if(gun_port) begin
			joyb_th <= ~gun_sensor;
			joyb <= {2'b11, ~gun_trigger ,4'b1111};
		end else begin
			joya_th <= ~gun_sensor;
			joya <= {2'b11, ~gun_trigger ,4'b1111};
			joyb <= raw_serial ? joyser : ~joy[0];
			joyb_th <= raw_serial ? joyser_th : 1'b1;
		end
	end

	if (paddle_en) begin
		{joya[0], joya[1], joya[2], joya[3], joya[5]} <= {paddle_0_nib, paddle_0_tr};
		{joyb[0], joyb[1], joyb[2], joyb[3], joyb[5]} <= {paddle_1_nib, paddle_1_tr};
	end
end

spram #(.widthad_a(13)) ram_inst
(
	.clock     (clk_sys),
	.address   (ram_a),
	.wren      (ram_we),
	.data      (ram_d),
	.q         (ram_q)
);

wire [15:0] audio_l, audio_r; 

compressor compressor
(
	clk_sys,
	audio_l[15:4], audio_r[15:4],
	AUDIO_L,       AUDIO_R
); 

wire [8:0] x;
wire [8:0] y;
wire [11:0] color;
wire mask_column;
wire smode_M1, smode_M2, smode_M3;
wire pal = status[2];
wire border = status[13] & ~gg;

video video
(
	.clk(clk_sys),
	.ce_pix(ce_pix),
	.pal(pal),
	.gg(gg),
	.border(border),
	.mask_column(mask_column),
	.cut_mask(status[29]),
   .smode_M1(smode_M1),
	.smode_M3(smode_M3),
	.x(x),
	.y(y),
	.hsync(HS),
	.vsync(VS),
	.hblank(HBlank),
	.vblank(VBlank)
);

reg ce_cpu;
reg ce_vdp;
reg ce_pix;
reg ce_sp;
always @(negedge clk_sys) begin
	reg [4:0] clkd;

	ce_sp <= clkd[0];
	ce_vdp <= 0;//div5
	ce_pix <= 0;//div10
	ce_cpu <= 0;//div15
	clkd <= clkd + 1'd1;
	if (clkd==29) begin
		clkd <= 0;
		ce_vdp <= 1;
		ce_pix <= 1;
	end else if (clkd==24) begin
		ce_cpu <= 1;  //-- changed cpu phase to please VDPTEST HCounter test;
		ce_vdp <= 1;
	end else if (clkd==19) begin
		ce_vdp <= 1;
		ce_pix <= 1;
	end else if (clkd==14) begin
		ce_vdp <= 1;
	end else if (clkd==9) begin
		ce_cpu <= 1;
		ce_vdp <= 1;
		ce_pix <= 1;
	end else if (clkd==4) begin
		ce_vdp <= 1;
	end
end

wire HS, VS;
reg  HSync, VSync;
wire HBlank, VBlank;

wire [2:0] scale = status[5:3];
wire [2:0] sl = scale ? scale - 1'd1 : 3'd0;

assign CLK_VIDEO = clk_sys;
assign VGA_SL = sl[1:0];

always @(posedge CLK_VIDEO) begin
	HSync <= HS;
	if(~HSync & HS) VSync <= VS;
end

video_mixer #(.HALF_DEPTH(1), .LINE_LENGTH(300), .GAMMA(1)) video_mixer
(
	.*,
	.scandoubler(scale || forced_scandoubler),
	.hq2x(scale==1),

	.VGA_DE(vga_de),
	.R((gun_en & gun_target) ? 8'd255 : {2{color[3:0]}}),
	.G((gun_en & gun_target) ? 8'd0   : {2{color[7:4]}}),
	.B((gun_en & gun_target) ? 8'd0   : {2{color[11:8]}})
);


/////////////////////////  STATE SAVE/LOAD  /////////////////////////////
wire bk_save_write = nvram_we;
reg bk_pending;

always @(posedge clk_sys) begin
	if (bk_ena && ~OSD_STATUS && bk_save_write)
		bk_pending <= 1'b1;
	else if (bk_state)
		bk_pending <= 1'b0;
end

dpram #(.widthad_a(15)) nvram_inst
(
	.clock_a     (clk_sys),
	.address_a   (nvram_a),
	.wren_a      (nvram_we),
	.data_a      (nvram_d),
	.q_a         (nvram_q),
	.clock_b     (clk_sys),
	.address_b   ({sd_lba[5:0],sd_buff_addr}),
	.wren_b      (sd_buff_wr & sd_ack),
	.data_b      (sd_buff_dout),
	.q_b         (sd_buff_din)
);

wire downloading = cart_download;
reg old_downloading = 0;
reg bk_ena = 0;
always @(posedge clk_sys) begin
	
	old_downloading <= downloading;
	if(~old_downloading & downloading) bk_ena <= 0;
	
	//Save file always mounted in the end of downloading state.
	if(downloading && img_mounted && !img_readonly) bk_ena <= 1;
end

wire bk_load    = status[6];
wire bk_save    = status[7] | (bk_pending & OSD_STATUS && status[25]);
reg  bk_loading = 0;
reg  bk_state   = 0;

always @(posedge clk_sys) begin
	reg old_load = 0, old_save = 0, old_ack;

	old_load <= bk_load & bk_ena;
	old_save <= bk_save & bk_ena;
	old_ack  <= sd_ack;
	
	if(~old_ack & sd_ack) {sd_rd, sd_wr} <= 0;
	
	if(!bk_state) begin
		if((~old_load & bk_load) | (~old_save & bk_save)) begin
			bk_state <= 1;
			bk_loading <= bk_load;
			sd_lba <= 0;
			sd_rd <=  bk_load;
			sd_wr <= ~bk_load;
		end
		if(old_downloading & ~downloading & |img_size & bk_ena) begin
			bk_state <= 1;
			bk_loading <= 1;
			sd_lba <= 0;
			sd_rd <= 1;
			sd_wr <= 0;
		end 
	end else begin
		if(old_ack & ~sd_ack) begin
			if(&sd_lba[5:0]) begin
				bk_loading <= 0;
				bk_state <= 0;
			end else begin
				sd_lba <= sd_lba + 1'd1;
				sd_rd  <=  bk_loading;
				sd_wr  <= ~bk_loading;
			end
		end
	end
end

wire [1:0] gun_mode = status[19:18];
wire       gun_btn_mode = status[20];
wire       gun_port = status[21];
wire       gun_en = gun_mode && !gg;
wire       gun_target;
wire       gun_sensor;
wire       gun_trigger;

lightgun lightgun
(
	.CLK(clk_sys),
	.RESET(reset),

	.MOUSE(ps2_mouse),
	.MOUSE_XY(&gun_mode),

	.JOY_X(gun_mode[0] ? joy0_x : joy1_x),
	.JOY_Y(gun_mode[0] ? joy0_y : joy1_y),
	.JOY(gun_mode[0] ? joy_0 : joy_1),

	.HDE(~HBlank),
	.VDE(~VBlank),
	.CE_PIX(ce_pix),

	.BTN_MODE(gun_btn_mode),
	.SIZE(status[23:22]),
	.SENSOR_DELAY(34),

	.TARGET(gun_target),
	.SENSOR(gun_sensor),
	.TRIGGER(gun_trigger)
);

// Paddle support
wire       jp_region    = status[10];
wire       paddle_en    = status[32];

reg  [3:0] paddle_0_nib,   paddle_1_nib;
reg  [3:0] paddle_0_nib_q, paddle_1_nib_q;
reg        paddle_0_tr,    paddle_1_tr;

reg        joya_th_out_q,  joyb_th_out_q;
wire       joya_th_rise,   joyb_th_rise;
wire       joya_th_fall,   joyb_th_fall;

always_ff @(posedge clk_sys) begin
	if (jp_region) begin
		// Japanese paddle (HPD-200)
		if (en16khz) begin
			if (paddle_0_tr) begin
				{paddle_0_nib_q, paddle_0_nib} <= paddle_0;
				{paddle_1_nib_q, paddle_1_nib} <= paddle_1;
				paddle_0_tr  <= 1'b0;
				paddle_1_tr  <= 1'b0;
			end else begin
				paddle_0_nib <= paddle_0_nib_q;
				paddle_1_nib <= paddle_1_nib_q;
				paddle_0_tr  <= 1'b1;
				paddle_1_tr  <= 1'b1;
			end
		end
	end else begin
		// Export paddle (Non-existent but implemented in some games?)
		joya_th_out_q <= joya_th_out;
		joyb_th_out_q <= joyb_th_out;

		if (joya_th_fall) begin
			{paddle_0_nib_q, paddle_0_nib} <= paddle_0;
			paddle_0_tr  <= 1'b0;
		end else if (joya_th_rise) begin
			paddle_0_nib <= paddle_0_nib_q;
			paddle_0_tr  <= 1'b0;
		end

		if (joyb_th_fall) begin
			{paddle_1_nib_q, paddle_1_nib} <= paddle_1;
			paddle_1_tr  <= 1'b0;
		end else if (joyb_th_rise) begin
			paddle_1_nib <= paddle_1_nib_q;
			paddle_1_tr  <= 1'b0;
		end
	end
end

assign joya_th_rise = ~joya_th_out_q &  joya_th_out;
assign joyb_th_rise = ~joyb_th_out_q &  joyb_th_out;
assign joya_th_fall =  joya_th_out_q & ~joya_th_out;
assign joyb_th_fall =  joyb_th_out_q & ~joyb_th_out;

wire       en16khz;
reg [11:0] cnt_en16khz;

always_ff @(posedge clk_sys) begin
	cnt_en16khz <= cnt_en16khz + 1'd1;
	if (cnt_en16khz == 3355) cnt_en16khz <= 0;
end
assign en16khz = cnt_en16khz == 0;

endmodule


