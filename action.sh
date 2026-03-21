#!/system/bin/sh

STEVENBLOCK_DIR="/data/adb/stevenblock"
STEVENBLOCK_CONFIG="$STEVENBLOCK_DIR/config.txt"
MODDIR="${0%/*}"
HOSTS_TARGET="$MODDIR/system/etc/hosts"
HOSTS_BACKUP="$STEVENBLOCK_DIR/hosts.bak"
HOSTS_TEMP="$STEVENBLOCK_DIR/hosts.tmp"

LIST_1_NAME="Default"
LIST_1_URL="https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
LIST_1_REPO="StevenBlack/hosts"
LIST_1_BRANCH="master"

LIST_2_NAME="Light"
LIST_2_URL="https://raw.githubusercontent.com/mikropsoft/StevenBlock/main/hosts/energized_spark_hosts"
LIST_2_REPO="mikropsoft/StevenBlock"
LIST_2_BRANCH="main"

LIST_3_NAME="Medium"
LIST_3_URL="https://raw.githubusercontent.com/mikropsoft/StevenBlock/main/hosts/energized_blu_hosts"
LIST_3_REPO="mikropsoft/StevenBlock"
LIST_3_BRANCH="main"

LIST_4_NAME="Aggressive"
LIST_4_URL="https://raw.githubusercontent.com/mikropsoft/StevenBlock/main/hosts/energized_ultimate_hosts"
LIST_4_REPO="mikropsoft/StevenBlock"
LIST_4_BRANCH="main"

print_banner() {
  echo ""
  echo "🛡️ StevenBlock"
  echo ""
  echo "👨‍💻 Developer  : mikropsoft"
  echo "🌐 GitHub     : github.com/mikropsoft/StevenBlock"
  echo "📢 Telegram   : t.me/stevenblockmodule"
  echo "☕ Coffee     : buymeacoffee.com/mikropsoft"
  echo ""
}

get_last_commit_date() {
  local repo="$1"
  local branch="$2"
  local api_url="https://api.github.com/repos/${repo}/commits?sha=${branch}&per_page=1"
  local date_str=""

  if command -v curl >/dev/null 2>&1; then
    date_str=$(curl -sL --connect-timeout 10 --max-time 15 "$api_url" 2>/dev/null | grep '"date"' | head -1 | sed 's/.*"date"[[:space:]]*:[[:space:]]*"//;s/".*//')
  elif command -v wget >/dev/null 2>&1; then
    date_str=$(wget -qO- --timeout=15 "$api_url" 2>/dev/null | grep '"date"' | head -1 | sed 's/.*"date"[[:space:]]*:[[:space:]]*"//;s/".*//')
  fi

  if [ -n "$date_str" ]; then
    echo "$date_str" | cut -c1-10
  else
    echo "❓ Unknown"
  fi
}

download_hosts() {
  local url="$1"
  local output="$2"
  local success=0

  if command -v curl >/dev/null 2>&1; then
    curl -sLf --connect-timeout 15 --max-time 120 --retry 3 --retry-delay 2 -o "$output" "$url" 2>/dev/null && success=1
  fi

  if [ "$success" -ne 1 ] && command -v wget >/dev/null 2>&1; then
    wget -qO "$output" --timeout=120 --tries=3 "$url" 2>/dev/null && success=1
  fi

  if [ "$success" -ne 1 ]; then
    for p in /data/adb/magisk/busybox /data/adb/ksu/bin/busybox /data/adb/ap/bin/busybox; do
      if [ -x "$p" ]; then
        $p wget -qO "$output" -T 120 "$url" 2>/dev/null && success=1
        [ "$success" -eq 1 ] && break
      fi
    done
  fi

  return $((1 - success))
}

clean_hosts_file() {
  local input="$1"
  local output="$2"

  printf "127.0.0.1 localhost\n::1 localhost\n" > "$output"

  sed -e '/^[[:space:]]*#/d' \
      -e '/^[[:space:]]*$/d' \
      -e '/^[[:space:]]*::1/d' \
      -e '/^[[:space:]]*127\.0\.0\.1[[:space:]]*localhost[[:space:]]*$/d' \
      -e '/^[[:space:]]*0\.0\.0\.0[[:space:]]*$/d' \
      -e 's/#.*$//' \
      -e 's/[[:space:]]*$//' \
      -e '/^[[:space:]]*$/d' \
      -e 's/^127\.0\.0\.1/0.0.0.0/' \
      "$input" >> "$output"

  sort -u "$output" -o "$output" 2>/dev/null || {
    local temp_sort="${output}.sort"
    if sort -u "$output" > "$temp_sort" 2>/dev/null; then
      mv "$temp_sort" "$output"
    fi
  }
}

flush_dns_cache() {
  ndc resolver flushdefaultif >/dev/null 2>&1
  ndc resolver clearnetdns >/dev/null 2>&1

  for svc in netd dns_tls mdnsd; do
    if [ -n "$(getprop init.svc.$svc 2>/dev/null)" ]; then
      setprop ctl.restart "$svc" 2>/dev/null
    fi
  done
}

set_hosts_permissions() {
  local file="$1"
  
  chown 0:0 "$file" 2>/dev/null
  chmod 644 "$file" 2>/dev/null
  chcon u:object_r:system_file:s0 "$file" 2>/dev/null
}

save_config() {
  local list_num="$1"
  local list_name="$2"
  local list_url="$3"
  
  mkdir -p "$STEVENBLOCK_DIR"
  printf "ACTIVE_LIST=%s\nACTIVE_NAME=%s\nACTIVE_URL=%s\nLAST_UPDATE=%s\n" \
    "$list_num" "$list_name" "$list_url" "$(date '+%Y-%m-%d %H:%M:%S')" > "$STEVENBLOCK_CONFIG"
  chmod 644 "$STEVENBLOCK_CONFIG" 2>/dev/null
}

load_config() {
  ACTIVE_LIST=""
  ACTIVE_NAME=""
  ACTIVE_URL=""
  LAST_UPDATE=""
  
  if [ -f "$STEVENBLOCK_CONFIG" ]; then
    . "$STEVENBLOCK_CONFIG"
  fi
}

install_hosts_list() {
  local list_num="$1"
  local list_name="$2"
  local list_url="$3"

  echo ""
  echo "📥 Downloading $list_name list..."

  mkdir -p "$STEVENBLOCK_DIR"

  if [ -f "$HOSTS_TARGET" ]; then
    cp -f "$HOSTS_TARGET" "$HOSTS_BACKUP" 2>/dev/null
  fi

  if ! download_hosts "$list_url" "$HOSTS_TEMP"; then
    echo "❌ Download failed"
    if [ -f "$HOSTS_BACKUP" ]; then
      cp -f "$HOSTS_BACKUP" "$HOSTS_TARGET" 2>/dev/null
      set_hosts_permissions "$HOSTS_TARGET"
      echo "🔄 Restored previous hosts file"
    fi
    return 1
  fi

  local filesize
  filesize=$(wc -c < "$HOSTS_TEMP" 2>/dev/null | tr -d ' ')
  
  if [ -z "$filesize" ] || [ "$filesize" -lt 10 ]; then
    echo "❌ Downloaded file is empty, corrupt, or invalid"
    if [ -f "$HOSTS_BACKUP" ]; then
      cp -f "$HOSTS_BACKUP" "$HOSTS_TARGET" 2>/dev/null
      set_hosts_permissions "$HOSTS_TARGET"
      echo "🔄 Restored previous hosts file"
    fi
    rm -f "$HOSTS_TEMP" 2>/dev/null
    return 1
  elif ! grep -q "0\.0\.0\.0" "$HOSTS_TEMP" 2>/dev/null && ! grep -q "127\.0\.0\.1" "$HOSTS_TEMP" 2>/dev/null; then
    echo "❌ Downloaded file is empty, corrupt, or invalid"
    if [ -f "$HOSTS_BACKUP" ]; then
      cp -f "$HOSTS_BACKUP" "$HOSTS_TARGET" 2>/dev/null
      set_hosts_permissions "$HOSTS_TARGET"
      echo "🔄 Restored previous hosts file"
    fi
    rm -f "$HOSTS_TEMP" 2>/dev/null
    return 1
  fi

  echo "🧹 Cleaning hosts file..."

  local cleaned_file="${HOSTS_TEMP}.clean"
  clean_hosts_file "$HOSTS_TEMP" "$cleaned_file"

  cp -f "$cleaned_file" "$HOSTS_TARGET"
  set_hosts_permissions "$HOSTS_TARGET"

  rm -f "$HOSTS_TEMP" "$cleaned_file" 2>/dev/null

  local c1
  c1=$(grep -c "^0\.0\.0\.0" "$HOSTS_TARGET" 2>/dev/null || echo "0")
  local c2
  c2=$(grep -c "^127\.0\.0\.1" "$HOSTS_TARGET" 2>/dev/null || echo "0")
  local total_domains=$((c1 + c2))

  save_config "$list_num" "$list_name" "$list_url"

  echo "🔄 Flushing DNS cache..."
  flush_dns_cache

  echo ""
  echo "✅ Done"
  echo "🏷️ List    : $list_name"
  echo "🚫 Blocked : $total_domains domains"
  echo ""
  echo "⚠️ Please REBOOT your device"
  echo ""

  return 0
}

show_status() {
  load_config

  echo ""
  echo "📊 Status"
  echo ""

  if [ -n "$ACTIVE_NAME" ]; then
    local c1
    c1=$(grep -c "^0\.0\.0\.0" "$HOSTS_TARGET" 2>/dev/null || echo "0")
    local c2
    c2=$(grep -c "^127\.0\.0\.1" "$HOSTS_TARGET" 2>/dev/null || echo "0")
    local total_domains=$((c1 + c2))
    
    echo "🏷️ List        : $ACTIVE_NAME"
    echo "🚫 Blocked     : $total_domains domains"
    echo "📅 Last Update : ${LAST_UPDATE:-Unknown}"
    echo "🛡️ Protection  : ✅ Active"
  else
    echo "ℹ️ Status      : ⚠️ Not configured"
    echo "🛡️ Protection  : ❌ Inactive"
  fi

  echo ""
}

force_update() {
  load_config

  if [ -z "$ACTIVE_URL" ] || [ -z "$ACTIVE_NAME" ]; then
    echo "⚠️ No active list found. Please reconfigure first."
    echo ""
    return 1
  fi

  echo "🔄 Force updating $ACTIVE_NAME..."
  install_hosts_list "$ACTIVE_LIST" "$ACTIVE_NAME" "$ACTIVE_URL"
}

show_hosts_menu() {
  echo "⏳ Fetching update dates..."
  echo ""

  local date1 date2 date3 date4
  
  if ping -c 1 -W 2 api.github.com >/dev/null 2>&1; then
    date1=$(get_last_commit_date "$LIST_1_REPO" "$LIST_1_BRANCH")
    date2=$(get_last_commit_date "$LIST_2_REPO" "$LIST_2_BRANCH")
    date3=$(get_last_commit_date "$LIST_3_REPO" "$LIST_3_BRANCH")
    date4=$(get_last_commit_date "$LIST_4_REPO" "$LIST_4_BRANCH")
  else
    date1="❓ Unknown"
    date2="❓ Unknown"
    date3="❓ Unknown"
    date4="❓ Unknown"
  fi

  echo "1️⃣ Default    [$date1]"
  echo "2️⃣ Light      [$date2]"
  echo "3️⃣ Medium     [$date3]"
  echo "4️⃣ Aggressive [$date4]"
  echo ""
}

wait_for_key() {
  while true; do
    local ev
    ev=$(getevent -lc 1 2>/dev/null)
    if echo "$ev" | grep -iE 'VOLUMEUP|0073' | grep -iE 'DOWN|00000001' >/dev/null 2>&1; then
      echo "up"
      return
    elif echo "$ev" | grep -iE 'VOLUMEDOWN|0072' | grep -iE 'DOWN|00000001' >/dev/null 2>&1; then
      echo "down"
      return
    fi
  done
}

reconfigure() {
  print_banner
  show_hosts_menu

  echo "🔊 Volume UP = Next  |  🔉 Volume DOWN = Select"
  echo ""
  
  local choice=1
  while true; do
    echo "👉 $choice"
    local pressed
    pressed=$(wait_for_key)
    if [ "$pressed" = "up" ]; then
      choice=$((choice % 4 + 1))
    else
      break
    fi
  done

  case "$choice" in
    1) install_hosts_list 1 "$LIST_1_NAME" "$LIST_1_URL" ;;
    2) install_hosts_list 2 "$LIST_2_NAME" "$LIST_2_URL" ;;
    3) install_hosts_list 3 "$LIST_3_NAME" "$LIST_3_URL" ;;
    4) install_hosts_list 4 "$LIST_4_NAME" "$LIST_4_URL" ;;
    *) echo "⚠️ Invalid selection" ;;
  esac
}

main_menu() {
  while true; do
    print_banner

    echo "1️⃣ Reconfigure / Update"
    echo "2️⃣ Force Update Current List"
    echo "3️⃣ View Status"
    echo "4️⃣ Exit"
    echo ""
    echo "🔊 Volume UP = Next  |  🔉 Volume DOWN = Select"
    echo ""
    
    local action_choice=1
    while true; do
      echo "👉 $action_choice"
      local pressed
      pressed=$(wait_for_key)
      if [ "$pressed" = "up" ]; then
        action_choice=$((action_choice % 4 + 1))
      else
        break
      fi
    done

    case "$action_choice" in
      1) reconfigure ;;
      2) force_update ;;
      3) show_status ;;
      4)
        echo ""
        echo "👋 Goodbye!"
        echo ""
        break
        ;;
      *)
        echo "⚠️ Invalid choice"
        sleep 1
        ;;
    esac
  done
}

main_menu