// savestate_ui.sv  (SMS_MiSTer)
//
// Translates OSD status bits, PS/2 keyboard shortcuts, and gamepad button
// combos into one-cycle ss_save / ss_load pulses and slot selection.
//
// Info message indices for hps_io (1-based; 0 = no display):
//   1    : hint message ("Slot=LR|Save=SS+Down|Load=SS+Up")
//   2-5  : "Active Slot 1..4"
//   6,8,10,12 : "Save to state 1..4"
//   7,9,11,13 : "Restore state 1..4"
//
// Slot OSD bits (status[16:15]): 0→slot 1, 1→slot 2, 2→slot 3, 3→slot 4
// OSD save  (status[61]):  rising edge → ss_save
// OSD load  (status[62]):  rising edge → ss_load
//
// Gamepad combos (SaveState button = joy[12]):
//   SS + Left              → switch to prev slot
//   SS + Right             → switch to next slot
//   SS + Down              → save state
//   SS + Up                → load state
//
// PS/2 keyboard:  F1 = load state,  Alt+F1 = save state

module savestate_ui (
    input             clk,
    input      [63:0] status,        // OSD status word from hps_io
    input      [10:0] ps2_key,       // PS/2 key interface from hps_io
    input             allow_ss,      // 1 when savestates are permitted
    input             joySS,         // SaveState button  (joy[12])
    input             joyRight,      // joy[0]
    input             joyLeft,       // joy[1]
    input             joyDown,       // joy[2]
    input             joyUp,         // joy[3]
    input             joyPause,      // joy[6]
    input       [1:0] status_slot,   // OSD slot selector  (status[16:15])
    input       [1:0] OSD_saveload,  // {load_bit, save_bit} = status[62:61]
    output reg  [1:0] selected_slot, // current slot (0-based), drives savestates
    output reg        ss_save,       // one-cycle save pulse
    output reg        ss_load,       // one-cycle load pulse
    output reg  [7:0] ss_info,       // info message index to display
    output reg        ss_info_req,   // one-cycle: latch ss_info into hps_io
    output reg        statusUpdate   // one-cycle: push slot back to OSD
);

// Internal slot register
reg [1:0] slot;
reg [1:0] old_status_slot;

// Two-stage statusUpdate: fires the cycle after slot changes so that
// selected_slot has already been updated when SMS.sv reads it.
reg statusUpdate_pending;

// PS/2 state
reg ps2_stb;
reg alt_held;
reg kbd_save, kbd_load;

// Joystick edge trackers
reg joyLeft_r, joyRight_r, joyDown_r, joyUp_r, joySS_r;

// SS hold-to-hint timer (~2.5s at 53.693 MHz = clk_sys)
// bit 27 trips at 2^27 = 134 M cycles
localparam SS_HINT_BITS = 27;
reg [SS_HINT_BITS:0] ss_hold_cnt;   // 28-bit up-counter
reg                  ss_combo_done; // combo or timeout already fired this press

// OSD edge trackers
reg old_osd_save, old_osd_load;

reg [27:0] cooldown_cnt = 0;

// -----------------------------------------------------------------------
// PS/2 keyboard: F1 = load,  Alt+F1 = save
// -----------------------------------------------------------------------
always @(posedge clk) begin
    ps2_stb  <= ps2_key[10];
    kbd_save <= 0;
    kbd_load <= 0;

    if (ps2_stb ^ ps2_key[10]) begin
        if (ps2_key[7:0] == 8'h11)
            alt_held <= ps2_key[9];
        if (ps2_key[7:0] == 8'h05 && ps2_key[9]) begin
            if (alt_held) kbd_save <= 1;
            else          kbd_load <= 1;
        end
    end
end

// -----------------------------------------------------------------------
// Main logic: OSD / keyboard / gamepad
// -----------------------------------------------------------------------
always @(posedge clk) begin
    // Cooldown timer decrement
    if (cooldown_cnt != 0) begin
        cooldown_cnt <= cooldown_cnt - 28'd1;
    end

    // Defaults
    ss_save              <= 0;
    ss_load              <= 0;
    ss_info_req          <= 0;
    statusUpdate         <= statusUpdate_pending; // fire 1 cycle after slot change
    statusUpdate_pending <= 0;

    // Latch joystick edges
    joySS_r    <= joySS;
    joyLeft_r  <= joyLeft;
    joyRight_r <= joyRight;
    joyDown_r  <= joyDown;
    joyUp_r    <= joyUp;

    // Rising edge of SS: show current slot; start hold-to-hint timer
    if (~joySS_r & joySS) begin
        ss_info_req   <= 1;
        ss_info       <= 8'd2 + slot;  // "Active Slot N"
        ss_hold_cnt   <= 0;
        ss_combo_done <= 0;
    end

    // SS held without action: count up; show hint after ~2.5s
    if (joySS & joySS_r & ~ss_combo_done) begin
        if (ss_hold_cnt[SS_HINT_BITS]) begin
            ss_info_req   <= 1;
            ss_info       <= 8'd1;     // hint
            ss_combo_done <= 1;
        end else
            ss_hold_cnt   <= ss_hold_cnt + 1'd1;
    end

    // Falling edge of SS: show hint only if no combo/timeout occurred
    if (joySS_r & ~joySS & ~ss_combo_done) begin
        ss_info_req <= 1;
        ss_info     <= 8'd1;           // hint
    end

    // Sync slot when user changes it through the OSD menu
    old_status_slot <= status_slot;
    if (status_slot != old_status_slot && (cooldown_cnt == 0))
        slot <= status_slot;

    // selected_slot tracks slot with 1-cycle lag; aligned with statusUpdate
    selected_slot <= slot;

    // OSD save/load (status[61]=save, status[62]=load)
    old_osd_save <= OSD_saveload[0];
    old_osd_load <= OSD_saveload[1];

    if (~old_osd_save & OSD_saveload[0] & allow_ss && (cooldown_cnt == 0)) begin
        ss_save      <= 1;
        ss_info_req  <= 1;
        ss_info      <= 8'd6 + {slot, 1'b0};   // "Save to state N"  (1-based: 6,8,10,12)
        cooldown_cnt <= 28'd26846500;          // 500ms cooldown
    end
    if (~old_osd_load & OSD_saveload[1] & allow_ss && (cooldown_cnt == 0)) begin
        ss_load      <= 1;
        ss_info_req  <= 1;
        ss_info      <= 8'd7 + {slot, 1'b0};   // "Restore state N"  (1-based: 7,9,11,13)
        cooldown_cnt <= 28'd26846500;          // 500ms cooldown
    end

    // PS/2 keyboard shortcuts
    if (kbd_save & allow_ss && (cooldown_cnt == 0)) begin
        ss_save      <= 1;
        ss_info_req  <= 1;
        ss_info      <= 8'd6 + {slot, 1'b0};
        cooldown_cnt <= 28'd26846500;          // 500ms cooldown
    end
    if (kbd_load & allow_ss && (cooldown_cnt == 0)) begin
        ss_load      <= 1;
        ss_info_req  <= 1;
        ss_info      <= 8'd7 + {slot, 1'b0};
        cooldown_cnt <= 28'd26846500;          // 500ms cooldown
    end

    // Gamepad combos — only when the dedicated SaveState button is held
    if (joySS) begin
        // Rising edge of Left (no Pause): previous slot
        if (~joyLeft_r & joyLeft & ~joyPause && (cooldown_cnt == 0)) begin
            slot                 <= (slot == 2'd0) ? 2'd3 : slot - 2'd1;
            statusUpdate_pending <= 1;
            ss_info_req          <= 1;
            ss_info              <= 8'd2 + ((slot == 2'd0) ? 2'd3 : slot - 2'd1);
            ss_combo_done        <= 1;
            cooldown_cnt         <= 28'd26846500;  // 500ms slot cooldown
        end
        // Rising edge of Right (no Pause): next slot
        if (~joyRight_r & joyRight & ~joyPause && (cooldown_cnt == 0)) begin
            slot                 <= (slot == 2'd3) ? 2'd0 : slot + 2'd1;
            statusUpdate_pending <= 1;
            ss_info_req          <= 1;
            ss_info              <= 8'd2 + ((slot == 2'd3) ? 2'd0 : slot + 2'd1);
            ss_combo_done        <= 1;
            cooldown_cnt         <= 28'd26846500;  // 500ms slot cooldown
        end
        // Rising edge of Down (no Pause needed): save
        if (~joyDown_r & joyDown & ~joyLeft & ~joyRight & allow_ss && (cooldown_cnt == 0)) begin
            ss_save       <= 1;
            ss_info_req   <= 1;
            ss_info       <= 8'd6 + {slot, 1'b0};
            ss_combo_done <= 1;
            cooldown_cnt  <= 28'd26846500;      // 500ms cooldown
        end
        // Rising edge of Up (no Pause needed): load
        if (~joyUp_r & joyUp & ~joyLeft & ~joyRight & allow_ss && (cooldown_cnt == 0)) begin
            ss_load       <= 1;
            ss_info_req   <= 1;
            ss_info       <= 8'd7 + {slot, 1'b0};
            ss_combo_done <= 1;
            cooldown_cnt  <= 28'd26846500;      // 500ms cooldown
        end
    end
end

endmodule
