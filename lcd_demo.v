// ============================================================
//  lcd_demo.v — DE2-115 16x2 LCD Message Display
//
//  Line 1: "hello           "
//  Line 2: "Dr.Sugantha mam "
//
//  Drives the HD44780-compatible LCD module in 8-bit mode.
//  Uses a single 100ms tick for all timing.
// ============================================================

module lcd_demo (
    input  clk,           // 50 MHz (PIN_Y2)

    // LCD control
    output [7:0] lcd_data,
    output       lcd_rs,   // 0=command, 1=data
    output       lcd_rw,   // 0=write, 1=read
    output       lcd_en,   // enable strobe
    output       lcd_on,   // backlight power
    output       lcd_blon,  // backlight on

    // Half-adder inputs
    input  sw17,         // SW17 — A
    input  sw16,         // SW16 — B

    // Dancing LEDs + half-adder outputs
    output [17:0] ledr,

    // HEX clock display (24h HH:MM:SS)
    output [6:0] hex7, hex6, hex5, hex4,
                 hex3, hex2, hex1, hex0
);

    // Half adder
    wire ha_sum   = sw17 ^ sw16;
    wire ha_carry = sw17 & sw16;

    assign lcd_on  = 1'b1;
    assign lcd_blon = 1'b1;
    assign lcd_rw  = 1'b0;   // always write

    // ============================================================
    //  100 ms tick generator (resets at 4,999,999 for true 100ms)
    // ============================================================
    reg [22:0] tick_cnt;
    wire tick_100ms;
    always @(posedge clk) begin
        if (tick_cnt == 23'd4_999_999) begin tick_cnt <= 23'd0; end
        else tick_cnt <= tick_cnt + 23'd1;
    end
    assign tick_100ms = (tick_cnt == 23'd4_999_999);

    // ============================================================
    //  Character ROM: 32 bytes (two 16-char lines)
    // ============================================================
    reg [7:0] char_rom [0:31];
    reg [4:0] char_idx;

    initial begin
        char_rom[0]  = "h"; char_rom[1]  = "e"; char_rom[2]  = "l";
        char_rom[3]  = "l"; char_rom[4]  = "o"; char_rom[5]  = " ";
        char_rom[6]  = " "; char_rom[7]  = " "; char_rom[8]  = " ";
        char_rom[9]  = " "; char_rom[10] = " "; char_rom[11] = " ";
        char_rom[12] = " "; char_rom[13] = " "; char_rom[14] = " ";
        char_rom[15] = " ";
        char_rom[16] = "D"; char_rom[17] = "r"; char_rom[18] = ".";
        char_rom[19] = "S"; char_rom[20] = "u"; char_rom[21] = "g";
        char_rom[22] = "a"; char_rom[23] = "n"; char_rom[24] = "t";
        char_rom[25] = "h"; char_rom[26] = "a"; char_rom[27] = " ";
        char_rom[28] = "m"; char_rom[29] = "a"; char_rom[30] = "m";
        char_rom[31] = " ";
    end

    // ============================================================
    //  LCD data & control registered outputs
    // ============================================================
    reg [7:0] lcd_dout;
    reg       lcd_rs_r;

    assign lcd_data = lcd_dout;
    assign lcd_rs   = lcd_rs_r;

    // ============================================================
    //  EN strobe: pulse high for ~400ns (20 cycles)
    // ============================================================
    reg [5:0] strobe;
    reg       lcd_en_r;
    assign lcd_en = lcd_en_r;

    // ============================================================
    //  Main LCD state machine
    //  Steps execute on every tick_100ms (100ms interval).
    //  EN strobe is generated within each step.
    // ============================================================
    reg [4:0] step;  // which step we're on

    localparam ST_INIT     = 5'd0;
    localparam ST_FUNC1    = 5'd1;
    localparam ST_FUNC2    = 5'd2;
    localparam ST_FUNC3    = 5'd3;
    localparam ST_DISP_OFF = 5'd4;
    localparam ST_DISP_CLR = 5'd5;
    localparam ST_ENTRY    = 5'd6;
    localparam ST_DISP_ON  = 5'd7;
    localparam ST_ADDR1    = 5'd8;
    localparam ST_LOOP1    = 5'd9;
    localparam ST_ADDR2    = 5'd10;
    localparam ST_LOOP2    = 5'd11;
    localparam ST_DONE     = 5'd12;

    // Sub-state within each step: 0=set up data, 1=strobe high, 2=strobe low, 3=done
    reg [1:0] sub;

    always @(posedge clk) begin
        if (tick_100ms) begin
            // ── Next step every 100ms ──
            case (step)
                ST_INIT: begin step <= ST_FUNC1; lcd_dout <= 8'h38; lcd_rs_r <= 1'b0; end
                ST_FUNC1: begin step <= ST_FUNC2; lcd_dout <= 8'h38; lcd_rs_r <= 1'b0; end
                ST_FUNC2: begin step <= ST_FUNC3; lcd_dout <= 8'h38; lcd_rs_r <= 1'b0; end
                ST_FUNC3: begin step <= ST_DISP_OFF; lcd_dout <= 8'h08; lcd_rs_r <= 1'b0; end
                ST_DISP_OFF: begin step <= ST_DISP_CLR; lcd_dout <= 8'h01; lcd_rs_r <= 1'b0; end
                ST_DISP_CLR: begin step <= ST_ENTRY; lcd_dout <= 8'h06; lcd_rs_r <= 1'b0; end
                ST_ENTRY: begin step <= ST_DISP_ON; lcd_dout <= 8'h0C; lcd_rs_r <= 1'b0; end
                ST_DISP_ON: begin step <= ST_ADDR1; lcd_dout <= 8'h80; lcd_rs_r <= 1'b0; end

                ST_ADDR1: begin
                    step  <= ST_LOOP1;
                    char_idx <= 0;
                    lcd_dout <= char_rom[0];
                    lcd_rs_r <= 1'b1;
                end

                ST_LOOP1: begin
                    if (char_idx == 5'd15) begin
                        step <= ST_ADDR2;
                        lcd_dout <= 8'hC0;
                        lcd_rs_r <= 1'b0;
                    end else begin
                        char_idx <= char_idx + 5'd1;
                        lcd_dout <= char_rom[char_idx + 5'd1];
                        lcd_rs_r <= 1'b1;
                    end
                end

                ST_ADDR2: begin
                    step  <= ST_LOOP2;
                    char_idx <= 5'd16;
                    lcd_dout <= char_rom[5'd16];
                    lcd_rs_r <= 1'b1;
                end

                ST_LOOP2: begin
                    if (char_idx == 5'd31) begin
                        step <= ST_DONE;
                    end else begin
                        char_idx <= char_idx + 5'd1;
                        lcd_dout <= char_rom[char_idx + 5'd1];
                        lcd_rs_r <= 1'b1;
                    end
                end

                ST_DONE: begin
                    // Stay here — message displayed
                end
            endcase
        end

        // ── EN strobe: run independently within each 100ms step ──
        //  strobe counter: 0=idle, 1-20=high, 21-40=low
        if (tick_100ms) begin
            strobe <= 0;
            lcd_en_r <= 1'b0;
        end else if (step != ST_DONE) begin
            if (strobe < 6'd20) begin
                lcd_en_r <= 1'b1;
                strobe <= strobe + 6'd1;
            end else if (strobe < 6'd40) begin
                lcd_en_r <= 1'b0;
                strobe <= strobe + 6'd1;
            end
        end
    end

    // ============================================================
    //  24h HH:MM:SS Clock on HEX7-HEX0
    // ============================================================
    reg [3:0]  sec_tick;
    reg [5:0]  sec;
    reg [5:0]  min;
    reg [4:0]  hour;

    // Power-up at 4:32 PM
    initial begin
        hour = 5'd16;
        min  = 6'd32;
        sec  = 6'd0;
    end

    // 1-second tick from 100ms tick (10 counts)
    always @(posedge clk) begin
        if (tick_100ms) begin
            if (sec_tick == 2'd9) begin sec_tick <= 0;
                if (sec == 6'd59) begin sec <= 0;
                    if (min == 6'd59) begin min <= 0;
                        if (hour == 5'd23) hour <= 0;
                        else hour <= hour + 1;
                    end else min <= min + 1;
                end else sec <= sec + 1;
            end else sec_tick <= sec_tick + 1;
        end
    end

    // 7-segment decoder
    function [6:0] seg7(input [3:0] v);
        case (v)
            4'd0: seg7 = 7'b1000000; 4'd1: seg7 = 7'b1111001;
            4'd2: seg7 = 7'b0100100; 4'd3: seg7 = 7'b0110000;
            4'd4: seg7 = 7'b0011001; 4'd5: seg7 = 7'b0010010;
            4'd6: seg7 = 7'b0000010; 4'd7: seg7 = 7'b1111000;
            4'd8: seg7 = 7'b0000000; 4'd9: seg7 = 7'b0010000;
            default: seg7 = 7'b1111111;
        endcase
    endfunction

    // Colon flash on HEX6 (second dot) and HEX4 (minute dot)
    wire colon_on = sec[0];  // blink every second

    assign hex7 = seg7(hour / 10);
    assign hex6 = seg7(hour % 10) & {colon_on ? 7'b0111111 : 7'b1111111};
    assign hex5 = seg7(min  / 10);
    assign hex4 = seg7(min  % 10) & 7'b0111111;  // always on
    assign hex3 = seg7(sec  / 10);
    assign hex2 = seg7(sec  % 10);
    assign hex1 = 7'b1111111;  // blank
    assign hex0 = 7'b1111111;  // blank

    // ============================================================
    //  Dancing LED — bounces a single lit LED across LEDR[15:0]
    //  Half adder (SW17^SW16) drives LEDR[17:16]
    // ============================================================
    reg [24:0] dance_cnt;
    reg [15:0] ledr_r;
    reg        dance_dir;  // 0=toward 15, 1=toward 0
    localparam DANCE_STEP = 25'd1_500_000;  // 30ms @ 50 MHz

    assign ledr[17]   = ha_carry;   // carry
    assign ledr[16]   = ha_sum;     // sum
    assign ledr[15:0] = ledr_r;

    initial begin
        dance_cnt <= 25'd0;
        ledr_r    <= 16'h0001;
        dance_dir <= 1'b0;
    end

    always @(posedge clk) begin
        if (dance_cnt >= DANCE_STEP) begin
            dance_cnt <= 25'd0;
            if (dance_dir == 1'b0) begin
                if (ledr_r[15]) begin dance_dir <= 1'b1; ledr_r <= ledr_r >> 1; end
                else ledr_r <= ledr_r << 1;
            end else begin
                if (ledr_r[0]) begin dance_dir <= 1'b0; ledr_r <= ledr_r << 1; end
                else ledr_r <= ledr_r >> 1;
            end
        end else begin
            dance_cnt <= dance_cnt + 25'd1;
        end
    end

endmodule
