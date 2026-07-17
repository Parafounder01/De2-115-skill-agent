// ============================================================
//  snake_vga.v — DE2-115 Snake Game on VGA
//
//  Controls:
//    KEY3 = UP
//    KEY2 = DOWN
//    KEY1 = LEFT
//    KEY0 = RIGHT (tap) / EXIT (hold >1s)
//
//  Grid: 20 columns x 15 rows, 32px cells = 640x480
//  Max snake length: 32 segments
// ============================================================

module snake_vga (
    input  clk,         // 50 MHz (PIN_Y2)
    input  key3,        // UP   (PIN_R24)
    input  key2,        // DOWN (PIN_P21)
    input  key1,        // LEFT (PIN_M21)
    input  key0,        // RIGHT/EXIT (PIN_M23)

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
    //  0. Internal power-on reset
    // ============================================================
    reg [19:0] por_cnt;
    reg        por_rst;
    always @(posedge clk) begin
        if (por_cnt == 20'hFFFFF) begin por_rst <= 0; end
        else begin por_cnt <= por_cnt + 1; por_rst <= 1; end
    end
    wire rst_n = ~por_rst;

    // ============================================================
    //  1. Clocks
    // ============================================================
    reg clk25;
    always @(posedge clk) clk25 <= ~clk25;
    assign vga_clk = clk25;
    assign vga_sync_n = 1'b1;  // separate HSync/VSync

    // ============================================================
    //  2. VGA sync
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
    //  3. Timers: 10us, 1ms, 100ms
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
    //  4. Key debounce (all 4 keys)
    // ============================================================
    reg [19:0] db_tmr;
    reg [3:0]  ks, kd, kp;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin ks <= 4'hF; kd <= 4'hF; kp <= 4'hF; db_tmr <= 0; end
        else begin
            kp <= kd;
            ks[3] <= key3; ks[2] <= key2; ks[1] <= key1; ks[0] <= key0;
            if (ks != kd) begin
                if (db_tmr == 20'd500_000) begin kd <= ks; db_tmr <= 0; end
                else db_tmr <= db_tmr + 1;
            end else db_tmr <= 0;
        end
    end

    // Edge detects (falling edge = key pressed)
    wire kup = ~kd[3] && kp[3];  // UP
    wire kdn = ~kd[2] && kp[2];  // DOWN
    wire klt = ~kd[1] && kp[1];  // LEFT

    // KEY0: RIGHT (tap) / EXIT (hold >1s)
    reg [6:0]  k0_hold;       // 100ms ticks counted while held
    reg        k0_pending;    // monitoring in progress
    reg        k0_is_exit;    // already decided as long press
    reg        k0_right;      // RIGHT command (one-shot)
    reg        k0_exit;       // EXIT command (one-shot)

    always @(posedge clk) begin
        if (!rst_n) begin
            k0_hold <= 0; k0_pending <= 0; k0_is_exit <= 0;
            k0_right <= 0; k0_exit <= 0;
        end else if (t100ms) begin
            // Default: clear one-shot pulses
            k0_right <= 0;
            k0_exit  <= 0;

            if (~kd[0] && ~k0_pending) begin
                // KEY0 just pressed, start monitoring
                k0_pending <= 1;
                k0_hold <= 0;
                k0_is_exit <= 0;
            end else if (k0_pending) begin
                if (kd[0]) begin
                    // KEY0 released
                    k0_pending <= 0;
                    if (!k0_is_exit) k0_right <= 1;  // tap = RIGHT
                end else begin
                    // Still held
                    if (k0_hold >= 7'd10) begin  // 1 second
                        if (!k0_is_exit) begin
                            k0_is_exit <= 1;
                            k0_exit <= 1;  // EXIT command
                        end
                    end else begin
                        k0_hold <= k0_hold + 1;
                    end
                end
            end
        end else begin
            k0_right <= 0;  // clear outside t100ms
            k0_exit  <= 0;
        end
    end

    // ============================================================
    //  5. 16-bit LFSR for food placement
    // ============================================================
    reg [15:0] rng;
    always @(posedge clk) begin
        if (!rst_n) rng <= 16'hACE1;
        else rng <= {rng[14:0], rng[15] ^ rng[13] ^ rng[12] ^ rng[10]};
    end

    // ============================================================
    //  6. Game constants
    // ============================================================
    parameter COLS       = 20;
    parameter ROWS       = 15;
    parameter CELL_SIZE  = 32;
    parameter MAX_SNAKE  = 32;

    // Direction encoding
    parameter DIR_UP    = 2'd0;
    parameter DIR_DOWN  = 2'd1;
    parameter DIR_LEFT  = 2'd2;
    parameter DIR_RIGHT = 2'd3;

    // ============================================================
    //  7. Game state
    // ============================================================
    reg        playing;
    reg        game_over;
    reg [4:0]  snake_x [0:MAX_SNAKE-1];
    reg [3:0]  snake_y [0:MAX_SNAKE-1];
    reg [5:0]  snake_len;    // up to MAX_SNAKE
    reg [1:0]  snake_dir;    // current direction
    reg [1:0]  dir_buf;      // buffered direction change
    reg        dir_valid;    // buffer has valid input
    reg [4:0]  food_x;
    reg [3:0]  food_y;
    reg [5:0]  score;

    // Game tick: 200ms (divide 100ms by 2)
    reg game_tick;
    always @(posedge clk) begin
        if (t100ms) game_tick <= ~game_tick;
    end

    // New head position (combinatorial)
    wire [4:0] new_hx =
        (snake_dir == DIR_LEFT)  ? snake_x[0] - 1 :
        (snake_dir == DIR_RIGHT) ? snake_x[0] + 1 : snake_x[0];
    wire [3:0] new_hy =
        (snake_dir == DIR_UP)    ? snake_y[0] - 1 :
        (snake_dir == DIR_DOWN)  ? snake_y[0] + 1 : snake_y[0];

    // Wall collision
    wire wall_hit = (new_hx >= COLS || new_hy >= ROWS);

    // Self collision (skip head at index 0, check body at 1..len-1)
    reg  self_hit;
    integer si;
    always @(*) begin
        self_hit = 0;
        for (si = 1; si < MAX_SNAKE; si = si + 1) begin
            if (si < snake_len && snake_x[si] == new_hx && snake_y[si] == new_hy)
                self_hit = 1;
        end
    end

    // Food eaten
    wire food_eaten = ~wall_hit && ~self_hit &&
                      (new_hx == food_x && new_hy == food_y);

    // Game init flag (first frame after reset or exit)
    reg init_pending;
    always @(posedge clk) begin
        if (!rst_n || k0_exit) init_pending <= 1;
        else if (game_tick && init_pending) init_pending <= 0;
    end

    // ── Main game update + direction buffer ──
    integer gi;
    always @(posedge clk) begin
        // ── Direction buffer (on t100ms, only when playing) ──
        if (!rst_n || k0_exit) begin
            dir_buf   <= DIR_RIGHT;
            dir_valid <= 0;
        end else if (t100ms && playing && ~game_over) begin
            if      (kup   && snake_dir != DIR_DOWN)  begin dir_buf <= DIR_UP;   dir_valid <= 1; end
            else if (kdn   && snake_dir != DIR_UP)    begin dir_buf <= DIR_DOWN; dir_valid <= 1; end
            else if (klt   && snake_dir != DIR_RIGHT) begin dir_buf <= DIR_LEFT; dir_valid <= 1; end
            else if (k0_right && snake_dir != DIR_LEFT) begin dir_buf <= DIR_RIGHT; dir_valid <= 1; end
        end

        // ── Game state reset or update ──
        if (!rst_n || k0_exit) begin
            playing   <= 1;
            game_over <= 0;
            snake_len <= 6'd3;
            snake_dir <= DIR_RIGHT;
            score     <= 0;
            for (gi = 0; gi < 3; gi = gi + 1) begin
                snake_x[gi] <= 10 - gi;
                snake_y[gi] <= 7;
            end
            food_x <= 15; food_y <= 7;
        end else if (game_tick && playing && ~game_over) begin
            // Apply buffered direction (not reverse)
            if (dir_valid) begin
                case (dir_buf)
                    DIR_UP:    if (snake_dir != DIR_DOWN)  snake_dir <= DIR_UP;
                    DIR_DOWN:  if (snake_dir != DIR_UP)    snake_dir <= DIR_DOWN;
                    DIR_LEFT:  if (snake_dir != DIR_RIGHT) snake_dir <= DIR_LEFT;
                    DIR_RIGHT: if (snake_dir != DIR_LEFT)  snake_dir <= DIR_RIGHT;
                endcase
                dir_valid <= 0;
            end

            if (wall_hit || self_hit) begin
                playing   <= 0;
                game_over <= 1;
            end else begin
                for (gi = MAX_SNAKE-1; gi > 0; gi = gi - 1) begin
                    snake_x[gi] <= snake_x[gi-1];
                    snake_y[gi] <= snake_y[gi-1];
                end
                snake_x[0] <= new_hx;
                snake_y[0] <= new_hy;

                if (food_eaten) begin
                    snake_len <= snake_len + 1;
                    score     <= score + 1;
                    food_x <= {1'b0, rng[7:4]} % COLS;
                    food_y <= rng[11:8] % ROWS;
                end
            end
        end
    end

    // ============================================================
    //  8. VGA pixel rendering
    // ============================================================

    // Current grid cell
    wire [4:0] gx = hcount / CELL_SIZE;
    wire [3:0] gy = vcount / CELL_SIZE;
    wire in_grid = (gx < COLS && gy < ROWS);

    // Is this cell a snake segment? Is it the head?
    reg  px_snake, px_head;
    integer ri;
    always @(*) begin
        px_snake = 0;
        px_head  = 0;
        for (ri = 0; ri < MAX_SNAKE; ri = ri + 1) begin
            if (ri < snake_len && snake_x[ri] == gx && snake_y[ri] == gy) begin
                px_snake = 1;
                if (ri == 0) px_head = 1;
            end
        end
    end
    wire px_food  = ~px_snake && (gx == food_x && gy == food_y);

    // Pixel within cell
    wire [4:0] px = hcount - gx * CELL_SIZE;
    wire [4:0] py = vcount - gy * CELL_SIZE;

    // Colors
    reg [7:0] r_out, g_out, b_out;

    always @(*) begin
        r_out = 0; g_out = 0; b_out = 0;  // default black
        if (blank_n && hcount < 640 && vcount < 480) begin
            if (game_over) begin
                // ── Game Over overlay ──
                r_out = 8'h00; g_out = 8'h00; b_out = 8'h00;
                if (vcount >= 180 && vcount < 300 && hcount >= 160 && hcount < 480) begin
                    r_out = 8'h44; g_out = 8'h00; b_out = 8'h00;  // dark red banner
                    // "GAME OVER" bar
                    if (vcount >= 200 && vcount < 230 && hcount >= 200 && hcount < 440) begin
                        r_out = 8'hFF; g_out = 8'h00; b_out = 8'h00;  // red text
                    end
                    // Score line
                    if (vcount >= 245 && vcount < 265 && hcount >= 240 && hcount < 400) begin
                        r_out = 8'hFF; g_out = 8'hFF; b_out = 8'hFF;  // white score
                    end
                end

            end else begin
                // ── Game field ──
                if (in_grid) begin
                    // Background: dark green gradient based on position
                    r_out = 8'h00;
                    g_out = {4'h0, gx[3:0]} + {4'h0, gy[3:0]} + 8'h10;
                    b_out = 8'h08;

                    // Grid line (subtle)
                    if (px == 0 || py == 0) begin
                        r_out = 8'h00; g_out = 8'h22; b_out = 8'h00;
                    end

                    // Snake body (with segment index variation)
                    if (px_snake && ~px_head) begin
                        r_out = 8'h00;
                        g_out = 8'h88 + {4'h0, ri[3:0]};  // gradient
                        b_out = 8'h00;
                        // Body border (slightly darker)
                        if (px == 0 || px == CELL_SIZE-1 || py == 0 || py == CELL_SIZE-1) begin
                            g_out = 8'h44;
                        end
                        // Eyes on first body segment
                        if (ri == 1 && py >= 12 && py <= 18 && (px == 8 || px == 23)) begin
                            r_out = 8'hFF; g_out = 8'hFF; b_out = 8'h00;  // yellow eyes
                        end
                    end

                    // Snake head
                    if (px_head) begin
                        r_out = 8'h00; g_out = 8'hFF; b_out = 8'h44;  // bright green
                        // Head outline
                        if (px <= 1 || px >= CELL_SIZE-2 || py <= 1 || py >= CELL_SIZE-2) begin
                            r_out = 8'h00; g_out = 8'h88; b_out = 8'h00;
                        end
                        // Eyes
                        if (((px >= 6 && px <= 10) || (px >= 21 && px <= 25)) &&
                            (py >= 6 && py <= 12)) begin
                            r_out = 8'hFF; g_out = 8'hFF; b_out = 8'hFF;  // white eyes
                            // Pupils
                            if ((px >= 7 && px <= 9) || (px >= 22 && px <= 24)) begin
                                if (py >= 7 && py <= 11) begin
                                    r_out = 8'h00; g_out = 8'h00; b_out = 8'h00;  // black pupils
                                end
                            end
                        end
                        // Tongue (small red line)
                        if (snake_dir == DIR_RIGHT && px >= 28 && px <= 30 && py >= 14 && py <= 17) begin
                            r_out = 8'hFF; g_out = 8'h00; b_out = 8'h00;
                        end
                        if (snake_dir == DIR_LEFT && px >= 1 && px <= 3 && py >= 14 && py <= 17) begin
                            r_out = 8'hFF; g_out = 8'h00; b_out = 8'h00;
                        end
                        if (snake_dir == DIR_UP && px >= 14 && px <= 17 && py >= 1 && py <= 3) begin
                            r_out = 8'hFF; g_out = 8'h00; b_out = 8'h00;
                        end
                        if (snake_dir == DIR_DOWN && px >= 14 && px <= 17 && py >= 28 && py <= 30) begin
                            r_out = 8'hFF; g_out = 8'h00; b_out = 8'h00;
                        end
                    end

                    // Food
                    if (px_food) begin
                        r_out = 8'hFF; g_out = 8'h00; b_out = 8'h00;  // red
                        // Apple shape
                        if (py < 6 || py > 25 || px < 6 || px > 25) begin
                            r_out = 8'h00; g_out = 8'h00; b_out = 8'h00;  // dark outside apple
                        end
                        // Stem
                        if (px >= 14 && px <= 17 && py >= 2 && py <= 7) begin
                            r_out = 8'h44; g_out = 8'h22; b_out = 8'h00;  // brown stem
                        end
                        // Shine
                        if (px >= 8 && px <= 14 && py >= 8 && py <= 14) begin
                            r_out = 8'hFF; g_out = 8'h66; b_out = 8'h66;  // lighter red
                        end
                    end

                end else begin
                    // Border area (outside grid)
                    r_out = 8'h00; g_out = 8'h00; b_out = 8'h10;
                end

                // ── HUD (top bar) ──
                if (vcount < 32 && hcount < 640) begin
                    r_out = 8'h00; g_out = 8'h00; b_out = 8'h20;  // dark blue bar
                    // Score text: "SCORE: XX"
                    if (vcount >= 8 && vcount < 24 && hcount >= 8 && hcount < 200) begin
                        r_out = 8'h00; g_out = 8'hFF; b_out = 8'h00;  // green text
                    end
                    // Score value
                    if (vcount >= 8 && vcount < 24 && hcount >= 200 && hcount < 280) begin
                        r_out = 8'hFF; g_out = 8'hFF; b_out = 8'h00;  // yellow score
                    end
                    // "SNAKE" title on right
                    if (vcount >= 6 && vcount < 26 && hcount >= 440 && hcount < 630) begin
                        r_out = 8'h00; g_out = 8'h44; b_out = 8'h00;  // dark green title
                    end
                end
            end
        end
    end

    assign vga_r = (blank_n) ? r_out : 8'h00;
    assign vga_g = (blank_n) ? g_out : 8'h00;
    assign vga_b = (blank_n) ? b_out : 8'h00;

endmodule
