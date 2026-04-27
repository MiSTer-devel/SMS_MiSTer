module keyboard
(
	input         clk_sys,
	input         reset,
	input         enable,
	input  [11:0] joy_row,
	input  [2:0]  row_sel,
	input  [10:0] ps2_key,
	output logic [11:0] row_data
);

	reg         ps2_key_stb = 0;
	reg  [11:0] key_row[0:6];
	reg         clr_key = 0;
	reg         home_key = 0;
	reg         ins_key = 0;
	reg         del_key = 0;
	reg         ro_key = 0;
	reg         bslash_key = 0;
	reg         enter_key = 0;
	reg         keypad_enter_key = 0;
	reg         func_f3_key = 0;
	reg         func_f1_key = 0;
	reg         break_key = 0;
	reg         pause_key = 0;
	reg         alt_key = 0;
	reg         altgr_key = 0;
	reg         ctrl_key = 0;
	reg         ctrl_r_key = 0;
	reg         shift_l_key = 0;
	reg         shift_r_key = 0;

	wire        key_event = ps2_key_stb ^ ps2_key[10];
	wire        key_ext = ps2_key[8];
	wire        key_pressed = ps2_key[9];
	wire  [7:0] key_code = ps2_key[7:0];

	always_ff @(posedge clk_sys) begin : key_state
		integer i;

		if (reset) begin
			ps2_key_stb <= 0;
			for (i = 0; i < 7; i = i + 1) begin
				key_row[i] <= 12'hFFF;
			end
			clr_key <= 0;
			home_key <= 0;
			ins_key <= 0;
			del_key <= 0;
			ro_key <= 0;
			bslash_key <= 0;
			enter_key <= 0;
			keypad_enter_key <= 0;
			func_f3_key <= 0;
			func_f1_key <= 0;
			break_key <= 0;
			pause_key <= 0;
			alt_key <= 0;
			altgr_key <= 0;
			ctrl_key <= 0;
			ctrl_r_key <= 0;
			shift_l_key <= 0;
			shift_r_key <= 0;
		end else begin
			ps2_key_stb <= ps2_key[10];
			if (key_event) begin
				case ({key_ext, key_code})
					9'h016: key_row[0][0] <= ~key_pressed; // 1
					9'h015: key_row[0][1] <= ~key_pressed; // Q
					9'h01C: key_row[0][2] <= ~key_pressed; // A
					9'h01A: key_row[0][3] <= ~key_pressed; // Z
					9'h058: key_row[0][4] <= ~key_pressed; // Kana/Eisuu
					9'h041: key_row[0][5] <= ~key_pressed; // ,
					9'h042: key_row[0][6] <= ~key_pressed; // K
					9'h043: key_row[0][7] <= ~key_pressed; // I
					9'h03E: key_row[0][8] <= ~key_pressed; // 8

					9'h01E: key_row[1][0] <= ~key_pressed; // 2
					9'h01D: key_row[1][1] <= ~key_pressed; // W
					9'h01B: key_row[1][2] <= ~key_pressed; // S
					9'h022: key_row[1][3] <= ~key_pressed; // X
					9'h029: key_row[1][4] <= ~key_pressed; // Space
					9'h049: key_row[1][5] <= ~key_pressed; // .
					9'h04B: key_row[1][6] <= ~key_pressed; // L
					9'h044: key_row[1][7] <= ~key_pressed; // O
					9'h046: key_row[1][8] <= ~key_pressed; // 9

					9'h026: key_row[2][0] <= ~key_pressed; // 3
					9'h024: key_row[2][1] <= ~key_pressed; // E
					9'h023: key_row[2][2] <= ~key_pressed; // D
					9'h021: key_row[2][3] <= ~key_pressed; // C
					9'h066: clr_key <= key_pressed; // CLR
					9'h16C: home_key <= key_pressed; // CLR
					9'h04A: key_row[2][5] <= ~key_pressed; // /
					9'h04C: key_row[2][6] <= ~key_pressed; // ;
					9'h04D: key_row[2][7] <= ~key_pressed; // P
					9'h045: key_row[2][8] <= ~key_pressed; // 0

					9'h025: key_row[3][0] <= ~key_pressed; // 4
					9'h02D: key_row[3][1] <= ~key_pressed; // R
					9'h02B: key_row[3][2] <= ~key_pressed; // F
					9'h02A: key_row[3][3] <= ~key_pressed; // V
					9'h170: ins_key <= key_pressed; // INS/DEL
					9'h171: del_key <= key_pressed; // INS/DEL
					9'h061: ro_key <= key_pressed; // RO
					9'h00B: bslash_key <= key_pressed; // RO
					9'h052: key_row[3][6] <= ~key_pressed; // :
					9'h054: key_row[3][7] <= ~key_pressed; // @
					9'h04E: key_row[3][8] <= ~key_pressed; // -

					9'h02E: key_row[4][0] <= ~key_pressed; // 5
					9'h02C: key_row[4][1] <= ~key_pressed; // T
					9'h034: key_row[4][2] <= ~key_pressed; // G
					9'h032: key_row[4][3] <= ~key_pressed; // B
					9'h172: key_row[4][5] <= ~key_pressed; // Down
					9'h05D: key_row[4][6] <= ~key_pressed; // ]
					9'h05B: key_row[4][7] <= ~key_pressed; // [
					9'h055: key_row[4][8] <= ~key_pressed; // ^

					9'h036: key_row[5][0] <= ~key_pressed; // 6
					9'h035: key_row[5][1] <= ~key_pressed; // Y
					9'h033: key_row[5][2] <= ~key_pressed; // H
					9'h031: key_row[5][3] <= ~key_pressed; // N
					9'h16B: key_row[5][5] <= ~key_pressed; // Left
					9'h05A: enter_key <= key_pressed; // CR
					9'h15A: keypad_enter_key <= key_pressed; // CR
					9'h00E: key_row[5][8] <= ~key_pressed; // Yen
					9'h00D: func_f3_key <= key_pressed; // FUNC
					9'h005: func_f1_key <= key_pressed; // FUNC

					9'h03D: key_row[6][0] <= ~key_pressed; // 7
					9'h03C: key_row[6][1] <= ~key_pressed; // U
					9'h03B: key_row[6][2] <= ~key_pressed; // J
					9'h03A: key_row[6][3] <= ~key_pressed; // M
					9'h174: key_row[6][5] <= ~key_pressed; // Right
					9'h175: key_row[6][6] <= ~key_pressed; // Up
					9'h076: break_key <= key_pressed; // BRK
					9'h177: pause_key <= key_pressed; // BRK
					9'h011: alt_key <= key_pressed; // GRP
					9'h111: altgr_key <= key_pressed; // GRP
					9'h014: ctrl_key <= key_pressed; // CTRL
					9'h114: ctrl_r_key <= key_pressed; // CTRL
					9'h012: shift_l_key <= key_pressed; // SHIFT
					9'h059: shift_r_key <= key_pressed; // SHIFT
					default: ;
				endcase
			end
		end
	end

	always_comb begin : keyboard_matrix_map
		case (row_sel)
			3'd0: row_data = key_row[0];
			3'd1: row_data = key_row[1];
			3'd2: begin
				row_data = key_row[2];
				row_data[4] = ~(clr_key | home_key); // CLR
			end
			3'd3: begin
				row_data = key_row[3];
				row_data[4] = ~(ins_key | del_key); // INS/DEL
				row_data[5] = ~(ro_key | bslash_key); // RO
			end
			3'd4: row_data = key_row[4];
			3'd5: begin
				row_data = key_row[5];
				row_data[6] = ~(enter_key | keypad_enter_key); // CR
				row_data[11] = ~(func_f3_key | func_f1_key); // FUNC
			end
			3'd6: begin
				row_data = key_row[6];
				row_data[8] = ~(break_key | pause_key); // BRK
				row_data[9] = ~(alt_key | altgr_key); // GRP
				row_data[10] = ~(ctrl_key | ctrl_r_key); // CTRL
				row_data[11] = ~(shift_l_key | shift_r_key); // SHIFT
			end
			3'd7: row_data = joy_row;
			default: row_data = 12'hFFF;
		endcase

		if (!enable) row_data = 12'hFFF;
	end

endmodule
