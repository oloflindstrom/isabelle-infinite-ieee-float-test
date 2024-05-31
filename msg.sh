#!/bin/bash

MODECHECKER="$1"
NUMTESTS="$2"

rm -f msg.txt
touch msg.txt

echo -e " Testing mode: \t"$MODECHECKER" \n Num_tests: \t"$NUMTESTS"\
\n\n Starting date and time:\n" > msg.txt
echo -n " $(date +%Y-%m-%d\ %H:%M:%S)" >> msg.txt