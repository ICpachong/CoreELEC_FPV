#!/bin/bash

# one-time bootstrap: seed /storage/digitalfpv from factory defaults
FACTORY=/usr/share/digitalfpv
SEED_HASH_FILE=/storage/digitalfpv/.wfb.seed_hash

# Re-seed wfb.conf when the factory default changed and the user never
# edited the stored copy. Unedited means either: recorded seed hash still
# matches, or (storage predates the seed file) the only difference from the
# factory default is the ground_res line we changed.
resync_wfb() {
	[ -f /storage/digitalfpv/wfb.conf ] || return 0
	local cur old fac
	cur=$(md5sum /storage/digitalfpv/wfb.conf | cut -d' ' -f1)
	old=$(cat $SEED_HASH_FILE 2>/dev/null)
	fac=$(md5sum $FACTORY/wfb.conf | cut -d' ' -f1)
	[ "$cur" = "$fac" ] && { echo "$fac" > $SEED_HASH_FILE; return 0; }
	if [ -n "$old" ]; then
		[ "$cur" = "$old" ] || return 0   # user edited -> keep
	else
		# no seed yet: only replace if stored differs from factory in ground_res alone
		diff -q <(grep -v '^ground_res=' /storage/digitalfpv/wfb.conf) \
		      <(grep -v '^ground_res=' $FACTORY/wfb.conf) >/dev/null || return 0
	fi
	echo "resync wfb.conf to new factory default" >/dev/kmsg
	cp -f $FACTORY/wfb.conf /storage/digitalfpv/wfb.conf
	echo "$fac" > $SEED_HASH_FILE
}

if [ -d "$FACTORY" ] && [ ! -f /storage/digitalfpv/.bootstrapped ]; then
	mkdir -p /storage/digitalfpv
	[ -f /storage/digitalfpv/wfb.conf ] || cp -n $FACTORY/wfb.conf /storage/digitalfpv/ 2>/dev/null
	cp -an $FACTORY/icons $FACTORY/fonts /storage/digitalfpv/ 2>/dev/null
	[ -f /storage/digitalfpv/command.cfg ] || cp -n $FACTORY/command.cfg /storage/digitalfpv/ 2>/dev/null
	touch /storage/digitalfpv/.bootstrapped
fi
[ -f $SEED_HASH_FILE ] || md5sum /storage/digitalfpv/wfb.conf 2>/dev/null | cut -d' ' -f1 > $SEED_HASH_FILE
resync_wfb

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
