#!/usr/bin/env sh
git clone git://myrepos.branchable.com/ myrepos
cd myrepos
make install
cd ..
rm -rf myrepos
