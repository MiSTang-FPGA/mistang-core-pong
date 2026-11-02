#!/usr/bin/env bash
set -e; cd "$(dirname "$0")"; mkdir -p build
TICKS=${TICKS:-900}
iverilog -g2012 -DTICKS=$TICKS -o build/tb.vvp sim/tb_pong.sv rtl/pong_game.sv rtl/pong_pixel.sv
vvp build/tb.vvp >/dev/null
python3 tools/refpong.py $TICKS > build/ref_pong.txt
diff build/ref_pong.txt build/rtl_pong.txt && echo "PASS: RTL playfield == reference after $TICKS ticks"
python3 tools/fb2png.py build/rtl_pong.txt docs/img/sim-pong.png 6
