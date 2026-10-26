#!/system/bin/sh
# StevenBlock: stops the WebUI server and removes every StevenBlock file.
# /system was never modified, so the original hosts file is back after the reboot.
MODDIR=${0%/*}
[ -f "$MODDIR/sb.sh" ] && sh "$MODDIR/sb.sh" _uninstall > /dev/null 2>&1
rm -rf /data/adb/stevenblock
