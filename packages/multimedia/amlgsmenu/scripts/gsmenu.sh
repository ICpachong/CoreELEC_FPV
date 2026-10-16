#!/bin/bash

# one-time bootstrap: seed /storage/digitalfpv from factory defaults
FACTORY=/usr/share/digitalfpv
if [ -d "$FACTORY" ] && [ ! -f /storage/digitalfpv/.bootstrapped ]; then
	mkdir -p /storage/digitalfpv
	[ -f /storage/digitalfpv/wfb.conf ] || cp -n $FACTORY/wfb.conf /storage/digitalfpv/ 2>/dev/null
	cp -an $FACTORY/icons $FACTORY/fonts /storage/digitalfpv/ 2>/dev/null
	[ -f /storage/digitalfpv/command.cfg ] || cp -n $FACTORY/command.cfg /storage/digitalfpv/ 2>/dev/null
	touch /storage/digitalfpv/.bootstrapped
fi

if [ -f /storage/digitalfpv/wfb.conf ]; then
	. /storage/digitalfpv/wfb.conf
elif [ -f /flash/wfb.conf ]; then
	. /flash/wfb.conf
fi

if [ -f /storage/digitalfpv/AMLgsMenu.new ]; then
	mv /storage/digitalfpv/AMLgsMenu.new /storage/digitalfpv/AMLgsMenu
fi

BIN=/usr/bin/AMLgsMenu
[ -x /storage/digitalfpv/AMLgsMenu ] && BIN=/storage/digitalfpv/AMLgsMenu

killall splash-image

echo ${ground_res:-1080p} >/sys/class/display/mode
$BIN -t /storage/digitalfpv/fonts/ZC0005-Regular-2.ttf -T /storage/digitalfpv/fonts/LXGWWenKaiMono-Regular.ttf
