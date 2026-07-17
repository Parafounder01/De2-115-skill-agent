// ============================================================
//  cursor_controller.v — Board cursor position controller
//  KEY[0]=UP, KEY[1]=DOWN, KEY[2]=LEFT, KEY[3]=RIGHT
//  Cursor wraps at edges, outputs cell index (0-8)
// ============================================================

module cursor_controller (
    input  clk,
    input  rst_n,
    input  key_up,      // falling edge: UP
    input  key_down,    // falling edge: DOWN
    input  key_left,    // falling edge: LEFT
    input  key_right,   // falling edge: RIGHT
    output reg [3:0] cell_idx,  // 0-8
    output reg [1:0] cell_col,  // 0-2
    output reg [1:0] cell_row   // 0-2
);

    reg [1:0] col, row;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin col <= 1; row <= 1; end
        else begin
            if (key_up    && row > 0)    row <= row - 1;
            if (key_down  && row < 2)    row <= row + 1;
            if (key_left  && col > 0)    col <= col - 1;
            if (key_right && col < 2)    col <= col + 1;
        end
    end

    always @(*) begin
        cell_idx = row * 3 + col;
        cell_col = col;
        cell_row = row;
    end

endmodule
