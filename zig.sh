#!/bin/bash
mkdir -p /opt/zig
cd /opt/zig
git clone https://codeberg.org/ziglang/zig.git
cd zig
mkdir build
cd build
cmake ..
make install
