#!/bin/bash

set -e

mkdir -p build

echo "[1/3] Synthesizing hardware with Yosys..."
yosys -p "synth_ice40 -top top -json build/vDAC_streamer.json" src/soc_pkg.sv src/uart_tx.sv src/top.sv

echo "[2/3] Place and route with nextpnr..."
nextpnr-ice40 --lp1k --package cm36 --pcf src/icesugar_nano.pcf --json build/vDAC_streamer.json --asc build/vDAC_streamer.asc

echo "[3/3] Generating bitstream..."
icepack build/vDAC_streamer.asc build/vDAC_streamer.bin

echo "Build complete! Bitstream ready at build/vDAC_streamer.bin"
