#!/system/bin/sh

MODDIR=${0%/*}
SYSTEM_HOSTS="/system/etc/hosts"
ORIGINAL_HOSTS="$MODDIR/original_hosts"

log_message() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') StevenBlock Uninstall: $1" >> /data/local/tmp/stevenblock.log
}

restore_original_hosts() {
  if [ -f "$ORIGINAL_HOSTS" ]; then
    cp -f "$ORIGINAL_HOSTS" "$SYSTEM_HOSTS"
    chmod 644 "$SYSTEM_HOSTS"
    chcon u:object_r:system_file:s0 "$SYSTEM_HOSTS" 2>/dev/null
    log_message "Original hosts file restored"
  else
    if [ -f "$SYSTEM_HOSTS" ]; then
      echo "127.0.0.1 localhost" > "$SYSTEM_HOSTS"
      echo "::1 localhost" >> "$SYSTEM_HOSTS"
      chmod 644 "$SYSTEM_HOSTS"
      chcon u:object_r:system_file:s0 "$SYSTEM_HOSTS" 2>/dev/null
      log_message "Reset hosts file to default"
    fi
  fi
}

cleanup_files() {
  rm -f "$MODDIR/selected_hosts" 2>/dev/null
  rm -f "$MODDIR/selected_name" 2>/dev/null
  rm -f "$MODDIR/original_hosts" 2>/dev/null
  rm -f "/data/local/tmp/stevenblock.log" 2>/dev/null
  
  log_message "Cleanup completed"
}

main() {
  log_message "Starting StevenBlock module uninstallation"
  restore_original_hosts
  cleanup_files
  log_message "StevenBlock module uninstalled successfully"
}

main
