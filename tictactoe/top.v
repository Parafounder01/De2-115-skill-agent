// ============================================================
//  top.v — DE2-115 Top-level for Tic-Tac-Toe with AI
//
//  Controls:
//    KEY[0]=UP, KEY[1]=DOWN, KEY[2]=LEFT, KEY[3]=RIGHT
//    SW[0]=Place X, SW[1]=Restart
//    SW[2]=Easy AI, SW[3]=Hard AI (both off = Medium)
//
//  Display:
//    VGA 640×480@60Hz, 7-segment HEX for scores
//    LEDR[0]=game_active, LEDR[1]=player_turn
//    LEDR[4:2]=result_code
// ============================================================

module top (
    input  CLOCK_50,
    input  [3:0] KEY,
    input  [17:0] SW,

    output [7:0] VGA_R, VGA_G, VGA_B,
    output       VGA_HS, VGA_VS, VGA_CLK,
    output       VGA_BLANK_N, VGA_SYNC_N,

    output [6:0] HEX7, HEX6, HEX5, HEX4,
                 HEX3, HEX2, HEX1, HEX0,
    output [17:0] LEDR,
    output [8:0]  LEDG
);

    // ============================================================
    //  Power-on reset
    // ============================================================
    reg [19:0] por_cnt;
    reg        por_n;
    always @(posedge CLOCK_50) begin
        if (por_cnt == 20'hFFFFF) begin por_n <= 1; end
        else begin por_cnt <= por_cnt + 1; por_n <= 0; end
    end

    // ============================================================
    //  Clock divider: 25 MHz pixel clock + system ticks
    // ============================================================
    wire clk_25, tick_1khz, tick_100hz;
    clock_divider u_clk (
        .clk_50(CLOCK_50), .clk_25(clk_25), .tick_1khz(tick_1khz), .tick_100hz(tick_100hz)
    );

    // ============================================================
    //  VGA controller
    // ============================================================
    wire hs, vs, blank;
    wire [9:0] vx, vy;
    vga_controller u_vga (
        .clk_25(clk_25), .rst_n(por_n),
        .hsync(hs), .vsync(vs), .blank_n(blank), .x(vx), .y(vy)
    );
    assign VGA_HS = hs;
    assign VGA_VS = vs;
    assign VGA_CLK = clk_25;
    assign VGA_BLANK_N = blank;
    assign VGA_SYNC_N = 1'b1;

    // ============================================================
    //  Debounced inputs
    // ============================================================
    wire k_up_lvl, k_up_fe, k_up_re;    // KEY0 = UP
    wire k_dn_lvl, k_dn_fe, k_dn_re;    // KEY1 = DOWN
    wire k_lt_lvl, k_lt_fe, k_lt_re;    // KEY2 = LEFT
    wire k_rt_lvl, k_rt_fe, k_rt_re;    // KEY3 = RIGHT

    wire sw_place_lvl, sw_place_re, sw_place_fe;   // SW0 = Place
    wire sw_rst_lvl,  sw_rst_re,  sw_rst_fe;       // SW1 = Restart

    input_debounce db_k0 (.clk(CLOCK_50), .rst_n(por_n), .raw(KEY[0]),
        .level(k_up_lvl), .rising(k_up_re), .falling(k_up_fe));
    input_debounce db_k1 (.clk(CLOCK_50), .rst_n(por_n), .raw(KEY[1]),
        .level(k_dn_lvl), .rising(k_dn_re), .falling(k_dn_fe));
    input_debounce db_k2 (.clk(CLOCK_50), .rst_n(por_n), .raw(KEY[2]),
        .level(k_lt_lvl), .rising(k_lt_re), .falling(k_lt_fe));
    input_debounce db_k3 (.clk(CLOCK_50), .rst_n(por_n), .raw(KEY[3]),
        .level(k_rt_lvl), .rising(k_rt_re), .falling(k_rt_fe));

    input_debounce db_sw0 (.clk(CLOCK_50), .rst_n(por_n), .raw(SW[0]),
        .level(sw_place_lvl), .rising(sw_place_re), .falling(sw_place_fe));
    input_debounce db_sw1 (.clk(CLOCK_50), .rst_n(por_n), .raw(SW[1]),
        .level(sw_rst_lvl), .rising(sw_rst_re), .falling(sw_rst_fe));

    // ============================================================
    //  Difficulty selection: SW2=Easy, SW3=Hard, none=Medium
    // ============================================================
    wire [1:0] difficulty = SW[3] ? 2'b10 : (SW[2] ? 2'b00 : 2'b01);

    // ============================================================
    //  Cursor controller
    // ============================================================
    wire [3:0] cursor_idx;
    wire [1:0] cell_col, cell_row;
    cursor_controller u_cursor (
        .clk(CLOCK_50), .rst_n(por_n),
        .key_up(k_up_fe), .key_down(k_dn_fe),
        .key_left(k_lt_fe), .key_right(k_rt_fe),
        .cell_idx(cursor_idx), .cell_col(cell_col), .cell_row(cell_row)
    );

    // ============================================================
    //  Board memory
    // ============================================================
    wire [17:0] board_state;
    wire [1:0]  board_at_cursor;

    board_memory u_board (
        .clk(CLOCK_50), .rst_n(por_n),
        .addr_w(board_addr_fsm), .data_w(board_data_fsm), .we(board_we_fsm),
        .addr_a(cursor_idx), .addr_b(4'd0),
        .data_a(board_at_cursor), .data_b(),
        .board_out(board_state)
    );

    // ============================================================
    //  Winner detector
    // ============================================================
    wire x_win, o_win, draw;
    winner_detector u_winner (
        .board(board_state), .x_win(x_win), .o_win(o_win), .draw(draw)
    );

    // ============================================================
    //  Game FSM
    // ============================================================
    wire [2:0] fsm_state;
    wire       player_turn, game_active;
    wire [3:0] result_code;

    wire       board_we_fsm;
    wire [3:0] board_addr_fsm;
    wire [1:0] board_data_fsm;

    wire       ai_start;
    wire       ai_done;
    wire [3:0] ai_move_idx;

    wire       x_win_event, o_win_event, draw_event;

    // Winner signals are combinational from board_memory.
    // Board writes take 1 cycle via the registered board_memory.
    // FSM transitions are 1 cycle apart, so winner values are
    // correct when the FSM enters the check state.
    game_fsm u_fsm (
        .clk(CLOCK_50), .rst_n(por_n),
        .sw_place(sw_place_re),     // rising edge of SW0
        .sw_restart(sw_rst_re),     // rising edge of SW1
        .board_we(board_we_fsm),
        .board_addr(board_addr_fsm),
        .board_data(board_data_fsm),
        .board_at_cursor(board_at_cursor),
        .board_state(board_state),
        .cursor_idx(cursor_idx),
        .x_win(x_win), .o_win(o_win), .draw(draw),
        .ai_start(ai_start), .ai_done(ai_done), .ai_move_idx(ai_move_idx),
        .x_win_event(x_win_event), .o_win_event(o_win_event), .draw_event(draw_event),
        .cur_state(fsm_state), .player_turn(player_turn),
        .game_active(game_active), .result_code(result_code)
    );

    // ============================================================
    //  AI Engine
    // ============================================================
    ai_engine u_ai (
        .clk(CLOCK_50), .rst_n(por_n),
        .start(ai_start), .difficulty(difficulty),
        .board(board_state), .done(ai_done), .move(ai_move_idx)
    );

    // ============================================================
    //  Score counter
    // ============================================================
    wire [7:0] x_wins, o_wins, draws;
    score_counter u_score (
        .clk(CLOCK_50), .rst_n(por_n),
        .x_win_event(x_win_event), .o_win_event(o_win_event), .draw_event(draw_event),
        .x_wins(x_wins), .o_wins(o_wins), .draws(draws)
    );

    // ============================================================
    //  Seven-segment display
    //   HEX7=X_wins_tens, HEX6=X_wins_ones
    //   HEX5=O_wins_tens, HEX4=O_wins_ones
    //   HEX3=Draws_tens,  HEX2=Draws_ones
    //   HEX1=result_code, HEX0=difficulty
    // ============================================================
    seven_segment s7 (.bcd(x_wins[7:4]),  .seg(HEX7));
    seven_segment s6 (.bcd(x_wins[3:0]),  .seg(HEX6));
    seven_segment s5 (.bcd(o_wins[7:4]),  .seg(HEX5));
    seven_segment s4 (.bcd(o_wins[3:0]),  .seg(HEX4));
    seven_segment s3 (.bcd(draws[7:4]),   .seg(HEX3));
    seven_segment s2 (.bcd(draws[3:0]),   .seg(HEX2));
    seven_segment s1 (.bcd({1'b0, fsm_state}), .seg(HEX1));
    seven_segment s0 (.bcd({2'b0, difficulty}), .seg(HEX0));

    // ============================================================
    //  VGA Renderer
    // ============================================================
    wire [7:0] vga_ri, vga_gi, vga_bi;
    renderer u_render (
        .clk_25(clk_25),
        .vx(vx), .vy(vy), .blank(blank),
        .board(board_state), .cursor_idx(cursor_idx),
        .cell_col(cell_col), .cell_row(cell_row),
        .player_turn(player_turn), .game_active(game_active),
        .result_code(result_code), .difficulty(difficulty),
        .vga_r(vga_ri), .vga_g(vga_gi), .vga_b(vga_bi)
    );

    // The renderer has pipeline regs, so connect directly
    assign VGA_R = vga_ri;
    assign VGA_G = vga_gi;
    assign VGA_B = vga_bi;

    // ============================================================
    //  Status LEDs
    // ============================================================
    assign LEDR[0]  = game_active;
    assign LEDR[1]  = player_turn;
    assign LEDR[2]  = result_code[0];
    assign LEDR[3]  = result_code[1];
    assign LEDR[4]  = result_code[2];
    assign LEDR[17:5] = 13'b0;

    assign LEDG[0] = ~k_up_lvl;   // UP key pressed
    assign LEDG[1] = ~k_dn_lvl;   // DOWN key pressed
    assign LEDG[2] = ~k_lt_lvl;   // LEFT key pressed
    assign LEDG[3] = ~k_rt_lvl;   // RIGHT key pressed
    assign LEDG[4] = SW[0];       // Place switch
    assign LEDG[5] = SW[1];       // Restart switch
    assign LEDG[6] = ai_done;     // AI ready
    assign LEDG[8:7] = 2'b0;

endmodule
