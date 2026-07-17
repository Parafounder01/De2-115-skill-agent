// ============================================================
//  space_impact_vga.v — DE2-115 Space Impact on VGA
//
//  Controls:
//    KEY3 = up (switch to lane 0)
//    KEY2 = down (switch to lane 1)
//    KEY1 = shoot
//    KEY0 = exit (reset)
//
//  VGA 640x480 @ 60Hz, 25MHz pixel clock
//  Game area: 2 lanes, 16 columns, 40x200 px per cell
// ============================================================

module space_impact_vga (
    input  clk,         // 50 MHz (PIN_Y2)
    input  rst_n,       // KEY0 (PIN_M23, active-low)
    input  key3,        // up   (PIN_R24)
    input  key2,        // down (PIN_P21)
    input  key1,        // shoot (PIN_M21)

    // VGA
    output [7:0] vga_r,
    output [7:0] vga_g,
    output [7:0] vga_b,
    output       vga_hs,
    output       vga_vs,
    output       vga_clk,
    output       vga_blank_n,
    output       vga_sync_n
);

    // ============================================================
    //  0. Derived clocks
    // ============================================================
    reg clk25;
    always @(posedge clk) clk25 <= ~clk25;

    assign vga_clk = clk25;
    assign vga_sync_n = 1'b1;   // inactive: separate HSync/VSync used

    // ============================================================
    //  1. VGA sync
    // ============================================================
    wire hsync, vsync, blank_n;
    wire [9:0] hcount, vcount;

    vga_sync sync_inst (
        .clk25   (clk25),
        .rst_n   (rst_n),
        .hsync   (hsync),
        .vsync   (vsync),
        .blank_n (blank_n),
        .hcount  (hcount),
        .vcount  (vcount)
    );

    assign vga_hs = hsync;
    assign vga_vs = vsync;
    assign vga_blank_n = blank_n;

    // ============================================================
    //  2. Timers: 10us, 1ms, 100ms
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
    //  3. Key debounce
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
    //  4. 16-bit LFSR pseudo-random generator
    // ============================================================
    reg [15:0] rng;
    always @(posedge clk) begin
        if (!rst_n) rng <= 16'hACE1;
        else rng <= {rng[14:0], rng[15] ^ rng[13] ^ rng[12] ^ rng[10]};
    end

    // ============================================================
    //  5. Game state (same logic as original space_impact)
    // ============================================================
    reg [7:0]  score;
    reg [1:0]  lives;
    reg        go;            // game over
    reg        player_row;    // 0=top lane, 1=bottom lane
    reg [3:0]  player_col;    // 0-15

    // Enemies: each has row (0/1), col (0-15), active flag
    reg [3:0]  e_col  [0:5];
    reg        e_row  [0:5];
    reg [5:0]  e_alive;

    // Bullets: row, col, active
    reg [3:0]  b_col  [0:2];
    reg        b_row  [0:2];
    reg [2:0]  b_alive;

    reg [4:0]  spawn_tmr;
    reg [5:0]  frame_tmr;
    reg        player_col_dir; // 0=left, 1=right (auto-scroll)

    always @(posedge clk) begin
        if (!rst_n) begin
            score <= 0; lives <= 3; go <= 0;
            player_row <= 1; player_col <= 3;
            player_col_dir <= 1;
            e_alive <= 0; b_alive <= 0;
            spawn_tmr <= 0; frame_tmr <= 0;
        end else if (t100ms) begin
            if (!go) begin
                // Player lane switch
                if (kup) player_row <= 0;
                if (kdn) player_row <= 1;

                // Auto-scroll player left/right across columns
                if (player_col_dir) begin
                    if (player_col == 15) player_col_dir <= 0;
                    else player_col <= player_col + 1;
                end else begin
                    if (player_col == 0) player_col_dir <= 1;
                    else player_col <= player_col - 1;
                end

                // Shoot
                if (ksh) begin
                    if      (!b_alive[0]) begin b_col[0] <= player_col; b_row[0] <= player_row; b_alive[0] <= 1; end
                    else if (!b_alive[1]) begin b_col[1] <= player_col; b_row[1] <= player_row; b_alive[1] <= 1; end
                    else if (!b_alive[2]) begin b_col[2] <= player_col; b_row[2] <= player_row; b_alive[2] <= 1; end
                end

                // Move bullets (row 0 = top of screen)
                if (b_alive[0]) begin if (b_row[0] == 0) b_alive[0] <= 0; else b_row[0] <= 0; end
                if (b_alive[1]) begin if (b_row[1] == 0) b_alive[1] <= 0; else b_row[1] <= 0; end
                if (b_alive[2]) begin if (b_row[2] == 0) b_alive[2] <= 0; else b_row[2] <= 0; end

                // Spawn enemies
                if (spawn_tmr == 0) begin
                    spawn_tmr <= 5'd6;
                    if      (!e_alive[0]) begin e_col[0] <= {1'b0, rng[3:1]} + 4; e_row[0] <= 0; e_alive[0] <= 1; end
                    else if (!e_alive[1]) begin e_col[1] <= {1'b0, rng[6:4]} + 4; e_row[1] <= 0; e_alive[1] <= 1; end
                    else if (!e_alive[2]) begin e_col[2] <= {1'b0, rng[9:7]} + 4; e_row[2] <= 0; e_alive[2] <= 1; end
                    else if (!e_alive[3]) begin e_col[3] <= {1'b0, rng[12:10]}+4; e_row[3] <= 0; e_alive[3] <= 1; end
                    else if (!e_alive[4]) begin e_col[4] <= {1'b0, rng[15:13]}+4; e_row[4] <= 0; e_alive[4] <= 1; end
                    else if (!e_alive[5]) begin e_col[5] <= {1'b0, rng[14:12]}+4; e_row[5] <= 0; e_alive[5] <= 1; end
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

                // Collision: bullet x enemy
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
                // Game over: press shoot to restart
                if (ksh) begin
                    score <= 0; lives <= 3; go <= 0;
                    player_row <= 1; player_col <= 3; player_col_dir <= 1;
                    e_alive <= 0; b_alive <= 0;
                end
            end
        end
    end

    // ============================================================
    //  6. VGA pixel rendering
    // ============================================================

    // Constants
    parameter LANE_TOP0 = 60;     // lane 0 starts at y=60
    parameter LANE_TOP1 = 260;    // lane 1 starts at y=260
    parameter LANE_H    = 200;    // each lane is 200px tall
    parameter COL_W     = 40;     // each column is 40px wide

    // Current cell coordinates
    wire [9:0] lane_top = (vcount < LANE_TOP1) ? LANE_TOP0 : LANE_TOP1;
    wire [3:0] col_idx  = hcount / COL_W;
    wire       lane_idx = (vcount >= LANE_TOP1);
    wire [9:0] cx       = hcount - col_idx * COL_W;   // pixel within cell (0..39)
    wire [9:0] cy       = vcount - lane_top;           // pixel within lane (0..199)

    // Lookup: what occupies this cell?
    wire cell_has_player = !go && (lane_idx == player_row && col_idx == player_col);
    wire cell_has_enemy  = |(e_alive[0] && lane_idx == e_row[0] && col_idx == e_col[0] ? 1'b1 :
                              e_alive[1] && lane_idx == e_row[1] && col_idx == e_col[1] ? 1'b1 :
                              e_alive[2] && lane_idx == e_row[2] && col_idx == e_col[2] ? 1'b1 :
                              e_alive[3] && lane_idx == e_row[3] && col_idx == e_col[3] ? 1'b1 :
                              e_alive[4] && lane_idx == e_row[4] && col_idx == e_col[4] ? 1'b1 :
                              e_alive[5] && lane_idx == e_row[5] && col_idx == e_col[5] ? 1'b1 : 1'b0);

    wire cell_has_bullet = |(b_alive[0] && lane_idx == b_row[0] && col_idx == b_col[0] ? 1'b1 :
                              b_alive[1] && lane_idx == b_row[1] && col_idx == b_col[1] ? 1'b1 :
                              b_alive[2] && lane_idx == b_row[2] && col_idx == b_col[2] ? 1'b1 : 1'b0);

    // ── Starfield (parallax-like, seeded by LFSR) ──
    wire [9:0] star_rand = {rng[7:0], hcount[1:0], vcount[2:0]};
    wire is_star = (star_rand[7:0] == 8'hA5 && vcount < 480 && hcount < 640);

    // ── Pixel color output ──
    reg [7:0] r_out, g_out, b_out;

    always @(*) begin
        // Default: dark space background
        r_out = 8'h00;
        g_out = 8'h00;
        b_out = 8'h14;   // very dark blue

        if (!blank_n || hcount >= 640 || vcount >= 480) begin
            // Outside visible area
            r_out = 0; g_out = 0; b_out = 0;

        end else if (go) begin
            // ── Game Over screen ──
            // Red flashing text area
            if (vcount >= 200 && vcount < 280 && hcount >= 200 && hcount < 440) begin
                r_out = 8'hFF; g_out = 8'h00; b_out = 8'h00;   // red banner
                // Text pixels: simple GAME OVER bars
                if (vcount >= 220 && vcount < 240 && hcount >= 240 && hcount < 400) begin
                    r_out = 8'h00; g_out = 8'h00; b_out = 8'h00;  // black text area
                    // Draw crude letters using horizontal bars
                    if (hcount >= 245 && hcount < 260) r_out = 8'hFF; // G bar
                    if (hcount >= 270 && hcount < 285) r_out = 8'hFF; // A bar
                    if (hcount >= 295 && hcount < 310) r_out = 8'hFF; // M bar
                    if (hcount >= 315 && hcount < 320) r_out = 8'hFF; // E bar
                    if (hcount >= 330 && hcount < 340) r_out = 8'hFF; // O bar
                    if (hcount >= 350 && hcount < 365) r_out = 8'hFF; // V bar
                    if (hcount >= 375 && hcount < 390) r_out = 8'hFF; // E bar
                    if (hcount >= 395 && hcount < 400) r_out = 8'hFF; // R bar
                end
            end
            // Score display on game over
            if (vcount >= 300 && vcount < 320 && hcount >= 240 && hcount < 400) begin
                r_out = 8'hFF; g_out = 8'hFF; b_out = 8'hFF; // white score text
            end

        end else begin
            // ── Game field ──
            if (vcount >= LANE_TOP0 && vcount < LANE_TOP0 + LANE_H &&
                hcount < 640) begin
                // ── Lane 0 ──
                if (cell_has_player)
                    // Player: green arrow shape
                    draw_player(cx, cy, r_out, g_out, b_out);
                else if (cell_has_enemy)
                    // Enemy: red alien shape
                    draw_enemy(cx, cy, r_out, g_out, b_out);
                else if (cell_has_bullet)
                    // Bullet: yellow line
                    draw_bullet(cx, cy, r_out, g_out, b_out);
                else begin
                    // Empty cell: dark with subtle grid lines
                    if (cx == 0 || cx == COL_W-1 || cy == 0 || cy == LANE_H-1) begin
                        r_out = 8'h22; g_out = 8'h22; b_out = 8'h44;  // grid line
                    end
                    // Random star in empty cells
                    if (is_star) begin
                        r_out = 8'h66; g_out = 8'h66; b_out = 8'h88;
                    end
                end

            end else if (vcount >= LANE_TOP1 && vcount < LANE_TOP1 + LANE_H &&
                         hcount < 640) begin
                // ── Lane 1 ──
                if (cell_has_player)
                    draw_player(cx, cy, r_out, g_out, b_out);
                else if (cell_has_enemy)
                    draw_enemy(cx, cy, r_out, g_out, b_out);
                else if (cell_has_bullet)
                    draw_bullet(cx, cy, r_out, g_out, b_out);
                else begin
                    if (cx == 0 || cx == COL_W-1 || cy == 0 || cy == LANE_H-1) begin
                        r_out = 8'h22; g_out = 8'h22; b_out = 8'h44;
                    end
                    if (is_star) begin
                        r_out = 8'h66; g_out = 8'h66; b_out = 8'h88;
                    end
                end

            // ── HUD: Score (top 60px) ──
            end else if (vcount < 60) begin
                if (vcount >= 10 && vcount < 50 && hcount >= 10 && hcount < 310) begin
                    // Score bar background
                    r_out = 8'h00; g_out = 8'h00; b_out = 8'h40;
                    // Score label area (left side)
                    if (hcount >= 20 && hcount < 100 && vcount >= 15 && vcount < 45) begin
                        // White bar
                        if (hcount >= 22 && hcount < 28) begin r_out = 8'hFF; g_out = 8'hFF; b_out = 8'hFF; end // S
                        if (hcount >= 30 && hcount < 36) begin r_out = 8'hFF; g_out = 8'hFF; b_out = 8'hFF; end // C
                        if (hcount >= 38 && hcount < 44) begin r_out = 8'hFF; g_out = 8'hFF; b_out = 8'hFF; end // O
                        if (hcount >= 46 && hcount < 52) begin r_out = 8'hFF; g_out = 8'hFF; b_out = 8'hFF; end // R
                        if (hcount >= 54 && hcount < 60) begin r_out = 8'hFF; g_out = 8'hFF; b_out = 8'hFF; end // E
                    end
                    // Score value (right of label)
                    if (hcount >= 120 && hcount < 300 && vcount >= 18 && vcount < 42) begin
                        r_out = 8'h00; g_out = 8'hFF; b_out = 8'h00; // green score digits
                    end
                end

            // ── Footer: Lives (bottom 20px) ──
            end else if (vcount >= 460) begin
                r_out = 8'h00; g_out = 8'h00; b_out = 8'h30;
                // Render hearts for lives
                if (hcount >= 20 && hcount < 100 && vcount >= 465) begin
                    r_out = 8'hFF; g_out = 8'h00; b_out = 8'h00; // red lives
                end
            end

            // ── Stars across whole screen ──
            if (is_star && !cell_has_player && !cell_has_enemy && !cell_has_bullet) begin
                if (r_out == 8'h00 && g_out == 8'h00) begin // only on background
                    r_out = 8'hAA; g_out = 8'hAA; b_out = 8'hCC;
                end
            end
        end
    end

    // ============================================================
    //  Sprite drawing functions
    // ============================================================

    // Player ship: green arrow/triangle shape
    task draw_player;
        input [9:0] cx, cy;
        inout [7:0] r, g, b;
        begin
            r = 8'h00; g = 8'h44; b = 8'h00; // dark green background
            // Central body
            if (cx >= 16 && cx <= 23 && cy >= 30 && cy <= 180) begin
                r = 8'h00; g = 8'hFF; b = 8'h00; // bright green body
            end
            // Nose cone (triangle pointing up)
            if (cy >= 15 && cy < 30 && cx >= 18 && cx <= 21) begin
                r = 8'h00; g = 8'hFF; b = 8'h00;
            end
            // Wings
            if (cy >= 100 && cy <= 160) begin
                if (cx >= 8 && cx < 16) begin r = 8'h00; g = 8'hCC; b = 8'h00; end // left wing
                if (cx > 23 && cx <= 31) begin r = 8'h00; g = 8'hCC; b = 8'h00; end // right wing
            end
            // Cockpit glow
            if (cy >= 50 && cy <= 70 && cx >= 18 && cx <= 21) begin
                r = 8'h44; g = 8'hFF; b = 8'hFF; // cyan cockpit
            end
            // Engine glow (bottom)
            if (cy >= 175 && cy <= 185 && cx >= 17 && cx <= 22) begin
                r = 8'hFF; g = 8'h88; b = 8'h00; // orange engine
            end
        end
    endtask

    // Enemy alien: red bug shape
    task draw_enemy;
        input [9:0] cx, cy;
        inout [7:0] r, g, b;
        begin
            r = 8'h44; g = 8'h00; b = 8'h00; // dark red background
            // Body
            if (cy >= 40 && cy <= 160 && cx >= 14 && cx <= 25) begin
                r = 8'hFF; g = 8'h00; b = 8'h00; // bright red body
            end
            // Head
            if (cy >= 20 && cy < 40 && cx >= 16 && cx <= 23) begin
                r = 8'hFF; g = 8'h00; b = 8'h00;
            end
            // Eyes
            if (cy >= 25 && cy <= 35) begin
                if (cx >= 17 && cx <= 19) begin r = 8'hFF; g = 8'hFF; b = 8'h00; end // left eye
                if (cx >= 20 && cx <= 22) begin r = 8'hFF; g = 8'hFF; b = 8'h00; end // right eye
            end
            // Legs
            if (cy >= 140 && cy <= 170) begin
                if (cx >= 8 && cx <= 13) begin r = 8'hCC; g = 8'h00; b = 8'h00; end // left legs
                if (cx >= 26 && cx <= 31) begin r = 8'hCC; g = 8'h00; b = 8'h00; end // right legs
            end
        end
    endtask

    // Bullet: yellow line
    task draw_bullet;
        input [9:0] cx, cy;
        inout [7:0] r, g, b;
        begin
            r = 8'h00; g = 8'h00; b = 8'h00; // black background
            // Vertical bright line
            if (cx >= 18 && cx <= 21 && cy >= 10 && cy <= 190) begin
                r = 8'hFF; g = 8'hFF; b = 8'h00; // yellow
            end
            // Glow effect
            if (cx >= 17 && cx <= 22 && cy >= 20 && cy <= 50) begin
                r = 8'hFF; g = 8'hFF; b = 8'h44; // brighter top
            end
        end
    endtask

    assign vga_r = (blank_n) ? r_out : 8'h00;
    assign vga_g = (blank_n) ? g_out : 8'h00;
    assign vga_b = (blank_n) ? b_out : 8'h00;

endmodule
