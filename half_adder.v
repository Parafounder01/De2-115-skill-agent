// ============================================================
//  half_adder.v — DE2-115 Half Adder (standalone)
//
//  A = SW17, B = SW16
//  Sum   = A ^ B  -> LEDR17
//  Carry = A & B  -> LEDR16
// ============================================================

module half_adder (
    input  sw17,   // SW17 — A (PIN_V23)
    input  sw16,   // SW16 — B (PIN_V24)

    output [17:0] ledr
);

    assign ledr[17]   = sw17 & sw16;   // Carry
    assign ledr[16]   = sw17 ^ sw16;   // Sum
    assign ledr[15:0] = 18'b0;         // rest off

endmodule
