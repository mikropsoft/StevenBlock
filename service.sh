#!/system/bin/sh
MODDIR=${0%/*}
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
done
BB=$(find /data/adb -name busybox -type f -executable | head -n 1)
$BB killall httpd
$BB httpd -p 9090 -h $MODDIR/web