#!/system/bin/sh
# StevenBlock v1.0 installer.
# Fully automatic: no questions, no volume keys. Never aborts because of a failed download.

ui_print " "
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ui_print "  🛡️ StevenBlock v1.0"
ui_print "  The Zero-Bloat Digital Guardian"
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ui_print " "

set_perm "$MODPATH/sb.sh" 0 0 0755
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/post-mount.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755

SB_MODDIR="$MODPATH" BOOTMODE="${BOOTMODE:-true}" \
  KSU="${KSU:-}" KSU_VER="${KSU_VER:-}" \
  APATCH="${APATCH:-}" APATCH_VER="${APATCH_VER:-}" \
  MAGISK_VER="${MAGISK_VER:-}" \
  sh "$MODPATH/sb.sh" _install 2>&1 | while IFS= read -r line; do ui_print "$line"; done

set_perm "$MODPATH/system/etc/hosts" 0 0 0644 u:object_r:system_file:s0
ui_print " "
