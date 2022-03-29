#!/bin/sh

mads starter.asm -o:starter.bin
xxd -i starter.bin > starter.h
gcc -Wall -o atrsd2car atrsd2car.c
atrsd2car test.atr test.car -c
