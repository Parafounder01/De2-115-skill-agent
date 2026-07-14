// ============================================================
//  mega_demo.v — DE2-115 All-in-One Demo
//
//  Combines:
//    - LCD 16x2: animated evil eye + clock + message cycling
//    - LEDR[17:0]: dancing patterns (knight rider)
//    - LEDG[7:0]: synchronized green LED patterns
//    - HEX7..HEX0: 12-hour HH:MM:SS clock with AM/PM
//
//  Initial time from time_init.v (compile-time define).
// ============================================================

`include "time_init.v"

module mega_demo (
    input  clk,           // 50 MHz (PIN_Y2)

    // ── HEX display ──
    output [6:0] hex7, hex6, hex5, hex4,
                   hex3, hex2, hex1, hex0,

    // ── LEDs ──
    output [17:0] ledr,
    output [7:0]  ledg,

    // ── LCD ──
    output [7:0] lcd_data,
    output       lcd_rs,
    output       lcd_rw,
    output       lcd_en,
    output       lcd_on,
    output       lcd_blon
);

    assign lcd_on   = 1'b1;
    assign lcd_blon = 1'b1;
    assign lcd_rw   = 1'b0;   // always write

    // ============================================================
    //  1. Tick generators
    // ============================================================
    //  50 MHz → 10 μs tick (500 cycles) → 1 ms tick (100 × 10μs)
    reg [8:0]  tick_10us_cnt;
    reg        tick_10us;
    reg [6:0]  tick_1ms_cnt;
    reg        tick_1ms;

    always @(posedge clk) begin
        if (tick_10us_cnt == 9'd499) begin tick_10us_cnt <= 0; tick_10us <= 1'b1; end
        else begin tick_10us_cnt <= tick_10us_cnt + 9'd1; tick_10us <= 1'b0; end
    end

    always @(posedge clk) begin
        if (tick_10us) begin
            if (tick_1ms_cnt == 7'd99) begin tick_1ms_cnt <= 0; tick_1ms <= 1'b1; end
            else begin tick_1ms_cnt <= tick_1ms_cnt + 7'd1; tick_1ms <= 1'b0; end
        end else tick_1ms <= 1'b0;
    end

    // 1-second tick
    reg [9:0] tick_1s_cnt;
    reg       tick_1s;
    always @(posedge clk) begin
        if (tick_1ms) begin
            if (tick_1s_cnt == 10'd999) begin tick_1s_cnt <= 0; tick_1s <= 1'b1; end
            else begin tick_1s_cnt <= tick_1s_cnt + 10'd1; tick_1s <= 1'b0; end
        end else tick_1s <= 1'b0;
    end

    // 250ms tick for LED animation
    reg [7:0] tick_250ms_cnt;
    reg       tick_250ms;
    always @(posedge clk) begin
        if (tick_1ms) begin
            if (tick_250ms_cnt == 8'd249) begin tick_250ms_cnt <= 0; tick_250ms <= 1'b1; end
            else begin tick_250ms_cnt <= tick_250ms_cnt + 8'd1; tick_250ms <= 1'b0; end
        end else tick_250ms <= 1'b0;
    end

    // ============================================================
    //  2. Time counter (24-hour, compile-time init)
    // ============================================================
    `ifndef INIT_HOUR
        `define INIT_HOUR    0
        `define INIT_MINUTE  0
        `define INIT_SECOND  0
    `endif

    reg [3:0] hr1, hr0, min1, min0, sec1, sec0;

    wire carry_sec0 = tick_1s && (sec0 == 4'd9);
    wire carry_sec1 = carry_sec0 && (sec1 == 4'd5);
    wire carry_min0 = carry_sec1 && (min0 == 4'd9);
    wire carry_min1 = carry_min0 && (min1 == 4'd5);
    wire is_23h59m  = (hr1 == 4'd2) && (hr0 == 4'd3);

    always @(posedge clk) begin
        if (carry_sec0) sec1 <= (sec1 == 4'd5) ? 4'd0 : sec1 + 4'd1;
        if (carry_sec1) min0 <= (min0 == 4'd9) ? 4'd0 : min0 + 4'd1;
        if (carry_min0) min1 <= (min1 == 4'd5) ? 4'd0 : min1 + 4'd1;
        if (carry_min1) begin
            if (is_23h59m) {hr1, hr0} <= {4'd0, 4'd0};
            else if (hr0 == 9) {hr1, hr0} <= {hr1 + 4'd1, 4'd0};
            else hr0 <= hr0 + 4'd1;
        end
        if (tick_1s) sec0 <= (sec0 == 4'd9) ? 4'd0 : sec0 + 4'd1;
    end

    // ============================================================
    //  3. HEX display: 12-hour clock with AM/PM
    // ============================================================
    wire [4:0] hour24 = hr1 * 4'd10 + hr0;
    wire [4:0] hour12_mod = hour24 % 4'd12;
    wire [4:0] hour12 = (hour12_mod == 0) ? 5'd12 : hour12_mod;
    wire       is_pm = (hour24 >= 5'd12);
    wire [3:0] h12_tens = hour12 / 4'd10;
    wire [3:0] h12_ones = hour12 % 4'd10;
    wire       blank_tens = (hour12 < 5'd10);

    function [6:0] seg7(input [3:0] v);
        case (v)
            4'd0: seg7 = 7'b1000000; 4'd1: seg7 = 7'b1111001;
            4'd2: seg7 = 7'b0100100; 4'd3: seg7 = 7'b0110000;
            4'd4: seg7 = 7'b0011001; 4'd5: seg7 = 7'b0010010;
            4'd6: seg7 = 7'b0000010; 4'd7: seg7 = 7'b1111000;
            4'd8: seg7 = 7'b0000000; 4'd9: seg7 = 7'b0010000;
            default: seg7 = 7'b1111111;
        endcase
    endfunction

    localparam SEG_A = 7'b0001000;
    localparam SEG_P = 7'b0001100;
    localparam SEG_BLANK = 7'b1111111;

    assign hex7 = blank_tens ? SEG_BLANK : seg7(h12_tens);
    assign hex6 = seg7(h12_ones);
    assign hex5 = seg7(min1);
    assign hex4 = seg7(min0);
    assign hex3 = seg7(sec1);
    assign hex2 = seg7(sec0);
    assign hex1 = is_pm ? SEG_P : SEG_A;
    assign hex0 = SEG_BLANK;

    // ============================================================
    //  4. LEDR[17:0] — dancing patterns
    // ============================================================
    reg [17:0] ledr_r;
    reg [4:0]  kr_pos;
    reg        kr_dir;

    always @(posedge clk) begin
        if (tick_250ms) begin
            if (kr_dir) begin
                if (kr_pos == 5'd17) begin kr_dir <= 0; kr_pos <= 5'd16; end
                else kr_pos <= kr_pos + 5'd1;
            end else begin
                if (kr_pos == 5'd0) begin kr_dir <= 1; kr_pos <= 5'd1; end
                else kr_pos <= kr_pos - 5'd1;
            end
        end
    end

    always @(*) begin
        ledr_r = 18'd0;
        ledr_r[kr_pos] = 1'b1;
        if (kr_pos > 0)  ledr_r[kr_pos - 1] = 1'b1;
        if (kr_pos < 17) ledr_r[kr_pos + 1] = 1'b1;
    end
    assign ledr = ledr_r;

    // ============================================================
    //  5. LEDG[7:0] — expanding bar
    // ============================================================
    reg [7:0] ledg_r;
    reg [3:0] ledg_phase;

    always @(posedge clk) begin
        if (tick_1s) begin
            ledg_phase <= ledg_phase + 4'd1;
            case (ledg_phase)
                0: ledg_r <= 8'b00000001;
                1: ledg_r <= 8'b00000011;
                2: ledg_r <= 8'b00000111;
                3: ledg_r <= 8'b00001111;
                4: ledg_r <= 8'b00011111;
                5: ledg_r <= 8'b00111111;
                6: ledg_r <= 8'b01111111;
                7: ledg_r <= 8'b11111111;
                8: ledg_r <= 8'b01111111;
                9: ledg_r <= 8'b00111111;
                10: ledg_r <= 8'b00011111;
                11: ledg_r <= 8'b00001111;
                12: ledg_r <= 8'b00000111;
                13: ledg_r <= 8'b00000011;
                14: ledg_r <= 8'b00000001;
                15: ledg_r <= 8'b00000000;
            endcase
        end
    end
    assign ledg = ledg_r;

    // ============================================================
    //  6. LCD — HD44780 8-bit driver with CGRAM & animation
    // ============================================================

    // CGRAM: 4 custom characters for the evil eye
    reg [7:0] cgram [0:31];
    initial begin
        // Char 0: left pupil  (◉_ )
        cgram[0]  = 8'b01110; cgram[1]  = 8'b10001;
        cgram[2]  = 8'b10101; cgram[3]  = 8'b10101;
        cgram[4]  = 8'b10101; cgram[5]  = 8'b10001;
        cgram[6]  = 8'b01110; cgram[7]  = 8'b00000;
        // Char 1: center pupil (_◉_)
        cgram[8]  = 8'b01110; cgram[9]  = 8'b10001;
        cgram[10] = 8'b11011; cgram[11] = 8'b11011;
        cgram[12] = 8'b11011; cgram[13] = 8'b10001;
        cgram[14] = 8'b01110; cgram[15] = 8'b00000;
        // Char 2: right pupil (_◉ )
        cgram[16] = 8'b01110; cgram[17] = 8'b10001;
        cgram[18] = 8'b11101; cgram[19] = 8'b11101;
        cgram[20] = 8'b11101; cgram[21] = 8'b10001;
        cgram[22] = 8'b01110; cgram[23] = 8'b00000;
        // Char 3: closed eye (___)
        cgram[24] = 8'b00000; cgram[25] = 8'b00000;
        cgram[26] = 8'b11111; cgram[27] = 8'b11111;
        cgram[28] = 8'b11111; cgram[29] = 8'b00000;
        cgram[30] = 8'b00000; cgram[31] = 8'b00000;
    end

    // ── Buffers for LCD lines ──
    //  We construct the strings we want to display, then a
    //  DMA engine writes them to the LCD character by character.
    reg [7:0] line1 [0:15];
    reg [7:0] line2 [0:15];

    // ── LCD state machine ──
    localparam IDLE       = 5'd0;
    localparam CMD_FUNC   = 5'd1;
    localparam CMD_OFF    = 5'd2;
    localparam CMD_CLR    = 5'd3;
    localparam CMD_ENTRY  = 5'd4;
    localparam CMD_ON     = 5'd5;
    localparam CGRAM_ADDR = 5'd6;
    localparam CGRAM_WR   = 5'd7;
    localparam CGRAM_NEXT = 5'd8;
    localparam SET_ADDR   = 5'd9;
    localparam WR_CHAR    = 5'd10;
    localparam NEXT_CHAR  = 5'd11;
    localparam DONE       = 5'd12;

    reg [4:0] lcd_state;
    reg [5:0] cg_idx;        // 0-31 for CGRAM loading
    reg [7:0] lcd_buf;       // output buffer
    reg       lcd_rs_buf;     // RS buffer
    reg [4:0] wr_idx;         // 0-31 for writing chars (0-15=line1, 16-31=line2)
    reg [15:0] wait_cnt;      // delay counter

    assign lcd_data = lcd_buf;
    assign lcd_rs   = lcd_rs_buf;

    // EN strobe: single pulse generator
    reg [3:0] en_cnt;
    reg       en_phase;
    reg       en_busy;

    always @(posedge clk) begin
        if (lcd_state == IDLE) begin
            en_cnt   <= 0;
            en_phase <= 0;
            en_busy  <= 0;
            lcd_en_r <= 1'b0;
        end else if (en_busy) begin
            if (!en_phase) begin
                lcd_en_r <= 1'b1;
                if (en_cnt == 4'd9) begin en_phase <= 1; en_cnt <= 0; end
                else en_cnt <= en_cnt + 4'd1;
            end else begin
                lcd_en_r <= 1'b0;
                if (en_cnt == 4'd9) begin en_busy <= 0; en_cnt <= 0; end
                else en_cnt <= en_cnt + 4'd1;
            end
        end
    end

    // ── Build display content based on mode ──
    reg [1:0] disp_mode;   // 0=eye, 1=clock, 2=message
    reg [7:0] mode_hold;   // ticks remaining in this mode
    reg [7:0] eye_frame;   // animation frame counter (0-31)
    reg [7:0] eye_idx;     // current eye char index 0-3

    // Build line1/line2 buffers based on disp_mode
    // (updated before each screen refresh cycle)

    // ── Main LCD state machine ──
    always @(posedge clk) begin
        case (lcd_state)
            IDLE: begin
                // Power-on wait ~20ms
                if (wait_cnt == 16'd20_000) begin
                    wait_cnt <= 0;
                    lcd_state <= CMD_FUNC;
                end else if (tick_10us) begin
                    wait_cnt <= wait_cnt + 16'd1;
                end
            end

            // ── Init commands ──
            CMD_FUNC: begin
                lcd_buf <= 8'h38; lcd_rs_buf <= 0;
                if (!en_busy) begin en_busy <= 1; end
                else if (wait_cnt == 16'd200) begin wait_cnt <= 0; lcd_state <= CMD_OFF; end
                else if (tick_10us) wait_cnt <= wait_cnt + 16'd1;
            end

            CMD_OFF: begin
                lcd_buf <= 8'h08; lcd_rs_buf <= 0;
                if (!en_busy) begin en_busy <= 1; end
                else if (wait_cnt == 16'd100) begin wait_cnt <= 0; lcd_state <= CMD_CLR; end
                else if (tick_10us) wait_cnt <= wait_cnt + 16'd1;
            end

            CMD_CLR: begin
                lcd_buf <= 8'h01; lcd_rs_buf <= 0;
                if (!en_busy) begin en_busy <= 1; end
                else if (wait_cnt == 16'd2000) begin wait_cnt <= 0; lcd_state <= CMD_ENTRY; end
                else if (tick_10us) wait_cnt <= wait_cnt + 16'd1;
            end

            CMD_ENTRY: begin
                lcd_buf <= 8'h06; lcd_rs_buf <= 0;
                if (!en_busy) begin en_busy <= 1; end
                else if (wait_cnt == 16'd100) begin wait_cnt <= 0; lcd_state <= CMD_ON; end
                else if (tick_10us) wait_cnt <= wait_cnt + 16'd1;
            end

            CMD_ON: begin
                lcd_buf <= 8'h0C; lcd_rs_buf <= 0;
                if (!en_busy) begin en_busy <= 1; end
                else if (wait_cnt == 16'd100) begin wait_cnt <= 0; lcd_state <= CGRAM_ADDR; cg_idx <= 0; end
                else if (tick_10us) wait_cnt <= wait_cnt + 16'd1;
            end

            // ── Load CGRAM (32 bytes at CGRAM addr 0x40) ──
            CGRAM_ADDR: begin
                lcd_buf <= {2'b01, cg_idx[4:0], 1'b0};  // 0x40 + cg_idx
                lcd_rs_buf <= 0;
                if (!en_busy) begin en_busy <= 1; end
                else if (wait_cnt == 16'd100) begin wait_cnt <= 0; lcd_state <= CGRAM_WR; end
                else if (tick_10us) wait_cnt <= wait_cnt + 16'd1;
            end

            CGRAM_WR: begin
                lcd_buf <= cgram[cg_idx];
                lcd_rs_buf <= 1;
                if (!en_busy) begin en_busy <= 1; end
                else if (wait_cnt == 16'd100) begin wait_cnt <= 0; lcd_state <= CGRAM_NEXT; end
                else if (tick_10us) wait_cnt <= wait_cnt + 16'd1;
            end

            CGRAM_NEXT: begin
                if (cg_idx == 6'd31) begin
                    lcd_state <= DONE;
                    disp_mode <= 0;
                    mode_hold <= 0;
                    eye_frame <= 0;
                end else begin
                    cg_idx <= cg_idx + 6'd1;
                    lcd_state <= CGRAM_ADDR;
                end
            end

            // ── Display cycling ──
            DONE: begin
                // Every ~40ms, refresh the screen
                if (tick_1ms && wait_cnt == 16'd40) begin
                    wait_cnt <= 0;

                    // Update mode if needed
                    if (mode_hold >= 8'd100) begin     // ~4 sec per mode
                        mode_hold <= 0;
                        disp_mode <= disp_mode + 2'd1;
                    end else begin
                        mode_hold <= mode_hold + 8'd1;
                    end

                    // Build display content
                    if (disp_mode == 0) begin
                        // ── EVIL EYE mode ──
                        eye_frame <= eye_frame + 8'd1;
                        case (eye_frame[4:3])  // change every 8 frames = ~320ms
                            0: eye_idx <= 8'd0;   // left
                            1: eye_idx <= 8'd1;   // center
                            2: eye_idx <= 8'd2;   // right
                            3: eye_idx <= 8'd3;   // blink
                        endcase

                        // Line 1: "  \x00 \x01 \x02  EVIL"
                        line1[0] <= " "; line1[1] <= " "; line1[2] <= " ";
                        line1[3] <= 8'd0 + eye_idx[1:0];  // left eye
                        line1[4] <= " ";
                        line1[5] <= 8'd0 + ((eye_idx[1:0] + 2'd1) % 2'd3);  // center eye
                        line1[6] <= " ";
                        line1[7] <= 8'd0 + ((eye_idx[1:0] + 2'd2) % 2'd3);  // right eye
                        line1[8] <= " "; line1[9] <= " ";
                        line1[10] <= "E"; line1[11] <= "V"; line1[12] <= "I";
                        line1[13] <= "L"; line1[14] <= " "; line1[15] <= " ";

                        // Line 2: "  WATCHING YOU!   "
                        line2[0] <= " "; line2[1] <= " "; line2[2] <= " ";
                        line2[3] <= "W"; line2[4] <= "A"; line2[5] <= "T";
                        line2[6] <= "C"; line2[7] <= "H"; line2[8] <= "I";
                        line2[9] <= "N"; line2[10] <= "G"; line2[11] <= " ";
                        line2[12] <= "Y"; line2[13] <= "O"; line2[14] <= "U";
                        line2[15] <= "!";
                    end else if (disp_mode == 1) begin
                        // ── CLOCK mode ──
                        // Line 1: "HH:MM:SS AM/PM"
                        line1[0] <= "0" + h12_tens;
                        line1[1] <= "0" + h12_ones;
                        line1[2] <= ":";
                        line1[3] <= "0" + min1;
                        line1[4] <= "0" + min0;
                        line1[5] <= ":";
                        line1[6] <= "0" + sec1;
                        line1[7] <= "0" + sec0;

                        if (h12_tens == 0) line1[0] <= " ";  // blank leading zero
                        line1[8] <= " ";
                        if (is_pm) begin line1[9] <= "P"; line1[10] <= "M"; end
                        else begin line1[9] <= "A"; line1[10] <= "M"; end
                        line1[11] <= " "; line1[12] <= " "; line1[13] <= " ";
                        line1[14] <= " "; line1[15] <= " ";

                        line2[0] <= "D"; line2[1] <= "E"; line2[2] <= "2";
                        line2[3] <= "-"; line2[4] <= "1"; line2[5] <= "1";
                        line2[6] <= "5"; line2[7] <= " "; line2[8] <= "C";
                        line2[9] <= "L"; line2[10] <= "O"; line2[11] <= "C";
                        line2[12] <= "K"; line2[13] <= " "; line2[14] <= " ";
                        line2[15] <= " ";
                    end else begin
                        // ── MESSAGE mode ──
                        line1[0] <= "d"; line1[1] <= "i"; line1[2] <= "s";
                        line1[3] <= "p"; line1[4] <= "l"; line1[5] <= "a";
                        line1[6] <= "y"; line1[7] <= " "; line1[8] <= "d";
                        line1[9] <= "e"; line1[10] <= "2"; line1[11] <= "-";
                        line1[12] <= "1"; line1[13] <= "1"; line1[14] <= "5";
                        line1[15] <= " ";

                        line2[0] <= "a"; line2[1] <= "g"; line2[2] <= "e";
                        line2[3] <= "n"; line2[4] <= "t"; line2[5] <= " ";
                        line2[6] <= "w"; line2[7] <= "o"; line2[8] <= "r";
                        line2[9] <= "k"; line2[10] <= "i"; line2[11] <= "n";
                        line2[12] <= "g"; line2[13] <= " "; line2[14] <= " ";
                        line2[15] <= " ";
                    end

                    // Start writing to LCD
                    wr_idx <= 0;
                    lcd_state <= SET_ADDR;
                end else if (tick_1ms) begin
                    wait_cnt <= wait_cnt + 16'd1;
                end
            end

            SET_ADDR: begin
                if (wr_idx < 16) lcd_buf <= 8'h80 + wr_idx[3:0];       // Line 1 addr
                else lcd_buf <= 8'hC0 + (wr_idx - 5'd16);              // Line 2 addr
                lcd_rs_buf <= 0;
                if (!en_busy) begin en_busy <= 1; end
                else if (wait_cnt == 16'd100) begin wait_cnt <= 0; lcd_state <= WR_CHAR; end
                else if (tick_10us) wait_cnt <= wait_cnt + 16'd1;
            end

            WR_CHAR: begin
                if (wr_idx < 16) lcd_buf <= line1[wr_idx];
                else lcd_buf <= line2[wr_idx - 5'd16];
                lcd_rs_buf <= 1;
                if (!en_busy) begin en_busy <= 1; end
                else if (wait_cnt == 16'd100) begin wait_cnt <= 0; lcd_state <= NEXT_CHAR; end
                else if (tick_10us) wait_cnt <= wait_cnt + 16'd1;
            end

            NEXT_CHAR: begin
                if (wr_idx == 5'd31) begin
                    lcd_state <= DONE;
                end else begin
                    wr_idx <= wr_idx + 5'd1;
                    lcd_state <= SET_ADDR;
                end
            end

            default: lcd_state <= IDLE;
        endcase
    end

endmodule
