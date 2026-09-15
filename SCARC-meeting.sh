#!/bin/bash 

cd `dirname $0`
./hamtag --printer /dev/usb/lp0 --lang tspl --label 4x2 --jokes ../DadJokeGenerator_LA_FP/data/dad-a-base.csv --banner "Sussex County Amateur Radio Club"  --note "Guest" --note-lookup ~/Documents/HAM/SCARC.membership.callsigns.hamtag.note.csv    ${1:- --gui}
