#!/bin/bash 

cd `dirname $0`
OPT=${1:- --gui}
shift

./hamtag --printer /dev/usb/lp0 --lang tspl --label 4x2 --jokes ~/Documents/dad-a-base.csv --banner "Sussex County Amateur Radio Club"  --note "Guest" --note-lookup ~/Documents/HAM/SCARC.membership.callsigns.hamtag.note.csv  $OPT $@
