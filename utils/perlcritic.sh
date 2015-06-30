#!/bin/sh

find . \( -name \*.pm -o -name \*.pl \) -print0 |\
xargs -0 perlcritic --severity 5
