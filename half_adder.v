// ============================================================
//  half_adder.v — DE2-115 Sequential Half Adder
//
//  A = SW17, B = SW16
//  Sum   = A ^ B  -> LEDR16
//  Carry = A & B  -> LEDR17
//
//  Outputs are registered on the 50 MHz clock edge.
// ============================================================

module half_adder (
    input  clk,      // 50 MHz (PIN_Y2)
    input  sw17,     // SW17 — A (PIN_V23)
    input  sw16,     // SW16 — B (PIN_V24)

    output [17:0] ledr
);

    reg sum_r;    // registered sum
    reg carry_r;  // registered carry

    always @(posedge clk) begin
        sum_r   <= sw17 ^ sw16;
        carry_r <= sw17 & sw16;
    end

    // Single clean assignment: carry -> LEDR17, sum -> LEDR16, rest off
    assign ledr = { carry_r, sum_r, 16'b0 };

endmodule
