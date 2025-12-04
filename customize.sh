#!/system/bin/sh

PROPFILE=false
POSTFSDATA=false
LATESTARTSERVICE=true

ui_print() {
  echo "$1" > /proc/self/fd/$OUTFD
}

keytest() {
  timeout 0.1 getevent -lc 1 2>&1 | grep VOLUME | grep " DOWN" | head -1
}

wait_for_keypress() {
  local timeout_count=0
  while [ $timeout_count -lt 100 ]; do
    local key=$(keytest)
    if echo "$key" | grep -q "VOLUMEUP"; then
      return 1
    elif echo "$key" | grep -q "VOLUMEDOWN"; then
      return 0
    fi
    sleep 0.1
    timeout_count=$((timeout_count + 1))
  done
  return 2
}

print_line() {
  ui_print " ───────────────────────────────────────────"
}

interactive_menu() {
  SELECTION=1
  
  ui_print ""
  print_line
  ui_print "      🛡️  STEVENBLOCK  |  ADBLOCK MODULE     "
  print_line
  ui_print ""
  ui_print "  👋 Welcome! Let's secure your device."
  ui_print "  💬 Support & Community: t.me/stevenblockmodule"
  ui_print ""
  print_line
  ui_print "  ⚠️  PRE-INSTALLATION CHECK:"
  ui_print "  • Ensure 'Systemless Hosts' is DISABLED."
  ui_print "  • Remove conflicting modules (AdAway, BindHosts)."
  print_line
  ui_print "  💡 KERNELSU USER TIP:"
  ui_print "  • If ads aren't blocked in Chrome, disable"
  ui_print "    'umount modules' for it in the KernelSU app."
  print_line
  ui_print ""
  ui_print "  🗂️  SELECT YOUR PROTECTION LEVEL:"
  ui_print "  (Larger lists = Better protection, but more RAM usage)"
  ui_print ""
  ui_print "  [ 1 ] ⭐ StevenBlack Unified"
  ui_print "        └─ Balanced & Recommended"
  ui_print ""
  ui_print "  [ 2 ] ⚡ Energized Spark"
  ui_print "        └─ Lightweight & Essential"
  ui_print ""
  ui_print "  [ 3 ] 💧 Energized Blu"
  ui_print "        └─ Balanced & Extended"
  ui_print ""
  ui_print "  [ 4 ] 🛡️ Energized Ultimate"
  ui_print "        └─ Comprehensive & Full"
  ui_print ""
  ui_print "  [ 5 ] ❌ Cancel Installation"
  ui_print ""
  print_line
  ui_print "  🔼 Vol+ : Next Option   |   🔽 Vol- : Select"
  print_line
  ui_print ""

  print_current_selection() {
    case "$SELECTION" in
      1) ui_print "  👉 SELECTED: [ StevenBlack Unified ]" ;;
      2) ui_print "  👉 SELECTED: [ Energized Spark ]" ;;
      3) ui_print "  👉 SELECTED: [ Energized Blu ]" ;;
      4) ui_print "  👉 SELECTED: [ Energized Ultimate ]" ;;
      5) ui_print "  👉 SELECTED: [ Exit Installation ]" ;;
    esac
  }

  print_current_selection

  while true; do
    wait_for_keypress
    key_result=$?

    if [ "$key_result" -eq 1 ]; then
      SELECTION=$((SELECTION + 1))
      [ "$SELECTION" -gt 5 ] && SELECTION=1
      print_current_selection
    elif [ "$key_result" -eq 0 ]; then
      ui_print ""
      print_line
      case "$SELECTION" in
        1)
          SELECTED_HOSTS="stevenblack_hosts"
          SELECTED_NAME="StevenBlack Unified"
          break
          ;;
        2)
          SELECTED_HOSTS="energized_spark_hosts"
          SELECTED_NAME="Energized Spark"
          break
          ;;
        3)
          SELECTED_HOSTS="energized_blu_hosts"
          SELECTED_NAME="Energized Blu"
          break
          ;;
        4)
          SELECTED_HOSTS="energized_ultimate_hosts"
          SELECTED_NAME="Energized Ultimate"
          break
          ;;
        5)
          abort "  🚫 Action cancelled by user."
          ;;
      esac
    else
      abort "  ⌛ Timeout: No input received."
    fi
    sleep 0.2
  done
}

install_module() {
  ui_print "  ⚙️  Configuring system..."
  
  if [ -f "$MODPATH/hosts/$SELECTED_HOSTS" ]; then
      mkdir -p "$MODPATH/system/etc"
      
      mv "$MODPATH/hosts/$SELECTED_HOSTS" "$MODPATH/system/etc/hosts"
      
      chown 0:0 "$MODPATH/system/etc/hosts"
      chmod 644 "$MODPATH/system/etc/hosts"
      
      echo "$SELECTED_HOSTS" > "$MODPATH/selected_hosts"
      echo "$SELECTED_NAME" > "$MODPATH/selected_name"
      
      ui_print "  ✅  Applied: $SELECTED_NAME"
      ui_print "  🧹  Cleaning up temporary files..."
      rm -rf "$MODPATH/hosts"
  else
      abort "  ❌ Error: Selected hosts file not found!"
  fi
}

main() {
  ui_print ""
  ui_print "  🚀 Initializing Installer..."
  sleep 0.5
  
  interactive_menu
  install_module
  
  ui_print ""
  print_line
  ui_print "      🎉 INSTALLATION SUCCESSFUL! 🎉"
  ui_print "  🔄 Reboot your device to activate protection."
  print_line
  ui_print ""
}

main