#!/system/bin/sh

ui_print " "
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ui_print "  🛡️ StevenBlock v2.0"
ui_print "  The Zero-Bloat Digital Guardian"
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ui_print " "

for SB_FILE in sb.sh action.sh service.sh post-mount.sh uninstall.sh; do
  set_perm "$MODPATH/$SB_FILE" 0 0 0755
done

SB_MODDIR="$MODPATH" BOOTMODE="${BOOTMODE:-true}" \
  KSU="${KSU:-}" KSU_VER="${KSU_VER:-}" \
  APATCH="${APATCH:-}" APATCH_VER="${APATCH_VER:-}" \
  MAGISK_VER="${MAGISK_VER:-}" \
  sh "$MODPATH/sb.sh" _install 2>&1 | while IFS= read -r SB_LINE; do ui_print "$SB_LINE"; done

set_perm "$MODPATH/system/etc/hosts" 0 0 0644 u:object_r:system_file:s0
rm -f "$MODPATH/CHANGELOG.md" "$MODPATH/LICENSE" "$MODPATH/update.json" 2>/dev/null
unset SB_FILE SB_LINE
ui_print " "
