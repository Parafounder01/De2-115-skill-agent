// ============================================================
//  space_impact.v — DE2-115 Space Shooter on LCD 16x2
//
//  Controls:
//    KEY3 = move UP (row 0)
//    KEY2 = move DOWN (row 1)
//    KEY1 = SHOOT (fires bullet upward)
//    KEY0 = reset
//
//  Custom CGRAM characters for ship, alien, bullet, etc.
//  Score on HEX7-HEX5, lives on HEX1-HEX0.
// ============================================================

`include "time_init.v"

module space_impact (
    input  clk,           // 50 MHz (PIN_Y2)
    input  rst_n,         // KEY0 (PIN_M23, active-low)
    input  key3,          // up   (PIN_R24)
    input  key2,          // down (PIN_P21)
    input  key1,          // shoot (PIN_M21)

    // LCD
    output [7:0] lcd_data,
    output       lcd_rs,
    output       lcd_rw,
    output       lcd_en,
    output       lcd_on,
    output       lcd_blon,

    // HEX score/lives
    output [6:0] hex7, hex6, hex5, hex4,
                   hex3, hex2, hex1, hex0
);

    assign lcd_on   = 1'b1;
    assign lcd_blon = 1'b1;
    assign lcd_rw   = 1'b0;
    assign hex3 = 7'b1111111;  // blank
    assign hex2 = 7'b1111111;
    assign hex4 = 7'b1111111;

    // ============================================================
    //  1. Ticks: 10us, 1ms, 100ms
    // ============================================================
    reg [8:0]  t10_cnt; reg t10;
    reg [6:0]  t1ms_cnt; reg t1ms;
    reg [6:0]  t100ms_cnt; reg t100ms;

    always @(posedge clk) begin
        if (t10_cnt == 9'd499) begin t10_cnt <= 0; t10 <= 1; end
        else begin t10_cnt <= t10_cnt + 1; t10 <= 0; end
    end
    always @(posedge clk) begin
        if (t10) begin
            if (t1ms_cnt == 7'd99) begin t1ms_cnt <= 0; t1ms <= 1; end
            else begin t1ms_cnt <= t1ms_cnt + 1; t1ms <= 0; end
        end else t1ms <= 0;
    end
    always @(posedge clk) begin
        if (t1ms) begin
            if (t100ms_cnt == 7'd100) begin t100ms_cnt <= 0; t100ms <= 1; end
            else begin t100ms_cnt <= t100ms_cnt + 1; t100ms <= 0; end
        end else t100ms <= 0;
    end

    // ============================================================
    //  2. Key debounce
    // ============================================================
    reg [19:0] db_tmr;
    reg [3:1]  ks, kd, kp;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin ks <= 3'h7; kd <= 3'h7; kp <= 3'h7; db_tmr <= 0; end
        else begin
            kp <= kd; ks[3] <= key3; ks[2] <= key2; ks[1] <= key1;
            if (ks[3:1] != kd) begin
                if (db_tmr == 20'd500_000) begin kd <= ks[3:1]; db_tmr <= 0; end
                else db_tmr <= db_tmr + 1;
            end else db_tmr <= 0;
        end
    end

    wire kup  = ~kd[3] && kp[3];
    wire kdn  = ~kd[2] && kp[2];
    wire ksh  = ~kd[1] && kp[1];

    // ============================================================
    //  2b. 16-bit LFSR pseudo-random number generator
    // ============================================================
    reg [15:0] rng;
    always @(posedge clk) begin
        if (!rst_n) rng <= 16'hACE1;
        else rng <= {rng[14:0], rng[15] ^ rng[13] ^ rng[12] ^ rng[10]};
    end

    // ============================================================
    //  3. Game state
    // ============================================================
    reg [7:0]  score;
    reg [1:0]  lives;
    reg        go;            // game over
    reg        player_row;    // 0=top row, 1=bottom row
    reg [3:0]  player_col;    // 0-15

    // Enemy: each enemy has row (0/1), col (0-15), active flag
    reg [3:0]  e_col  [0:5];
    reg        e_row  [0:5];
    reg [5:0]  e_alive;

    // Bullet: row (0/1), col (0-15), active
    reg [3:0]  b_col  [0:2];
    reg        b_row  [0:2];
    reg [2:0]  b_alive;

    reg [4:0]  spawn_tmr;
    reg [5:0]  frame_tmr;

    always @(posedge clk) begin
        if (!rst_n) begin
            score <= 0; lives <= 3; go <= 0;
            player_row <= 1; player_col <= 3;
            e_alive <= 0; b_alive <= 0;
            spawn_tmr <= 0; frame_tmr <= 0;
        end else if (t100ms) begin
            if (!go) begin
                if (kup) player_row <= 0;
                if (kdn) player_row <= 1;

                // Shoot (unrolled for 3 bullets)
                if (ksh) begin
                    if (!b_alive[0]) begin b_col[0] <= player_col; b_row[0] <= player_row; b_alive[0] <= 1; end
                    else if (!b_alive[1]) begin b_col[1] <= player_col; b_row[1] <= player_row; b_alive[1] <= 1; end
                    else if (!b_alive[2]) begin b_col[2] <= player_col; b_row[2] <= player_row; b_alive[2] <= 1; end
                end

                // Move bullets
                if (b_alive[0]) begin if (b_row[0] == 0) b_alive[0] <= 0; else b_row[0] <= 0; end
                if (b_alive[1]) begin if (b_row[1] == 0) b_alive[1] <= 0; else b_row[1] <= 0; end
                if (b_alive[2]) begin if (b_row[2] == 0) b_alive[2] <= 0; else b_row[2] <= 0; end

                // Spawn enemies
                if (spawn_tmr == 0) begin
                    spawn_tmr <= 5'd6;
                    if (!e_alive[0]) begin e_col[0] <= {1'b0, rng[3:1]} + 4; e_row[0] <= 0; e_alive[0] <= 1; end
                    else if (!e_alive[1]) begin e_col[1] <= {1'b0, rng[6:4]} + 4; e_row[1] <= 0; e_alive[1] <= 1; end
                    else if (!e_alive[2]) begin e_col[2] <= {1'b0, rng[9:7]} + 4; e_row[2] <= 0; e_alive[2] <= 1; end
                    else if (!e_alive[3]) begin e_col[3] <= {1'b0, rng[12:10]} + 4; e_row[3] <= 0; e_alive[3] <= 1; end
                    else if (!e_alive[4]) begin e_col[4] <= {1'b0, rng[15:13]} + 4; e_row[4] <= 0; e_alive[4] <= 1; end
                    else if (!e_alive[5]) begin e_col[5] <= {1'b0, rng[14:12]} + 4; e_row[5] <= 0; e_alive[5] <= 1; end
                end else spawn_tmr <= spawn_tmr - 1;

                // Move enemies down (unrolled for 6)
                begin
                    integer i;
                    for (i = 0; i < 6; i = i + 1) begin
                        if (e_alive[i]) begin
                            if (e_row[i] == 1) begin
                                if (e_row[i] == player_row && e_col[i] == player_col) begin
                                    if (lives > 0) lives <= lives - 1;
                                    if (lives <= 1) go <= 1;
                                end
                                e_alive[i] <= 0;
                            end else begin
                                e_row[i] <= 1;
                                if (rng[1:0] == 2'b00 && e_col[i] > 1) e_col[i] <= e_col[i] - 1;
                                if (rng[3:2] == 2'b00 && e_col[i] < 14) e_col[i] <= e_col[i] + 1;
                            end
                        end
                    end
                end

                // Collision: bullet × enemy (unrolled for 3 bullets × 6 enemies)
                begin
                    integer bi, ej;
                    for (bi = 0; bi < 3; bi = bi + 1) begin
                        if (b_alive[bi]) begin
                            for (ej = 0; ej < 6; ej = ej + 1) begin
                                if (e_alive[ej] && b_row[bi] == e_row[ej] && b_col[bi] == e_col[ej]) begin
                                    b_alive[bi] <= 0;
                                    e_alive[ej] <= 0;
                                    score <= score + 10;
                                end
                            end
                        end
                    end
                end

                if (lives == 0) go <= 1;

            end else begin
                if (ksh) begin
                    score <= 0; lives <= 3; go <= 0;
                    player_row <= 1; player_col <= 3;
                    e_alive <= 0; b_alive <= 0;
                end
            end
        end
    end

    // ============================================================
    //  4. LCD driver — shows game field
    // ============================================================

    // ── CGRAM: 8 custom chars ──
    reg [7:0] cgram [0:63];
    initial begin
        // Char 0: ship (▀▄ shape - 5x8)
        cgram[0]  = 8'b00100; //  . X . . 
        cgram[1]  = 8'b01110; //  . X X . 
        cgram[2]  = 8'b11111; //  X X X X 
        cgram[3]  = 8'b11111; //  X X X X 
        cgram[4]  = 8'b01110; //  . X X . 
        cgram[5]  = 8'b01010; //  . X . X 
        cgram[6]  = 8'b10001; //  X . . X 
        cgram[7]  = 8'b00000; //  . . . . 
        // Char 1: alien (▄▀ shape)
        cgram[8]  = 8'b01110; //  .XXX.
        cgram[9]  = 8'b10101; //  X.X.X
        cgram[10] = 8'b11111; //  XXXXX
        cgram[11] = 8'b01010; //  .X.X.
        cgram[12] = 8'b11011; //  XX.XX
        cgram[13] = 8'b10001; //  X...X
        cgram[14] = 8'b00000; //  .....
        cgram[15] = 8'b00000;
        // Char 2: bullet (|)
        cgram[16] = 8'b00100;
        cgram[17] = 8'b00100;
        cgram[18] = 8'b01110;
        cgram[19] = 8'b01110;
        cgram[20] = 8'b00100;
        cgram[21] = 8'b00100;
        cgram[22] = 8'b00000;
        cgram[23] = 8'b00000;
        // Char 3: explosion (*)
        cgram[24] = 8'b10001;
        cgram[25] = 8'b01010;
        cgram[26] = 8'b00100;
        cgram[27] = 8'b01010;
        cgram[28] = 8'b10001;
        cgram[29] = 8'b00000;
        cgram[30] = 8'b00000;
        cgram[31] = 8'b00000;
        // Char 4: heart ♥
        cgram[32] = 8'b01010;
        cgram[33] = 8'b11111;
        cgram[34] = 8'b11111;
        cgram[35] = 8'b11111;
        cgram[36] = 8'b01110;
        cgram[37] = 8'b00100;
        cgram[38] = 8'b00000;
        cgram[39] = 8'b00000;
        // Char 5: game over skull
        cgram[40] = 8'b01110;
        cgram[41] = 8'b10101;
        cgram[42] = 8'b11111;
        cgram[43] = 8'b10101;
        cgram[44] = 8'b01110;
        cgram[45] = 8'b01010;
        cgram[46] = 8'b10001;
        cgram[47] = 8'b00000;
        // Char 6: blank with bottom line (for ground)
        cgram[48] = 8'b00000;
        cgram[49] = 8'b00000;
        cgram[50] = 8'b00000;
        cgram[51] = 8'b00000;
        cgram[52] = 8'b00000;
        cgram[53] = 8'b00000;
        cgram[54] = 8'b11111;
        cgram[55] = 8'b00000;
        // Char 7: star
        cgram[56] = 8'b00000;
        cgram[57] = 8'b00100;
        cgram[58] = 8'b00000;
        cgram[59] = 8'b00000;
        cgram[60] = 8'b00100;
        cgram[61] = 8'b00000;
        cgram[62] = 8'b00000;
        cgram[63] = 8'b00000;
    end

    // ── Line buffers ──
    reg [7:0] line1 [0:15];
    reg [7:0] line2 [0:15];

    // Fill line buffers based on game state
    reg [7:0] rand_star;
    always @(*) begin
        if (go) begin
            // Game Over screen
            line1[0]  = " "; line1[1]  = " "; line1[2]  = " ";
            line1[3]  = "G"; line1[4]  = "A"; line1[5]  = "M";
            line1[6]  = "E"; line1[7]  = " "; line1[8]  = "O";
            line1[9]  = "V"; line1[10] = "E"; line1[11] = "R";
            line1[12] = " "; line1[13] = " "; line1[14] = " ";
            line1[15] = " ";
            line2[0]  = " "; line2[1]  = " "; line2[2]  = " ";
            line2[3]  = " "; line2[4]  = 8'd5; line2[5]  = " ";
            line2[6]  = " "; line2[7]  = 8'd4; line2[8]  = " ";
            line2[9]  = " "; line2[10] = " "; line2[11] = " ";
            line2[12] = " "; line2[13] = " "; line2[14] = " ";
            line2[15] = " ";
        end else begin
            // Build game field (default: spaces)
            line1[0] = 8'h20; line1[1] = 8'h20; line1[2] = 8'h20;
            line1[3] = 8'h20; line1[4] = 8'h20; line1[5] = 8'h20;
            line1[6] = 8'h20; line1[7] = 8'h20; line1[8] = 8'h20;
            line1[9] = 8'h20; line1[10] = 8'h20; line1[11] = 8'h20;
            line1[12] = 8'h20; line1[13] = 8'h20; line1[14] = 8'h20;
            line1[15] = 8'h20;
            line2[0] = 8'h20; line2[1] = 8'h20; line2[2] = 8'h20;
            line2[3] = 8'h20; line2[4] = 8'h20; line2[5] = 8'h20;
            line2[6] = 8'h20; line2[7] = 8'h20; line2[8] = 8'h20;
            line2[9] = 8'h20; line2[10] = 8'h20; line2[11] = 8'h20;
            line2[12] = 8'h20; line2[13] = 8'h20; line2[14] = 8'h20;
            line2[15] = 8'h20;

            // Stars on line1
            rand_star = {clk, rst_n, key1, key2, key3};
            if (rand_star[0] == 1) line1[2] = 8'd7;
            if (rand_star[1] == 1) line1[5] = 8'd7;
            if (rand_star[2] == 1) line1[9] = 8'd7;
            if (rand_star[3] == 1) line1[13] = 8'd7;

            // Player
            if (player_row == 0) line1[player_col] = 8'd0;
            if (player_row == 1) line2[player_col] = 8'd0;

            // Bullets
            if (b_alive[0]) begin
                if (b_row[0] == 0) line1[b_col[0]] = 8'd2;
                else line2[b_col[0]] = 8'd2;
            end
            if (b_alive[1]) begin
                if (b_row[1] == 0) line1[b_col[1]] = 8'd2;
                else line2[b_col[1]] = 8'd2;
            end
            if (b_alive[2]) begin
                if (b_row[2] == 0) line1[b_col[2]] = 8'd2;
                else line2[b_col[2]] = 8'd2;
            end

            // Enemies
            if (e_alive[0]) begin
                if (e_row[0] == 0) line1[e_col[0]] = 8'd1; else line2[e_col[0]] = 8'd1;
            end
            if (e_alive[1]) begin
                if (e_row[1] == 0) line1[e_col[1]] = 8'd1; else line2[e_col[1]] = 8'd1;
            end
            if (e_alive[2]) begin
                if (e_row[2] == 0) line1[e_col[2]] = 8'd1; else line2[e_col[2]] = 8'd1;
            end
            if (e_alive[3]) begin
                if (e_row[3] == 0) line1[e_col[3]] = 8'd1; else line2[e_col[3]] = 8'd1;
            end
            if (e_alive[4]) begin
                if (e_row[4] == 0) line1[e_col[4]] = 8'd1; else line2[e_col[4]] = 8'd1;
            end
            if (e_alive[5]) begin
                if (e_row[5] == 0) line1[e_col[5]] = 8'd1; else line2[e_col[5]] = 8'd1;
            end
        end
    end

    // ── LCD state machine ──
    reg [4:0]  step;
    reg [6:0]  cg_i;
    reg [7:0]  lcd_dout;
    reg        lcd_rs_r;
    reg [4:0]  ch_i;
    reg [5:0]  delay;

    assign lcd_data = lcd_dout;
    assign lcd_rs   = lcd_rs_r;

    // EN strobe: 15-cycle pulse (150us @10us tick)
    reg [3:0]  en_cnt;
    reg        lcd_en_r;
    assign lcd_en = lcd_en_r;

    always @(posedge clk) begin
        if (t10) begin
            // ── EN strobe generator (parallel) ──
            if (en_cnt > 0) begin
                if (en_cnt < 10) begin lcd_en_r <= 1; en_cnt <= en_cnt + 1; end
                else if (en_cnt < 15) begin lcd_en_r <= 0; en_cnt <= en_cnt + 1; end
                else en_cnt <= 0;
            end

            // ── LCD state machine ──
            case (step)
                // ── Init ──
                0:  if (delay == 40) begin step <= 1; delay <= 0; end else delay <= delay + 1;
                1:  begin lcd_dout <= 8'h38; lcd_rs_r <= 0; en_cnt <= 1; step <= 2; end
                2:  if (en_cnt == 0) begin
                        if (delay == 100) begin step <= 3; delay <= 0; end
                        else delay <= delay + 1;
                    end
                3:  begin lcd_dout <= 8'h38; lcd_rs_r <= 0; en_cnt <= 1; step <= 4; end
                4:  if (en_cnt == 0) begin
                        if (delay == 10) begin step <= 5; delay <= 0; end
                        else delay <= delay + 1;
                    end
                5:  begin lcd_dout <= 8'h38; lcd_rs_r <= 0; en_cnt <= 1; step <= 6; end
                6:  if (en_cnt == 0) begin
                        if (delay == 10) begin step <= 7; delay <= 0; end
                        else delay <= delay + 1;
                    end
                7:  begin lcd_dout <= 8'h08; lcd_rs_r <= 0; en_cnt <= 1; step <= 8; end
                8:  if (en_cnt == 0) begin
                        if (delay == 10) begin step <= 9; delay <= 0; end
                        else delay <= delay + 1;
                    end
                9:  begin lcd_dout <= 8'h01; lcd_rs_r <= 0; en_cnt <= 1; step <= 10; end
                10: if (en_cnt == 0) begin
                        if (delay == 200) begin step <= 11; delay <= 0; end
                        else delay <= delay + 1;
                    end
                11: begin lcd_dout <= 8'h06; lcd_rs_r <= 0; en_cnt <= 1; step <= 12; end
                12: if (en_cnt == 0) begin
                        if (delay == 10) begin step <= 13; delay <= 0; end
                        else delay <= delay + 1;
                    end
                13: begin lcd_dout <= 8'h0C; lcd_rs_r <= 0; en_cnt <= 1; step <= 14; end
                14: if (en_cnt == 0) begin delay <= 0; step <= 15; cg_i <= 0; end

                // ── Load CGRAM (8 chars × 8 bytes = 64 bytes) ──
                15: begin lcd_dout <= 8'h40; lcd_rs_r <= 0; en_cnt <= 1; step <= 16; end
                16: if (en_cnt == 0) begin delay <= 0; step <= 17; end
                17: begin lcd_dout <= cgram[cg_i]; lcd_rs_r <= 1; en_cnt <= 1; step <= 18; end
                18: if (en_cnt == 0) begin
                        if (cg_i == 63) begin step <= 20; end
                        else begin cg_i <= cg_i + 1; step <= 15; end
                    end

                // ── Display loop ──
                20: begin lcd_dout <= 8'h80; lcd_rs_r <= 0; en_cnt <= 1; step <= 21; ch_i <= 0; end
                21: if (en_cnt == 0) begin delay <= 0; step <= 22; end
                22: begin lcd_dout <= line1[ch_i]; lcd_rs_r <= 1; en_cnt <= 1; step <= 23; end
                23: if (en_cnt == 0) begin
                        if (ch_i == 15) begin step <= 25; end
                        else begin ch_i <= ch_i + 1; step <= 22; end
                    end
                25: begin lcd_dout <= 8'hC0; lcd_rs_r <= 0; en_cnt <= 1; step <= 26; ch_i <= 0; end
                26: if (en_cnt == 0) begin delay <= 0; step <= 27; end
                27: begin lcd_dout <= line2[ch_i]; lcd_rs_r <= 1; en_cnt <= 1; step <= 28; end
                28: if (en_cnt == 0) begin
                        if (ch_i == 15) begin step <= 20; end
                        else begin ch_i <= ch_i + 1; step <= 27; end
                    end
            endcase
        end
    end

    // ============================================================
    //  5. HEX score/lives display
    // ============================================================
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

    assign hex7 = seg7(score / 4'd100);
    assign hex6 = seg7((score % 4'd100) / 4'd10);
    assign hex5 = seg7(score % 4'd10);
    assign hex1 = (lives >= 2) ? seg7(4'd1) : 7'b1111111;
    assign hex0 = (lives == 3) ? seg7(4'd3) : (lives == 2) ? seg7(4'd2) :
                  (lives == 1) ? seg7(4'd1) : 7'b1000000;

endmodule
