// ============================================================
//  score_counter.v — Tracks X wins, O wins, draws
//  Outputs as BCD for seven-segment display (max 99 each)
// ============================================================

module score_counter (
    input  clk,
    input  rst_n,
    input  x_win_event,   // single-cycle pulse when X wins
    input  o_win_event,   // single-cycle pulse when O wins
    input  draw_event,    // single-cycle pulse when draw
    output [7:0] x_wins,  // BCD: high nibble = tens, low = ones
    output [7:0] o_wins,
    output [7:0] draws
);

    reg [3:0] x_tens, x_ones;
    reg [3:0] o_tens, o_ones;
    reg [3:0] d_tens, d_ones;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_tens <= 0; x_ones <= 0;
            o_tens <= 0; o_ones <= 0;
            d_tens <= 0; d_ones <= 0;
        end else begin
            if (x_win_event) begin
                if (x_ones == 9) begin x_ones <= 0; x_tens <= x_tens + 1; end
                else x_ones <= x_ones + 1;
            end
            if (o_win_event) begin
                if (o_ones == 9) begin o_ones <= 0; o_tens <= o_tens + 1; end
                else o_ones <= o_ones + 1;
            end
            if (draw_event) begin
                if (d_ones == 9) begin d_ones <= 0; d_tens <= d_tens + 1; end
                else d_ones <= d_ones + 1;
            end
        end
    end

    assign x_wins = {x_tens, x_ones};
    assign o_wins = {o_tens, o_ones};
    assign draws  = {d_tens, d_ones};

endmodule
