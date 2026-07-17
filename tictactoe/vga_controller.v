// ============================================================
//  vga_controller.v — 640×480 @ 60 Hz VGA sync generator
//  Input:  clk_25 (25 MHz pixel clock)
//  Outputs: hsync, vsync, blank_n, x[9:0], y[9:0]
// ============================================================

module vga_controller (
    input  clk_25,
    input  rst_n,
    output reg       hsync,
    output reg       vsync,
    output reg       blank_n,
    output reg [9:0] x,
    output reg [9:0] y
);

    // Horizontal timing: 640 visible + 16 FP + 96 sync + 48 BP = 800
    parameter H_DISP  = 640;
    parameter H_FP    = 16;
    parameter H_SYNC  = 96;
    parameter H_BP    = 48;
    parameter H_TOTAL = 800;
    parameter H_SYNC_START = H_DISP + H_FP - 1;
    parameter H_SYNC_END   = H_DISP + H_FP + H_SYNC - 1;

    // Vertical timing: 480 visible + 10 FP + 2 sync + 33 BP = 525
    parameter V_DISP  = 480;
    parameter V_FP    = 10;
    parameter V_SYNC  = 2;
    parameter V_BP    = 33;
    parameter V_TOTAL = 525;
    parameter V_SYNC_START = V_DISP + V_FP - 1;
    parameter V_SYNC_END   = V_DISP + V_FP + V_SYNC - 1;

    // Horizontal counter
    always @(posedge clk_25 or negedge rst_n) begin
        if (!rst_n) begin x <= 0; hsync <= 1; end
        else begin
            if (x == H_TOTAL - 1) x <= 0; else x <= x + 1;
            hsync <= ~(x >= H_SYNC_START && x < H_SYNC_END);
        end
    end

    // Vertical counter
    always @(posedge clk_25 or negedge rst_n) begin
        if (!rst_n) begin y <= 0; vsync <= 1; end
        else begin
            if (x == H_TOTAL - 1) begin
                if (y == V_TOTAL - 1) y <= 0; else y <= y + 1;
            end
            vsync <= ~(y >= V_SYNC_START && y < V_SYNC_END);
        end
    end

    // Blank: visible when x < 640 and y < 480
    always @(*) begin
        blank_n = (x < H_DISP && y < V_DISP);
    end

endmodule
