#!/system/bin/sh
MODDIR=${0%/*}
[ "$MODDIR" = "$0" ] && MODDIR=.
[ -f "$MODDIR/sb.sh" ] && sh "$MODDIR/sb.sh" _uninstall > /dev/null 2>&1
rm -rf /data/adb/stevenblock
