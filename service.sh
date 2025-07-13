#!/system/bin/sh

MODDIR=${0%/*}
SELECTED_FILE="$MODDIR/selected_hosts"

log_message() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') StevenBlock: $1" >> /data/local/tmp/stevenblock.log
}

apply_hosts_file() {
  if [ -f "$SELECTED_FILE" ]; then
    SELECTED_HOSTS=$(cat "$SELECTED_FILE")
    
    if [ -f "$MODDIR/hosts/$SELECTED_HOSTS" ]; then
      if [ -f "/system/etc/hosts" ]; then
        if ! cmp -s "$MODDIR/hosts/$SELECTED_HOSTS" "/system/etc/hosts"; then
          cp -f "$MODDIR/hosts/$SELECTED_HOSTS" "/system/etc/hosts"
          chmod 644 "/system/etc/hosts"
          chcon u:object_r:system_file:s0 "/system/etc/hosts" 2>/dev/null
          log_message "Applied hosts file: $SELECTED_HOSTS"
        fi
      else
        cp -f "$MODDIR/hosts/$SELECTED_HOSTS" "/system/etc/hosts"
        chmod 644 "/system/etc/hosts"
        chcon u:object_r:system_file:s0 "/system/etc/hosts" 2>/dev/null
        log_message "Created hosts file: $SELECTED_HOSTS"
      fi
    else
      log_message "Selected hosts file not found: $SELECTED_HOSTS"
    fi
  else
    log_message "No hosts selection found, using default"
    if [ -f "$MODDIR/hosts/stevenblack_hosts" ]; then
      cp -f "$MODDIR/hosts/stevenblack_hosts" "/system/etc/hosts"
      chmod 644 "/system/etc/hosts"
      chcon u:object_r:system_file:s0 "/system/etc/hosts" 2>/dev/null
      log_message "Applied default hosts file"
    fi
  fi
}

apply_hosts_file
