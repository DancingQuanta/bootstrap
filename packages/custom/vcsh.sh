#!/usr/bin/env sh
git clone https://github.com/RichiH/vcsh vcsh
cd vcsh
make install
cd ..
rm -rf vcsh
