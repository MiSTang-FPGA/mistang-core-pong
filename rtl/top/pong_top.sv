// MiSTang Pong: 720p60 HDMI (160x120 at 6x, centred), S1/S2 move the left paddle, UART screenshot stream.
module pong_top (
    input  logic       sys_clk, s1, s2,
    output logic [1:0] led,
    output logic       uart_tx,
    input  logic       uart_rx,
    output logic       tmds_clk_p, tmds_clk_n,
    output logic [2:0] tmds_d_p, tmds_d_n
);
    logic clk_p5, clk_p, hdmi_lock;
    pll_hdmi u_pll (.clock_in(sys_clk), .clock_out(clk_p5), .locked(hdmi_lock));
    CLKDIV #(.DIV_MODE("5")) u_div5 (.CLKOUT(clk_p), .HCLKIN(clk_p5), .RESETN(hdmi_lock), .CALIB(1'b0));
    logic [3:0] rst_cnt = 0; logic reset = 1;
    always_ff @(posedge clk_p) begin
        if (!hdmi_lock) rst_cnt <= 0; else if (rst_cnt != 4'hf) rst_cnt <= rst_cnt + 1'd1;
        reset <= rst_cnt != 4'hf;
    end
    logic [10:0] cx; logic [9:0] cy; logic [23:0] rgb;

    // game on the 27 MHz clock (its logic is slow), one step per 1/60 s; video reads a copy of the state on the pixel clock
    logic [7:0] g_rst_cnt = 0; logic g_rst = 1;
    always_ff @(posedge sys_clk) begin if (g_rst_cnt != 8'hff) g_rst_cnt <= g_rst_cnt + 1'd1; g_rst <= (g_rst_cnt != 8'hff); end
    logic [18:0] t60 = 0; logic tick;
    always_ff @(posedge sys_clk) begin tick <= (t60 == 19'd449999); t60 <= (t60 == 19'd449999) ? 19'd0 : t60 + 19'd1; end
    logic s1_q, s2_q; always_ff @(posedge sys_clk) begin s1_q <= s1; s2_q <= s2; end
    logic [39:0] st;
    pong_game u_game (.clk(sys_clk), .rst(g_rst), .tick(tick), .up(s1_q), .down(s2_q), .st(st));
    logic [39:0] st_v; always_ff @(posedge clk_p) if (cx == 11'd0 && cy == 10'd0) st_v <= st;

    // video: counters walk the 160x120 playfield, each logical pixel is 6x6 screen pixels
    logic [7:0] lx = 0; logic [6:0] ly = 0; logic [2:0] sx = 0, sy = 0; logic in_x = 0;
    always_ff @(posedge clk_p) begin
        if (cx == 11'd159) begin lx <= 0; sx <= 0; in_x <= 1'b1; end
        else if (cx == 11'd1119) in_x <= 1'b0;
        else if (in_x) begin
            if (sx == 3'd5) begin sx <= 0; lx <= lx + 8'd1; end else sx <= sx + 3'd1;
        end
        if (cx == 11'd0) begin
            if (cy == 10'd0) begin ly <= 0; sy <= 0; end
            else if (sy == 3'd5) begin sy <= 0; ly <= ly + 7'd1; end
            else sy <= sy + 3'd1;
        end
    end
    wire in_y = (cy < 10'd720);
    logic px; pong_pixel u_px (.x(lx), .y(ly), .st(st_v), .px(px));
    logic box_d;
    always_ff @(posedge clk_p) begin box_d <= in_x && in_y; rgb <= !box_d ? 24'h000000 : px ? 24'hE8E8E8 : 24'h0B0B0B; end

    logic [2:0] tmds; logic tmds_clock; logic [15:0] silence [1:0];
    initial begin silence[0] = 0; silence[1] = 0; end
    logic [10:0] aud_div = 0; logic clk_audio = 0;
    always_ff @(posedge clk_p) if (aud_div == 11'd773) begin aud_div <= 0; clk_audio <= ~clk_audio; end else aud_div <= aud_div + 1'd1;
    hdmi #(.VIDEO_ID_CODE(4), .DVI_OUTPUT(0), .VIDEO_REFRESH_RATE(60.0), .AUDIO_RATE(48000), .AUDIO_BIT_WIDTH(16),
           .VENDOR_NAME({"MiSTang", 8'd0}), .PRODUCT_DESCRIPTION({"TangNano20K", 40'd0})) u_hdmi (
        .clk_pixel_x5(clk_p5), .clk_pixel(clk_p), .clk_audio(clk_audio), .reset(reset),
        .rgb(rgb), .audio_sample_word(silence), .tmds(tmds), .tmds_clock(tmds_clock),
        .cx(cx), .cy(cy), .frame_width(), .frame_height(), .screen_width(), .screen_height());
    TLVDS_OBUF u_obuf [3:0] (.I({tmds_clock, tmds}), .O({tmds_clk_p, tmds_d_p}), .OB({tmds_clk_n, tmds_d_n}));

    // UART screenshot: "PONG" + 2400 bytes (160x120, 8 px per byte MSB first); state snapshot taken per frame
    logic [7:0] tx_data; logic tx_start, tx_busy;
    uart_tx #(.DIV(234)) u_tx (.clk(sys_clk), .data(tx_data), .start(tx_start), .busy(tx_busy), .tx(uart_tx));
    logic [39:0] snap = 0;
    logic [14:0] pi = 0; logic [2:0] bit_i = 0; logic [7:0] acc = 0; logic [2:0] hi = 0;
    logic [7:0] ux; logic [6:0] uy; logic upx;
    pong_pixel u_upx (.x(ux), .y(uy), .st(snap), .px(upx));
    typedef enum logic [1:0] {U_HDR, U_PIX, U_SEND} u_t; u_t us = U_HDR;
    wire tx_ready = !tx_busy && !tx_start;
    always_comb begin ux = pi % 160; uy = pi / 160; end
    always_ff @(posedge sys_clk) begin
        tx_start <= 1'b0;
        case (us)
            U_HDR: if (tx_ready) begin
                if (hi == 0) snap <= st;
                tx_data <= (hi == 0) ? "P" : (hi == 1) ? "O" : (hi == 2) ? "N" : "G"; tx_start <= 1'b1;
                if (hi == 3) begin hi <= 0; pi <= 0; bit_i <= 0; us <= U_PIX; end else hi <= hi + 3'd1;
            end
            U_PIX: begin
                acc <= {acc[6:0], upx}; pi <= pi + 15'd1; bit_i <= bit_i + 3'd1;
                if (bit_i == 3'd7) us <= U_SEND;
            end
            U_SEND: if (tx_ready) begin
                tx_data <= acc; tx_start <= 1'b1;
                if (pi == 15'd19200) us <= U_HDR; else us <= U_PIX;
            end
            default: us <= U_HDR;
        endcase
    end
    logic [24:0] hb = 0; always_ff @(posedge sys_clk) hb <= hb + 1'd1;
    assign led = {~hdmi_lock, ~hb[24]};
endmodule
