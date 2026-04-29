// savestates.sv
// Pure-hardware save-state FSM for SMS_MiSTer.
//
// Memory layout (DDRAM word addresses, slot n base = 0x3E000000 + n*0x10000):
//   Word 0x000: MiSTer SS control word [31:0]=change_det, [63:32]=size_in_32b_words
//   Word 0x001: magic "SMS1" (0x534D5331)
//   Word 0x002-0x005: Z80 REG[211:0]   (4 × 64-bit words, MSBs unused)
//   Word 0x006-0x007: VDP regs [127:0] (2 × 64-bit words)
//   Word 0x008-0x00D: CRAM [383:0]     (6 × 64-bit words)
//   Word 0x00E:       PSG  [55:0]      (1 × 64-bit word, upper 8 bits unused)
//   Word 0x00F:       Mapper [63:0]    (1 × 64-bit word)
//   Words 0x101-0x900: VRAM 16KB       (2048 × 64-bit words)
//   Words 0x901-0xD00: WRAM 8KB        (1024 × 64-bit words)
//   Words 0xD01-0x1100: NVRAM 8KB (Dahjee A only)
//
// Slot size = 0x2000 words = 64KB.  Up to 4 slots.
// Base word address = 29'h07C00000 + slot * 29'h2000

module savestates (
    input             clk,
    input             reset_n,

    // Trigger interface (from savestate_ui)
    input             ss_save,         // one-cycle save pulse
    input             ss_load,         // one-cycle load pulse
    input       [1:0] ss_slot,
    input             ss_bios_mode,    // 1 when running BIOS without cart

    // Freeze: hold '1' to pause CPU + VDP clock enables
    output reg        ss_freeze,

    // VBlank level from video.vhd (not gated by ss_freeze)
    // Used to defer unfreeze until a clean frame boundary after load
    input             vblank,

    // ---- Z80 snapshot / restore ----
    input     [211:0] z80_reg,         // live snapshot from T80s
    output reg [211:0] z80_dir,        // restore data
    output reg        z80_set,         // one-cycle restore strobe
    input             z80_m1_n,        // Z80 M1 cycle (low = opcode fetch in progress)
    // '0' = memory request = normal opcode fetch; '1' = interrupt acknowledge (skip!)
    input             z80_mreq_n,
    // "00" = no active prefix = clean instruction boundary (safe to save)
    input       [1:0] z80_iset,
    // Raw CPU clock-enable pulse (ungated by ss_freeze)
    input             cpu_ce,
    // Raw VDP clock-enable pulse (ungated by ss_freeze)
    input             vdp_ce,

    // ---- VDP registers ----
    input     [127:0] vdp_regs,
    output reg [127:0] vdp_regs_in,
    output reg        vdp_regs_set,

    // ---- CRAM ----
    input     [383:0] cram_out,
    output reg  [4:0] cram_A,
    output reg [11:0] cram_D,
    output reg        cram_wr,

    // ---- VRAM DMA (port A of dpram in vdp, muxed when freeze) ----
    output reg        vram_en,         // take over port A for reads
    output reg [14:0] vram_A,          // read address
    input       [7:0] vram_D,          // read data (2-cycle latency after vram_A changes)
    output reg        vram_WE,
    output reg [14:0] vram_WA,
    output reg  [7:0] vram_WD,

    // ---- PSG snapshot / restore ----
    input      [55:0] psg_out,
    output reg [55:0] psg_in,
    output reg        psg_set,

    // ---- Mapper snapshot / restore ----
    input      [63:0] mapper_out,
    output reg [63:0] mapper_in,
    output reg        mapper_set,

    // ---- Work RAM DMA (second port of a dpram) ----
    output reg [13:0] wram_A,          // read address (byte)
    input       [7:0] wram_D,          // read data
    output reg        wram_WE,
    output reg [13:0] wram_WA,
    output reg  [7:0] wram_WD,

    // ---- NVRAM DMA (Dahjee A expansion RAM, 8KB at $2000-$3FFF) ----
    // Only saved/restored when mapper_snap[48] (detect_dahjee_a) is set.
    output reg [12:0] nvram_A,          // read address
    input       [7:0] nvram_D,          // read data
    output reg        nvram_WE,
    output reg [12:0] nvram_WA,
    output reg  [7:0] nvram_WD,

    // ---- DDRAM interface ----
    output reg [28:0] DDRAM_ADDR,
    output reg [63:0] DDRAM_DIN,
    output reg  [7:0] DDRAM_BE,
    output reg        DDRAM_WE,
    input      [63:0] DDRAM_DOUT,
    input             DDRAM_DOUT_READY,
    output reg        DDRAM_RD,
    output reg  [7:0] DDRAM_BURSTCNT,
    input             DDRAM_BUSY
);

// -----------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------
localparam [31:0] MAGIC = 32'h534D5331; // "SMS1"
localparam [31:0] MAGIC_BIOS = 32'h534D5342; // "SMSB"

// Slot base word address for cartridge savestates (slots 0-3)
function automatic [28:0] slot_base;
    input [1:0] slot;
    slot_base = 29'h07C00000 + {27'd0, slot} * 29'h2000;
endfunction

// Slot base word address for BIOS savestates (slots 4-7).
// Placed after the 4 game slots so game and BIOS state never share the same
// DDRAM words. Addresses here are outside the CONF_STR SS range so the
// MiSTer ARM side will not write them to disk -- BIOS states are DDRAM-only.
function automatic [28:0] bios_slot_base;
    input [1:0] slot;
    bios_slot_base = 29'h07C08000 + {27'd0, slot} * 29'h2000;
endfunction

// -----------------------------------------------------------------------
// State machine
// -----------------------------------------------------------------------
localparam ST_IDLE         = 6'd0;
localparam ST_WAIT_BOUNDARY= 6'd37;  // wait for Z80 instruction boundary (M1)
localparam ST_ARM_FREEZE   = 6'd41;  // assert freeze so it is active before next CE pulse
localparam ST_FREEZE       = 6'd1;
localparam ST_SAVE_HDR     = 6'd2;
localparam ST_SAVE_CPU0    = 6'd3;
localparam ST_SAVE_CPU1    = 6'd4;
localparam ST_SAVE_CPU2    = 6'd5;
localparam ST_SAVE_CPU3    = 6'd6;
localparam ST_SAVE_VDP0    = 6'd7;
localparam ST_SAVE_VDP1    = 6'd8;
localparam ST_SAVE_CRAM0   = 6'd9;
// CRAM is 6 words (SAVE_CRAM0 .. SAVE_CRAM5 via cram_idx counter)
localparam ST_SAVE_PSG     = 6'd15;
localparam ST_SAVE_MAPPER  = 6'd16;
localparam ST_SAVE_VRAM    = 6'd17;
localparam ST_SAVE_WRAM    = 6'd18;
localparam ST_SAVE_DONE    = 6'd19;

localparam ST_LOAD_HDR_RD  = 6'd20;
localparam ST_LOAD_HDR_WT  = 6'd21;
localparam ST_LOAD_CPU0    = 6'd22;
localparam ST_LOAD_CPU1    = 6'd23;
localparam ST_LOAD_CPU2    = 6'd24;
localparam ST_LOAD_CPU3    = 6'd25;
localparam ST_LOAD_VDP0    = 6'd26;
localparam ST_LOAD_VDP1    = 6'd27;
localparam ST_LOAD_CRAM    = 6'd28;  // streams 32 × 12-bit entries via cram_A/D/wr
localparam ST_LOAD_PSG     = 6'd29;
localparam ST_LOAD_MAPPER  = 6'd30;
localparam ST_LOAD_VRAM    = 6'd31;
localparam ST_LOAD_WRAM    = 6'd32;
localparam ST_LOAD_RESTORE = 6'd33;
localparam ST_UNFREEZE     = 6'd34;
localparam ST_SAVE_NVRAM   = 6'd35;
localparam ST_LOAD_NVRAM   = 6'd36;
localparam ST_WAIT_VBLANK  = 6'd38;  // wait for VBlank before unfreeze (load path)
localparam ST_WAIT_RESTORE_BOUNDARY = 6'd39;  // one-cycle mapper-settle phase before core restore
localparam ST_ERROR        = 6'd40;  // error state - unfreeze and return to idle

reg [5:0]  state;
reg        do_save;     // 1=save, 0=load
reg [1:0]  cur_slot;
reg [28:0] base_addr;
reg [31:0] ss_change_det; // MiSTer framework change detector (increment to trigger save-to-disk)
reg [31:0] cur_magic;
reg        cur_bios_mode;

// counters
reg [10:0] word_cnt;    // general DMA word counter
reg  [2:0] cram_idx;    // 0..5 for CRAM 64-bit words
reg  [4:0] cram_entry;  // 0..31 for entry-by-entry restore
reg  [2:0] cpu_idx;     // 0..3 for CPU words
reg  [2:0] vdp_idx;     // 0..1 for VDP reg words
// Latching buffers for multi-word state
reg [211:0] z80_snap;
reg [127:0] vdp_snap;
reg [383:0] cram_snap;
reg  [55:0] psg_snap;
reg  [63:0] mapper_snap;

// VRAM DMA pipelining: address issued, wait 2 clocks for data
reg  [2:0]  vram_pipe;
reg [14:0]  vram_save_addr;  // current byte address being saved
reg [14:0]  vram_load_addr;  // current byte address being loaded
reg  [2:0]  vram_byte_cnt;   // 0..7 bytes within 64-bit DDRAM word
reg [63:0]  vram_word_buf;   // accumulate 8 bytes → 1 DDRAM write
reg         vram_load_active; // 1 while writing 8 bytes from dout_latch
// Byte-7 latch: when DDRAM_BUSY stalls a word write, the SPRAM/DPRAM pipeline
// still advances on the next cycle so vram_D would have wrong data on retry.
// We latch the correct byte-7 value on the first stall cycle and use it on retry.
reg  [7:0]  vram_d_latch;
reg         vram_d_latched;  // 1 = latch holds a valid stalled byte-7 value

// WRAM DMA similar
reg [13:0]  wram_save_addr;
reg [13:0]  wram_load_addr;
reg  [2:0]  wram_byte_cnt;
reg [63:0]  wram_word_buf;
reg  [1:0]  wram_pipe;
reg         wram_load_active; // 1 while writing 8 bytes from dout_latch
reg  [7:0]  wram_d_latch;
reg         wram_d_latched;

// NVRAM DMA (8KB Dahjee A expansion RAM)
reg [12:0]  nvram_save_addr;
reg [12:0]  nvram_load_addr;
reg  [2:0]  nvram_byte_cnt;
reg [63:0]  nvram_word_buf;
reg  [1:0]  nvram_pipe;
reg         nvram_load_active;
reg  [7:0]  nvram_d_latch;
reg         nvram_d_latched;

// Shared latch for DDRAM read data (LOAD path)
reg [63:0]  dout_latch;

// Guard flag: set when a ddram_read is issued, cleared when DOUT_READY is consumed.
// Prevents stale DOUT_READY pulses (from pre-freeze scaler reads) from
// being misinterpreted as responses to our own load-path read requests.
reg         dout_expected;

// Watchdog: if a DDRAM read is outstanding for > ~640ms (25-bit @ ~53MHz)
// we abort to ST_ERROR so the FSM never hangs forever.
// ~2^25 / 53e6 ≈ 630 ms -- far longer than any real DDRAM latency.
reg [24:0]  ddram_watchdog;
localparam  DDRAM_WATCHDOG_MAX = 25'h1FFFFFF;

// VBlank edge-detection for clean unfreeze
reg         vblank_seen;   // goes 1 once we have seen vblank=1 in ST_WAIT_VBLANK

// -----------------------------------------------------------------------
// DDRAM helper tasks (inline)
// -----------------------------------------------------------------------
task ddram_write;
    input [28:0] addr;
    input [63:0] din;
    input  [7:0] be;
    begin
        DDRAM_ADDR     <= addr;
        DDRAM_DIN      <= din;
        DDRAM_BE       <= be;
        DDRAM_WE       <= 1;
        DDRAM_RD       <= 0;
        DDRAM_BURSTCNT <= 8'd1;
    end
endtask

task ddram_read;
    input [28:0] addr;
    begin
        DDRAM_ADDR     <= addr;
        DDRAM_BE       <= 8'hFF;
        DDRAM_WE       <= 0;
        DDRAM_RD       <= 1;
        DDRAM_BURSTCNT <= 8'd1;
        dout_expected  <= 1;   // mark that a response is in flight
    end
endtask

task ddram_idle;
    begin
        DDRAM_WE <= 0;
        DDRAM_RD <= 0;
    end
endtask

// -----------------------------------------------------------------------
// Main FSM
// -----------------------------------------------------------------------
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        state           <= ST_IDLE;
        ss_freeze       <= 0;
        ss_change_det   <= 0;
        cur_magic       <= MAGIC;
        cur_bios_mode   <= 0;
        z80_set         <= 0;
        vdp_regs_set    <= 0;
        cram_wr         <= 0;
        psg_set         <= 0;
        mapper_set      <= 0;
        vram_en         <= 0;
        vram_WE         <= 0;
        vram_load_active <= 0;
        wram_WE         <= 0;
        wram_load_active <= 0;
        nvram_WE        <= 0;
        nvram_load_active <= 0;
        dout_latch      <= 64'd0;
        vblank_seen     <= 0;
        dout_expected   <= 0;
        ddram_watchdog  <= 0;
        DDRAM_WE        <= 0;
        DDRAM_RD        <= 0;
        DDRAM_BURSTCNT  <= 8'd1;
    end else begin
        // default: clear one-cycle strobes
        z80_set      <= 0;
        vdp_regs_set <= 0;
        cram_wr      <= 0;
        psg_set      <= 0;
        mapper_set   <= 0;
        vram_WE      <= 0;
        wram_WE      <= 0;
        nvram_WE     <= 0;
        ddram_idle();

        // DDRAM read watchdog: abort if no response after ~640ms
        if (dout_expected) begin
            if (ddram_watchdog == DDRAM_WATCHDOG_MAX) begin
                dout_expected  <= 0;
                ddram_watchdog <= 0;
                state          <= ST_ERROR;
            end else
                ddram_watchdog <= ddram_watchdog + 25'd1;
        end else
            ddram_watchdog <= 0;

        case (state)
        // ---------------------------------------------------------------
        ST_IDLE: begin
            ss_freeze   <= 0;
            vblank_seen <= 0;  // reset for next VBlank wait
            if (ss_save) begin
                do_save   <= 1;
                cur_slot  <= ss_slot;
                state     <= ST_WAIT_BOUNDARY;
            end else if (ss_load) begin
                do_save   <= 0;
                cur_slot  <= ss_slot;
                state     <= ST_WAIT_BOUNDARY;
            end
        end

        // ---------------------------------------------------------------
        ST_WAIT_BOUNDARY: begin
            // Wait for a clean Z80 instruction boundary:
            //   - M1_n low  : opcode-fetch machine cycle
            //   - MREQ_n low: normal memory read (not interrupt acknowledge)
            //   - ISet=00   : no prefix active (not mid-way through CB/DD/ED/FD sequence)
            //   - cpu_ce     : only act on an actual CPU tick, not on held bus
            //                  levels between ticks.
            if (cpu_ce && !z80_m1_n && !z80_mreq_n && z80_iset == 2'b00) begin
                base_addr <= ss_bios_mode ? bios_slot_base(cur_slot) : slot_base(cur_slot);
                cur_bios_mode <= ss_bios_mode;
                cur_magic <= ss_bios_mode ? MAGIC_BIOS : MAGIC;

                // Capture snapshot in the same cycle the boundary is detected.
                // Capturing one cycle later can occasionally grab post-boundary
                // state (or partially advanced mapper/VDP side effects), creating
                // non-deterministic loads that crash or glitch.
                z80_snap    <= z80_reg;
                vdp_snap    <= vdp_regs;
                cram_snap   <= cram_out;
                psg_snap    <= psg_out;
                mapper_snap <= mapper_out;
                state       <= ST_ARM_FREEZE;
            end
        end

        // ---------------------------------------------------------------
        ST_ARM_FREEZE: begin
            // Freeze is asserted one clk_sys cycle after boundary detection so
            // it is guaranteed active before the next CPU/VDP CE pulse.
            // This prevents one extra micro-step after snapshot capture.
            ss_freeze <= 1;
            state     <= ST_FREEZE;
        end

        // ---------------------------------------------------------------
        ST_FREEZE: begin
            ss_freeze <= 1;
            state <= do_save ? ST_SAVE_HDR : ST_LOAD_HDR_RD;
        end

        // ---------------------------------------------------------------
        ST_WAIT_RESTORE_BOUNDARY: begin
            // Restore mapper/bank state first and give it one full clk_sys cycle
            // to settle before loading CPU/VDP/PSG. This avoids occasional
            // resumes with stale ROM mapping or BIOS/cart decode for the first
            // restored core cycle.
            mapper_in  <= mapper_snap;
            mapper_set <= 1;
            state      <= ST_LOAD_RESTORE;
        end

        // ===============================================================
        // SAVE
        // ===============================================================

        ST_SAVE_HDR: begin
            if (!DDRAM_BUSY) begin
                ddram_write(base_addr + 29'd1, {32'd0, cur_magic}, 8'h0F);
                state <= ST_SAVE_CPU0;
                cpu_idx <= 0;
            end
        end

        ST_SAVE_CPU0: begin
            // z80_snap[211:0] = 212 bits → 4 × 64-bit words (w0..w2 = 192 bits + w3 spare 20 bits)
            if (!DDRAM_BUSY) begin
                case (cpu_idx)
                    3'd0: ddram_write(base_addr + 29'd2, z80_snap[63:0],    8'hFF);
                    3'd1: ddram_write(base_addr + 29'd3, z80_snap[127:64],  8'hFF);
                    3'd2: ddram_write(base_addr + 29'd4, z80_snap[191:128], 8'hFF);
                    3'd3: ddram_write(base_addr + 29'd5, {52'd0, z80_snap[211:192]}, 8'hFF);
                endcase
                if (cpu_idx == 3) begin
                    state   <= ST_SAVE_VDP0;
                    vdp_idx <= 0;
                end else
                    cpu_idx <= cpu_idx + 3'd1;
            end
        end

        ST_SAVE_VDP0: begin
            if (!DDRAM_BUSY) begin
                case (vdp_idx[0])
                    1'b0: ddram_write(base_addr + 29'd6, vdp_snap[63:0],   8'hFF);
                    1'b1: ddram_write(base_addr + 29'd7, vdp_snap[127:64], 8'hFF);
                endcase
                if (vdp_idx[0] == 1) begin
                    state    <= ST_SAVE_CRAM0;
                    cram_idx <= 0;
                end else
                    vdp_idx[0] <= 1'b1;
            end
        end

        ST_SAVE_CRAM0: begin
            // cram_snap[383:0] = 6 × 64 bits
            if (!DDRAM_BUSY) begin
                case (cram_idx)
                    3'd0: ddram_write(base_addr + 29'd8,  cram_snap[63:0],    8'hFF);
                    3'd1: ddram_write(base_addr + 29'd9,  cram_snap[127:64],  8'hFF);
                    3'd2: ddram_write(base_addr + 29'd10, cram_snap[191:128], 8'hFF);
                    3'd3: ddram_write(base_addr + 29'd11, cram_snap[255:192], 8'hFF);
                    3'd4: ddram_write(base_addr + 29'd12, cram_snap[319:256], 8'hFF);
                    3'd5: ddram_write(base_addr + 29'd13, cram_snap[383:320], 8'hFF);
                    default: ;
                endcase
                if (cram_idx == 5)
                    state <= ST_SAVE_PSG;
                else
                    cram_idx <= cram_idx + 3'd1;
            end
        end

        ST_SAVE_PSG: begin
            if (!DDRAM_BUSY) begin
                ddram_write(base_addr + 29'd14, {8'd0, psg_snap}, 8'hFF);
                state <= ST_SAVE_MAPPER;
            end
        end

        ST_SAVE_MAPPER: begin
            if (!DDRAM_BUSY) begin
                ddram_write(base_addr + 29'd15, mapper_snap, 8'hFF);
                // Start VRAM DMA: 16384 bytes → 2048 × 64-bit words
                // DDRAM offset 0x100 words from base
                vram_save_addr <= 0;
                vram_byte_cnt  <= 0;
                vram_word_buf  <= 0;
                vram_pipe      <= 0;
                vram_en        <= 1;
                vram_A         <= 0;
                word_cnt       <= 0;
                vram_d_latched <= 0;
                state          <= ST_SAVE_VRAM;
            end
        end

        ST_SAVE_VRAM: begin
            // Pipeline: issue address on cycle 0, data is ready 2 cycles later
            vram_en <= 1;
            if (vram_pipe < 3'd2) begin
                // Prime the pipeline: advance address each cycle
                vram_pipe <= vram_pipe + 3'd1;
                if (vram_pipe >= 1 && vram_save_addr < 15'd16384)
                    vram_A <= vram_save_addr + 15'd1;
            end else begin
                // Stall entire pipeline at 8-byte word boundary if DDRAM is busy.
                // Holding all signals stable means vram_D (and word_buf) remain
                // valid so the write can be retried on the next cycle.
                if (vram_byte_cnt < 7 || !DDRAM_BUSY) begin
                    // On first arrival at byte 7 after a stall the SPRAM
                    // pipeline has already advanced one address, so vram_D
                    // now holds the NEXT byte – use the value we latched on
                    // the stall cycle instead.
                    vram_d_latched <= 0;   // clear for next word
                    vram_word_buf <= {(vram_byte_cnt == 7 && vram_d_latched) ? vram_d_latch : vram_D,
                                      vram_word_buf[63:8]};
                    vram_byte_cnt <= vram_byte_cnt + 3'd1;
                    if (vram_byte_cnt == 7) begin
                        ddram_write(base_addr + 29'h101 + {18'd0, word_cnt},
                                    {vram_d_latched ? vram_d_latch : vram_D,
                                     vram_word_buf[63:8]}, 8'hFF);
                        word_cnt <= word_cnt + 11'd1;
                    end
                    // Advance address pipeline
                    if (vram_save_addr < 15'd16383) begin
                        vram_save_addr <= vram_save_addr + 15'd1;
                        vram_A         <= vram_save_addr + 15'd2;
                    end else if (vram_byte_cnt == 7) begin
                        vram_en <= 0;
                        // Start WRAM DMA
                        wram_save_addr <= 0;
                        wram_byte_cnt  <= 0;
                        wram_word_buf  <= 0;
                        wram_pipe      <= 0;
                        wram_A         <= 0;
                        word_cnt       <= 0;
                        wram_d_latched <= 0;
                        state          <= ST_SAVE_WRAM;
                    end
                end else begin
                    // DDRAM busy at boundary: latch byte-7 on the first
                    // stall cycle before the SPRAM pipeline advances.
                    if (!vram_d_latched) begin
                        vram_d_latch   <= vram_D;
                        vram_d_latched <= 1;
                    end
                end
            end
        end

        ST_SAVE_WRAM: begin
            if (wram_pipe < 2'd2) begin
                wram_pipe <= wram_pipe + 2'd1;
                if (wram_pipe >= 1 && wram_save_addr < 14'd8191)
                    wram_A <= wram_save_addr + 14'd1;
            end else begin
                // Stall at 8-byte boundary if DDRAM is busy (same pattern as VRAM)
                if (wram_byte_cnt < 7 || !DDRAM_BUSY) begin
                    wram_d_latched <= 0;
                    wram_word_buf <= {(wram_byte_cnt == 7 && wram_d_latched) ? wram_d_latch : wram_D,
                                      wram_word_buf[63:8]};
                    wram_byte_cnt <= wram_byte_cnt + 3'd1;
                    if (wram_byte_cnt == 7) begin
                        ddram_write(base_addr + 29'h901 + {18'd0, word_cnt},
                                    {wram_d_latched ? wram_d_latch : wram_D,
                                     wram_word_buf[63:8]}, 8'hFF);
                        word_cnt <= word_cnt + 11'd1;
                    end
                    if (wram_save_addr < 14'd8191) begin
                        wram_save_addr <= wram_save_addr + 14'd1;
                        wram_A         <= wram_save_addr + 14'd2;
                    end else if (wram_byte_cnt == 7) begin
                        if (mapper_snap[48]) begin
                            // Dahjee A: save 8KB nvram (expansion RAM at $2000-$3FFF)
                            nvram_save_addr <= 0;
                            nvram_byte_cnt  <= 0;
                            nvram_word_buf  <= 0;
                            nvram_pipe      <= 0;
                            nvram_A         <= 0;
                            word_cnt        <= 0;
                            nvram_d_latched <= 0;
                            state           <= ST_SAVE_NVRAM;
                        end else begin
                            state <= ST_SAVE_DONE;
                        end
                    end
                end else begin
                    if (!wram_d_latched) begin
                        wram_d_latch   <= wram_D;
                        wram_d_latched <= 1;
                    end
                end
            end
        end

        ST_SAVE_NVRAM: begin
            if (nvram_pipe < 2'd2) begin
                nvram_pipe <= nvram_pipe + 2'd1;
                if (nvram_pipe >= 1 && nvram_save_addr < 13'd8191)
                    nvram_A <= nvram_save_addr + 13'd1;
            end else begin
                // Stall at 8-byte boundary if DDRAM is busy (same pattern as VRAM/WRAM)
                if (nvram_byte_cnt < 7 || !DDRAM_BUSY) begin
                    nvram_d_latched <= 0;
                    nvram_word_buf <= {(nvram_byte_cnt == 7 && nvram_d_latched) ? nvram_d_latch : nvram_D,
                                       nvram_word_buf[63:8]};
                    nvram_byte_cnt <= nvram_byte_cnt + 3'd1;
                    if (nvram_byte_cnt == 7) begin
                        ddram_write(base_addr + 29'h0D01 + {18'd0, word_cnt},
                                    {nvram_d_latched ? nvram_d_latch : nvram_D,
                                     nvram_word_buf[63:8]}, 8'hFF);
                        word_cnt <= word_cnt + 11'd1;
                    end
                    if (nvram_save_addr < 13'd8191) begin
                        nvram_save_addr <= nvram_save_addr + 13'd1;
                        nvram_A         <= nvram_save_addr + 13'd2;
                    end else if (nvram_byte_cnt == 7) begin
                        state <= ST_SAVE_DONE;
                    end
                end else begin
                    if (!nvram_d_latched) begin
                        nvram_d_latch   <= nvram_D;
                        nvram_d_latched <= 1;
                    end
                end
            end
        end

        ST_SAVE_DONE: begin
            // Write MiSTer framework control word at slot base (word 0).
            // [31:0]  = change_det: must change on every save to trigger firmware write to /savestates/
            // [63:32] = size in 32-bit words = (slot_size_bytes - 8) / 4
            //           slot = 64KB = 65536 bytes; minus 8-byte control word = 65528 bytes → 16382 words
            if (cur_bios_mode) begin
                // BIOS states live in their own DDRAM region (bios_slot_base);
                // no change_det write → ARM never saves them to disk, so they
                // cannot contaminate the last-loaded game's .ss file.
                state <= ST_UNFREEZE;
            end else if (!DDRAM_BUSY) begin
                ddram_write(base_addr + 29'd0, {32'd16382, ss_change_det}, 8'hFF);
                ss_change_det <= ss_change_det + 32'd1;
                state <= ST_UNFREEZE;
            end
        end

        // ===============================================================
        // LOAD
        // ===============================================================

        ST_LOAD_HDR_RD: begin
            if (!DDRAM_BUSY) begin
                ddram_read(base_addr + 29'd1);
                state <= ST_LOAD_HDR_WT;
            end
        end

        ST_LOAD_HDR_WT: begin
            if (DDRAM_DOUT_READY && dout_expected) begin
                dout_expected <= 0;
                if (DDRAM_DOUT[31:0] == cur_magic) begin
                    // Read Z80 words
                    ddram_read(base_addr + 29'd2);
                    cpu_idx <= 0;
                    state   <= ST_LOAD_CPU0;
                end else begin
                    // Invalid magic: abort
                    state <= ST_UNFREEZE;
                end
            end
        end

        ST_LOAD_CPU0: begin
            if (DDRAM_DOUT_READY && dout_expected) begin
                dout_expected <= 0;
                case (cpu_idx)
                    3'd0: begin z80_dir[63:0]    <= DDRAM_DOUT; ddram_read(base_addr + 29'd3); end
                    3'd1: begin z80_dir[127:64]  <= DDRAM_DOUT; ddram_read(base_addr + 29'd4); end
                    3'd2: begin z80_dir[191:128] <= DDRAM_DOUT; ddram_read(base_addr + 29'd5); end
                    3'd3: begin z80_dir[211:192] <= DDRAM_DOUT[19:0]; ddram_read(base_addr + 29'd6); end
                endcase
                if (cpu_idx == 3) begin
                    vdp_idx <= 0;
                    state   <= ST_LOAD_VDP0;
                end else
                    cpu_idx <= cpu_idx + 3'd1;
            end
        end

        ST_LOAD_VDP0: begin
            if (DDRAM_DOUT_READY && dout_expected) begin
                dout_expected <= 0;
                case (vdp_idx[0])
                    1'b0: begin vdp_regs_in[63:0]   <= DDRAM_DOUT; ddram_read(base_addr + 29'd7); end
                    1'b1: begin vdp_regs_in[127:64]  <= DDRAM_DOUT; ddram_read(base_addr + 29'd8); end
                endcase
                if (vdp_idx[0]) begin
                    cram_idx <= 0;
                    state    <= ST_LOAD_CRAM;
                end else
                    vdp_idx[0] <= 1'b1;
            end
        end

        ST_LOAD_CRAM: begin
            // Read 6 DDRAM words, then restore 32 entries one-by-one
            // Phase 1: read all 6 words (use cram_idx as word index)
            // Phase 2: write entries (use cram_entry)
            if (DDRAM_DOUT_READY && dout_expected) begin
                dout_expected <= 0;
                case (cram_idx)
                    3'd0: begin cram_snap[63:0]    <= DDRAM_DOUT; ddram_read(base_addr + 29'd9);  end
                    3'd1: begin cram_snap[127:64]  <= DDRAM_DOUT; ddram_read(base_addr + 29'd10); end
                    3'd2: begin cram_snap[191:128] <= DDRAM_DOUT; ddram_read(base_addr + 29'd11); end
                    3'd3: begin cram_snap[255:192] <= DDRAM_DOUT; ddram_read(base_addr + 29'd12); end
                    3'd4: begin cram_snap[319:256] <= DDRAM_DOUT; ddram_read(base_addr + 29'd13); end
                    3'd5: begin cram_snap[383:320] <= DDRAM_DOUT; ddram_read(base_addr + 29'd14); end
                    default: ;
                endcase
                if (cram_idx == 5) begin
                    // Start writing entries next cycle
                    cram_entry <= 0;
                    state      <= ST_LOAD_PSG;
                    // Note: cram restore happens in ST_LOAD_RESTORE after all reads
                end else
                    cram_idx <= cram_idx + 3'd1;
            end
        end

        ST_LOAD_PSG: begin
            if (DDRAM_DOUT_READY && dout_expected) begin
                dout_expected <= 0;
                psg_snap <= DDRAM_DOUT[55:0];
                ddram_read(base_addr + 29'd15);
                state    <= ST_LOAD_MAPPER;
            end
        end

        ST_LOAD_MAPPER: begin
            if (DDRAM_DOUT_READY && dout_expected) begin
                dout_expected    <= 0;
                mapper_snap      <= DDRAM_DOUT;
                // Restore memory (VRAM/WRAM) BEFORE applying registers so the VDP never
                // renders with new register settings against old VRAM content.
                vram_load_addr   <= 0;
                vram_byte_cnt    <= 0;
                vram_load_active <= 0;
                word_cnt         <= 0;
                ddram_read(base_addr + 29'h101);
                state <= ST_LOAD_VRAM;
            end
        end

        ST_LOAD_VRAM: begin
            if (!vram_load_active) begin
                // Wait for DDRAM read to complete, then latch the 64-bit word
                if (DDRAM_DOUT_READY && dout_expected) begin
                    dout_expected    <= 0;
                    dout_latch       <= DDRAM_DOUT;
                    vram_byte_cnt    <= 0;
                    vram_load_active <= 1;
                end
            end else begin
                // Write one byte per clock cycle from the latched word
                vram_WE         <= 1;
                vram_WA         <= vram_load_addr;
                vram_WD         <= dout_latch[8*vram_byte_cnt +: 8];
                vram_load_addr  <= vram_load_addr + 15'd1;
                vram_byte_cnt   <= vram_byte_cnt + 3'd1; // 3-bit: wraps 7→0
                if (vram_byte_cnt == 3'd7) begin
                    // Last byte - deactivate and fetch next word
                    vram_load_active <= 0;
                    if (word_cnt < 11'd2047) begin
                        word_cnt <= word_cnt + 11'd1;
                        ddram_read(base_addr + 29'h101 + {18'd0, word_cnt + 11'd1});
                    end else begin
                        // VRAM done → WRAM
                        wram_load_addr   <= 0;
                        wram_byte_cnt    <= 0;
                        wram_load_active <= 0;
                        word_cnt         <= 0;
                        ddram_read(base_addr + 29'h901);
                        state <= ST_LOAD_WRAM;
                    end
                end
            end
        end

        ST_LOAD_WRAM: begin
            if (!wram_load_active) begin
                if (DDRAM_DOUT_READY && dout_expected) begin
                    dout_expected    <= 0;
                    dout_latch       <= DDRAM_DOUT;
                    wram_byte_cnt    <= 0;
                    wram_load_active <= 1;
                end
            end else begin
                wram_WE         <= 1;
                wram_WA         <= wram_load_addr;
                wram_WD         <= dout_latch[8*wram_byte_cnt +: 8];
                wram_load_addr  <= wram_load_addr + 14'd1;
                wram_byte_cnt   <= wram_byte_cnt + 3'd1;
                if (wram_byte_cnt == 3'd7) begin
                    wram_load_active <= 0;
                    if (word_cnt < 11'd1023) begin
                        word_cnt <= word_cnt + 11'd1;
                        ddram_read(base_addr + 29'h901 + {18'd0, word_cnt + 11'd1});
                    end else begin
                        if (mapper_snap[48]) begin
                            // Dahjee A: restore 8KB nvram
                            nvram_load_addr   <= 0;
                            nvram_byte_cnt    <= 0;
                            nvram_load_active <= 0;
                            word_cnt          <= 0;
                            ddram_read(base_addr + 29'h0D01);
                            state <= ST_LOAD_NVRAM;
                        end else begin
                            // All memory restored; restore mapper first, then core.
                            state      <= ST_WAIT_RESTORE_BOUNDARY;
                            cram_entry <= 0;
                        end
                    end
                end
            end
        end

        ST_LOAD_NVRAM: begin
            if (!nvram_load_active) begin
                if (DDRAM_DOUT_READY && dout_expected) begin
                    dout_expected     <= 0;
                    dout_latch        <= DDRAM_DOUT;
                    nvram_byte_cnt    <= 0;
                    nvram_load_active <= 1;
                end
            end else begin
                nvram_WE        <= 1;
                nvram_WA        <= nvram_load_addr;
                nvram_WD        <= dout_latch[8*nvram_byte_cnt +: 8];
                nvram_load_addr <= nvram_load_addr + 13'd1;
                nvram_byte_cnt  <= nvram_byte_cnt + 3'd1;
                if (nvram_byte_cnt == 3'd7) begin
                    nvram_load_active <= 0;
                    if (word_cnt < 11'd1023) begin
                        word_cnt <= word_cnt + 11'd1;
                        ddram_read(base_addr + 29'h0D01 + {18'd0, word_cnt + 11'd1});
                    end else begin
                        // All memory restored; restore mapper first, then core.
                        state      <= ST_WAIT_RESTORE_BOUNDARY;
                        cram_entry <= 0;
                    end
                end
            end
        end

        ST_LOAD_RESTORE: begin
            // VRAM/WRAM and mapper are fully restored. Apply CPU+VDP+PSG state,
            // then stream CRAM while remaining frozen.
            if (cram_entry == 0) begin
                // CPU is frozen; restore all registers unconditionally.
                // z80_set loads z80_dir into T80s regardless of CEN.
                z80_set      <= 1;
                vdp_regs_set <= 1;
                psg_in       <= psg_snap;
                psg_set      <= 1;
            end
            // Write CRAM entries one per cycle (32 cycles total)
            cram_wr <= 1;
            cram_A  <= cram_entry;
            cram_D  <= cram_snap[12*cram_entry +: 12];
            if (cram_entry == 31) begin
                // All state applied; wait for VBlank before unfreezing
                state <= ST_WAIT_VBLANK;
            end else
                cram_entry <= cram_entry + 5'd1;
        end

        // ---------------------------------------------------------------
        ST_WAIT_VBLANK: begin
            // Wait for a full VBlank rising → falling edge so we always unfreeze
            // at y=0 (the very start of active display).  This guarantees:
            //   • hbl_counter has been reloaded from irq_line_count by the VDP
            //     during at least one VBlank line at x=486.
            //   • The game resumes at the cleanest possible frame boundary.
            // If we enter this state already inside VBlank (vblank=1), vblank_seen
            // is set immediately, so we unfreeze on the next falling edge (y=0)
            // rather than exiting right away mid-VBlank.
            if (vblank)                   vblank_seen <= 1;
            if (vblank_seen && !vblank)   state <= ST_UNFREEZE;
        end

        // ---------------------------------------------------------------
        ST_UNFREEZE: begin
            // Release freeze only on a quiet CE phase to avoid resuming exactly
            // on a CPU/VDP enable pulse edge, which can cause rare load-time
            // glitches or resets in timing-sensitive games.
            if (!cpu_ce && !vdp_ce) begin
                ss_freeze <= 0;
                state     <= ST_IDLE;
            end else begin
                ss_freeze <= 1;
            end
        end
        // ---------------------------------------------------------------
        ST_ERROR: begin
            // Handle load error - unfreeze and return to idle
            ss_freeze <= 0;
            state <= ST_IDLE;
        end
        default: state <= ST_IDLE;
        endcase
    end
end

endmodule
