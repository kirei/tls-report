#!/bin/sh

TIDYRC=`dirname $0`/perltidy.rc

find . \( -name \*.pm -o -name \*.pl \) -print0 |\
xargs -0 perltidy --profile=${TIDYRC} --backup-and-modify-in-place

find . -name '*.bak'  -type f -print0 | xargs -0 rm
