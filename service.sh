#!/system/bin/sh

MODDIR=${0%/*}
LOG_FILE="/data/local/tmp/stevenblock.log"
SOURCE_HOSTS="$MODDIR/system/etc/hosts"
TEMP_HOSTS="/data/local/tmp/stevenblock_hosts_active"
SYS_HOSTS="/system/etc/hosts"

log_print() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

while [ "$(getprop sys.boot_completed)" != "1" ]; do
  sleep 2
done

sleep 5

if [ -f "$SOURCE_HOSTS" ]; then
  cp -f "$SOURCE_HOSTS" "$TEMP_HOSTS"
  chmod 644 "$TEMP_HOSTS"
  chown 0:0 "$TEMP_HOSTS"
  chcon u:object_r:system_file:s0 "$TEMP_HOSTS" 2>/dev/null

  umount "$SYS_HOSTS" 2>/dev/null
  if mount --bind "$TEMP_HOSTS" "$SYS_HOSTS"; then
    log_print "✅ Hosts mounted successfully with SELinux context."
    ndc resolver clearnetdns 2>/dev/null
  else
    log_print "❌ Mount failed."
  fi
else
  log_print "❌ Error: Source hosts not found."
fi