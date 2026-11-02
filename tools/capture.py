#!/usr/bin/env python3
"""Screenshot over the board's USB-UART: 'PONG' + 2400 bytes (160x120, 1 bit/px). usage: capture.py /dev/cu.usbserial-XXXX out.png"""
import os, sys, termios, time, subprocess
fd = os.open(sys.argv[1], os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
a = termios.tcgetattr(fd); a[0]=0; a[1]=0; a[2]=termios.CS8|termios.CREAD|termios.CLOCAL; a[3]=0
a[4]=a[5]=termios.B115200; a[6][termios.VMIN]=0; a[6][termios.VTIME]=0; termios.tcsetattr(fd, termios.TCSANOW, a)
buf = b''; t = time.time()
while time.time() - t < 8:
    try: buf += os.read(fd, 8192)
    except BlockingIOError: time.sleep(0.02)
    i = buf.find(b'PONG')
    if i >= 0 and len(buf) >= i + 2404:
        pkt = buf[i+4:i+2404]
        lines = [''.join('#' if (pkt[(r*160+c)//8] >> (7-(r*160+c)%8)) & 1 else '.' for c in range(160)) for r in range(120)]
        txt = os.path.splitext(sys.argv[2])[0] + '.txt'
        open(txt, 'w').write('\n'.join(lines) + '\n')
        subprocess.run([sys.executable, os.path.join(os.path.dirname(os.path.abspath(__file__)), 'fb2png.py'), txt, sys.argv[2], '6'], check=True)
        print('captured'); sys.exit(0)
print('no frame, got', len(buf), 'bytes'); sys.exit(1)
