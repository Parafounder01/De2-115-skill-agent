// ============================================================
//  top.v — DE2-115 top-level for Snake Game
//
//  KEY[3:1] = UP, DOWN, LEFT
//  SW[0]    = RIGHT
//  SW[2:1]  = Difficulty: 00=400ms, 01=300ms, 10=200ms, 11=100ms
//  SW[4:3]  = Win length: 00=30, 01=40, 10=50, 11=60
//  SW[5]    = Pause
//  KEY[0]   = Global reset / Start
//  HEX[7:5] = Score (BCD), HEX[4] = blank
//  HEX[3:2] = Snake length
//  HEX[1]   = State code
//  HEX[0]   = Foods eaten (tens)
// ============================================================

module top (
    input  CLOCK_50,
    input  [3:0] KEY,
    input  [17:0] SW,

    output [7:0] VGA_R,
    output [7:0] VGA_G,
    output [7:0] VGA_B,
    output       VGA_HS,
    output       VGA_VS,
    output       VGA_CLK,
    output       VGA_BLANK_N,
    output       VGA_SYNC_N,

    output [6:0] HEX7, HEX6, HEX5, HEX4,
                 HEX3, HEX2, HEX1, HEX0,

    output [17:0] LEDR,
    output [8:0]  LEDG
);

    snake_game u_snake (
        .clk        (CLOCK_50),
        .rst_n      (KEY[0]),
        .key1       (KEY[1]),
        .key2       (KEY[2]),
        .key3       (KEY[3]),
        .sw0        (SW[0]),
        .sw_diff    (SW[2:1]),
        .sw_win     (SW[4:3]),
        .sw5_pause  (SW[5]),

        .vga_r      (VGA_R),
        .vga_g      (VGA_G),
        .vga_b      (VGA_B),
        .vga_hs     (VGA_HS),
        .vga_vs     (VGA_VS),
        .vga_clk    (VGA_CLK),
        .vga_blank_n(VGA_BLANK_N),
        .vga_sync_n (VGA_SYNC_N),

        .hex7       (HEX7),
        .hex6       (HEX6),
        .hex5       (HEX5),
        .hex4       (HEX4),
        .hex3       (HEX3),
        .hex2       (HEX2),
        .hex1       (HEX1),
        .hex0       (HEX0),

        .ledr       (LEDR),
        .ledg       (LEDG)
    );

endmodule
