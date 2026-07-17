// ============================================================
//  vga_sync.v — 640x480 @ 60Hz VGA sync generator
//  Input:  clk25 (25 MHz pixel clock)
//  Outputs: hsync, vsync, blank_n, hcount[9:0], vcount[9:0]
// ============================================================

module vga_sync (
    input  clk25,
    input  rst_n,
    output reg       hsync,
    output reg       vsync,
    output reg       blank_n,
    output reg [9:0] hcount,
    output reg [9:0] vcount
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

    // Horizontal counter
    always @(posedge clk25 or negedge rst_n) begin
        if (!rst_n) begin
            hcount <= 0;
            hsync  <= 1;
        end else begin
            if (hcount == H_TOTAL - 1)
                hcount <= 0;
            else
                hcount <= hcount + 1;

            if (hcount >= H_DISP + H_FP - 1 &&
                hcount <  H_DISP + H_FP + H_SYNC - 1)
                hsync <= 0;
            else
                hsync <= 1;
        end
    end

    // Vertical counter
    always @(posedge clk25 or negedge rst_n) begin
        if (!rst_n) begin
            vcount <= 0;
            vsync  <= 1;
        end else begin
            if (hcount == H_TOTAL - 1) begin
                if (vcount == V_TOTAL - 1)
                    vcount <= 0;
                else
                    vcount <= vcount + 1;
            end

            if (vcount >= V_DISP + V_FP - 1 &&
                vcount <  V_DISP + V_FP + V_SYNC - 1)
                vsync <= 0;
            else
                vsync <= 1;
        end
    end

    always @(*) begin
        blank_n = (hcount < H_DISP && vcount < V_DISP);
    end

endmodule
