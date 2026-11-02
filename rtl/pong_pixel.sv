// Monochrome pixel of the playfield. x 0..159, y 0..119, st from pong_game.
module pong_pixel (input logic [7:0] x, input logic [6:0] y, input logic [39:0] st, output logic px);
    wire [7:0] bx = st[39:32], by = st[31:24], p1y = st[23:16], p2y = st[15:8];
    wire [3:0] s1 = st[7:4], s2 = st[3:0];
    function automatic logic [14:0] glyph(input logic [3:0] d);   // 3x5, row-major, MSB = top-left
        case (d)
            0: glyph = 15'b111_101_101_101_111; 1: glyph = 15'b010_110_010_010_111;
            2: glyph = 15'b111_001_111_100_111; 3: glyph = 15'b111_001_111_001_111;
            4: glyph = 15'b101_101_111_001_001; 5: glyph = 15'b111_100_111_001_111;
            6: glyph = 15'b111_100_111_101_111; 7: glyph = 15'b111_001_001_001_001;
            8: glyph = 15'b111_101_111_101_111; default: glyph = 15'b111_101_111_001_111;
        endcase
    endfunction
    // score digits: scale 4, left at x 56, right at x 92, y 6
    logic [7:0] dx; logic [6:0] dy; logic [3:0] dd; logic indig;
    always_comb begin
        indig = 0; dx = 0; dy = 0; dd = 0;
        if (y >= 6 && y < 26) begin
            dy = y - 7'd6;
            if (x >= 56 && x < 68) begin indig = 1; dx = x - 8'd56; dd = s1; end
            else if (x >= 92 && x < 104) begin indig = 1; dx = x - 8'd92; dd = s2; end
        end
    end
    wire [2:0] gx = dx[3:2]; wire [2:0] gy = dy[4:2];
    wire [14:0] g = glyph(dd);
    wire dig_on = indig && (gx < 3) && (gy < 5) && g[14 - (gy * 3 + gx)];
    wire wall   = (y < 2) || (y >= 118);
    wire net    = (x == 79 || x == 80) && y[2];
    wire pad1   = (x >= 6 && x < 9)     && (y >= p1y) && (y < p1y + 20);
    wire pad2   = (x >= 151 && x < 154) && (y >= p2y) && (y < p2y + 20);
    wire ball   = (x >= bx) && (x < bx + 3) && (y >= by) && (y < by + 3);
    assign px = wall | net | pad1 | pad2 | ball | dig_on;
endmodule
