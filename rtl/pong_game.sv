// Pong game logic for MiSTang. Original implementation. 160x120 logical playfield, one step per `tick`.
module pong_game (
    input  logic       clk, rst, tick,
    input  logic       up, down,            // left paddle (human)
    output logic [39:0] st                   // {bx,by,p1y,p2y,s1,s2}
);
    logic signed [10:0] bx, by, vx, vy;
    logic [7:0] p1y, p2y;
    logic [3:0] s1, s2;
    logic [15:0] rng;
    logic [8:0] idle;
    assign st = {bx[7:0], by[7:0], p1y, p2y, s1, s2};

    function automatic logic signed [10:0] steer(input logic signed [10:0] off);
        if (off < -3) steer = -2; else if (off < 0) steer = -1; else if (off < 4) steer = 1; else steer = 2;
    endfunction

    logic signed [10:0] nx, ny, nvx, nvy, off;
    logic [7:0] np1, np2;
    logic hitl, hitr, miss_l, miss_r;
    always_ff @(posedge clk) begin
        if (rst) begin
            bx <= 78; by <= 58; vx <= 1; vy <= 1; p1y <= 50; p2y <= 50; s1 <= 0; s2 <= 0; rng <= 16'hACE1; idle <= 0;
        end else if (tick) begin
            rng <= {rng[14:0], rng[15] ^ rng[13] ^ rng[12] ^ rng[10]};
            nx = bx + vx; ny = by + vy; nvx = vx; nvy = vy;
            np1 = p1y; np2 = p2y;
            // paddles
            if (up || down) begin
                idle <= 0;
                if (up && p1y > 2) np1 = p1y - 2;
                if (down && p1y < 96) np1 = p1y + 2;
            end else begin
                if (idle != 9'd180) idle <= idle + 9'd1;
                if (idle == 9'd180) begin
                    if (by + 1 < p1y + 8) np1 = (p1y > 2) ? p1y - 1 : p1y;
                    else if (by + 1 > p1y + 12) np1 = (p1y < 98) ? p1y + 1 : p1y;
                end
            end
            if (by + 1 < p2y + 8) np2 = (p2y > 2) ? p2y - 1 : p2y;
            else if (by + 1 > p2y + 12) np2 = (p2y < 98) ? p2y + 1 : p2y;
            p1y <= np1; p2y <= np2;
            // walls
            if (ny < 2)   begin ny = 2;   nvy = (vy < 0) ? -vy : vy; end
            if (ny > 115) begin ny = 115; nvy = (vy > 0) ? -vy : vy; end
            // paddles hit
            hitl = (vx < 0) && (nx <= 9)   && (ny + 3 > np1) && (ny < np1 + 20);
            hitr = (vx > 0) && (nx >= 148) && (ny + 3 > np2) && (ny < np2 + 20);
            if (hitl) begin off = ny + 1 - (np1 + 10); nx = 9;   nvx = (vx < 0) ? -vx : vx; nvy = steer(off); end
            else if (hitr) begin off = ny + 1 - (np2 + 10); nx = 148; nvx = (vx > 0) ? -vx : vx; nvy = steer(off); end
            miss_l = (vx < 0) && !hitl && (nx < 4);
            miss_r = (vx > 0) && !hitr && (nx > 153);
            if (miss_l || miss_r) begin
                if (miss_l) s2 <= (s2 == 4'd9) ? 4'd0 : s2 + 4'd1;
                else        s1 <= (s1 == 4'd9) ? 4'd0 : s1 + 4'd1;
                nx = 78; ny = 58; nvx = miss_l ? 11'sd1 : -11'sd1; nvy = rng[0] ? 11'sd1 : -11'sd1;
            end
            bx <= nx; by <= ny; vx <= nvx; vy <= nvy;
        end
    end
endmodule
