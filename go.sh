#!/bin/sh

./mads starter.asm -o:starter.bin
./build

gcc -Wall -o atrsd2car atrsd2car.c
./atrsd2car SilentService.atr SilentService.car -c
