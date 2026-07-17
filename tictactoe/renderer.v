// ============================================================
//  renderer.v — VGA pixel renderer for Tic-Tac-Toe
//
//  Draws:
//    - 3×3 grid centered on screen
//    - Green X for human, Red O for AI
//    - Yellow cursor highlight
//    - Title, status, game result overlay
//    - Current player indicator, difficulty label
// ============================================================

module renderer (
    input  clk_25,
    input  [9:0] vx, vy,
    input  blank,
    input  [17:0] board,
    input  [3:0]  cursor_idx,
    input  [1:0]  cell_col,
    input  [1:0]  cell_row,
    input         player_turn,
    input         game_active,
    input  [3:0]  result_code,
    input  [1:0]  difficulty,
    output reg [7:0] vga_r,
    output reg [7:0] vga_g,
    output reg [7:0] vga_b
);

    // Board layout: 3 cells x 76px + 4 grid lines x 4px = 244px
    parameter CELL = 10'd76;
    parameter GRID = 10'd4;
    parameter LEFT = 10'd198;  // (640-244)/2
    parameter TOP  = 10'd118;  // (480-244)/2

    // Cell edge positions
    parameter C0 = LEFT + GRID;                     // col 0 start: 202
    parameter C1 = LEFT + (CELL + GRID) + GRID;     // col 1 start: 282
    parameter C2 = LEFT + (CELL + GRID)*2 + GRID;   // col 2 start: 362
    parameter R0 = TOP + GRID;                      // row 0 start: 122
    parameter R1 = TOP + (CELL + GRID) + GRID;      // row 1 start: 202
    parameter R2 = TOP + (CELL + GRID)*2 + GRID;    // row 2 start: 282

    // In board area
    wire in_board = (vx >= LEFT && vx < LEFT + 244 &&
                     vy >= TOP  && vy < TOP  + 244);

    // Grid line detection
    wire hgrid0 = (vy >= TOP  && vy < TOP  + GRID);
    wire hgrid1 = (vy >= R0 + CELL && vy < R0 + CELL + GRID);
    wire hgrid2 = (vy >= R1 + CELL && vy < R1 + CELL + GRID);
    wire hgrid3 = (vy >= R2 + CELL && vy < R2 + CELL + GRID);
    wire vgrid0 = (vx >= LEFT && vx < LEFT + GRID);
    wire vgrid1 = (vx >= C0 + CELL && vx < C0 + CELL + GRID);
    wire vgrid2 = (vx >= C1 + CELL && vx < C1 + CELL + GRID);
    wire vgrid3 = (vx >= C2 + CELL && vx < C2 + CELL + GRID);
    wire is_grid = ((hgrid0||hgrid1||hgrid2||hgrid3) ||
                    (vgrid0||vgrid1||vgrid2||vgrid3)) && in_board;

    // Cell identification
    wire [1:0] cell_x = (vx < C1) ? 2'd0 : (vx < C2) ? 2'd1 : 2'd2;
    wire [1:0] cell_y = (vy < R1) ? 2'd0 : (vy < R2) ? 2'd1 : 2'd2;
    wire [3:0] cell_idx = cell_y * 3 + cell_x;

    // Inside a play cell (not grid)
    wire in_cell = in_board && !is_grid;

    // Position within cell
    wire [9:0] px = (cell_x == 0) ? (vx - C0) :
                    (cell_x == 1) ? (vx - C1) : (vx - C2);
    wire [9:0] py = (cell_y == 0) ? (vy - R0) :
                    (cell_y == 1) ? (vy - R1) : (vy - R2);

    // Board cell content (case for variable index)
    reg [1:0] cd;
    always @(*) begin
        case (cell_idx)
            0: cd = board[1:0];   1: cd = board[3:2];
            2: cd = board[5:4];   3: cd = board[7:6];
            4: cd = board[9:8];   5: cd = board[11:10];
            6: cd = board[13:12]; 7: cd = board[15:14];
            8: cd = board[17:16]; default: cd = 2'b00;
        endcase
    end
    wire c_has_x = (cd == 2'b01);
    wire c_has_o = (cd == 2'b10);

    // Cursor at this cell
    wire cur_here = (cell_x == cell_col && cell_y == cell_row);

    // O-circle constants
    parameter R_INNER = 26*26;
    parameter R_OUTER = 33*33;
    wire [19:0] odx = px - 38;
    wire [19:0] ody = py - 38;
    wire [19:0] odist = odx*odx + ody*ody;
    wire in_o = (odist >= R_INNER && odist <= R_OUTER);

    //============================================================
    //  Combinational color logic
    //============================================================
    reg [7:0] rr, gg, bb;

    always @(*) begin
        rr = 8'h05; gg = 8'h05; bb = 8'h10;  // default: dark blue-black background

        if (blank) begin

            // ── Title bar ──
            if (vy >= 15 && vy < 55 && vx >= 220 && vx < 420) begin
                rr = 8'hFF; gg = 8'hFF; bb = 8'h00;  // yellow
                if ((vx >= 225 && vx < 245 && vy < 35) ||
                    (vx >= 260 && vx < 280 && vy < 35) ||
                    (vx >= 295 && vx < 315 && vy < 35) ||
                    (vx >= 330 && vx < 350 && vy < 35) ||
                    (vx >= 365 && vx < 395 && vy < 35)) begin
                    rr = 8'hFF; gg = 8'h80; bb = 8'h00;  // orange accent
                end
            end

            // ── Score/status bar ──
            // Left: X score
            if (vy >= 65 && vy < 110 && vx >= 40 && vx < 200) begin
                rr = 8'h00; gg = 8'h40; bb = 8'h00;
                if (vx >= 50 && vx < 90 && vy >= 70 && vy < 90) begin
                    rr = 8'h00; gg = 8'hFF; bb = 8'h00;  // X label
                end
            end
            // Right: O score
            if (vy >= 65 && vy < 110 && vx >= 440 && vx < 600) begin
                rr = 8'h40; bb = 8'h00; gg = 8'h00;
                if (vx >= 550 && vx < 590 && vy >= 70 && vy < 90) begin
                    rr = 8'hFF; gg = 8'h00; bb = 8'h00;  // O label
                end
            end
            // Center: status / difficulty
            if (vy >= 65 && vy < 110 && vx >= 240 && vx < 400) begin
                rr = 8'h10; gg = 8'h10; bb = 8'h30;
                if (vy >= 72 && vy < 90) begin
                    if (game_active) begin
                        if (player_turn && vx >= 260 && vx < 380) begin
                            rr = 8'h00; gg = 8'hFF; bb = 8'h00;  // "YOUR TURN"
                        end else if (!player_turn && vx >= 260 && vx < 380) begin
                            rr = 8'hFF; gg = 8'hFF; bb = 8'h00;  // "AI..."
                        end
                    end
                end
                if (vy >= 95 && vy < 108 && vx >= 250 && vx < 390) begin
                    case (difficulty)
                        2'b00: begin rr = 8'h00; gg = 8'hFF; bb = 8'h00; end
                        2'b01: begin rr = 8'hFF; gg = 8'hFF; bb = 8'h00; end
                        default: begin rr = 8'hFF; gg = 8'h00; bb = 8'h00; end
                    endcase
                end
            end

            // ── Board ──
            if (in_board) begin
                if (is_grid) begin
                    rr = 8'hFF; gg = 8'hFF; bb = 8'hFF;  // white grid
                end

                if (in_cell) begin
                    rr = 8'h08; gg = 8'h08; bb = 8'h18;  // cell background

                    // Cursor: yellow border
                    if (cur_here) begin
                        if (px < 6 || px >= CELL-6 || py < 6 || py >= CELL-6) begin
                            rr = 8'hFF; gg = 8'hFF; bb = 8'h00;
                        end
                    end

                    // X: green diagonal lines
                    if (c_has_x) begin
                        if ((px >= py - 3 && px <= py + 3) ||
                            (px >= (CELL-1-py) - 3 && px <= (CELL-1-py) + 3)) begin
                            if (px >= 4 && px <= CELL-4 && py >= 4 && py <= CELL-4) begin
                                rr = 8'h00; gg = 8'hFF; bb = 8'h00;
                            end
                        end
                    end

                    // O: red circle
                    if (c_has_o && in_o) begin
                        rr = 8'hFF; gg = 8'h00; bb = 8'h00;
                    end

                    // Win glow
                    if (result_code == 1 && c_has_x) begin
                        rr = 8'h00; gg = 8'h88; bb = 8'h00;
                        if ((px >= py - 3 && px <= py + 3) ||
                            (px >= (CELL-1-py) - 3 && px <= (CELL-1-py) + 3)) begin
                            if (px >= 4 && px <= CELL-4 && py >= 4 && py <= CELL-4) begin
                                rr = 8'h00; gg = 8'hFF; bb = 8'h00;
                            end
                        end
                    end
                    if (result_code == 2 && c_has_o && in_o) begin
                        rr = 8'hFF; gg = 8'h00; bb = 8'h00;
                    end
                end
            end

            // ── Game over overlay ──
            if (result_code != 0) begin
                if (vy >= 190 && vy < 280 && vx >= 170 && vx < 470) begin
                    rr = 8'h00; gg = 8'h00; bb = 8'h00;
                    if (vy >= 210 && vy < 265 && vx >= 200 && vx < 440) begin
                        case (result_code)
                            1: begin rr = 8'h00; gg = 8'hFF; bb = 8'h00; end
                            2: begin rr = 8'hFF; gg = 8'h00; bb = 8'h00; end
                            3: begin rr = 8'hFF; gg = 8'hFF; bb = 8'hFF; end
                            default: rr = 8'hFF;
                        endcase
                    end
                    if (vy >= 270 && vy < 280 && vx >= 240 && vx < 400) begin
                        rr = 8'h88; gg = 8'h88; bb = 8'h88;
                    end
                end
            end

            // ── Bottom info ──
            if (vy >= 430 && vy < 475) begin
                rr = 8'h10; gg = 8'h10; bb = 8'h20;
                if (vx >= 180 && vx < 460 && vy >= 440 && vy < 460) begin
                    rr = 8'h66; gg = 8'h66; bb = 8'h66;
                end
            end
        end
    end

    // Pipeline register for timing
    always @(posedge clk_25) begin
        vga_r <= rr;
        vga_g <= gg;
        vga_b <= bb;
    end

endmodule
