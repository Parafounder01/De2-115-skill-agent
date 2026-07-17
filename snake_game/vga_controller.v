// ============================================================
//  vga_controller.v — 640×480 @ 60Hz VGA sync generator
//  Input:  clk25 (25 MHz pixel clock)
//  Outputs: hsync, vsync, blank_n, x[9:0], y[9:0]
// ============================================================

module vga_controller (
    input  clk25,
    input  rst_n,
    output reg       hsync,
    output reg       vsync,
    output reg       blank_n,
    output reg [9:0] x,
    output reg [9:0] y
);

    parameter H_DISP  = 640;
    parameter H_FP    = 16;
    parameter H_SYNC  = 96;
    parameter H_BP    = 48;
    parameter H_TOTAL = 800;

    parameter V_DISP  = 480;
    parameter V_FP    = 10;
    parameter V_SYNC  = 2;
    parameter V_BP    = 33;
    parameter V_TOTAL = 525;

    // Horizontal
    always @(posedge clk25 or negedge rst_n) begin
        if (!rst_n) begin x <= 0; hsync <= 1; end
        else begin
            if (x == H_TOTAL - 1) x <= 0; else x <= x + 1;
            hsync <= ~(x >= H_DISP + H_FP - 1 && x < H_DISP + H_FP + H_SYNC - 1);
        end
    end

    // Vertical
    always @(posedge clk25 or negedge rst_n) begin
        if (!rst_n) begin y <= 0; vsync <= 1; end
        else begin
            if (x == H_TOTAL - 1) begin
                if (y == V_TOTAL - 1) y <= 0; else y <= y + 1;
            end
            vsync <= ~(y >= V_DISP + V_FP - 1 && y < V_DISP + V_FP + V_SYNC - 1);
        end
    end

    // Blank
    always @(*) begin blank_n = (x < H_DISP && y < V_DISP); end

endmodule
