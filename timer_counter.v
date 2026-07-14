// ============================================================
//  timer_counter.v — DE2-115 HH:MM Clock (24-hour)
//
//  Displays:  HEX3 HEX2 : HEX1 HEX0   (format: HH:MM)
//  Counts  from 00:00 → 23:59, then wraps.
//
//  50 MHz clk, KEY0 = reset_n (active-low push-button)
//  All 7-segment outputs: active-low, {g,f,e,d,c,b,a}
// ============================================================

module timer_counter (
    input  clk,          // 50 MHz
    input  rst_n,        // KEY0 (active-low)
    output [6:0] hex3,   // hours tens  (0-2)
    output [6:0] hex2,   // hours ones  (0-9)
    output [6:0] hex1,   // minutes tens (0-5)
    output [6:0] hex0    // minutes ones (0-9)
);

    // ── 1-second tick from 50 MHz ──────────────────────────
    //  50 MHz × 1 s = 50,000,000 cycles
    localparam TICK_1S = 26'd50_000_000;
    reg [25:0] tick_cnt;

    wire t_1s = (tick_cnt == TICK_1S - 1);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)          tick_cnt <= 0;
        else if (t_1s)       tick_cnt <= 0;
        else                 tick_cnt <= tick_cnt + 26'd1;
    end

    // ── BCD time counters ──────────────────────────────────
    reg [3:0] min0, min1;   // minutes ones, minutes tens
    reg [3:0] hr0,  hr1;    // hours ones,   hours tens

    wire carry_min0 = t_1s && (min0 == 4'd9);           // every 10 sec
    wire carry_min1 = carry_min0 && (min1 == 4'd5);     // every 60 sec = 1 min
    wire is_23      = (hr1 == 4'd2) && (hr0 == 4'd3);   // 23:XX → wrap

    // minutes ones (0→9, +1 every 60 s)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)          min0 <= 4'd0;
        else if (t_1s)       min0 <= (min0 == 4'd9) ? 4'd0 : min0 + 4'd1;
    end

    // minutes tens (0→5, +1 every 10 min)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)            min1 <= 4'd0;
        else if (carry_min0)   min1 <= (min1 == 4'd5) ? 4'd0 : min1 + 4'd1;
    end

    // hours (00→23→00 cascade)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hr0 <= 4'd0;
            hr1 <= 4'd0;
        end else if (carry_min1) begin
            if (is_23) begin                   // 23:59 → 00:00
                hr0 <= 4'd0;
                hr1 <= 4'd0;
            end else if (hr0 == 4'd9) begin    // 09:59 → 10:00
                hr0 <= 4'd0;
                hr1 <= hr1 + 4'd1;
            end else begin                     // normal increment
                hr0 <= hr0 + 4'd1;
            end
        end
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

    assign hex3 = seg7(hr1);
    assign hex2 = seg7(hr0);
    assign hex1 = seg7(min1);
    assign hex0 = seg7(min0);

endmodule
