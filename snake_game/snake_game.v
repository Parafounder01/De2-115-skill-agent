// ============================================================
//  snake_game.v — Complete Nokia Snake Game
//
//  Features:
//    Start screen, KEY0 to start
//    KEY1=UP, KEY2=DOWN, KEY3=LEFT, SW0=RIGHT
//    Food at random positions, snake grows, score increases
//    Speed increases every 5 food
//    Wall/self collision = Game Over
//    Pause (SW5), Win at configurable length
//    Difficulty levels via SW[2:1]
//    20×20 pixel cells, 32×24 grid
//    Blinking food, Game Over / Win animations
// ============================================================

module snake_game (
    input clk,              // 50 MHz
    input rst_n,            // global reset (KEY0)
    input key1, key2, key3, // UP, DOWN, LEFT
    input sw0,              // RIGHT
    input [2:1] sw_diff,    // difficulty
    input [4:3] sw_win,     // win length select
    input sw5_pause,        // pause

    output [7:0] vga_r, vga_g, vga_b,
    output vga_hs, vga_vs, vga_clk, vga_blank_n, vga_sync_n,

    output [6:0] hex7, hex6, hex5, hex4,
                  hex3, hex2, hex1, hex0,
    output [17:0] ledr,
    output [8:0]  ledg
);

    // ============================================================
    //  0. Parameters
    // ============================================================
    parameter CELL      = 6'd20;   // 20×20 pixel cells
    parameter COLS      = 5'd32;   // 32 columns
    parameter ROWS      = 5'd24;   // 24 rows
    parameter MAX_SNAKE = 7'd100;  // max segments

    parameter ST_RESET = 3'd0;
    parameter ST_START = 3'd1;
    parameter ST_PLAY  = 3'd2;
    parameter ST_PAUSE = 3'd3;
    parameter ST_GOVER = 3'd4;
    parameter ST_WIN   = 3'd5;

    parameter DIR_UP    = 2'd0;
    parameter DIR_DOWN  = 2'd1;
    parameter DIR_LEFT  = 2'd2;
    parameter DIR_RIGHT = 2'd3;

    // ============================================================
    //  1. Power-on reset
    // ============================================================
    reg [19:0] por_cnt;
    reg        por_rst;
    always @(posedge clk) begin
        if (por_cnt == 20'hFFFFF) por_rst <= 0;
        else begin por_cnt <= por_cnt + 1; por_rst <= 1; end
    end
    wire pwr_up = ~por_rst;
    wire reset = ~rst_n;

    // ============================================================
    //  2. 25 MHz pixel clock
    // ============================================================
    reg clk25;
    always @(posedge clk) clk25 <= ~clk25;
    assign vga_clk    = clk25;
    assign vga_sync_n = 1'b1;

    // ============================================================
    //  3. VGA controller
    // ============================================================
    wire hs, vs, blank;
    wire [9:0] vx, vy;

    vga_controller vga (
        .clk25   (clk25),
        .rst_n   (pwr_up),
        .hsync   (hs),
        .vsync   (vs),
        .blank_n (blank),
        .x       (vx),
        .y       (vy)
    );
    assign vga_hs = hs;
    assign vga_vs = vs;
    assign vga_blank_n = blank;

    // ============================================================
    //  4. Timers: 10us, 1ms, 100ms
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

    // 250ms tick for blink/animation
    reg blink_tick;
    always @(posedge clk) begin
        if (t100ms) begin
            if (blink_tick == 1'b1) blink_tick <= 0; else blink_tick <= 1;
        end
    end
    reg [2:0] anim_cnt;
    always @(posedge clk) begin
        if (t100ms) begin
            if (blink_tick) anim_cnt <= anim_cnt + 1;
        end
    end

    // ============================================================
    //  5. KEY0 edge detect (start/reset)
    // ============================================================
    reg [19:0] k0_db;
    reg k0_s, k0_stable, k0_prev;
    wire k0_press;
    always @(posedge clk) begin
        if (!pwr_up) begin k0_s <= 1; k0_stable <= 1; k0_prev <= 1; k0_db <= 0; end
        else begin
            k0_prev <= k0_stable; k0_s <= rst_n;
            if (k0_s != k0_stable) begin
                if (k0_db == 20'd500_000) begin k0_stable <= k0_s; k0_db <= 0; end
                else k0_db <= k0_db + 1;
            end else k0_db <= 0;
        end
    end
    assign k0_press = ~k0_stable & k0_prev;

    // ============================================================
    //  6. Key debounce for direction keys
    // ============================================================
    wire k1_lvl, k2_lvl, k3_lvl;
    wire k1_fe, k2_fe, k3_fe;

    debounce db_k1 (.clk(clk), .rst_n(pwr_up), .raw(key1), .level(k1_lvl), .falling_edge(k1_fe), .rising_edge());
    debounce db_k2 (.clk(clk), .rst_n(pwr_up), .raw(key2), .level(k2_lvl), .falling_edge(k2_fe), .rising_edge());
    debounce db_k3 (.clk(clk), .rst_n(pwr_up), .raw(key3), .level(k3_lvl), .falling_edge(k3_fe), .rising_edge());

    // SW0 debounce (active-high switch)
    wire sw0_lvl, sw0_fe;
    debounce db_sw0 (.clk(clk), .rst_n(pwr_up), .raw(~sw0), .level(sw0_lvl), .falling_edge(sw0_fe), .rising_edge());

    // ============================================================
    //  7. LFSR pseudo-random
    // ============================================================
    reg [15:0] rng;
    always @(posedge clk) begin
        if (!pwr_up) rng <= 16'hACE1;
        else rng <= {rng[14:0], rng[15] ^ rng[13] ^ rng[12] ^ rng[10]};
    end

    // ============================================================
    //  8. Game state & snake data
    // ============================================================
    reg [2:0] state;
    reg [4:0] snake_x [0:MAX_SNAKE-1];  // 0..31
    reg [4:0] snake_y [0:MAX_SNAKE-1];  // 0..23
    reg [6:0] snake_len;
    reg [1:0] snake_dir;
    reg [1:0] dir_buf;
    reg       dir_valid;
    reg [4:0] food_x;
    reg [4:0] food_y;
    reg [7:0] score;
    reg [5:0] food_eaten_count;
    reg [5:0] tick_period;              // in 100ms units
    reg [5:0] tick_acc;
    reg       game_tick;

    // Speed config from difficulty
    reg [5:0] base_period;
    always @(*) begin
        case (sw_diff)
            2'b00: base_period = 6'd4;  // 400ms
            2'b01: base_period = 6'd3;  // 300ms
            2'b10: base_period = 6'd2;  // 200ms
            2'b11: base_period = 6'd1;  // 100ms
        endcase
    end

    // Win length config
    reg [6:0] win_len;
    always @(*) begin
        case (sw_win)
            2'b00: win_len = 7'd30;
            2'b01: win_len = 7'd40;
            2'b10: win_len = 7'd50;
            2'b11: win_len = 7'd60;
        endcase
    end

    // New head position
    wire [4:0] new_hx =
        (snake_dir == DIR_LEFT)  ? (snake_x[0] == 0 ? 0 : snake_x[0] - 1) :
        (snake_dir == DIR_RIGHT) ? (snake_x[0] == 31 ? 31 : snake_x[0] + 1) : snake_x[0];
    wire [4:0] new_hy =
        (snake_dir == DIR_UP)    ? (snake_y[0] == 0 ? 0 : snake_y[0] - 1) :
        (snake_dir == DIR_DOWN)  ? (snake_y[0] == 23 ? 23 : snake_y[0] + 1) : snake_y[0];

    // Wall collision
    wire wall_hit =
        (snake_dir == DIR_LEFT  && snake_x[0] == 0) ||
        (snake_dir == DIR_RIGHT && snake_x[0] == 31) ||
        (snake_dir == DIR_UP    && snake_y[0] == 0) ||
        (snake_dir == DIR_DOWN  && snake_y[0] == 23);

    // Self collision
    reg self_hit;
    integer si;
    always @(*) begin
        self_hit = 0;
        for (si = 1; si < MAX_SNAKE; si = si + 1) begin
            if (si < snake_len &&
                snake_x[si] == new_hx && snake_y[si] == new_hy)
                self_hit = 1;
        end
    end

    // Food eaten
    wire food_eaten = (new_hx == food_x && new_hy == food_y);

    // ============================================================
    //  9. Main game update
    // ============================================================
    integer gi;
    integer ri;
    always @(posedge clk) begin
        if (!pwr_up || reset) begin
            state <= ST_RESET;
            snake_dir <= DIR_RIGHT;
            dir_buf <= DIR_RIGHT; dir_valid <= 0;
            score <= 0; food_eaten_count <= 0;
            tick_period <= base_period; tick_acc <= 0;
            game_tick <= 0;
            snake_len <= 7'd3;
            snake_x[0] <= 15; snake_y[0] <= 12;
            snake_x[1] <= 14; snake_y[1] <= 12;
            snake_x[2] <= 13; snake_y[2] <= 12;
            food_x <= 20; food_y <= 12;
        end else begin

            // ── Tick counter (runs in all states) ──
            if (t100ms) begin
                if (state == ST_PLAY) begin
                    if (tick_acc >= tick_period - 1) begin
                        tick_acc <= 0;
                        game_tick <= 1;
                    end else begin
                        tick_acc <= tick_acc + 1;
                        game_tick <= 0;
                    end
                end else begin
                    tick_acc <= 0;
                    game_tick <= 0;
                end
            end else begin
                game_tick <= 0;
            end

            // ── State machine ──
            case (state)

            ST_RESET: begin
                state <= ST_START;
            end

            ST_START: begin
                if (k0_press) begin
                    state <= ST_PLAY;
                    score <= 0; food_eaten_count <= 0;
                    tick_period <= base_period; tick_acc <= 0;
                    game_tick <= 1;  // first move immediately
                    snake_len <= 7'd3;
                    snake_x[0] <= 15; snake_y[0] <= 12;
                    snake_x[1] <= 14; snake_y[1] <= 12;
                    snake_x[2] <= 13; snake_y[2] <= 12;
                    snake_dir <= DIR_RIGHT;
                    dir_buf <= DIR_RIGHT; dir_valid <= 0;
                    // Random food
                    food_x <= rng[4:0] % 32;
                    food_y <= rng[9:5] % 24;
                end
            end

            ST_PLAY: begin
                // Direction buffer (on t100ms)
                if (t100ms) begin
                    if (k1_fe && snake_dir != DIR_DOWN) begin dir_buf <= DIR_UP;    dir_valid <= 1; end
                    else if (k2_fe && snake_dir != DIR_UP) begin dir_buf <= DIR_DOWN;  dir_valid <= 1; end
                    else if (k3_fe && snake_dir != DIR_RIGHT) begin dir_buf <= DIR_LEFT;  dir_valid <= 1; end
                    else if (sw0_fe && snake_dir != DIR_LEFT) begin dir_buf <= DIR_RIGHT; dir_valid <= 1; end
                end

                // Pause check
                if (sw5_pause) state <= ST_PAUSE;

                // Snake movement
                if (game_tick) begin
                    // Apply buffered direction
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
                        state <= ST_GOVER;
                    end else begin
                        // Shift body
                        for (gi = MAX_SNAKE-1; gi > 0; gi = gi - 1) begin
                            snake_x[gi] <= snake_x[gi-1];
                            snake_y[gi] <= snake_y[gi-1];
                        end
                        snake_x[0] <= new_hx;
                        snake_y[0] <= new_hy;

                        if (food_eaten) begin
                            snake_len <= snake_len + 1;
                            score <= score + 10;
                            food_eaten_count <= food_eaten_count + 1;

                            // Speed increase every 5 food
                            if (food_eaten_count == 5 || food_eaten_count == 10 ||
                                food_eaten_count == 15 || food_eaten_count == 20) begin
                                if (tick_period > 1) tick_period <= tick_period - 1;
                            end

                            // New food
                            food_x <= rng[4:0] % 32;
                            food_y <= rng[9:5] % 24;

                            // Win check
                            if (snake_len + 1 >= win_len) begin
                                state <= ST_WIN;
                            end
                        end
                        // Wall was checked before move, so we're safe
                    end
                end
            end

            ST_PAUSE: begin
                if (!sw5_pause) state <= ST_PLAY;
            end

            ST_GOVER: begin
                // Wait for KEY0 to restart
                if (k0_press) state <= ST_RESET;
            end

            ST_WIN: begin
                if (k0_press) state <= ST_RESET;
            end

        endcase
        end  // end of else
    end  // end of always @(posedge clk)

    // ============================================================
    //  10. VGA pixel rendering
    // ============================================================

    // Cell coordinates
    wire [4:0] cx = vx / CELL;
    wire [4:0] cy = vy / CELL;
    wire in_grid = (cx < COLS && cy < ROWS);

    // Snake/food detection
    reg  px_snake, px_head, px_food;
    always @(*) begin
        px_snake = 0; px_head = 0; px_food = 0;
        for (ri = 0; ri < MAX_SNAKE; ri = ri + 1) begin
            if (ri < snake_len && snake_x[ri] == cx && snake_y[ri] == cy) begin
                px_snake = 1;
                if (ri == 0) px_head = 1;
            end
        end
        if (!px_snake && cx == food_x && cy == food_y) px_food = 1;
    end

    // Pixel within cell
    wire [4:0] px = vx - cx * CELL;
    wire [4:0] py = vy - cy * CELL;

    // Food blink: toggle at 500ms (every other 250ms tick)
    wire food_on = (anim_cnt[1] == 0);  // toggles every 500ms

    // Colors
    reg [7:0] r, g, b;

    always @(*) begin
        r = 0; g = 0; b = 0;
        if (blank && vx < 640 && vy < 480) begin

            case (state)

                // ============================================
                //  START screen
                // ============================================
                ST_RESET, ST_START: begin
                    r = 0; g = 0; b = 0;

                    // "SNAKE" text (crude pixel letters centered)
                    if (vy >= 100 && vy < 130 && vx >= 180 && vx < 460) begin
                        // Row offsets within the text block: 0-29
                        // Each char ~30px wide, 30px tall, 8 chars
                        // "  SNAKE  " = 8 chars × 30px = 240px, centered at 640/2=320, so start = 200
                        // Actually, let me make it simpler with a pixel range approach:

                        // "S" block
                        if (vx >= 200 && vx < 230) begin
                            if (vy < 110 || vy >= 120) r = 8'h00; g = 8'hFF; b = 8'h00; // green "S"
                        end
                        // "N" block
                        if (vx >= 240 && vx < 270) begin
                            if (vx < 250 || (vx >= 260 && vy < 120) || (vx >= 250 && vx < 260)) begin
                                r = 8'h00; g = 8'hFF; b = 8'h00;
                            end
                        end
                        // "A" block
                        if (vx >= 280 && vx < 310) begin
                            if (vy < 115 || vx < 285 || vx >= 305) begin
                                r = 8'h00; g = 8'hFF; b = 8'h00;
                            end
                        end
                        // "K" block
                        if (vx >= 320 && vx < 350) begin
                            if (vx < 325 || (vx >= 335 && vy < 115) || (vx >= 325 && vx < 335 && vy >= 115)) begin
                                r = 8'h00; g = 8'hFF; b = 8'h00;
                            end
                        end
                        // "E" block
                        if (vx >= 360 && vx < 390) begin
                            if (vy < 110 || vx < 365 || vy >= 120) begin
                                r = 8'h00; g = 8'hFF; b = 8'h00;
                            end
                        end
                        // "2" block (representing classic version)
                        if (vx >= 400 && vx < 430) begin
                            if (vy < 110 || (vy >= 110 && vy < 120 && vx >= 420) || (vy >= 120 && vx < 405)) begin
                                r = 8'h00; g = 8'hFF; b = 8'h00;
                            end
                        end
                    end

                    // "Press KEY0" instruction
                    if (vy >= 200 && vy < 215 && vx >= 240 && vx < 400) begin
                        // Simple text: white pixel blocks
                        // "P" at x=240
                        if (vx >= 242 && vx < 248) begin r = 8'hFF; g = 8'hFF; b = 8'hFF; end
                        if (vx >= 250 && vx < 256 && vy < 208) begin r = 8'hFF; g = 8'hFF; b = 8'hFF; end
                        // "r" at x=258
                        if (vx >= 260 && vx < 264 && vy < 208) begin r = 8'hFF; g = 8'hFF; b = 8'hFF; end
                        // "e" at x=266  
                        if (vx >= 268 && vx < 274) begin r = 8'hFF; g = 8'hFF; b = 8'hFF; end
                        // "s" at x=276
                        if (vx >= 278 && vx < 284 && vy < 208) begin r = 8'hFF; g = 8'hFF; b = 8'hFF; end
                        // "s" at x=286
                        if (vx >= 288 && vx < 294 && vy < 208) begin r = 8'hFF; g = 8'hFF; b = 8'hFF; end
                        // space
                        // "K" at x=300
                        if (vx >= 300 && vx < 304) begin r = 8'hFF; g = 8'hFF; b = 8'hFF; end
                        if (vx >= 306 && vx < 310 && vy < 208) begin r = 8'hFF; g = 8'hFF; b = 8'hFF; end
                        // "E" at x=312
                        if (vx >= 312 && vx < 318) begin r = 8'hFF; g = 8'hFF; b = 8'hFF; end
                        // "Y" at x=320
                        if (vx >= 320 && vx < 326) begin
                            if (vy < 208 || vx >= 323) begin r = 8'hFF; g = 8'hFF; b = 8'hFF; end
                        end
                        // "0" at x=330
                        if (vx >= 330 && vx < 336) begin
                            if (vy < 207 || vy >= 213 || vx < 332 || vx >= 334) begin
                                r = 8'hFF; g = 8'hFF; b = 8'hFF;
                            end
                        end
                    end

                    // Controls hint
                    if (vy >= 300 && vy < 320 && vx >= 160 && vx < 480) begin
                        r = 8'h44; g = 8'h44; b = 8'h44; // dim text area
                    end
                end

                // ============================================
                //  PLAY / PAUSE state
                // ============================================
                ST_PLAY, ST_PAUSE: begin
                    if (in_grid) begin
                        // Background: dark
                        r = 8'h00; g = 8'h0C; b = 8'h02;

                        // Subtle grid lines
                        if (px == 0 || py == 0) begin
                            r = 8'h00; g = 8'h18; b = 8'h00;
                        end

                        // Snake body
                        if (px_snake && ~px_head) begin
                            r = 8'h00; g = 8'h88; b = 8'h00;
                            if (px <= 1 || px >= CELL-2 || py <= 1 || py >= CELL-2)
                                g = 8'h44;
                        end

                        // Snake head
                        if (px_head) begin
                            r = 8'h20; g = 8'hFF; b = 8'h20;  // bright green
                            if (px <= 1 || px >= CELL-2 || py <= 1 || py >= CELL-2) begin
                                r = 8'h00; g = 8'h66; b = 8'h00;
                            end
                            // Eyes
                            if ((px >= 5 && px <= 8) && (py >= 5 && py <= 8)) begin
                                r = 8'hFF; g = 8'hFF; b = 8'hFF;
                            end
                            if ((px >= 12 && px <= 15) && (py >= 5 && py <= 8)) begin
                                r = 8'hFF; g = 8'hFF; b = 8'hFF;
                            end
                        end

                        // Food blinking
                        if (px_food && food_on) begin
                            r = 8'hFF; g = 8'h10; b = 8'h10;  // red apple
                            // Apple shape (circle approximation)
                            if (px < 3 || px > 16 || py < 3 || py > 16) begin
                                r = 8'h00; g = 8'h0C; b = 8'h02;  // bg color
                            end
                            // Shine
                            if (px >= 5 && px <= 9 && py >= 4 && py <= 7) begin
                                r = 8'hFF; g = 8'h88; b = 8'h88;
                            end
                        end

                        // Pause overlay
                        if (state == ST_PAUSE) begin
                            // Dark overlay
                            if (vy >= 200 && vy < 280 && vx >= 260 && vx < 380) begin
                                r = 8'h00; g = 8'h00; b = 8'h00;
                                // "PAUSED"
                                if (vy >= 210 && vy < 230 && vx >= 275 && vx < 365) begin
                                    r = 8'hFF; g = 8'hFF; b = 8'h00;
                                end
                            end
                        end
                    end
                end

                // ============================================
                //  GAME OVER state
                // ============================================
                ST_GOVER: begin
                    // Frozen game background
                    if (in_grid) begin
                        r = 8'h00; g = 8'h0C; b = 8'h02;
                        if (px_snake && ~px_head) begin r = 8'h00; g = 8'h88; b = 8'h00; end
                        if (px_head) begin r = 8'h20; g = 8'hFF; b = 8'h20; end
                        if (px_food && food_on) begin r = 8'hFF; g = 8'h10; b = 8'h10; end
                    end

                    // Flashing red overlay (first 3 blinks = 1.5s)
                    if (anim_cnt < 6 && anim_cnt[0] == 0) begin
                        // Red overlay
                        if (vx < 640 && vy < 480) begin
                            r = 8'h44; g = 8'h00; b = 8'h00;
                            // "GAME OVER" text
                            if (vy >= 200 && vy < 230 && vx >= 220 && vx < 420) begin
                                r = 8'hFF; g = 8'h00; b = 8'h00;
                            end
                        end
                    end else if (anim_cnt >= 6) begin
                        // Dark overlay with text
                        if (vy >= 180 && vy < 300 && vx >= 200 && vx < 440) begin
                            r = 8'h00; g = 8'h00; b = 8'h00;
                            if (vy >= 205 && vy < 230 && vx >= 230 && vx < 410) begin
                                r = 8'hFF; g = 8'h00; b = 8'h00;
                            end
                            // Score
                            if (vy >= 245 && vy < 265 && vx >= 250 && vx < 390) begin
                                r = 8'hFF; g = 8'hFF; b = 8'hFF;
                            end
                        end
                    end
                end

                // ============================================
                //  WIN state
                // ============================================
                ST_WIN: begin
                    if (in_grid) begin
                        r = 8'h00; g = 8'h0C; b = 8'h02;
                        if (px_snake && ~px_head) begin r = 8'h00; g = 8'h88; b = 8'h00; end
                        if (px_head) begin r = 8'h20; g = 8'hFF; b = 8'h20; end
                    end

                    // Flashing green overlay
                    if (anim_cnt < 6 && anim_cnt[0] == 0) begin
                        if (vx < 640 && vy < 480) begin
                            r = 8'h00; g = 8'h44; b = 8'h00;
                            if (vy >= 200 && vy < 230 && vx >= 240 && vx < 400) begin
                                r = 8'h00; g = 8'hFF; b = 8'h00;
                            end
                        end
                    end else if (anim_cnt >= 6) begin
                        if (vy >= 180 && vy < 300 && vx >= 200 && vx < 440) begin
                            r = 8'h00; g = 8'h00; b = 8'h00;
                            if (vy >= 205 && vy < 230 && vx >= 250 && vx < 390) begin
                                r = 8'h00; g = 8'hFF; b = 8'h00;
                            end
                            if (vy >= 245 && vy < 265 && vx >= 250 && vx < 390) begin
                                r = 8'hFF; g = 8'hFF; b = 8'hFF;
                            end
                        end
                    end
                end

                default: begin r = 0; g = 0; b = 0; end
            endcase
        end
    end

    assign vga_r = (blank) ? r : 8'h00;
    assign vga_g = (blank) ? g : 8'h00;
    assign vga_b = (blank) ? b : 8'h00;

    // ============================================================
    //  11. Seven-segment score display
    // ============================================================
    wire [6:0] seg [0:7];
    seven_segment s7 (.bcd(score / 100),          .seg(seg[7]));
    seven_segment s6 (.bcd((score / 10) % 10),    .seg(seg[6]));
    seven_segment s5 (.bcd(score % 10),           .seg(seg[5]));
    seven_segment s4 (.bcd(4'd0),                 .seg(seg[4]));
    seven_segment s3 (.bcd(snake_len / 10),       .seg(seg[3]));
    seven_segment s2 (.bcd(snake_len % 10),       .seg(seg[2]));
    seven_segment s1 (.bcd({1'b0, state}),        .seg(seg[1]));
    seven_segment s0 (.bcd(food_eaten_count / 10), .seg(seg[0]));

    assign hex7 = seg[7];
    assign hex6 = seg[6];
    assign hex5 = seg[5];
    assign hex4 = seg[4];
    assign hex3 = seg[3];
    assign hex2 = seg[2];
    assign hex1 = seg[1];
    assign hex0 = seg[0];

    // ============================================================
    //  12. LEDs
    // ============================================================
    assign ledr[0]  = sw0;
    assign ledr[1]  = sw5_pause;
    assign ledr[2]  = sw_diff[1];
    assign ledr[3]  = sw_diff[2];
    assign ledr[4]  = sw_win[3];
    assign ledr[5]  = sw_win[4];
    assign ledr[17:6] = 12'b0;

    assign ledg[0]  = ~k1_lvl;  // UP key pressed
    assign ledg[1]  = ~k2_lvl;  // DOWN key pressed
    assign ledg[2]  = ~k3_lvl;  // LEFT key pressed
    assign ledg[3]  = (state == ST_PLAY);
    assign ledg[4]  = (state == ST_PAUSE);
    assign ledg[5]  = (state == ST_GOVER);
    assign ledg[6]  = (state == ST_WIN);
    assign ledg[8:7] = 2'b0;

endmodule
