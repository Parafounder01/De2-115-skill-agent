// ============================================================
//  game_fsm.v — Main game state machine
//
//  States:
//    RESET        → Clear board
//    START        → Begin game
//    PLAYER_MOVE  → Wait for valid human placement (SW0 press)
//    CHECK_WIN    → Check X win or draw after human move
//    AI_MOVE      → Signal AI to compute
//    AI_WAIT      → Wait for AI completion
//    AI_COMMIT    → Write AI move to board, check result
//    GAME_OVER    → Display result, wait for restart
// ============================================================

module game_fsm (
    input  clk,
    input  rst_n,             // board reset
    input  sw_place,          // SW0: place X at cursor
    input  sw_restart,        // SW1: restart game

    // Board interface
    output reg        board_we,
    output reg [3:0]  board_addr,
    output reg [1:0]  board_data,
    input  [1:0]      board_at_cursor,
    input  [17:0]     board_state,

    // Cursor position
    input  [3:0]      cursor_idx,

    // Winner detection
    input  x_win, o_win, draw,

    // AI interface
    output reg        ai_start,
    input             ai_done,
    input  [3:0]      ai_move_idx,

    // Score events
    output reg        x_win_event,
    output reg        o_win_event,
    output reg        draw_event,

    // Status outputs
    output wire [2:0] cur_state,
    output reg        player_turn,  // 1=human(X), 0=AI(O)
    output reg        game_active,
    output reg [3:0]  result_code   // 0=playing, 1=X_win, 2=O_win, 3=draw
);

    parameter S_RESET     = 3'd0;
    parameter S_START     = 3'd1;
    parameter S_PLAYER    = 3'd2;
    parameter S_CHECK_WIN = 3'd3;
    parameter S_AI_MOVE   = 3'd4;
    parameter S_AI_WAIT   = 3'd5;
    parameter S_AI_COMMIT = 3'd6;
    parameter S_GAME_OVER = 3'd7;

    reg [2:0] state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_RESET;
            board_we <= 0; board_addr <= 0; board_data <= 0;
            ai_start <= 0;
            x_win_event <= 0; o_win_event <= 0; draw_event <= 0;
            player_turn <= 1; game_active <= 0; result_code <= 0;
        end else begin
            board_we <= 0; ai_start <= 0;
            x_win_event <= 0; o_win_event <= 0; draw_event <= 0;

            case (state)

                S_RESET: begin
                    player_turn <= 1; game_active <= 0; result_code <= 0;
                    state <= S_START;
                end

                S_START: begin
                    game_active <= 1;
                    state <= S_PLAYER;
                end

                S_PLAYER: begin
                    if (sw_place && board_at_cursor == 2'b00) begin
                        board_addr <= cursor_idx;
                        board_data <= 2'b01;  // X
                        board_we <= 1;
                        state <= S_CHECK_WIN;
                    end
                end

                S_CHECK_WIN: begin
                    if (x_win) begin
                        result_code <= 1; x_win_event <= 1;
                        state <= S_GAME_OVER;
                    end else if (draw) begin
                        result_code <= 3; draw_event <= 1;
                        state <= S_GAME_OVER;
                    end else begin
                        player_turn <= 0;
                        state <= S_AI_MOVE;
                    end
                end

                S_AI_MOVE: begin
                    ai_start <= 1;
                    state <= S_AI_WAIT;
                end

                S_AI_WAIT: begin
                    if (ai_done) begin
                        board_addr <= ai_move_idx;
                        board_data <= 2'b10;  // O
                        board_we <= 1;
                        state <= S_AI_COMMIT;
                    end
                end

                S_AI_COMMIT: begin
                    // Board write took effect last cycle
                    if (o_win) begin
                        result_code <= 2; o_win_event <= 1;
                        state <= S_GAME_OVER;
                    end else if (draw) begin
                        result_code <= 3; draw_event <= 1;
                        state <= S_GAME_OVER;
                    end else begin
                        player_turn <= 1;
                        state <= S_PLAYER;
                    end
                end

                S_GAME_OVER: begin
                    game_active <= 0;
                    if (sw_restart) state <= S_RESET;
                end

                default: state <= S_RESET;

            endcase
        end
    end

    assign cur_state = state;

endmodule
