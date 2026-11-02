#!/usr/bin/env python3
"""Independent reference for pong_game: prints the playfield after N ticks as 120 lines of 160 chars (no input)."""
import sys
def run(n):
    bx,by,vx,vy,p1,p2,s1,s2,rng,idle=78,58,1,1,50,50,0,0,0xACE1,0
    steer=lambda o: -2 if o<-3 else -1 if o<0 else 1 if o<4 else 2
    for _ in range(n):
        rng=((rng<<1)&0xFFFF)|(((rng>>15)^(rng>>13)^(rng>>12)^(rng>>10))&1)
        nx,ny,nvx,nvy=bx+vx,by+vy,vx,vy
        np1,np2=p1,p2
        ai=(idle==180)
        if idle!=180: idle+=1
        if ai:
            if by+1<p1+8: np1=p1-1 if p1>2 else p1
            elif by+1>p1+12: np1=p1+1 if p1<98 else p1
        if by+1<p2+8: np2=p2-1 if p2>2 else p2
        elif by+1>p2+12: np2=p2+1 if p2<98 else p2
        p1,p2=np1,np2
        if ny<2: ny=2; nvy=abs(vy)
        if ny>115: ny=115; nvy=-abs(vy)
        hl=vx<0 and nx<=9 and ny+3>np1 and ny<np1+20
        hr=vx>0 and nx>=148 and ny+3>np2 and ny<np2+20
        if hl: nx=9; nvx=abs(vx); nvy=steer(ny+1-(np1+10))
        elif hr: nx=148; nvx=-abs(vx); nvy=steer(ny+1-(np2+10))
        ml=vx<0 and not hl and nx<4; mr=vx>0 and not hr and nx>153
        if ml or mr:
            if ml: s2=(s2+1)%10
            else: s1=(s1+1)%10
            nx,ny=78,58; nvx=1 if ml else -1; nvy=1 if rng&1 else -1
        bx,by,vx,vy=nx,ny,nvx,nvy
    return bx,by,p1,p2,s1,s2
G={0:"111101101101111",1:"010110010010111",2:"111001111100111",3:"111001111001111",4:"101101111001001",5:"111100111001111",6:"111100111101111",7:"111001001001001",8:"111101111101111",9:"111101111001111"}
def frame(st):
    bx,by,p1,p2,s1,s2=st; out=[]
    for y in range(120):
        row=''
        for x in range(160):
            on = y<2 or y>=118 or (x in(79,80) and (y>>2)&1) or (6<=x<9 and p1<=y<p1+20) or (151<=x<154 and p2<=y<p2+20) or (bx<=x<bx+3 and by<=y<by+3)
            for d,x0 in ((s1,56),(s2,92)):
                if 6<=y<26 and x0<=x<x0+12:
                    gx,gy=(x-x0)//4,(y-6)//4
                    if gx<3 and gy<5 and G[d][gy*3+gx]=='1': on=True
            row+='#' if on else '.'
        out.append(row)
    return out
if __name__=='__main__':
    st=run(int(sys.argv[1])); print('\n'.join(frame(st)))
