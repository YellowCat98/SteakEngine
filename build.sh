#!/bin/bash

if ! command -v cmake &> /dev/null
then
    echo "Installing CMake...\n"
    brew install cmake
fi

git clone https://github.com/YellowCat98/lua-ios.git lib/lua

cmake -S . -B build -G Xcode
if [ $? -eq 0 ]; then
    cmake --build build --config Release
fi