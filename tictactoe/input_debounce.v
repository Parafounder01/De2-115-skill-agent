// ============================================================
//  input_debounce.v — Key/switch debounce module
//  Debounce time: ~10 ms at 50 MHz (500,000 cycles)
//  Works for active-low keys and active-high switches
// ============================================================

module input_debounce (
    input  clk,        // 50 MHz
    input  rst_n,      // system reset
    input  raw,        // raw input
    output level,      // debounced level
    output rising,     // rising edge detected (1 cycle pulse)
    output falling     // falling edge detected (1 cycle pulse)
);

    reg [18:0] cnt;
    reg        stable;
    reg        prev;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin cnt <= 0; stable <= 0; prev <= 0; end
        else begin
            prev <= stable;
            if (raw != stable) begin
                if (cnt == 19'd500_000) begin stable <= raw; cnt <= 0; end
                else cnt <= cnt + 1;
            end else cnt <= 0;
        end
    end

    assign level   = stable;
    assign rising  =  stable & ~prev;
    assign falling = ~stable &  prev;

endmodule
