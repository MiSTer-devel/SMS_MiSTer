// savestate_ui.sv
// Translates OSD status bits and PS/2 keyboard shortcuts into
// one-cycle ss_save / ss_load pulses and slot selection.
//
// Slot OSD bits (status[16:15]):  0→slot 1, 1→slot 2, 2→slot 3, 3→slot 4
// Save trigger  (status[61]):     rising edge → ss_save pulse
// Load trigger  (status[62]):     rising edge → ss_load pulse
//
// Keyboard shortcuts (via MiSTer ps2_key interface):
//   F1          → load state  (keycode 0x05, not extended)
//   Alt + F1    → save state  (Left-Alt = 0x11 non-ext, Right-Alt = 0x11 ext)
// ps2_key[10] = toggle strobe (changes on every key event)
// ps2_key[9]  = 1 when key pressed, 0 when released
// ps2_key[8]  = extended key flag
// ps2_key[7:0]= PS/2 scan-code set 2 key code

module savestate_ui (
    input             clk,
    input      [63:0]  status,        // OSD status word from hps_io
    input      [10:0]  ps2_key,       // PS/2 key from hps_io
    output reg  [1:0] ss_slot,        // current slot (0-based)
    output reg        ss_save,        // one-cycle save pulse
    output reg        ss_load         // one-cycle load pulse
);

// Slot selection is live from status bits
always @(posedge clk) begin
    ss_slot <= status[16:15];
end

// -----------------------------------------------------------------------
// PS/2 keyboard shortcuts: F1 = load, Alt+F1 = save
// -----------------------------------------------------------------------
reg  ps2_stb;
reg  alt_held;
reg  kbd_save, kbd_load;

always @(posedge clk) begin
    ps2_stb  <= ps2_key[10];
    kbd_save <= 0;
    kbd_load <= 0;

    if (ps2_stb ^ ps2_key[10]) begin   // new key event
        if (ps2_key[7:0] == 8'h11)         // Left-Alt or Right-Alt
            alt_held <= ps2_key[9];
        if (ps2_key[7:0] == 8'h05 && ps2_key[9]) begin  // F1 pressed
            if (alt_held) kbd_save <= 1;
            else          kbd_load <= 1;
        end
    end
end

// -----------------------------------------------------------------------
// Edge detectors for OSD save / load triggers; OR with keyboard shortcuts
// -----------------------------------------------------------------------
reg old_save, old_load;

always @(posedge clk) begin
    old_save <= status[61];
    old_load <= status[62];

    ss_save <= (~old_save & status[61]) | kbd_save;
    ss_load <= (~old_load & status[62]) | kbd_load;
end

endmodule
