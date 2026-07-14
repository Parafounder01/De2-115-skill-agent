// ============================================================
//  timer_counter.v — DE2-115 4-digit Hundredths-of-Second Timer
//
//  Displays:  HEX3 HEX2 : HEX1 HEX0   (format: SS.dd)
//  Counts  from 00.00 → 99.99 seconds, then wraps.
//
//  50 MHz clk, KEY0 = reset_n (active-low push-button)
//  All 7-segment outputs: active-low, {g,f,e,d,c,b,a}
// ============================================================

module timer_counter (
    input  clk,          // 50 MHz
    input  rst_n,        // KEY0 (active-low)
    output [6:0] hex3,   // seconds tens
    output [6:0] hex2,   // seconds ones
    output [6:0] hex1,   // tenths
    output [6:0] hex0    // hundredths
);

    // ── 10 ms tick from 50 MHz ──────────────────────────────
    //  50 MHz × 0.01 s = 500,000 cycles
    localparam TICK_10MS = 19'd500_000;
    reg [18:0] tick_cnt;

    wire t_10ms = (tick_cnt == TICK_10MS - 1);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)          tick_cnt <= 0;
        else if (t_10ms)     tick_cnt <= 0;
        else                 tick_cnt <= tick_cnt + 19'd1;
    end

    // ── BCD digit counters (cascaded carry) ────────────────
    reg [3:0] d0, d1, d2, d3;   // hundredths, tenths, sec_ones, sec_tens

    wire carry_d0 = t_10ms && (d0 == 4'd9);
    wire carry_d1 = carry_d0 && (d1 == 4'd9);
    wire carry_d2 = carry_d1 && (d2 == 4'd9);

    // d0 — hundredths (0→9, +1 every 10 ms)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)         d0 <= 0;
        else if (t_10ms)    d0 <= (d0 == 4'd9) ? 4'd0 : d0 + 4'd1;
    end

    // d1 — tenths (0→9, +1 every 100 ms)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)          d1 <= 4'd0;
        else if (carry_d0)   d1 <= (d1 == 4'd9) ? 4'd0 : d1 + 4'd1;
    end

    // d2 — seconds ones (0→9, +1 every 1 s)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)          d2 <= 4'd0;
        else if (carry_d1)   d2 <= (d2 == 4'd9) ? 4'd0 : d2 + 4'd1;
    end

    // d3 — seconds tens (0→9, wraps 99.99 → 00.00)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)          d3 <= 4'd0;
        else if (carry_d2)   d3 <= (d3 == 4'd9) ? 4'd0 : d3 + 4'd1;
    end

    // ── 7-segment decoder (active-low, common anode) ──────
    //  bit order: {g, f, e, d, c, b, a}  — LSB = segment A
    function [6:0] seg7(input [3:0] v);
        case (v)
            4'd0: seg7 = 7'b1000000;
            4'd1: seg7 = 7'b1111001;
            4'd2: seg7 = 7'b0100100;
            4'd3: seg7 = 7'b0110000;
            4'd4: seg7 = 7'b0011001;
            4'd5: seg7 = 7'b0010010;
            4'd6: seg7 = 7'b0000010;
            4'd7: seg7 = 7'b1111000;
            4'd8: seg7 = 7'b0000000;
            4'd9: seg7 = 7'b0010000;
            default: seg7 = 7'b1111111;  // blank
        endcase
    endfunction

    assign hex3 = seg7(d3);
    assign hex2 = seg7(d2);
    assign hex1 = seg7(d1);
    assign hex0 = seg7(d0);

endmodule
