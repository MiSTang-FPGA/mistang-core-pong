`timescale 1ns/1ps
module pll_hdmi(input clock_in, output reg clock_out, output locked); initial clock_out=0; always #1.346 clock_out=~clock_out; assign locked=1; endmodule
module CLKDIV #(parameter DIV_MODE="5")(output reg CLKOUT, input HCLKIN, input RESETN, input CALIB); initial CLKOUT=0; always #6.73 CLKOUT=~CLKOUT; endmodule
module TLVDS_OBUF(input I, output O, output OB); assign O=I; assign OB=~I; endmodule
module hdmi #(parameter VIDEO_ID_CODE=4, parameter DVI_OUTPUT=0, parameter VIDEO_REFRESH_RATE=60, parameter AUDIO_RATE=48000, parameter AUDIO_BIT_WIDTH=16, parameter VENDOR_NAME=0, parameter PRODUCT_DESCRIPTION=0)
 (input clk_pixel_x5, input clk_pixel, input clk_audio, input reset, input [23:0] rgb, input [15:0] audio_sample_word [1:0], output [2:0] tmds, output tmds_clock, output reg [10:0] cx, output reg [9:0] cy, output [10:0] frame_width, output [10:0] frame_height, output [10:0] screen_width, output [10:0] screen_height);
 assign tmds=0; assign tmds_clock=0; initial begin cx=0; cy=0; end
 always @(posedge clk_pixel) begin cx<=cx+1; if (cx==1649) begin cx<=0; cy<=cy+1; if (cy==749) cy<=0; end end
endmodule
module tb_top;
  logic clk=0; always #18.5 clk=~clk;
  wire tx; wire [1:0] led; wire [2:0] a,b; wire c,d;
  pong_top dut(.sys_clk(clk), .s1(1'b0), .s2(1'b0), .led(led), .uart_tx(tx), .uart_rx(1'b1), .tmds_clk_p(c), .tmds_clk_n(d), .tmds_d_p(a), .tmds_d_n(b));
  integer n=0, i, f, k; reg [7:0] r; reg [7:0] mem [0:2403];
  initial begin
    forever begin
      @(negedge tx); #(8680/2); #8680;
      for (i=0;i<8;i++) begin r[i]=tx; #8680; end
      mem[n]=r; n++;
      if (n==2404) begin
        $display("header %c%c%c%c", mem[0], mem[1], mem[2], mem[3]);
        f=$fopen("build/uart_pong.txt","w");
        for (k=0;k<19200;k++) begin
          $fwrite(f, "%s", mem[4+k/8][7-(k%8)] ? "#" : ".");
          if (k%160==159) $fwrite(f, "\n");
        end
        $fclose(f); $finish;
      end
    end
  end
  initial begin #400000000; $display("timeout, bytes=%0d", n); $finish; end
endmodule
