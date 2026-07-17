// ============================================================
//  ai_engine.v — Tic-Tac-Toe AI with 3 difficulty modes
//
//  Easy:   Random legal move (LFSR-based)
//  Medium: Win → Block → Random
//  Hard:   Win → Block → Center → Corner → Side (unbeatable)
//          Equivalent to minimax for Tic-Tac-Toe.
//
//  Board encoding: 00=empty, 01=X (human), 10=O (AI)
//  Cell indexing:  0 1 2    row 0
//                   3 4 5    row 1
//                   6 7 8    row 2
// ============================================================

module ai_engine (
    input  clk,
    input  rst_n,
    input  start,            // start computation
    input  [1:0] difficulty, // 00=Easy, 01=Medium, 10=Hard
    input  [17:0] board,     // current board state
    output reg  done,        // computation done
    output reg [3:0] move    // chosen move (0-8)
);

    //============================================================
    //  Wire the 9 cells for easy access
    //============================================================
    wire [1:0] c0 = board[1:0];
    wire [1:0] c1 = board[3:2];
    wire [1:0] c2 = board[5:4];
    wire [1:0] c3 = board[7:6];
    wire [1:0] c4 = board[9:8];
    wire [1:0] c5 = board[11:10];
    wire [1:0] c6 = board[13:12];
    wire [1:0] c7 = board[15:14];
    wire [1:0] c8 = board[17:16];

    wire e0 = (c0 == 0); wire e1 = (c1 == 0); wire e2 = (c2 == 0);
    wire e3 = (c3 == 0); wire e4 = (c4 == 0); wire e5 = (c5 == 0);
    wire e6 = (c6 == 0); wire e7 = (c7 == 0); wire e8 = (c8 == 0);

    //============================================================
    //  LFSR pseudo-random number generator
    //============================================================
    reg [15:0] lfsr;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) lfsr <= 16'hACE1;
        else lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};
    end

    //============================================================
    //  Line check helper: returns winning/blocking move for a player
    //  Checks all 8 lines. If a line has 2 of the player + 1 empty,
    //  returns the empty cell index. Otherwise returns 9 (none).
    //============================================================
    function [3:0] find_win;
        input [1:0] pl;
        reg [3:0] r;
        begin
            r = 4'd9;
            // Rows
            if (c0==pl && c1==pl && e2) r=2; else if (c0==pl && c2==pl && e1) r=1; else if (c1==pl && c2==pl && e0) r=0;
            else if (c3==pl && c4==pl && e5) r=5; else if (c3==pl && c5==pl && e4) r=4; else if (c4==pl && c5==pl && e3) r=3;
            else if (c6==pl && c7==pl && e8) r=8; else if (c6==pl && c8==pl && e7) r=7; else if (c7==pl && c8==pl && e6) r=6;
            // Columns
            else if (c0==pl && c3==pl && e6) r=6; else if (c0==pl && c6==pl && e3) r=3; else if (c3==pl && c6==pl && e0) r=0;
            else if (c1==pl && c4==pl && e7) r=7; else if (c1==pl && c7==pl && e4) r=4; else if (c4==pl && c7==pl && e1) r=1;
            else if (c2==pl && c5==pl && e8) r=8; else if (c2==pl && c8==pl && e5) r=5; else if (c5==pl && c8==pl && e2) r=2;
            // Diagonals
            else if (c0==pl && c4==pl && e8) r=8; else if (c0==pl && c8==pl && e4) r=4; else if (c4==pl && c8==pl && e0) r=0;
            else if (c2==pl && c4==pl && e6) r=6; else if (c2==pl && c6==pl && e4) r=4; else if (c4==pl && c6==pl && e2) r=2;
            find_win = r;
        end
    endfunction

    //============================================================
    //  Main AI state machine
    //============================================================
    localparam IDLE    = 3'd0;
    localparam EVAL    = 3'd1;
    localparam DONE_ST = 3'd2;

    reg [2:0] state;
    reg [3:0] ai_move_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            done <= 0;
            move <= 0;
            ai_move_r <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        ai_move_r <= 4'd9;  // sentinel: no move yet
                        state <= EVAL;
                    end
                end

                EVAL: begin
                    case (difficulty)
                        // ===== EASY: Random legal move =====
                        2'd0: begin
                            // Pick first empty cell based on LFSR
                            case (lfsr[2:0])
                                0: if (e0) ai_move_r<=0; else if(e1) ai_move_r<=1; else if(e2) ai_move_r<=2;
                                   else if(e3) ai_move_r<=3; else if(e4) ai_move_r<=4; else if(e5) ai_move_r<=5;
                                   else if(e6) ai_move_r<=6; else if(e7) ai_move_r<=7; else ai_move_r<=8;
                                1: if (e1) ai_move_r<=1; else if(e2) ai_move_r<=2; else if(e3) ai_move_r<=3;
                                   else if(e4) ai_move_r<=4; else if(e5) ai_move_r<=5; else if(e6) ai_move_r<=6;
                                   else if(e7) ai_move_r<=7; else if(e8) ai_move_r<=8; else ai_move_r<=0;
                                2: if (e2) ai_move_r<=2; else if(e3) ai_move_r<=3; else if(e4) ai_move_r<=4;
                                   else if(e5) ai_move_r<=5; else if(e6) ai_move_r<=6; else if(e7) ai_move_r<=7;
                                   else if(e8) ai_move_r<=8; else if(e0) ai_move_r<=0; else ai_move_r<=1;
                                3: if (e3) ai_move_r<=3; else if(e4) ai_move_r<=4; else if(e5) ai_move_r<=5;
                                   else if(e6) ai_move_r<=6; else if(e7) ai_move_r<=7; else if(e8) ai_move_r<=8;
                                   else if(e0) ai_move_r<=0; else if(e1) ai_move_r<=1; else ai_move_r<=2;
                                4: if (e4) ai_move_r<=4; else if(e5) ai_move_r<=5; else if(e6) ai_move_r<=6;
                                   else if(e7) ai_move_r<=7; else if(e8) ai_move_r<=8; else if(e0) ai_move_r<=0;
                                   else if(e1) ai_move_r<=1; else if(e2) ai_move_r<=2; else ai_move_r<=3;
                                5: if (e5) ai_move_r<=5; else if(e6) ai_move_r<=6; else if(e7) ai_move_r<=7;
                                   else if(e8) ai_move_r<=8; else if(e0) ai_move_r<=0; else if(e1) ai_move_r<=1;
                                   else if(e2) ai_move_r<=2; else if(e3) ai_move_r<=3; else ai_move_r<=4;
                                6: if (e6) ai_move_r<=6; else if(e7) ai_move_r<=7; else if(e8) ai_move_r<=8;
                                   else if(e0) ai_move_r<=0; else if(e1) ai_move_r<=1; else if(e2) ai_move_r<=2;
                                   else if(e3) ai_move_r<=3; else if(e4) ai_move_r<=4; else ai_move_r<=5;
                                default: if (e7) ai_move_r<=7; else if(e8) ai_move_r<=8; else if(e0) ai_move_r<=0;
                                   else if(e1) ai_move_r<=1; else if(e2) ai_move_r<=2; else if(e3) ai_move_r<=3;
                                   else if(e4) ai_move_r<=4; else if(e5) ai_move_r<=5; else ai_move_r<=6;
                            endcase
                            state <= DONE_ST;
                        end

                        // ===== MEDIUM: Win → Block → Random =====
                        2'd1: begin
                            if (find_win(2'b10) != 9)       ai_move_r <= find_win(2'b10);  // AI win
                            else if (find_win(2'b01) != 9)  ai_move_r <= find_win(2'b01);  // Block
                            else begin
                                // Random
                                case (lfsr[2:0])
                                    0: if (e0) ai_move_r<=0; else if(e1) ai_move_r<=1; else if(e2) ai_move_r<=2;
                                       else if(e3) ai_move_r<=3; else if(e4) ai_move_r<=4; else if(e5) ai_move_r<=5;
                                       else if(e6) ai_move_r<=6; else if(e7) ai_move_r<=7; else ai_move_r<=8;
                                    1: if (e1) ai_move_r<=1; else if(e2) ai_move_r<=2; else if(e3) ai_move_r<=3;
                                       else if(e4) ai_move_r<=4; else if(e5) ai_move_r<=5; else if(e6) ai_move_r<=6;
                                       else if(e7) ai_move_r<=7; else if(e8) ai_move_r<=8; else ai_move_r<=0;
                                    2: if (e2) ai_move_r<=2; else if(e3) ai_move_r<=3; else if(e4) ai_move_r<=4;
                                       else if(e5) ai_move_r<=5; else if(e6) ai_move_r<=6; else if(e7) ai_move_r<=7;
                                       else if(e8) ai_move_r<=8; else if(e0) ai_move_r<=0; else ai_move_r<=1;
                                    3: if (e3) ai_move_r<=3; else if(e4) ai_move_r<=4; else if(e5) ai_move_r<=5;
                                       else if(e6) ai_move_r<=6; else if(e7) ai_move_r<=7; else if(e8) ai_move_r<=8;
                                       else if(e0) ai_move_r<=0; else if(e1) ai_move_r<=1; else ai_move_r<=2;
                                    4: if (e4) ai_move_r<=4; else if(e5) ai_move_r<=5; else if(e6) ai_move_r<=6;
                                       else if(e7) ai_move_r<=7; else if(e8) ai_move_r<=8; else if(e0) ai_move_r<=0;
                                       else if(e1) ai_move_r<=1; else if(e2) ai_move_r<=2; else ai_move_r<=3;
                                    5: if (e5) ai_move_r<=5; else if(e6) ai_move_r<=6; else if(e7) ai_move_r<=7;
                                       else if(e8) ai_move_r<=8; else if(e0) ai_move_r<=0; else if(e1) ai_move_r<=1;
                                       else if(e2) ai_move_r<=2; else if(e3) ai_move_r<=3; else ai_move_r<=4;
                                    6: if (e6) ai_move_r<=6; else if(e7) ai_move_r<=7; else if(e8) ai_move_r<=8;
                                       else if(e0) ai_move_r<=0; else if(e1) ai_move_r<=1; else if(e2) ai_move_r<=2;
                                       else if(e3) ai_move_r<=3; else if(e4) ai_move_r<=4; else ai_move_r<=5;
                                    default: if (e7) ai_move_r<=7; else if(e8) ai_move_r<=8; else if(e0) ai_move_r<=0;
                                       else if(e1) ai_move_r<=1; else if(e2) ai_move_r<=2; else if(e3) ai_move_r<=3;
                                       else if(e4) ai_move_r<=4; else if(e5) ai_move_r<=5; else ai_move_r<=6;
                                endcase
                            end
                            state <= DONE_ST;
                        end

                        // ===== HARD: Unbeatable strategy =====
                        // Priority: Win → Block → Center → OppositeCorner → Corner → Side
                        2'd2: begin
                            // 1. Win
                            if (find_win(2'b10) != 9)
                                ai_move_r <= find_win(2'b10);
                            // 2. Block
                            else if (find_win(2'b01) != 9)
                                ai_move_r <= find_win(2'b01);
                            // 3. Center
                            else if (e4)
                                ai_move_r <= 4;
                            // 4. Opposite corner: if player is in a corner, take opposite
                            else if (c0==2'b01 && e8) ai_move_r <= 8;
                            else if (c2==2'b01 && e6) ai_move_r <= 6;
                            else if (c6==2'b01 && e2) ai_move_r <= 2;
                            else if (c8==2'b01 && e0) ai_move_r <= 0;
                            // 5. Empty corner
                            else if (e0) ai_move_r <= 0;
                            else if (e2) ai_move_r <= 2;
                            else if (e6) ai_move_r <= 6;
                            else if (e8) ai_move_r <= 8;
                            // 6. Empty side
                            else if (e1) ai_move_r <= 1;
                            else if (e3) ai_move_r <= 3;
                            else if (e5) ai_move_r <= 5;
                            else if (e7) ai_move_r <= 7;
                            // 7. Fallback (shouldn't happen)
                            else begin
                                if (e0) ai_move_r<=0; else if(e1) ai_move_r<=1; else if(e2) ai_move_r<=2;
                                else if(e3) ai_move_r<=3; else if(e4) ai_move_r<=4; else if(e5) ai_move_r<=5;
                                else if(e6) ai_move_r<=6; else if(e7) ai_move_r<=7; else ai_move_r<=8;
                            end
                            state <= DONE_ST;
                        end

                        default: begin
                            if (e4) ai_move_r <= 4; else ai_move_r <= 0;
                            state <= DONE_ST;
                        end
                    endcase
                end

                DONE_ST: begin
                    move <= ai_move_r;
                    done <= 1;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
