#!/system/bin/sh

MODDIR=${0%/*}
LOG_FILE="/data/local/tmp/stevenblock.log"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ℹ️ Service Started (Native Mount Mode)" >> "$LOG_FILE"

if [ -f "/system/etc/hosts" ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Hosts file is present in system." >> "$LOG_FILE"
else
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️ Warning: Hosts file check failed." >> "$LOG_FILE"
fi