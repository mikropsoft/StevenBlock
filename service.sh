#!/system/bin/sh

MODDIR=${0%/*}
MODULE_HOSTS="$MODDIR/target_hosts"
SYSTEM_HOSTS="/system/etc/hosts"
LOG_FILE="/data/local/tmp/stevenblock.log"

log_message() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ℹ️ $1" >> "$LOG_FILE"
}

mount_hosts() {
  log_message "--- Service Started (Clean Mount Method) ---"

  if [ ! -f "$MODULE_HOSTS" ]; then
    log_message "❌ Error: Host file missing at $MODULE_HOSTS"
    return
  fi

  chcon u:object_r:system_file:s0 "$MODULE_HOSTS"

  if grep -q "$SYSTEM_HOSTS" /proc/mounts; then
    umount "$SYSTEM_HOSTS"
    log_message "Previous mount unmounted."
  fi

  mount --bind "$MODULE_HOSTS" "$SYSTEM_HOSTS"

  if grep -q "$SYSTEM_HOSTS" /proc/mounts; then
    log_message "✅ Success: Protection Active. ($MODULE_HOSTS mounted)"
  else
    log_message "❌ Critical: Mount failed!"
  fi
}

sleep 3
mount_hosts