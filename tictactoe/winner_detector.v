// ============================================================
//  winner_detector.v — Tic-Tac-Toe win/draw detection
//  Checks all 8 lines for 3-in-a-row
//  Outputs: X_win, O_win, draw
// ============================================================

module winner_detector (
    input  [17:0] board,  // packed: cell0=bits[1:0], cell1=bits[3:2], ...
    output reg    x_win,   // X (human) has won
    output reg    o_win,   // O (AI) has won
    output reg    draw     // board full, no winner
);

    // Unpack cells
    wire [1:0] c0 = board[1:0];
    wire [1:0] c1 = board[3:2];
    wire [1:0] c2 = board[5:4];
    wire [1:0] c3 = board[7:6];
    wire [1:0] c4 = board[9:8];
    wire [1:0] c5 = board[11:10];
    wire [1:0] c6 = board[13:12];
    wire [1:0] c7 = board[15:14];
    wire [1:0] c8 = board[17:16];

    // X = 01, O = 10, empty = 00
    wire x1 = (c0 == 2'b01); wire o1 = (c0 == 2'b10);
    wire x2 = (c1 == 2'b01); wire o2 = (c1 == 2'b10);
    wire x3 = (c2 == 2'b01); wire o3 = (c2 == 2'b10);
    wire x4 = (c3 == 2'b01); wire o4 = (c3 == 2'b10);
    wire x5 = (c4 == 2'b01); wire o5 = (c4 == 2'b10);
    wire x6 = (c5 == 2'b01); wire o6 = (c5 == 2'b10);
    wire x7 = (c6 == 2'b01); wire o7 = (c6 == 2'b10);
    wire x8 = (c7 == 2'b01); wire o8 = (c7 == 2'b10);
    wire x9 = (c8 == 2'b01); wire o9 = (c8 == 2'b10);

    // Rows
    wire x_row0 = x1 && x2 && x3; wire o_row0 = o1 && o2 && o3;
    wire x_row1 = x4 && x5 && x6; wire o_row1 = o4 && o5 && o6;
    wire x_row2 = x7 && x8 && x9; wire o_row2 = o7 && o8 && o9;

    // Columns
    wire x_col0 = x1 && x4 && x7; wire o_col0 = o1 && o4 && o7;
    wire x_col1 = x2 && x5 && x8; wire o_col1 = o2 && o5 && o8;
    wire x_col2 = x3 && x6 && x9; wire o_col2 = o3 && o6 && o9;

    // Diagonals
    wire x_diag0 = x1 && x5 && x9; wire o_diag0 = o1 && o5 && o9;
    wire x_diag1 = x3 && x5 && x7; wire o_diag1 = o3 && o5 && o7;

    // Board full (no empty cells)
    wire any_empty = (c0 == 0 || c1 == 0 || c2 == 0 ||
                      c3 == 0 || c4 == 0 || c5 == 0 ||
                      c6 == 0 || c7 == 0 || c8 == 0);

    always @(*) begin
        x_win = x_row0 || x_row1 || x_row2 ||
                x_col0 || x_col1 || x_col2 ||
                x_diag0 || x_diag1;

        o_win = o_row0 || o_row1 || o_row2 ||
                o_col0 || o_col1 || o_col2 ||
                o_diag0 || o_diag1;

        draw = !x_win && !o_win && !any_empty;
    end

endmodule
