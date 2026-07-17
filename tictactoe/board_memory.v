// ============================================================
//  board_memory.v — 3×3 Tic-Tac-Toe board
//  9 cells, 2 bits each: 00=empty, 01=X, 10=O
//  Single write port, combinational read port
// ============================================================

module board_memory (
    input  clk,
    input  rst_n,
    input  [3:0] addr_w,     // cell to write (0-8), 9=no write
    input  [1:0] data_w,     // 00=empty, 01=X, 10=O
    input  we,               // write enable

    input  [3:0] addr_a,     // read address A (0-8)
    input  [3:0] addr_b,     // read address B (0-8)
    output [1:0] data_a,     // read data A
    output [1:0] data_b,     // read data B

    output [17:0] board_out  // all 9 cells packed: cell0=bits[1:0], cell1=bits[3:2], ...
);

    reg [1:0] mem [0:8];     // 9 cells, 2 bits each

    // Write
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 9; i = i + 1) mem[i] <= 2'b00;
        end else begin
            if (we && addr_w < 9) mem[addr_w] <= data_w;
        end
    end

    // Combinational read
    assign data_a = (addr_a < 9) ? mem[addr_a] : 2'b00;
    assign data_b = (addr_b < 9) ? mem[addr_b] : 2'b00;

    // Packed board output
    assign board_out = {
        mem[8], mem[7], mem[6], mem[5], mem[4],
        mem[3], mem[2], mem[1], mem[0]
    };

endmodule
