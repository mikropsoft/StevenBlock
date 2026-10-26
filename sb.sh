#!/system/bin/sh
# StevenBlock v1.0 backend.
# Every WebUI request, Action press, install step and boot task runs through this script.
# Public commands print exactly one line of JSON: {"ok":..,"code":"..","message":"..","data":{..}}
# shellcheck disable=SC2016
# (SC2016: the awk programs below are single-quoted on purpose.)

if [ -z "${SB_BB:-}" ]; then
  for _bb in /data/adb/magisk/busybox /data/adb/ksu/bin/busybox /data/adb/ap/bin/busybox; do
    if [ -x "$_bb" ]; then
      SB_BB=$_bb
      ASH_STANDALONE=1
      export SB_BB ASH_STANDALONE
      exec "$_bb" sh "$0" "$@"
    fi
  done
  SB_BB=none
  export SB_BB
fi

umask 022
PATH=/system/bin:/system/xbin:/vendor/bin:${PATH:-/bin}
export PATH

SB_VER=v1.0
SB_VCODE=1000
SELF=$0
case $SELF in /*) ;; *) SELF=$(pwd)/$SELF ;; esac
MODDIR=${SB_MODDIR:-${SELF%/*}}
MODROOT=/data/adb/modules
DATA=/data/adb/stevenblock
CFG=$DATA/config
SEQF=$DATA/seq
PENDF=$DATA/reboot.pending
LOGF=$DATA/stevenblock.log
RULESD=$DATA/rules
ALLOWF=$RULESD/allow.list
BLOCKF=$RULESD/block.list
CACHED=$DATA/cache
LISTCACHE=$CACHED/list.domains
METAD=$CACHED/meta
BACKUPD=$DATA/backup
ORIGHOSTS=$BACKUPD/hosts.original
RUND=$DATA/run
TMPD=$DATA/tmp
LOCKD=$RUND/lock
METALOCK=$RUND/meta.lock
OPF=$RUND/op
DLPART=$TMPD/download.part
DLHDR=$TMPD/download.hdr
HOSTSD=$MODDIR/system/etc
HOSTS=$HOSTSD/hosts
PROP=$MODDIR/module.prop
SYS_HOSTS=/system/etc/hosts
INIT_HOSTS=/proc/1/root/system/etc/hosts
PORT=9090
IDLE_LIMIT=600
UA="StevenBlock/1.0 (+https://github.com/mikropsoft/StevenBlock)"
LIST_IDS="stevenblack hblock hagezi-light hagezi-normal hagezi-pro hagezi-proplus hagezi-ultimate"
MODE=cli
DL_TOOL=
DL_PIDF=
NL='
'
CR=$(printf '\r')
TAB=$(printf '\t')

# ---------------------------------------------------------------- lists

list_info() {
  case $1 in
    stevenblack)
      L_NAME='StevenBlack Main'; L_GROUP=unified; L_LEVEL=green; L_LEVELTXT=Balanced
      L_URL='https://raw.githubusercontent.com/StevenBlack/hosts/refs/heads/master/hosts'
      L_DESC='Classic unified list for ads and malware, with very few false positives.' ;;
    hblock)
      L_NAME='hBlock'; L_GROUP=unified; L_LEVEL=blue; L_LEVELTXT=Mixed
      L_URL='https://hblock.molinero.dev/hosts'
      L_DESC='Merges dozens of public blocklists into one broad, all-purpose list.' ;;
    hagezi-light)
      L_NAME='HaGeZi Light'; L_GROUP=hagezi; L_LEVEL=green; L_LEVELTXT=Basic
      L_URL='https://raw.githubusercontent.com/hagezi/dns-blocklists-legacy/refs/heads/main/hosts/light.txt'
      L_DESC='Basic protection from ads, tracking and telemetry. Built to break nothing.' ;;
    hagezi-normal)
      L_NAME='HaGeZi Normal'; L_GROUP=hagezi; L_LEVEL=blue; L_LEVELTXT=All-round
      L_URL='https://raw.githubusercontent.com/hagezi/dns-blocklists-legacy/refs/heads/main/hosts/multi.txt'
      L_DESC='All-round protection from ads, tracking, phishing, malware and scams.' ;;
    hagezi-pro)
      L_NAME='HaGeZi Pro'; L_GROUP=hagezi; L_LEVEL=yellow; L_LEVELTXT=Extended
      L_URL='https://raw.githubusercontent.com/hagezi/dns-blocklists-legacy/refs/heads/main/hosts/pro.txt'
      L_DESC='Extended protection with many more trackers. May need an allow rule.' ;;
    hagezi-proplus)
      L_NAME='HaGeZi Pro++'; L_GROUP=hagezi; L_LEVEL=orange; L_LEVELTXT=Aggressive
      L_URL='https://raw.githubusercontent.com/hagezi/dns-blocklists-legacy/refs/heads/main/hosts/pro.plus.txt'
      L_DESC='Aggressive blocking. Some legitimate sites or app features may break.' ;;
    hagezi-ultimate)
      L_NAME='HaGeZi Ultimate'; L_GROUP=hagezi; L_LEVEL=red; L_LEVELTXT=Maximum
      L_URL='https://raw.githubusercontent.com/hagezi/dns-blocklists-legacy/refs/heads/main/hosts/ultimate.txt'
      L_DESC='The most aggressive list. Can restrict app and website features.' ;;
    *) return 1 ;;
  esac
  return 0
}

# ---------------------------------------------------------------- awk programs

AWK_JESC='
BEGIN { ORS = ""; printf "\"" }
{
  if (NR > 1) printf "\\n"
  s = $0; o = ""; n = length(s)
  for (i = 1; i <= n; i++) {
    c = substr(s, i, 1)
    if (c == "\\") o = o "\\\\"
    else if (c == "\"") o = o "\\\""
    else if (c == "\t") o = o " "
    else if (c != "\r") o = o c
  }
  printf "%s", o
}
END { printf "\"" }'

AWK_NORM='
function okdom(d,   n, i, L) {
  if (length(d) > 253) return 0
  if (d !~ /^([a-z0-9_]([a-z0-9_-]*[a-z0-9_])?\.)+[a-z]([a-z0-9-]*[a-z0-9])?$/) return 0
  if (length(d) > 63) {
    n = split(d, L, ".")
    for (i = 1; i <= n; i++) if (length(L[i]) > 63) return 0
  }
  return 1
}
BEGIN {
  SYS["localhost"] = 1; SYS["localhost.localdomain"] = 1; SYS["local"] = 1
  SYS["localdomain"] = 1; SYS["broadcasthost"] = 1; SYS["0.0.0.0"] = 1
}
{
  sub(/\r$/, "")
  c = index($0, "#")
  if (c) $0 = substr($0, 1, c - 1)
  if (NF == 0) next
  if (NF == 1) s = 1
  else if ($1 ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/ || index($1, ":")) s = 2
  else next
  for (f = s; f <= NF; f++) {
    d = tolower($f)
    sub(/\.$/, "", d)
    if (d in SYS) continue
    if (d ~ /^ip6-/) continue
    if (!okdom(d)) continue
    if (d in seen) continue
    seen[d] = 1
    print d
    n++
  }
}
END { print n + 0 > cntf }'

AWK_COMPILE='
BEGIN {
  while ((getline l < allowf) > 0) if (l != "") A[l] = 1
  close(allowf)
  while ((getline l < blockf) > 0) if (l != "" && !(l in A) && !(l in B)) { B[l] = 1; BO[++nb] = l }
  close(blockf)
  print "# StevenBlock " ver " - systemless hosts file"
  print "# List: " name
  print "# Source: " url
  print "# Managed by StevenBlock. Manual edits are overwritten."
  print "# https://github.com/mikropsoft/StevenBlock"
  print ""
  print "127.0.0.1 localhost"
  print "::1 localhost ip6-localhost"
  print ""
}
{
  if ($0 in A) next
  if ($0 in B) inl[$0] = 1
  print "0.0.0.0 " $0
  n++
}
END {
  for (i = 1; i <= nb; i++) if (!(BO[i] in inl)) { print "0.0.0.0 " BO[i]; n++ }
  print n + 0 > cntf
}'

AWK_HEAD='
{ l = $0; sub(/\r$/, "", l) }
l !~ /^[ \t]*#/ { next }
{ x = tolower(l) }
cnt == "" && x ~ /(number of (unique )?(domains|entries)|blocked domains|total (domains|entries)|entries)[ \t]*:/ {
  v = l; sub(/^[^:]*:[ \t]*/, "", v); gsub(/[,. _]/, "", v)
  if (v ~ /^[0-9]+$/) cnt = v
}
dt == "" && x ~ /^[ \t]*#[ \t]*(date|last[ -]modified|last updated|updated)[ \t]*:/ {
  v = l; sub(/^[^:]*:[ \t]*/, "", v); dt = v
}
END { print cnt; print dt }'

AWK_DATE='
function civ(y, m, d,   era, yoe, doy, doe) {
  y -= (m <= 2)
  era = int((y >= 0 ? y : y - 399) / 400)
  yoe = y - era * 400
  doy = int((153 * (m + (m > 2 ? -3 : 9)) + 2) / 5) + d - 1
  doe = yoe * 365 + int(yoe / 4) - int(yoe / 100) + doy
  return era * 146097 + doe - 719468
}
BEGIN {
  split("jan feb mar apr may jun jul aug sep oct nov dec", MN, " ")
  for (i = 1; i <= 12; i++) MI[MN[i]] = i
}
NR == 1 {
  s = tolower($0)
  gsub(/[(),]/, " ", s)
  y = 0; m = 0; d = 0; hh = 0; mm = 0; ss = 0; off = 0
  if (match(s, /[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/)) {
    y = substr(s, RSTART, 4) + 0; m = substr(s, RSTART + 5, 2) + 0; d = substr(s, RSTART + 8, 2) + 0
    s = substr(s, 1, RSTART - 1) " " substr(s, RSTART + 10)
  }
  n = split(s, T, /[ \t]+/)
  for (i = 1; i <= n; i++) {
    t = T[i]
    sub(/^t/, "", t)
    if (t == "") continue
    if (t ~ /^[0-9]+:[0-9]+/) {
      split(t, P, ":"); hh = P[1] + 0; mm = P[2] + 0; ss = (P[3] ~ /^[0-9]/) ? int(P[3]) : 0
      if (match(t, /[+-][0-9][0-9]:?[0-9][0-9]$/)) {
        o = substr(t, RSTART); gsub(/:/, "", o)
        off = (substr(o, 2, 2) * 3600 + substr(o, 4, 2) * 60) * (substr(o, 1, 1) == "-" ? -1 : 1)
      }
    }
    else if (t ~ /^[0-9][0-9][0-9][0-9]$/ && !y) y = t + 0
    else if (t ~ /^[0-9][0-9]?$/ && !d) d = t + 0
    else if ((substr(t, 1, 3) in MI) && !m) m = MI[substr(t, 1, 3)]
    else if (t ~ /^[+-][0-9][0-9][0-9][0-9]$/) off = (substr(t, 2, 2) * 3600 + substr(t, 4, 2) * 60) * (substr(t, 1, 1) == "-" ? -1 : 1)
  }
  if (y < 1990 || m < 1 || m > 12 || d < 1 || d > 31 || hh > 23 || mm > 59) exit
  printf "%.0f\n", civ(y, m, d) * 86400 + hh * 3600 + mm * 60 + ss - off
  exit
}'

AWK_OPJSON='
function esc(s,   o, i, c, n) {
  o = ""; n = length(s)
  for (i = 1; i <= n; i++) {
    c = substr(s, i, 1)
    if (c == "\\") o = o "\\\\"
    else if (c == "\"") o = o "\\\""
    else if (c >= " ") o = o c
  }
  return o
}
{ i = index($0, "="); if (i) O[substr($0, 1, i - 1)] = substr($0, i + 1) }
END {
  while ((getline l < hdr) > 0) {
    sub(/\r$/, "", l); sub(/^[ \t]+/, "", l); x = tolower(l)
    if (x ~ /^http\/[0-9.]+[ \t]+[0-9]/) cl = ""
    else if (x ~ /^content-length:/) { v = l; sub(/^[^:]*:[ \t]*/, "", v); if (v ~ /^[0-9]+$/) cl = v }
  }
  st = O["STATE"]; run = 0
  if (st == "running") { if (alive == 1) run = 1; else st = "interrupted" }
  ph = O["PHASE"]
  tot = O["TOTAL"] + 0
  if (!tot && cl != "") tot = cl + 0
  can = "false"
  if (run && (ph == "prepare" || ph == "check" || ph == "download" || ph == "verify" || ph == "optimize")) can = "true"
  printf "{\"running\":%s,\"state\":\"%s\",\"kind\":\"%s\",\"list\":\"%s\",\"phase\":\"%s\",\"code\":\"%s\",\"message\":\"%s\",\"seq\":%.0f,\"bytes\":%.0f,\"total\":%.0f,\"domains\":%.0f,\"reboot\":%s,\"started\":%.0f,\"ended\":%.0f,\"cancellable\":%s,\"cancelling\":%s}", (run ? "true" : "false"), esc(st), esc(O["KIND"]), esc(O["LIST"]), esc(ph), esc(O["CODE"]), esc(O["MSG"]), O["SEQ"] + 0, (run ? bytes + 0 : 0), tot, O["DOMAINS"] + 0, (O["REBOOT"] == "1" ? "true" : "false"), O["START"] + 0, O["END"] + 0, can, (cancelling == 1 && run ? "true" : "false")
}'

AWK_LOGS='
function esc(s,   o, i, c, n) {
  o = ""; n = length(s)
  for (i = 1; i <= n; i++) {
    c = substr(s, i, 1)
    if (c == "\\") o = o "\\\\"
    else if (c == "\"") o = o "\\\""
    else if (c >= " ") o = o c
  }
  return o
}
BEGIN { ORS = ""; printf "[" }
{
  i = index($0, "|"); if (!i) next
  t = substr($0, 1, i - 1); r = substr($0, i + 1)
  j = index(r, "|"); if (!j) next
  lv = substr(r, 1, j - 1); m = substr(r, j + 1)
  if (t !~ /^[0-9]+$/) next
  if (lv != "INFO" && lv != "WARN" && lv != "ERROR") lv = "INFO"
  printf "%s{\"t\":%s,\"l\":\"%s\",\"m\":\"%s\"}", (n++ ? "," : ""), t, lv, esc(m)
}
END { printf "]" }'

AWK_QUERY='
BEGIN { for (i = 33; i < 127; i++) H[sprintf("%02x", i)] = sprintf("%c", i) }
function dec(s,   o, i, c, h) {
  o = ""
  for (i = 1; i <= length(s); i++) {
    c = substr(s, i, 1)
    if (c == "%") {
      h = tolower(substr(s, i + 1, 2))
      if (!(h in H)) return "\001"
      c = H[h]; i += 2
    } else if (c == "+") return "\001"
    o = o c
  }
  return o
}
{
  n = split($0, P, "&")
  for (i = 1; i <= n; i++) {
    k = P[i]; v = ""
    j = index(k, "=")
    if (j) { v = substr(k, j + 1); k = substr(k, 1, j - 1) }
    if (k == "t" || k == "c" || k == "a" || k == "b") V[k] = dec(v)
  }
}
END { print V["t"]; print V["c"]; print V["a"]; print V["b"] }'

AWK_VALID='
{
  d = $0
  if (length(d) < 1 || length(d) > 253) exit 1
  n = split(d, L, ".")
  if (n < 2) exit 1
  for (i = 1; i <= n; i++) {
    if (length(L[i]) < 1 || length(L[i]) > 63) exit 1
    if (i < n) { if (L[i] !~ /^[a-z0-9_]([a-z0-9_-]*[a-z0-9_])?$/) exit 1 }
    else if (L[i] !~ /^[a-z][a-z]+$/ && L[i] !~ /^xn--[a-z0-9]([a-z0-9-]*[a-z0-9])?$/) exit 1
  }
  exit 0
}'

# ---------------------------------------------------------------- helpers

now() { date +%s; }
nap() { sleep "$1" 2>/dev/null || sleep 1; }
is_num() { case $1 in '' | *[!0-9]*) return 1 ;; esac; return 0; }
say() { [ "$MODE" = install ] && printf '%s\n' "$1"; return 0; }
fsize() { _fs=$(stat -c %s "$1" 2>/dev/null); is_num "$_fs" || _fs=0; printf '%s' "$_fs"; }
fmt_num() { printf '%s\n' "${1:-0}" | awk '{ n = $1 ""; o = ""; while (length(n) > 3) { o = "," substr(n, length(n) - 2) o; n = substr(n, 1, length(n) - 3) } print n o }'; }
fmt_mb() { awk -v b="${1:-0}" 'BEGIN { printf "%.1f MB", b / 1048576 }'; }
clean_val() { printf '%s' "$1" | tr -d '\000-\037\134' | cut -c1-200; }
count_lines() { _cn=0; [ -s "$1" ] && _cn=$(grep -c . "$1" 2>/dev/null); is_num "$_cn" || _cn=0; printf '%s' "$_cn"; }
boot_id() { cat /proc/sys/kernel/random/boot_id 2>/dev/null; }

ensure_dirs() {
  mkdir -p "$RULESD" "$METAD" "$BACKUPD" "$RUND" "$TMPD" 2>/dev/null
  chmod 0700 "$DATA" 2>/dev/null
  [ -f "$ALLOWF" ] || : > "$ALLOWF"
  [ -f "$BLOCKF" ] || : > "$BLOCKF"
}

log() {
  _lg_m=$2
  case $_lg_m in *"$NL"* | *"$CR"* | *"$TAB"*) _lg_m=$(printf '%s' "$_lg_m" | tr '\r\n\t' '   ') ;; esac
  [ -d "$DATA" ] || return 0
  printf '%s|%s|%s\n' "$(date +%s)" "$1" "$_lg_m" >> "$LOGF" 2>/dev/null || return 0
  _lg_n=$(wc -l < "$LOGF" 2>/dev/null)
  if is_num "$_lg_n" && [ "$_lg_n" -gt 500 ]; then
    tail -n 500 "$LOGF" > "$LOGF.trim" 2>/dev/null && mv -f "$LOGF.trim" "$LOGF"
  fi
  return 0
}

jstr() {
  case $1 in
    *\\* | *\"* | *"$NL"* | *"$CR"* | *"$TAB"*) printf '%s' "$1" | awk "$AWK_JESC" ;;
    *) printf '"%s"' "$1" ;;
  esac
}

jnum() { if is_num "$1"; then printf '%s' "$1"; else printf 'null'; fi; }

reply() {
  _rp_d=${4:-}
  [ -n "$_rp_d" ] || _rp_d='{}'
  printf '{"ok":%s,"code":"%s","message":%s,"data":%s}\n' "$1" "$2" "$(jstr "$3")" "$_rp_d"
}

# ---------------------------------------------------------------- config

cfg_load() {
  C_LIST=; C_ENABLED=1; C_ETAG=; C_SRCDATE=; C_UPDATED=0; C_COUNT=0; C_DOMAINS=0; C_SETUP=
  if [ -f "$CFG" ]; then
    while IFS='=' read -r _ck _cv; do
      case $_ck in
        LIST) C_LIST=$_cv ;;
        ENABLED) C_ENABLED=$_cv ;;
        ETAG) C_ETAG=$_cv ;;
        SRCDATE) C_SRCDATE=$_cv ;;
        UPDATED) C_UPDATED=$_cv ;;
        COUNT) C_COUNT=$_cv ;;
        DOMAINS) C_DOMAINS=$_cv ;;
        SETUP) C_SETUP=$_cv ;;
      esac
    done < "$CFG"
  fi
  list_info "$C_LIST" >/dev/null 2>&1 || C_LIST=stevenblack
  [ "$C_ENABLED" = 0 ] || C_ENABLED=1
  is_num "$C_UPDATED" || C_UPDATED=0
  is_num "$C_COUNT" || C_COUNT=0
  is_num "$C_DOMAINS" || C_DOMAINS=0
  case $C_SETUP in ready | pending | failed) ;; *) C_SETUP=ready ;; esac
}

cfg_save() {
  {
    printf 'LIST=%s\n' "$C_LIST"
    printf 'ENABLED=%s\n' "$C_ENABLED"
    printf 'ETAG=%s\n' "$C_ETAG"
    printf 'SRCDATE=%s\n' "$C_SRCDATE"
    printf 'UPDATED=%s\n' "$C_UPDATED"
    printf 'COUNT=%s\n' "$C_COUNT"
    printf 'DOMAINS=%s\n' "$C_DOMAINS"
    printf 'SETUP=%s\n' "$C_SETUP"
  } > "$CFG.tmp" && mv -f "$CFG.tmp" "$CFG"
}

# ---------------------------------------------------------------- locks

lock_pid() { _lp=; [ -f "$1/pid" ] && read -r _lp < "$1/pid"; printf '%s' "$_lp"; }

lock_alive() {
  [ -d "$1" ] || return 1
  _la=$(lock_pid "$1")
  if [ -z "$_la" ]; then
    _la_m=$(stat -c %Y "$1" 2>/dev/null)
    is_num "$_la_m" || return 1
    [ $(($(date +%s) - _la_m)) -lt 20 ]
    return
  fi
  [ -d "/proc/$_la" ] || return 1
  grep -q 'sb\.sh' "/proc/$_la/cmdline" 2>/dev/null || return 1
  return 0
}

lock_take() {
  if mkdir "$1" 2>/dev/null; then echo "$$" > "$1/pid"; return 0; fi
  lock_alive "$1" && return 1
  rm -rf "$1"
  if mkdir "$1" 2>/dev/null; then echo "$$" > "$1/pid"; return 0; fi
  return 1
}

lock_drop() { rm -rf "$1" 2>/dev/null; return 0; }
# shellcheck disable=SC2329
lock_drop_if_mine() { [ "$(lock_pid "$1")" = "$$" ] && rm -rf "$1" 2>/dev/null; return 0; }

busy_reply() { reply false busy '⏳ Another task is still running. Please wait until it finishes.'; }

# ---------------------------------------------------------------- operation state

op_load() {
  OP_KIND=; OP_LIST=; OP_PHASE=; OP_STATE=; OP_CODE=; OP_MSG=; OP_SEQ=0; OP_START=0; OP_END=0; OP_TOTAL=0; OP_DOMAINS=0; OP_REBOOT=0
  [ -f "$OPF" ] || return 0
  while IFS='=' read -r _ok _ov; do
    case $_ok in
      KIND) OP_KIND=$_ov ;;
      LIST) OP_LIST=$_ov ;;
      PHASE) OP_PHASE=$_ov ;;
      STATE) OP_STATE=$_ov ;;
      CODE) OP_CODE=$_ov ;;
      MSG) OP_MSG=$_ov ;;
      SEQ) OP_SEQ=$_ov ;;
      START) OP_START=$_ov ;;
      END) OP_END=$_ov ;;
      TOTAL) OP_TOTAL=$_ov ;;
      DOMAINS) OP_DOMAINS=$_ov ;;
      REBOOT) OP_REBOOT=$_ov ;;
    esac
  done < "$OPF"
}

op_save() {
  [ "$MODE" = install ] && return 0
  {
    printf 'KIND=%s\nLIST=%s\nPHASE=%s\nSTATE=%s\nCODE=%s\n' "$OP_KIND" "$OP_LIST" "$OP_PHASE" "$OP_STATE" "$OP_CODE"
    printf 'MSG=%s\nSEQ=%s\nSTART=%s\nEND=%s\nTOTAL=%s\n' "$OP_MSG" "$OP_SEQ" "$OP_START" "$OP_END" "$OP_TOTAL"
    printf 'DOMAINS=%s\nREBOOT=%s\n' "$OP_DOMAINS" "$OP_REBOOT"
  } > "$OPF.tmp" 2>/dev/null && mv -f "$OPF.tmp" "$OPF"
}

op_begin() {
  _ob=0
  [ -f "$SEQF" ] && read -r _ob < "$SEQF"
  is_num "$_ob" || _ob=0
  _ob=$((_ob + 1))
  echo "$_ob" > "$SEQF"
  OP_KIND=$1; OP_LIST=$2; OP_PHASE=prepare; OP_STATE=running; OP_CODE=; OP_MSG=
  OP_SEQ=$_ob; OP_START=$(now); OP_END=0; OP_TOTAL=0; OP_DOMAINS=0; OP_REBOOT=0
  rm -f "$DLPART" "$DLHDR" "$RUND/cancel"
  op_save
}

op_phase() { OP_PHASE=$1; op_save; }

op_finish() {
  OP_STATE=$1; OP_CODE=$2; OP_MSG=$3; OP_END=$(now)
  op_save
}

op_reconcile() {
  [ -f "$OPF" ] || return 0
  grep -q '^STATE=running$' "$OPF" 2>/dev/null || return 0
  lock_alive "$LOCKD" && return 0
  op_load
  OP_PHASE=; OP_STATE=error; OP_CODE=interrupted; OP_END=$(now)
  OP_MSG='⚠️ The last task was interrupted. Your hosts file is intact — run it again to finish.'
  op_save
  lock_drop "$LOCKD"
  log WARN "A background task stopped unexpectedly; its state was reset"
}

op_json() {
  op_reconcile
  if [ ! -f "$OPF" ]; then
    printf '{"running":false,"state":"idle","seq":0}'
    return 0
  fi
  _oj_b=0
  [ -f "$DLPART" ] && _oj_b=$(fsize "$DLPART")
  _oj_a=0
  lock_alive "$LOCKD" && _oj_a=1
  _oj_c=0
  [ -f "$RUND/cancel" ] && _oj_c=1
  _oj=$(awk -v bytes="$_oj_b" -v alive="$_oj_a" -v cancelling="$_oj_c" -v hdr="$DLHDR" "$AWK_OPJSON" "$OPF" 2> /dev/null)
  case $_oj in
    '{'*'}') printf '%s' "$_oj" ;;
    *) printf '{"running":%s,"state":"%s","seq":0}' "$([ "$_oj_a" = 1 ] && echo true || echo false)" "$([ "$_oj_a" = 1 ] && echo running || echo idle)" ;;
  esac
}

cancel_requested() { [ -f "$RUND/cancel" ]; }

spawn() {
  _sp_out=$1
  shift
  _sp_mark=$RUND/spawn.$$.$(date +%s)
  rm -f "$_sp_mark"
  if command -v setsid >/dev/null 2>&1; then
    SB_SPAWN_MARK=$_sp_mark setsid sh "$SELF" "$@" < /dev/null > "$_sp_out" 2>&1 &
  else
    SB_SPAWN_MARK=$_sp_mark nohup sh "$SELF" "$@" < /dev/null > "$_sp_out" 2>&1 &
  fi
  _sp_i=0
  while [ "$_sp_i" -lt 50 ]; do
    if [ -f "$_sp_mark" ]; then
      rm -f "$_sp_mark"
      return 0
    fi
    nap 0.1
    _sp_i=$((_sp_i + 1))
  done
  return 1
}

spawned() { [ -n "${SB_SPAWN_MARK:-}" ] && : > "$SB_SPAWN_MARK"; return 0; }

# ---------------------------------------------------------------- downloads

dl_detect() {
  [ -n "$DL_TOOL" ] && [ "$DL_TOOL" != none ] && return 0
  if command -v curl >/dev/null 2>&1 && curl --version >/dev/null 2>&1; then
    DL_TOOL=curl
  elif wget --help 2>&1 | grep -qi -e '--header'; then
    DL_TOOL=wget
  else
    DL_TOOL=none
    return 1
  fi
  return 0
}

hdr_parse() {
  _hp=$(awk '
    { l = $0; sub(/\r$/, "", l); sub(/^[ \t]+/, "", l); x = tolower(l) }
    x ~ /^http\/[0-9.]+[ \t]+[0-9][0-9][0-9]/ { split(l, p, /[ \t]+/); code = p[2]; cl = ""; tot = ""; et = ""; lm = ""; next }
    x ~ /^content-length:/ { v = l; sub(/^[^:]*:[ \t]*/, "", v); if (v ~ /^[0-9]+$/) cl = v; next }
    x ~ /^content-range:/ { v = l; sub(/^.*\//, "", v); if (v ~ /^[0-9]+$/) tot = v; next }
    x ~ /^etag:/ { v = l; sub(/^[^:]*:[ \t]*/, "", v); et = v; next }
    x ~ /^last-modified:/ { v = l; sub(/^[^:]*:[ \t]*/, "", v); lm = v; next }
    END { if (tot == "" && code == "200") tot = cl; print code; print cl; print tot; print et; print lm }' "$1" 2>/dev/null)
  { read -r DL_CODE; read -r DL_CL; read -r DL_TOTAL; read -r DL_ETAG; read -r DL_LASTMOD; } << EOF
$_hp
EOF
  is_num "$DL_CODE" || DL_CODE=
  is_num "$DL_CL" || DL_CL=
  is_num "$DL_TOTAL" || DL_TOTAL=
  DL_ETAG=$(clean_val "$DL_ETAG")
  DL_LASTMOD=$(clean_val "$DL_LASTMOD")
}

# dl_get URL OUT HDR MODE   MODE=full downloads everything, MODE=peek only the first 8 KB.
# curl peeks with a real HTTP Range request. BusyBox wget rejects 206 responses it did not
# ask for itself, so it streams the file and closes the connection after the first 8 KB.
dl_get() {
  _dg_u=$1; _dg_o=$2; _dg_h=$3; _dg_m=$4
  rm -f "$_dg_o" "$_dg_h.err"
  : > "$_dg_h"
  DL_FAIL=; DL_ERR=; DL_CODE=; DL_CL=; DL_TOTAL=; DL_ETAG=; DL_LASTMOD=
  case $DL_TOOL in
    curl)
      if [ "$_dg_m" = peek ]; then
        curl -sS -L --connect-timeout 15 --speed-limit 1024 --speed-time 30 -A "$UA" -r 0-8191 -D "$_dg_h" -o "$_dg_o" "$_dg_u" 2> "$_dg_h.err" &
      else
        curl -sS -L --connect-timeout 15 --speed-limit 1024 --speed-time 30 -A "$UA" -D "$_dg_h" -o "$_dg_o" "$_dg_u" 2> "$_dg_h.err" &
      fi
      ;;
    wget)
      if [ "$_dg_m" = peek ]; then
        sh -c 'wget -q -S -T 15 -U "$1" -O - "$2" 2> "$3" | head -c 8192 > "$4"' sb-peek "$UA" "$_dg_u" "$_dg_h" "$_dg_o" &
      else
        wget -q -S -T 15 -U "$UA" -O "$_dg_o" "$_dg_u" 2> "$_dg_h" &
      fi
      ;;
    *)
      DL_FAIL=network
      DL_ERR='no downloader available'
      return 1
      ;;
  esac
  _dg_p=$!
  [ -n "$DL_PIDF" ] && echo "$_dg_p" > "$DL_PIDF"
  wait "$_dg_p"
  _dg_rc=$?
  [ -n "$DL_PIDF" ] && rm -f "$DL_PIDF"
  hdr_parse "$_dg_h"
  if [ "$DL_TOOL" = curl ]; then
    DL_ERR=$(head -n 1 "$_dg_h.err" 2>/dev/null)
  else
    DL_ERR=$(grep -m 1 '^wget:' "$_dg_h" 2>/dev/null)
  fi
  DL_ERR=$(clean_val "$DL_ERR")
  rm -f "$_dg_h.err"
  if [ -z "$DL_CODE" ]; then
    DL_FAIL=network
  elif [ "$DL_CODE" != 200 ] && [ "$DL_CODE" != 206 ]; then
    DL_FAIL=http
  elif [ "$_dg_rc" -ne 0 ] && [ "$_dg_m" = full ]; then
    DL_FAIL=incomplete
  fi
  [ -z "$DL_FAIL" ]
}

dl_reason() {
  case $DL_FAIL in
    http) printf 'HTTP %s' "$DL_CODE" ;;
    incomplete) printf 'transfer interrupted%s' "${DL_ERR:+ ($DL_ERR)}" ;;
    *) printf 'no connection%s' "${DL_ERR:+ ($DL_ERR)}" ;;
  esac
}

dl_fetch() {
  _df_t=1
  while :; do
    dl_get "$1" "$2" "$3" "$4" && return 0
    if [ "$DL_FAIL" = http ]; then
      case $DL_CODE in 408 | 425 | 429 | 5??) ;; *) return 1 ;; esac
    fi
    [ "$_df_t" -ge 3 ] && return 1
    cancel_requested && return 1
    [ "$MODE" = install ] || log WARN "Download attempt $_df_t failed: $(dl_reason). Retrying"
    nap $((_df_t * 2))
    cancel_requested && return 1
    _df_t=$((_df_t + 1))
  done
}

looks_html() {
  head -c 4096 "$1" 2>/dev/null | tr '[:upper:]' '[:lower:]' | grep -q -e '<!doctype' -e '<html' -e '<head' -e '<body' -e '<title'
}

head_info() {
  _hi=$(head -c 8192 "$1" 2>/dev/null | awk "$AWK_HEAD")
  { read -r HI_COUNT; read -r HI_DATE; } << EOF
$_hi
EOF
  is_num "$HI_COUNT" || HI_COUNT=
  HI_DATE=$(clean_val "$HI_DATE")
}

date_epoch() { [ -n "$1" ] && printf '%s\n' "$1" | awk "$AWK_DATE"; return 0; }

free_kb() { df -Pk "$1" 2>/dev/null | awk 'NR == 2 { print $4 }'; }

# ---------------------------------------------------------------- hosts file

set_hosts_perm() {
  chmod 0644 "$1" 2>/dev/null
  chown 0:0 "$1" 2>/dev/null
  chcon u:object_r:system_file:s0 "$1" 2>/dev/null
  return 0
}

compile_into() {
  _ci_o=$1; _ci_e=$2; _ci_l=$3
  list_info "$C_LIST" || return 1
  if [ "$_ci_e" = 1 ]; then
    [ -s "$_ci_l" ] || return 1
    rm -f "$TMPD/compile.count"
    awk -v allowf="$ALLOWF" -v blockf="$BLOCKF" -v cntf="$TMPD/compile.count" -v ver="$SB_VER" -v name="$L_NAME" -v url="$L_URL" "$AWK_COMPILE" "$_ci_l" > "$_ci_o" 2>/dev/null || return 1
    CH_COUNT=
    [ -f "$TMPD/compile.count" ] && read -r CH_COUNT < "$TMPD/compile.count"
    rm -f "$TMPD/compile.count"
    is_num "$CH_COUNT" || return 1
  else
    {
      printf '# StevenBlock %s - systemless hosts file\n' "$SB_VER"
      printf '# Blocking is disabled. Turn it back on from the StevenBlock WebUI.\n'
      printf '# https://github.com/mikropsoft/StevenBlock\n\n'
      printf '127.0.0.1 localhost\n::1 localhost ip6-localhost\n'
    } > "$_ci_o" 2>/dev/null || return 1
    CH_COUNT=0
  fi
  return 0
}

write_clean_hosts() {
  mkdir -p "$HOSTSD"
  {
    printf '# StevenBlock %s - systemless hosts file\n' "$SB_VER"
    printf '# No blocklist is installed yet. StevenBlock downloads one as soon as it can.\n'
    printf '# https://github.com/mikropsoft/StevenBlock\n\n'
    printf '127.0.0.1 localhost\n::1 localhost ip6-localhost\n'
  } > "$HOSTSD/.hosts.sbclean" && set_hosts_perm "$HOSTSD/.hosts.sbclean" && mv -f "$HOSTSD/.hosts.sbclean" "$HOSTS"
}

backup_hosts() {
  [ -f "$HOSTS" ] || return 0
  rm -f "$BACKUPD/hosts.3"
  [ -f "$BACKUPD/hosts.2" ] && mv -f "$BACKUPD/hosts.2" "$BACKUPD/hosts.3"
  [ -f "$BACKUPD/hosts.1" ] && mv -f "$BACKUPD/hosts.1" "$BACKUPD/hosts.2"
  cp -f "$HOSTS" "$BACKUPD/hosts.1"
}

restore_backup() {
  if [ -f "$BACKUPD/hosts.1" ] && cp -f "$BACKUPD/hosts.1" "$HOSTSD/.hosts.sbrestore" 2>/dev/null; then
    set_hosts_perm "$HOSTSD/.hosts.sbrestore"
    if mv -f "$HOSTSD/.hosts.sbrestore" "$HOSTS"; then
      log WARN "Restored the previous hosts file from backup"
      return 0
    fi
  fi
  rm -f "$HOSTSD/.hosts.sbrestore"
  write_clean_hosts
  log ERROR "No usable backup was found; wrote a clean localhost-only hosts file"
  return 1
}

verify_hosts() {
  [ -s "$HOSTS" ] || return 1
  grep -qx '127\.0\.0\.1 localhost' "$HOSTS" || return 1
  grep -qx '::1 localhost ip6-localhost' "$HOSTS" || return 1
  _vh=$(grep -c '^0\.0\.0\.0 ' "$HOSTS" 2>/dev/null)
  [ "${_vh:-0}" = "$1" ]
}

# install_hosts NEWFILE EXPECTED -> 0 ok, 1 write failed, 2 verification failed. Sets IH_CHANGED.
install_hosts() {
  IH_CHANGED=1
  mkdir -p "$HOSTSD"
  if [ -f "$HOSTS" ] && cmp -s "$1" "$HOSTS"; then
    rm -f "$1"
    IH_CHANGED=0
    return 0
  fi
  backup_hosts
  set_hosts_perm "$1"
  if ! mv -f "$1" "$HOSTS"; then
    rm -f "$1"
    restore_backup
    return 1
  fi
  set_hosts_perm "$HOSTS"
  if ! verify_hosts "$2"; then
    log ERROR "The new hosts file failed verification"
    restore_backup
    return 2
  fi
  return 0
}

live_hosts() {
  if head -c 1 "$INIT_HOSTS" > /dev/null 2>&1; then printf '%s' "$INIT_HOSTS"; else printf '%s' "$SYS_HOSTS"; fi
}

mark_pending() { boot_id > "$PENDF.tmp" 2>/dev/null && mv -f "$PENDF.tmp" "$PENDF"; return 0; }

pending_flag() {
  [ -f "$PENDF" ] || return 1
  [ "$(cat "$PENDF" 2>/dev/null)" = "$(boot_id)" ]
}

applied_state() {
  if [ ! -f "$HOSTS" ]; then printf 'unknown'; return 0; fi
  if cmp -s "$(live_hosts)" "$HOSTS"; then
    printf 'applied'
  elif pending_flag; then
    printf 'pending'
  else
    printf 'overridden'
  fi
}

describe() {
  cfg_load
  list_info "$C_LIST"
  case $C_SETUP in
    pending) printf '🛡️ ⏳ Setup pending • %s downloads automatically once you are online' "$L_NAME"; return 0 ;;
    failed) printf '🛡️ ❌ Setup incomplete • Open the WebUI and pick a list to finish setup'; return 0 ;;
  esac
  _ds=$(applied_state)
  if [ "$_ds" = pending ]; then
    if [ "$C_ENABLED" = 1 ]; then
      printf '🛡️ 🟡 Reboot required • %s • %s domains ready' "$L_NAME" "$(fmt_num "$C_DOMAINS")"
    else
      printf '🛡️ 🟡 Reboot required • Blocking will be turned off'
    fi
  elif [ "$C_ENABLED" != 1 ]; then
    printf '🛡️ 🔴 Disabled • %s is paused' "$L_NAME"
  elif [ "$_ds" = overridden ]; then
    printf '🛡️ ⚠️ Overridden • Another module replaces /system/etc/hosts'
  else
    printf '🛡️ 🟢 Active • %s • %s domains blocked' "$L_NAME" "$(fmt_num "$C_DOMAINS")"
  fi
}

set_description() {
  [ -f "$PROP" ] || return 0
  _sd=$(describe)
  awk -v d="$_sd" 'BEGIN { f = 0 } /^description=/ { if (!f) print "description=" d; f = 1; next } { print } END { if (!f) print "description=" d }' "$PROP" > "$PROP.sbtmp" 2>/dev/null && mv -f "$PROP.sbtmp" "$PROP"
  chmod 0644 "$PROP" 2>/dev/null
  return 0
}

flush_dns() {
  _fd=
  if [ -x /system/bin/ndc ]; then
    case $(/system/bin/ndc resolver flushdefaultif 2>&1) in 200*) _fd='flushdefaultif' ;; esac
    _fd_ip=/system/bin/ip
    [ -x "$_fd_ip" ] || _fd_ip=ip
    for _fd_n in $("$_fd_ip" rule 2>/dev/null | awk '{ for (i = 1; i < NF; i++) if ($i == "fwmark" && $(i + 1) ~ /^0x1[0-9a-f][0-9a-f][0-9a-f][0-9a-f]\/0x1ffff$/) print substr($(i + 1), 4, 4) }' | sort -u); do
      _fd_id=$((0x$_fd_n))
      case $(/system/bin/ndc resolver flushnet "$_fd_id" 2>&1) in 200*) _fd="${_fd:+$_fd, }flushnet $_fd_id" ;; esac
    done
  fi
  if [ -n "$_fd" ]; then
    log INFO "DNS cache flushed ($_fd)"
  else
    log INFO "DNS cache flush is not available on this Android version; the reboot clears it"
  fi
  return 0
}

conflicts() {
  _cf=
  for _cf_d in "$MODROOT"/*; do
    [ -d "$_cf_d" ] || continue
    _cf_i=${_cf_d##*/}
    [ "$_cf_i" = stevenblock ] && continue
    [ -f "$_cf_d/system/etc/hosts" ] || continue
    [ -f "$_cf_d/disable" ] && continue
    [ -f "$_cf_d/remove" ] && continue
    _cf="$_cf $_cf_i"
  done
  printf '%s' "${_cf# }"
}

detect_manager() {
  MGR_NAME=; MGR_VER=
  _dm_b=$(boot_id)
  if [ -f "$RUND/manager" ]; then
    { read -r _dm_c; read -r MGR_NAME; read -r MGR_VER; } < "$RUND/manager"
    [ "$_dm_c" = "$_dm_b" ] && [ -n "$MGR_NAME" ] && return 0
  fi
  if [ "${APATCH:-}" = true ] || [ -x /data/adb/apd ]; then
    MGR_NAME=APatch
    MGR_VER=${APATCH_VER:-$(timeout 3 /data/adb/apd -V 2>/dev/null | head -n 1)}
  elif [ "${KSU:-}" = true ] || [ -x /data/adb/ksud ]; then
    if [ -d /data/data/com.sukisu.ultra ]; then
      MGR_NAME='SukiSU Ultra'
    elif [ -d /data/data/com.rifsxd.ksunext ]; then
      MGR_NAME='KernelSU Next'
    else
      MGR_NAME=KernelSU
    fi
    MGR_VER=${KSU_VER:-$(timeout 3 /data/adb/ksud -V 2>/dev/null | head -n 1)}
  elif [ -n "${MAGISK_VER:-}" ] || [ -d /data/adb/magisk ]; then
    MGR_NAME=Magisk
    MGR_VER=${MAGISK_VER:-$(timeout 3 magisk -v 2>/dev/null | head -n 1)}
    MGR_VER=${MGR_VER%%:*}
  else
    MGR_NAME=Unknown
  fi
  case $MGR_VER in *' '*) MGR_VER=${MGR_VER##* } ;; esac
  MGR_VER=$(clean_val "$MGR_VER")
  [ -d "$RUND" ] && printf '%s\n%s\n%s\n' "$_dm_b" "$MGR_NAME" "$MGR_VER" > "$RUND/manager" 2>/dev/null
  return 0
}

httpd_available() { [ "$SB_BB" != none ] && "$SB_BB" --list 2>/dev/null | grep -qx httpd; }

open_url() {
  [ -x /system/bin/am ] || return 1
  _ou=$(/system/bin/am start -a android.intent.action.VIEW -d "$1" 2>&1) || return 1
  case $_ou in *Error* | *error:* | *Exception*) return 1 ;; esac
  return 0
}

# ---------------------------------------------------------------- metadata (entry count and date)

meta_load() {
  M_COUNT=; M_EPOCH=; M_RAW=; M_ERR=; M_FETCHED=0; M_SIZE=
  [ -f "$METAD/$1" ] || return 1
  while IFS='=' read -r _mk _mv; do
    case $_mk in
      COUNT) M_COUNT=$_mv ;;
      EPOCH) M_EPOCH=$_mv ;;
      RAW) M_RAW=$_mv ;;
      ERR) M_ERR=$_mv ;;
      FETCHED) M_FETCHED=$_mv ;;
      SIZE) M_SIZE=$_mv ;;
    esac
  done < "$METAD/$1"
  is_num "$M_FETCHED" || M_FETCHED=0
  return 0
}

meta_save() {
  {
    printf 'COUNT=%s\nEPOCH=%s\nRAW=%s\n' "$2" "$3" "$4"
    printf 'ERR=%s\nFETCHED=%s\nSIZE=%s\n' "$5" "$(now)" "$6"
  } > "$METAD/$1.tmp" 2>/dev/null && mv -f "$METAD/$1.tmp" "$METAD/$1"
}

meta_fetch_one() {
  list_info "$1" || return 0
  _mf_b=$TMPD/meta.$1.body
  _mf_h=$TMPD/meta.$1.hdr
  if [ "$DL_TOOL" = none ] || [ -z "$DL_TOOL" ]; then
    meta_save "$1" '' '' '' no_downloader ''
  elif ! dl_fetch "$L_URL" "$_mf_b" "$_mf_h" peek; then
    meta_save "$1" '' '' '' "${DL_FAIL:-network}" ''
    log WARN "Could not fetch details for $L_NAME: $(dl_reason)"
  else
    head_info "$_mf_b"
    _mf_c=$HI_COUNT
    _mf_d=$HI_DATE
    _mf_s=$DL_TOTAL
    [ -n "$_mf_d" ] || _mf_d=$DL_LASTMOD
    if [ -z "$_mf_c" ]; then
      _mf_full=0
      if [ "$DL_CODE" = 200 ] && [ "$DL_TOOL" = curl ]; then
        [ -z "$DL_CL" ] || [ "$(fsize "$_mf_b")" = "$DL_CL" ] && _mf_full=1
      fi
      if [ "$_mf_full" = 0 ]; then
        dl_fetch "$L_URL" "$_mf_b" "$_mf_h" full && _mf_full=1
        [ -n "$DL_TOTAL" ] && _mf_s=$DL_TOTAL
      fi
      if [ "$_mf_full" = 1 ] && ! looks_html "$_mf_b"; then
        rm -f "$TMPD/meta.$1.count"
        awk -v cntf="$TMPD/meta.$1.count" "$AWK_NORM" "$_mf_b" > /dev/null 2>&1
        [ -f "$TMPD/meta.$1.count" ] && read -r _mf_c < "$TMPD/meta.$1.count"
        rm -f "$TMPD/meta.$1.count"
        is_num "$_mf_c" && [ "$_mf_c" -gt 0 ] || _mf_c=
      fi
    fi
    if [ -n "$_mf_c" ]; then
      meta_save "$1" "$_mf_c" "$(date_epoch "$_mf_d")" "$_mf_d" '' "$_mf_s"
    else
      meta_save "$1" '' "$(date_epoch "$_mf_d")" "$_mf_d" count_unavailable "$_mf_s"
      log WARN "Could not determine the entry count of $L_NAME"
    fi
  fi
  rm -f "$_mf_b" "$_mf_h" "$_mf_h.err" "$METAD/$1.busy"
}

meta_start() {
  lock_take "$METALOCK" || return 1
  for _ms in "$@"; do : > "$METAD/$_ms.busy"; done
  if spawn "$RUND/meta.out" _meta "$@"; then
    return 0
  fi
  for _ms in "$@"; do rm -f "$METAD/$_ms.busy"; done
  lock_drop "$METALOCK"
  return 1
}

meta_worker_main() {
  MODE=worker
  echo "$$" > "$METALOCK/pid" 2>/dev/null
  spawned
  trap 'rm -f "$METAD"/*.busy; lock_drop_if_mine "$METALOCK"' EXIT
  trap 'exit 143' TERM INT HUP
  dl_detect
  for _mw in "$@"; do
    list_info "$_mw" || continue
    (
      trap - EXIT TERM INT HUP
      meta_fetch_one "$_mw"
    ) &
  done
  wait
}

list_item_json() {
  list_info "$1"
  meta_load "$1"
  _li_host=${L_URL#*://}
  _li_host=${_li_host%%/*}
  printf '{"id":"%s","name":%s,"group":"%s","level":"%s","levelText":%s,"desc":%s,"host":%s,"count":%s,"date":%s,"dateRaw":%s,"size":%s,"error":%s,"fetched":%s,"busy":%s}' \
    "$1" "$(jstr "$L_NAME")" "$L_GROUP" "$L_LEVEL" "$(jstr "$L_LEVELTXT")" "$(jstr "$L_DESC")" "$(jstr "$_li_host")" \
    "$(jnum "$M_COUNT")" "$(jnum "$M_EPOCH")" "$(jstr "$M_RAW")" "$(jnum "$M_SIZE")" "$(jstr "$M_ERR")" "$(jnum "$M_FETCHED")" "$2"
}

# ---------------------------------------------------------------- the download / apply pipeline

pl_set() { PL_CODE=$1; PL_MSG=$2; }

pl_cancelled() {
  pl_set cancelled '✖️ Cancelled. Nothing was changed.'
  log INFO "Cancelled by the user; nothing was changed"
}

pl_download_error() {
  case $DL_FAIL in
    http) pl_set http_error "🌐 The list server answered with HTTP $DL_CODE. Nothing was changed — please try again later." ;;
    incomplete) pl_set download_interrupted '✂️ The download was interrupted. Nothing was changed — please try again.' ;;
    *) pl_set network_error "🌐 Couldn’t reach the list server. Check your connection and try again." ;;
  esac
  log ERROR "Download of $L_NAME failed: $(dl_reason)"
}

pl_cleanup() {
  rm -f "$DLPART" "$DLHDR" "$DLHDR.err" "$TMPD/list.new" "$TMPD/norm.count" "$TMPD/peek.body" "$TMPD/peek.hdr" "$TMPD/peek.hdr.err" "$CACHED/list.domains.new" "$RUND/cancel" "$RUND/dl.pid" 2>/dev/null
  rm -f "$HOSTSD"/.hosts.sb* 2>/dev/null
  return 0
}

# pipeline KIND LIST  (KIND: apply | update | enable | setup)
pipeline() {
  PL_KIND=$1; PL_ID=$2; PL_CODE=; PL_MSG=; PL_REBOOT=0; PL_DOMAINS=0
  if ! list_info "$PL_ID"; then
    pl_set invalid_list '❌ Unknown list.'
    return 1
  fi
  ensure_dirs
  pl_cleanup
  op_phase prepare
  if ! dl_detect; then
    pl_set no_downloader '❌ No downloader available. StevenBlock needs curl or BusyBox wget with HTTPS support.'
    log ERROR "No downloader available (curl or BusyBox wget)"
    return 1
  fi

  if [ "$PL_KIND" = update ]; then
    op_phase check
    say "🔎 Checking $L_NAME for updates…"
    log INFO "Checking $L_NAME for updates"
    if ! dl_fetch "$L_URL" "$TMPD/peek.body" "$TMPD/peek.hdr" peek; then
      cancel_requested && { pl_cancelled; pl_cleanup; return 1; }
      pl_download_error
      pl_cleanup
      return 1
    fi
    head_info "$TMPD/peek.body"
    _pl_et=$DL_ETAG
    _pl_sd=$HI_DATE
    rm -f "$TMPD/peek.body" "$TMPD/peek.hdr"
    cfg_load
    _pl_same=0
    if [ -n "$_pl_et" ] && [ -n "$C_ETAG" ]; then
      [ "$_pl_et" = "$C_ETAG" ] && _pl_same=1
    elif [ -n "$_pl_sd" ] && [ -n "$C_SRCDATE" ]; then
      [ "$_pl_sd" = "$C_SRCDATE" ] && _pl_same=1
    fi
    if [ "$_pl_same" = 1 ] && [ -s "$LISTCACHE" ]; then
      PL_DOMAINS=$C_DOMAINS
      pl_set up_to_date "✅ Already up to date — $L_NAME has no new changes."
      log INFO "$L_NAME is already up to date"
      return 0
    fi
    cancel_requested && { pl_cancelled; return 1; }
  fi

  _pl_need=51200
  if meta_load "$PL_ID" && is_num "$M_SIZE"; then
    _pl_est=$((M_SIZE * 4 / 1024))
    [ "$_pl_est" -gt "$_pl_need" ] && _pl_need=$_pl_est
  fi
  _pl_free=$(free_kb "$DATA")
  if is_num "$_pl_free" && [ "$_pl_free" -lt "$_pl_need" ]; then
    pl_set no_space "💾 Not enough free storage. About $((_pl_need / 1024)) MB is needed, $((_pl_free / 1024)) MB is available."
    log ERROR "Not enough free storage: need ${_pl_need} KB, ${_pl_free} KB available"
    return 1
  fi

  op_phase download
  say "⬇️ Downloading $L_NAME…"
  log INFO "Downloading $L_NAME"
  DL_PIDF=$RUND/dl.pid
  if ! dl_fetch "$L_URL" "$DLPART" "$DLHDR" full; then
    DL_PIDF=
    if cancel_requested; then pl_cancelled; else pl_download_error; fi
    pl_cleanup
    return 1
  fi
  DL_PIDF=
  if cancel_requested; then pl_cancelled; pl_cleanup; return 1; fi

  op_phase verify
  _pl_size=$(fsize "$DLPART")
  OP_TOTAL=${DL_CL:-0}
  if [ "$DL_CODE" != 200 ]; then
    pl_set http_error "🌐 The list server answered with HTTP $DL_CODE instead of the list. Nothing was changed."
    log ERROR "Unexpected HTTP status $DL_CODE for $L_NAME"
    pl_cleanup
    return 1
  fi
  if [ "$_pl_size" -eq 0 ]; then
    pl_set empty_file '📭 The server sent an empty file. Nothing was changed.'
    log ERROR "Downloaded file for $L_NAME was empty"
    pl_cleanup
    return 1
  fi
  if looks_html "$DLPART"; then
    pl_set html_page '🧱 The server sent a web page instead of a hosts list. Nothing was changed.'
    log ERROR "Downloaded file for $L_NAME was an HTML page"
    pl_cleanup
    return 1
  fi
  if [ -n "$DL_CL" ] && [ "$DL_CL" != "$_pl_size" ]; then
    pl_set size_mismatch "✂️ The download was incomplete ($(fmt_mb "$_pl_size") of $(fmt_mb "$DL_CL")). Nothing was changed."
    log ERROR "Incomplete download for $L_NAME: $_pl_size of $DL_CL bytes"
    pl_cleanup
    return 1
  fi
  say "✅ Downloaded $(fmt_mb "$_pl_size")"
  head_info "$DLPART"
  _pl_hc=$HI_COUNT
  _pl_hd=$HI_DATE
  [ -n "$_pl_hd" ] || _pl_hd=$DL_LASTMOD
  _pl_et=$DL_ETAG
  if cancel_requested; then pl_cancelled; pl_cleanup; return 1; fi

  op_phase optimize
  say "🧹 Cleaning and optimizing entries…"
  rm -f "$TMPD/norm.count"
  if ! awk -v cntf="$TMPD/norm.count" "$AWK_NORM" "$DLPART" > "$TMPD/list.new" 2>/dev/null; then
    pl_set process_failed '❌ The list could not be processed. Nothing was changed.'
    log ERROR "Processing $L_NAME failed"
    pl_cleanup
    return 1
  fi
  _pl_n=0
  [ -f "$TMPD/norm.count" ] && read -r _pl_n < "$TMPD/norm.count"
  is_num "$_pl_n" || _pl_n=0
  rm -f "$DLPART" "$TMPD/norm.count"
  if [ "$_pl_n" -lt 1000 ]; then
    pl_set too_few_entries "📉 Only $(fmt_num "$_pl_n") valid entries were found (at least 1,000 are required). Nothing was changed."
    log ERROR "$L_NAME had only $_pl_n valid entries"
    pl_cleanup
    return 1
  fi
  say "✅ Verified $(fmt_num "$_pl_n") unique domains"
  if cancel_requested; then pl_cancelled; pl_cleanup; return 1; fi

  op_phase install
  rm -f "$RUND/cancel"
  if ! mv -f "$TMPD/list.new" "$CACHED/list.domains.new"; then
    pl_set write_failed "❌ Couldn’t save the processed list. Nothing was changed."
    log ERROR "Could not stage the processed list"
    pl_cleanup
    return 1
  fi
  cfg_load
  _pl_prev=$C_LIST
  C_LIST=$PL_ID
  if ! compile_into "$HOSTSD/.hosts.sbnew" 1 "$CACHED/list.domains.new"; then
    C_LIST=$_pl_prev
    pl_set write_failed "❌ Couldn’t build the new hosts file. Nothing was changed."
    log ERROR "Could not build the hosts file for $L_NAME"
    pl_cleanup
    return 1
  fi
  install_hosts "$HOSTSD/.hosts.sbnew" "$CH_COUNT"
  case $? in
    1)
      pl_set write_failed "❌ Couldn’t write the hosts file. Your previous hosts file was restored."
      log ERROR "Could not write the hosts file for $L_NAME"
      pl_cleanup
      return 1
      ;;
    2)
      pl_set verify_failed '❌ The new hosts file failed verification. Your previous hosts file was restored.'
      pl_cleanup
      return 1
      ;;
  esac
  mv -f "$CACHED/list.domains.new" "$LISTCACHE"
  C_ENABLED=1
  C_ETAG=$_pl_et
  C_SRCDATE=$_pl_hd
  C_UPDATED=$(now)
  C_COUNT=$_pl_n
  C_DOMAINS=$CH_COUNT
  C_SETUP=ready
  cfg_save
  meta_save "$PL_ID" "${_pl_hc:-$_pl_n}" "$(date_epoch "$_pl_hd")" "$_pl_hd" '' "$_pl_size"

  op_phase finish
  PL_DOMAINS=$CH_COUNT
  if [ "$IH_CHANGED" = 1 ]; then
    PL_REBOOT=1
    mark_pending
    flush_dns
  fi
  set_description
  case $PL_KIND in
    update) _pl_msg="✅ $L_NAME updated — $(fmt_num "$CH_COUNT") domains." ;;
    enable) _pl_msg="🟢 Blocking is back on with $L_NAME — $(fmt_num "$CH_COUNT") domains." ;;
    *) _pl_msg="✅ $L_NAME is ready — $(fmt_num "$CH_COUNT") domains." ;;
  esac
  if [ "$IH_CHANGED" = 1 ]; then
    _pl_msg="$_pl_msg Reboot to activate it."
    _pl_code=applied
  else
    _pl_msg="✅ $L_NAME is up to date — the hosts file didn’t change."
    _pl_code=unchanged
  fi
  pl_set "$_pl_code" "$_pl_msg"
  log INFO "$L_NAME installed: $(fmt_num "$CH_COUNT") domains ($(fmt_num "$_pl_n") from the list)$( [ "$IH_CHANGED" = 1 ] && printf ', reboot required')"
  pl_cleanup
  return 0
}

# rebuild the hosts file from the cached list after a rule change
rebuild() {
  RB_CHANGED=0; RB_STATE=ok
  cfg_load
  if [ "$C_ENABLED" != 1 ]; then RB_STATE=disabled; return 0; fi
  if [ "$C_SETUP" != ready ] || [ ! -s "$LISTCACHE" ]; then RB_STATE=nocache; return 0; fi
  if ! compile_into "$HOSTSD/.hosts.sbnew" 1 "$LISTCACHE"; then
    rm -f "$HOSTSD/.hosts.sbnew"
    RB_STATE=write_failed
    return 1
  fi
  install_hosts "$HOSTSD/.hosts.sbnew" "$CH_COUNT"
  case $? in
    1) RB_STATE=write_failed; return 1 ;;
    2) RB_STATE=verify_failed; return 1 ;;
  esac
  RB_CHANGED=$IH_CHANGED
  C_DOMAINS=$CH_COUNT
  cfg_save
  [ "$RB_CHANGED" = 1 ] && mark_pending
  set_description
  return 0
}

# ---------------------------------------------------------------- domains

extract_domain() {
  _ed=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
  _ed=${_ed#"${_ed%%[! 	]*}"}
  _ed=${_ed%"${_ed##*[! 	]}"}
  case $_ed in
    *://*)
      _ed=${_ed#*://}
      _ed=${_ed%%/*}
      _ed=${_ed%%\?*}
      _ed=${_ed%%#*}
      _ed=${_ed##*@}
      case $_ed in \[*) ;; *:*) _ed=${_ed%:*} ;; esac
      ;;
    */* | *\?* | *#*)
      _ed=${_ed%%/*}
      _ed=${_ed%%\?*}
      _ed=${_ed%%#*}
      ;;
  esac
  printf '%s' "${_ed%.}"
}

domain_problem() {
  if [ -z "$1" ]; then printf '✏️ Enter a domain first.'; return 0; fi
  case $1 in
    *' '* | *"$TAB"*) printf "🚫 Spaces aren’t allowed in a domain."; return 0 ;;
    *'*'*) printf "🚫 Wildcards (*) aren’t supported by hosts files. Enter the exact domain."; return 0 ;;
    \[* | *:*) printf "🚫 Ports and IPv6 addresses aren’t allowed. Enter just the domain, like example.com."; return 0 ;;
  esac
  case $1 in *[!0-9.]*) ;; *) printf "🚫 IP addresses aren’t allowed. Enter a domain name instead."; return 0 ;; esac
  if ! printf '%s\n' "$1" | awk "$AWK_VALID"; then
    printf "🚫 That doesn’t look like a valid domain. Example: ads.example.com"
  fi
  return 0
}

rules_json() {
  printf '{"allow":%s,"block":%s}' "$(rules_array "$ALLOWF")" "$(rules_array "$BLOCKF")"
}

rules_array() {
  if [ -s "$1" ]; then
    awk 'BEGIN { ORS = ""; printf "[" } NF { printf "%s\"%s\"", (n++ ? "," : ""), $1 } END { printf "]" }' "$1"
  else
    printf '[]'
  fi
}

# ---------------------------------------------------------------- public commands

cmd_status() {
  op_reconcile
  cfg_load
  detect_manager
  list_info "$C_LIST"
  _st_app=$(applied_state)
  _st_cf=$(conflicts)
  _st_cfj=$(printf '%s\n' "$_st_cf" | awk 'BEGIN { ORS = ""; printf "[" } { for (i = 1; i <= NF; i++) printf "%s\"%s\"", (n++ ? "," : ""), $i } END { printf "]" }')
  _st_en=false; [ "$C_ENABLED" = 1 ] && _st_en=true
  _st_rb=false; [ "$_st_app" = pending ] && _st_rb=true
  _st_hd=false; httpd_available && _st_hd=true
  _st_aa=false; [ -d /data/data/org.adaway ] && _st_aa=true
  _st_d=$(printf '{"version":"%s","versionCode":%s,"manager":%s,"managerVersion":%s,"enabled":%s,"list":"%s","listName":%s,"level":"%s","levelText":%s,"domains":%s,"listCount":%s,"allow":%s,"block":%s,"updated":%s,"sourceDate":%s,"reboot":%s,"applied":"%s","setup":"%s","conflicts":%s,"adaway":%s,"httpd":%s,"op":%s}' \
    "$SB_VER" "$SB_VCODE" "$(jstr "$MGR_NAME")" "$(jstr "$MGR_VER")" "$_st_en" "$C_LIST" "$(jstr "$L_NAME")" "$L_LEVEL" "$(jstr "$L_LEVELTXT")" \
    "$C_DOMAINS" "$C_COUNT" "$(count_lines "$ALLOWF")" "$(count_lines "$BLOCKF")" "$C_UPDATED" "$(jstr "$C_SRCDATE")" \
    "$_st_rb" "$_st_app" "$C_SETUP" "$_st_cfj" "$_st_aa" "$_st_hd" "$(op_json)")
  reply true status '' "$_st_d"
}

cmd_progress() { reply true progress '' "$(op_json)"; }

cmd_lists() {
  _cl_now=$(now)
  _cl_stale=
  for _cl_id in $LIST_IDS; do
    if meta_load "$_cl_id"; then
      _cl_age=$((_cl_now - M_FETCHED))
      if [ -n "$M_ERR" ]; then
        [ "$_cl_age" -ge 900 ] && _cl_stale="$_cl_stale $_cl_id"
      elif [ "$_cl_age" -ge 21600 ] || [ "$_cl_age" -lt 0 ]; then
        _cl_stale="$_cl_stale $_cl_id"
      fi
    else
      _cl_stale="$_cl_stale $_cl_id"
    fi
  done
  _cl_ref=false
  if lock_alive "$METALOCK"; then
    _cl_ref=true
  elif [ -n "$_cl_stale" ]; then
    # shellcheck disable=SC2086
    meta_start $_cl_stale && _cl_ref=true
  fi
  _cl_items=
  for _cl_id in $LIST_IDS; do
    _cl_busy=false
    [ "$_cl_ref" = true ] && [ -f "$METAD/$_cl_id.busy" ] && _cl_busy=true
    _cl_items="$_cl_items${_cl_items:+,}$(list_item_json "$_cl_id" "$_cl_busy")"
  done
  cfg_load
  _cl_en=false; [ "$C_ENABLED" = 1 ] && _cl_en=true
  reply true lists '' "{\"lists\":[$_cl_items],\"refreshing\":$_cl_ref,\"active\":\"$C_LIST\",\"enabled\":$_cl_en,\"setup\":\"$C_SETUP\"}"
}

cmd_meta_refresh() {
  if [ -n "$1" ]; then
    if ! list_info "$1"; then reply false invalid_list '❌ Unknown list.'; return 0; fi
    _mr=$1
  else
    _mr=$LIST_IDS
  fi
  if lock_alive "$METALOCK"; then
    reply true refreshing '🔄 Already refreshing list details…' '{"refreshing":true}'
    return 0
  fi
  # shellcheck disable=SC2086
  if meta_start $_mr; then
    reply true refreshing '🔄 Refreshing list details…' '{"refreshing":true}'
  else
    reply false refresh_failed "❌ Couldn’t start refreshing list details. Please try again." '{"refreshing":false}'
  fi
}

start_job() {
  op_begin "$1" "$2"
  if spawn "$RUND/worker.out" _worker "$1" "$2"; then
    return 0
  fi
  op_finish error spawn_failed "❌ Couldn’t start the background task. Please try again."
  lock_drop "$LOCKD"
  log ERROR "Could not start a background task"
  return 1
}

cmd_apply() {
  if ! list_info "$1"; then reply false invalid_list '❌ Unknown list.'; return 0; fi
  _ap_id=$1
  cfg_load
  if [ "$C_ENABLED" != 1 ]; then reply false blocker_disabled '⏻ Enable the blocker first.'; return 0; fi
  if [ "$C_LIST" = "$_ap_id" ] && [ "$C_SETUP" = ready ] && [ -s "$LISTCACHE" ]; then
    reply false already_active '⚠️ This list is already active. Use Update Current List instead.'
    return 0
  fi
  lock_take "$LOCKD" || { busy_reply; return 0; }
  list_info "$_ap_id"
  log INFO "Switching to $L_NAME"
  if start_job apply "$_ap_id"; then
    reply true started "⬇️ Downloading $L_NAME…" "{\"op\":$(op_json)}"
  else
    reply false spawn_failed "❌ Couldn’t start the background task. Please try again."
  fi
}

cmd_update() {
  cfg_load
  if [ "$C_ENABLED" != 1 ]; then reply false blocker_disabled '⏻ Enable the blocker first.'; return 0; fi
  lock_take "$LOCKD" || { busy_reply; return 0; }
  list_info "$C_LIST"
  _up_kind=update
  [ "$C_SETUP" = ready ] && [ -s "$LISTCACHE" ] || _up_kind=setup
  if start_job "$_up_kind" "$C_LIST"; then
    reply true started "🔄 Checking $L_NAME for updates…" "{\"op\":$(op_json)}"
  else
    reply false spawn_failed "❌ Couldn’t start the background task. Please try again."
  fi
}

cmd_cancel() {
  op_reconcile
  op_load
  if [ "$OP_STATE" != running ]; then
    reply false not_running 'ℹ️ There is nothing to cancel.'
    return 0
  fi
  case $OP_PHASE in
    prepare | check | download | verify | optimize)
      : > "$RUND/cancel"
      _cc=
      [ -f "$RUND/dl.pid" ] && read -r _cc < "$RUND/dl.pid"
      is_num "$_cc" && kill "$_cc" 2>/dev/null
      log INFO "Cancel requested"
      reply true cancelling '✖️ Cancelling…'
      ;;
    *)
      reply false too_late "⏳ Almost done — the new hosts file is being installed and can’t be cancelled now."
      ;;
  esac
}

cmd_rules() { reply true rules '' "$(rules_json)"; }

rule_files() {
  case $1 in
    allow) RF=$ALLOWF; RF_OTHER=$BLOCKF; RF_NAME=Allow; RF_OTHERNAME=Block ;;
    block) RF=$BLOCKF; RF_OTHER=$ALLOWF; RF_NAME=Block; RF_OTHERNAME=Allow ;;
    *) return 1 ;;
  esac
  return 0
}

cmd_rule_add() {
  if ! rule_files "$1"; then reply false invalid_type '❌ Unknown rule type.'; return 0; fi
  _ra=$(extract_domain "$2")
  _ra_p=$(domain_problem "$_ra")
  if [ -n "$_ra_p" ]; then reply false rule_invalid "$_ra_p"; return 0; fi
  if grep -qxF "$_ra" "$RF" 2>/dev/null; then
    reply false rule_exists "⚠️ $_ra is already in your $RF_NAME list."
    return 0
  fi
  if grep -qxF "$_ra" "$RF_OTHER" 2>/dev/null; then
    reply false rule_conflict "⚠️ Already in $RF_OTHERNAME list. Remove $_ra there first."
    return 0
  fi
  if [ "$(count_lines "$RF")" -ge 1000 ]; then
    reply false rule_limit "📦 You’ve reached the limit of 1,000 rules for this list. Remove some first."
    return 0
  fi
  lock_take "$LOCKD" || { busy_reply; return 0; }
  cp -f "$RF" "$RF.undo" 2>/dev/null
  if ! { cat "$RF" 2>/dev/null; printf '%s\n' "$_ra"; } > "$RF.tmp" || ! mv -f "$RF.tmp" "$RF"; then
    rm -f "$RF.tmp" "$RF.undo"
    lock_drop "$LOCKD"
    reply false write_failed "❌ Couldn’t save the rule. Please try again."
    return 0
  fi
  if ! rebuild; then
    mv -f "$RF.undo" "$RF"
    lock_drop "$LOCKD"
    log ERROR "Rebuilding the hosts file failed after adding $_ra; the rule was rolled back"
    reply false "$RB_STATE" "❌ Couldn’t rebuild the hosts file, so the rule was not added. Your previous hosts file is in place."
    return 0
  fi
  rm -f "$RF.undo"
  lock_drop "$LOCKD"
  _ra_inlist=0
  [ -s "$LISTCACHE" ] && grep -qxF "$_ra" "$LISTCACHE" 2>/dev/null && _ra_inlist=1
  if [ "$1" = allow ]; then _ra_e='✅'; _ra_v=allowed; else _ra_e='⛔'; _ra_v=blocked; fi
  case $RB_STATE in
    disabled) _ra_m="$_ra_e $_ra saved to your $RF_NAME list. It applies when you enable the blocker." ;;
    nocache) _ra_m="$_ra_e $_ra saved to your $RF_NAME list. It applies once your list is downloaded." ;;
    *)
      if [ "$RB_CHANGED" = 1 ]; then
        _ra_m="$_ra_e $_ra $_ra_v. Reboot to apply."
      elif [ "$1" = allow ] && [ "$_ra_inlist" = 0 ]; then
        _ra_m="$_ra_e $_ra allowed. It isn’t on your current list, so nothing changes right now."
      elif [ "$1" = block ] && [ "$_ra_inlist" = 1 ]; then
        _ra_m="$_ra_e $_ra blocked. Your current list already blocks it."
      else
        _ra_m="$_ra_e $_ra $_ra_v."
      fi
      ;;
  esac
  log INFO "$RF_NAME rule added: $_ra"
  _ra_rb=false; [ "$RB_CHANGED" = 1 ] && _ra_rb=true
  reply true rule_added "$_ra_m" "{\"rules\":$(rules_json),\"changed\":$_ra_rb}"
}

cmd_rule_del() {
  if ! rule_files "$1"; then reply false invalid_type '❌ Unknown rule type.'; return 0; fi
  _rd=$(extract_domain "$2")
  if [ -z "$_rd" ] || [ -n "$(domain_problem "$_rd")" ] || ! grep -qxF "$_rd" "$RF" 2>/dev/null; then
    reply false rule_missing "⚠️ That domain isn’t in your $RF_NAME list."
    return 0
  fi
  lock_take "$LOCKD" || { busy_reply; return 0; }
  cp -f "$RF" "$RF.undo" 2>/dev/null
  grep -vxF "$_rd" "$RF" > "$RF.tmp" 2>/dev/null
  if [ $? -gt 1 ] || ! mv -f "$RF.tmp" "$RF"; then
    rm -f "$RF.tmp" "$RF.undo"
    lock_drop "$LOCKD"
    reply false write_failed "❌ Couldn’t remove the rule. Please try again."
    return 0
  fi
  if ! rebuild; then
    mv -f "$RF.undo" "$RF"
    lock_drop "$LOCKD"
    log ERROR "Rebuilding the hosts file failed after removing $_rd; the rule was restored"
    reply false "$RB_STATE" "❌ Couldn’t rebuild the hosts file, so the rule was kept. Your previous hosts file is in place."
    return 0
  fi
  rm -f "$RF.undo"
  lock_drop "$LOCKD"
  log INFO "$RF_NAME rule removed: $_rd"
  _rd_m="🗑️ Removed $_rd from your $RF_NAME list."
  [ "$RB_CHANGED" = 1 ] && _rd_m="$_rd_m Reboot to apply."
  _rd_rb=false; [ "$RB_CHANGED" = 1 ] && _rd_rb=true
  reply true rule_removed "$_rd_m" "{\"rules\":$(rules_json),\"changed\":$_rd_rb}"
}

cmd_disable() {
  cfg_load
  if [ "$C_ENABLED" != 1 ]; then reply false already_disabled '🔴 The blocker is already disabled.'; return 0; fi
  lock_take "$LOCKD" || { busy_reply; return 0; }
  if ! compile_into "$HOSTSD/.hosts.sbnew" 0; then
    rm -f "$HOSTSD/.hosts.sbnew"
    lock_drop "$LOCKD"
    reply false write_failed "❌ Couldn’t write the hosts file. Nothing was changed."
    return 0
  fi
  install_hosts "$HOSTSD/.hosts.sbnew" 0
  _ds_rc=$?
  if [ "$_ds_rc" != 0 ]; then
    lock_drop "$LOCKD"
    reply false write_failed "❌ Couldn’t write the hosts file. Your previous hosts file was restored."
    return 0
  fi
  C_ENABLED=0
  cfg_save
  [ "$IH_CHANGED" = 1 ] && mark_pending
  set_description
  lock_drop "$LOCKD"
  log INFO "Blocker disabled; list and rules are kept"
  reply true disabled '🔴 Blocker disabled. Reboot to stop blocking. Your list and rules are kept.'
}

cmd_enable() {
  cfg_load
  if [ "$C_ENABLED" = 1 ]; then reply false already_enabled '🟢 The blocker is already enabled.'; return 0; fi
  lock_take "$LOCKD" || { busy_reply; return 0; }
  list_info "$C_LIST"
  if [ "$C_SETUP" = ready ] && [ -s "$LISTCACHE" ]; then
    C_ENABLED=1
    if ! compile_into "$HOSTSD/.hosts.sbnew" 1 "$LISTCACHE"; then
      rm -f "$HOSTSD/.hosts.sbnew"
      lock_drop "$LOCKD"
      reply false write_failed "❌ Couldn’t build the hosts file. Nothing was changed."
      return 0
    fi
    if ! install_hosts "$HOSTSD/.hosts.sbnew" "$CH_COUNT"; then
      lock_drop "$LOCKD"
      reply false write_failed "❌ Couldn’t write the hosts file. Your previous hosts file was restored."
      return 0
    fi
    C_DOMAINS=$CH_COUNT
    cfg_save
    [ "$IH_CHANGED" = 1 ] && mark_pending
    set_description
    lock_drop "$LOCKD"
    log INFO "Blocker enabled with $L_NAME ($(fmt_num "$CH_COUNT") domains)"
    reply true enabled "🟢 Blocker enabled — $(fmt_num "$CH_COUNT") domains. Reboot to apply."
    return 0
  fi
  log INFO "Blocker enable requested; the cached list is missing, downloading $L_NAME"
  if start_job enable "$C_LIST"; then
    reply true started "⬇️ Downloading $L_NAME to turn blocking back on…" "{\"op\":$(op_json)}"
  else
    reply false spawn_failed "❌ Couldn’t start the background task. Please try again."
  fi
}

cmd_logs() {
  if [ -s "$LOGF" ]; then
    reply true logs '' "{\"logs\":$(awk "$AWK_LOGS" "$LOGF")}"
  else
    reply true logs '' '{"logs":[]}'
  fi
}

cmd_logs_clear() {
  : > "$LOGF"
  reply true logs_cleared '🧹 Logs cleared.'
}

cmd_reboot() {
  if [ ! -x /system/bin/svc ] && [ ! -x /system/bin/reboot ]; then
    reply false reboot_failed "❌ Rebooting isn’t possible from here. Please reboot your device manually."
    return 0
  fi
  log INFO "Reboot requested from the WebUI"
  reply true rebooting '🔁 Rebooting your device…'
  if command -v setsid >/dev/null 2>&1; then
    setsid sh -c 'sleep 2; /system/bin/svc power reboot || /system/bin/reboot || /system/bin/setprop sys.powerctl reboot' < /dev/null > /dev/null 2>&1 &
  else
    sh -c 'sleep 2; /system/bin/svc power reboot || /system/bin/reboot || /system/bin/setprop sys.powerctl reboot' < /dev/null > /dev/null 2>&1 &
  fi
}

cmd_open() {
  case $1 in
    github) _op=https://github.com/mikropsoft ;;
    telegram) _op=https://t.me/stevenblockmodule ;;
    repo) _op=https://github.com/mikropsoft/StevenBlock ;;
    stevenblack) _op=https://github.com/StevenBlack/hosts ;;
    hblock) _op=https://github.com/hectorm/hblock ;;
    hagezi) _op=https://github.com/hagezi/dns-blocklists ;;
    inter) _op=https://github.com/rsms/inter ;;
    *) reply false invalid_link '❓ Unknown link.'; return 0 ;;
  esac
  if open_url "$_op"; then
    reply true opened '🌐 Opening in your browser…'
  else
    reply false open_failed "❌ Couldn’t open your browser. Visit $_op manually."
  fi
}

dispatch() {
  case ${1:-} in
    status) cmd_status ;;
    progress) cmd_progress ;;
    lists) cmd_lists ;;
    meta-refresh) cmd_meta_refresh "${2:-}" ;;
    apply) cmd_apply "${2:-}" ;;
    update) cmd_update ;;
    cancel) cmd_cancel ;;
    rules) cmd_rules ;;
    rule-add) cmd_rule_add "${2:-}" "${3:-}" ;;
    rule-del) cmd_rule_del "${2:-}" "${3:-}" ;;
    disable) cmd_disable ;;
    enable) cmd_enable ;;
    logs) cmd_logs ;;
    logs-clear) cmd_logs_clear ;;
    reboot) cmd_reboot ;;
    open) cmd_open "${2:-}" ;;
    ping) reply true pong '' ;;
    *) reply false unknown_command '❓ Unknown command.' ;;
  esac
}

# ---------------------------------------------------------------- local HTTP server (busybox httpd)

port_listening() {
  _pl_x=$(printf ':%04X' "$PORT")
  for _pl_f in /proc/net/tcp /proc/net/tcp6; do
    [ -r "$_pl_f" ] || continue
    awk -v p="$_pl_x" 'NR > 1 && $4 == "0A" && substr($2, length($2) - 4) == p { f = 1 } END { exit !f }' "$_pl_f" && return 0
  done
  return 1
}

pid_alive() { is_num "$1" && [ -d "/proc/$1" ]; }

server_running() {
  _sr_w=; _sr_h=
  [ -f "$RUND/watchdog.pid" ] && read -r _sr_w < "$RUND/watchdog.pid"
  [ -f "$RUND/httpd.pid" ] && read -r _sr_h < "$RUND/httpd.pid"
  pid_alive "$_sr_w" && pid_alive "$_sr_h" && [ -s "$RUND/token" ] && port_listening
}

gen_token() {
  _gt=$(od -An -N16 -tx1 /dev/urandom 2>/dev/null | tr -dc '0-9a-f')
  [ "${#_gt}" -eq 32 ] || _gt=$(tr -dc '0-9a-f' < /proc/sys/kernel/random/uuid)
  printf '%s' "$_gt"
}

server_prepare() {
  rm -rf "$RUND/www"
  mkdir -p "$RUND/www/cgi-bin" || return 1
  cp -r "$MODDIR/webroot/." "$RUND/www/" || return 1
  printf '#!/system/bin/sh\nexec /system/bin/sh "%s" cgi\n' "$MODDIR/sb.sh" > "$RUND/www/cgi-bin/api" || return 1
  chmod 0755 "$RUND/www/cgi-bin/api"
  {
    printf 'A:127.0.0.1\nD:*\n'
    printf '.woff2:font/woff2\n.svg:image/svg+xml\n.json:application/json\n.js:text/javascript\n.css:text/css\n'
  } > "$RUND/httpd.conf"
  gen_token > "$RUND/token"
  chmod 0600 "$RUND/token"
  [ -s "$RUND/token" ]
}

touch_activity() {
  date +%s > "$RUND/last_request.$$" 2> /dev/null && mv -f "$RUND/last_request.$$" "$RUND/last_request"
  rm -f "$RUND/last_request.$$" 2> /dev/null
  return 0
}

server_cleanup() {
  rm -rf "$RUND/www" 2>/dev/null
  rm -f "$RUND/token" "$RUND/httpd.pid" "$RUND/watchdog.pid" "$RUND/last_request" "$RUND"/last_request.* "$RUND/httpd.conf" 2>/dev/null
  return 0
}

server_stop() {
  _ss_w=; _ss_h=
  [ -f "$RUND/watchdog.pid" ] && read -r _ss_w < "$RUND/watchdog.pid"
  [ -f "$RUND/httpd.pid" ] && read -r _ss_h < "$RUND/httpd.pid"
  pid_alive "$_ss_h" && kill "$_ss_h" 2>/dev/null
  pid_alive "$_ss_w" && kill "$_ss_w" 2>/dev/null
  server_cleanup
}

serve_main() {
  MODE=worker
  echo "$$" > "$RUND/watchdog.pid"
  "$SB_BB" httpd -f -p "127.0.0.1:$PORT" -h "$RUND/www" -c "$RUND/httpd.conf" &
  _sv_h=$!
  echo "$_sv_h" > "$RUND/httpd.pid"
  touch_activity
  spawned
  _sv_s=
  trap 'kill "$_sv_h" $_sv_s 2>/dev/null; server_cleanup; exit 0' TERM INT HUP
  log INFO "Local WebUI server started on 127.0.0.1:$PORT"
  while kill -0 "$_sv_h" 2>/dev/null; do
    sleep 15 &
    _sv_s=$!
    wait "$_sv_s"
    _sv_s=
    if [ ! -f "$RUND/last_request" ]; then
      kill "$_sv_h" 2>/dev/null
      break
    fi
    _sv_l=
    read -r _sv_l < "$RUND/last_request"
    is_num "$_sv_l" || continue
    if [ $(($(date +%s) - _sv_l)) -ge "$IDLE_LIMIT" ]; then
      log INFO "Local WebUI server stopped after 10 minutes of inactivity"
      kill "$_sv_h" 2>/dev/null
      break
    fi
  done
  wait "$_sv_h" 2> /dev/null
  server_cleanup
}

cgi_deny() {
  printf 'HTTP/1.0 403 Forbidden\r\nContent-Type: application/json; charset=utf-8\r\nCache-Control: no-store\r\nX-Content-Type-Options: nosniff\r\n\r\n'
  reply false unauthorized "$1"
}

cgi_main() {
  _cg_q=${QUERY_STRING:-}
  if [ "${#_cg_q}" -gt 2048 ]; then
    cgi_deny '🚫 Request rejected.'
    return 0
  fi
  _cg_p=$(printf '%s\n' "$_cg_q" | awk "$AWK_QUERY")
  { read -r Q_T; read -r Q_C; read -r Q_A; read -r Q_B; } << EOF
$_cg_p
EOF
  _cg_t=
  [ -f "$RUND/token" ] && read -r _cg_t < "$RUND/token"
  if [ -z "$_cg_t" ] || [ "$Q_T" != "$_cg_t" ]; then
    cgi_deny '🔑 This session has expired. Press the Action button on StevenBlock in your root manager to open a new one.'
    return 0
  fi
  case ${HTTP_HOST:-} in
    '' | "127.0.0.1:$PORT" | "localhost:$PORT") ;;
    *) cgi_deny '🚫 Request rejected.'; return 0 ;;
  esac
  touch_activity
  printf 'Content-Type: application/json; charset=utf-8\r\nCache-Control: no-store\r\nX-Content-Type-Options: nosniff\r\n\r\n'
  dispatch "$Q_C" "$Q_A" "$Q_B"
}

action_main() {
  MODE=action
  ensure_dirs
  detect_manager
  printf '\n🛡️ StevenBlock %s\n' "$SB_VER"
  printf '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
  _ac_d=$(describe)
  printf '%s\n\n' "${_ac_d#🛡️ }"
  case $MGR_NAME in
    KernelSU* | SukiSU* | APatch) _ac_ksu=1 ;;
    *) _ac_ksu=0 ;;
  esac
  if ! httpd_available; then
    printf '%s\n' "❌ BusyBox httpd isn’t available on this device, so the local WebUI server can’t start."
    if [ "$_ac_ksu" = 1 ]; then
      printf '💡 Use the WebUI button on the StevenBlock card instead.\n'
    else
      printf '💡 KsuWebUI, MMRL or WebUI X can open the StevenBlock WebUI without the local server.\n'
    fi
    log ERROR "Local WebUI server unavailable: BusyBox httpd was not found"
    return 0
  fi
  if server_running; then
    read -r _ac_t < "$RUND/token"
    touch_activity
    printf '♻️ The WebUI server is already running — reopening it.\n'
  else
    server_stop
    if port_listening; then
      printf '❌ Port %s is already in use by another app.\n' "$PORT"
      printf '💡 Close that app or reboot, then press Action again.\n'
      log ERROR "Port $PORT is already in use by another app; the WebUI server was not started"
      return 0
    fi
    printf '🚀 Starting the local WebUI server…\n'
    if ! server_prepare; then
      server_cleanup
      printf '%s\n' "❌ Couldn’t prepare the WebUI files. Please try again."
      log ERROR "Could not prepare the WebUI server files"
      return 0
    fi
    if ! spawn "$RUND/server.out" _serve; then
      server_stop
      printf '❌ The WebUI server failed to start. Please try again.\n'
      log ERROR "The WebUI server process did not start"
      return 0
    fi
    _ac_i=0
    while [ "$_ac_i" -lt 30 ] && ! port_listening; do
      nap 0.2
      _ac_i=$((_ac_i + 1))
    done
    if ! port_listening; then
      server_stop
      printf '❌ The WebUI server failed to start. Please try again.\n'
      log ERROR "The WebUI server did not start listening on port $PORT"
      return 0
    fi
    read -r _ac_t < "$RUND/token"
    printf '✅ Server running at http://127.0.0.1:%s (this device only)\n' "$PORT"
    printf '🔐 Protected with a one-time session token\n'
  fi
  _ac_u="http://127.0.0.1:$PORT/#t=$_ac_t"
  printf '🌐 Opening your browser…\n'
  if ! open_url "$_ac_u"; then
    printf '%s\n%s\n' "⚠️ Couldn’t open a browser automatically. Open this address manually:" "$_ac_u"
  fi
  printf '⏱️ The server stops by itself after 10 minutes without activity.\n'
  if [ "$_ac_ksu" = 1 ]; then
    printf '💡 Tip: the WebUI button on the StevenBlock card opens the same interface inside %s.\n' "$MGR_NAME"
  fi
  printf '\n'
}

# ---------------------------------------------------------------- background job entry points

worker_main() {
  MODE=worker
  echo "$$" > "$LOCKD/pid" 2>/dev/null
  op_load
  spawned
  trap 'worker_exit' EXIT
  trap 'exit 143' TERM INT HUP
  if pipeline "$1" "$2"; then
    OP_DOMAINS=$PL_DOMAINS
    OP_REBOOT=$PL_REBOOT
    op_finish success "$PL_CODE" "$PL_MSG"
  elif [ "$PL_CODE" = cancelled ]; then
    op_finish cancelled "$PL_CODE" "$PL_MSG"
  else
    op_finish error "$PL_CODE" "$PL_MSG"
  fi
}

# shellcheck disable=SC2329
worker_exit() {
  pl_cleanup
  if [ -f "$OPF" ] && grep -q '^STATE=running$' "$OPF" 2>/dev/null; then
    op_load
    OP_STATE=error; OP_CODE=interrupted; OP_END=$(now)
    OP_MSG='⚠️ The task was stopped before it finished. Your hosts file is intact.'
    op_save
  fi
  lock_drop_if_mine "$LOCKD"
}

setup_main() {
  MODE=worker
  spawned
  _su_w=0
  while [ "$(getprop sys.boot_completed 2>/dev/null)" != 1 ] && [ "$_su_w" -lt 300 ]; do
    sleep 5
    _su_w=$((_su_w + 5))
  done
  _su_try=1
  while :; do
    cfg_load
    [ "$C_SETUP" = pending ] || return 0
    if lock_take "$LOCKD"; then
      trap 'worker_exit' EXIT
      op_begin setup "$C_LIST"
      if pipeline setup "$C_LIST"; then
        OP_DOMAINS=$PL_DOMAINS
        OP_REBOOT=$PL_REBOOT
        op_finish success "$PL_CODE" "$PL_MSG"
        lock_drop "$LOCKD"
        trap - EXIT
        return 0
      fi
      if [ "$PL_CODE" = cancelled ]; then
        op_finish cancelled "$PL_CODE" "$PL_MSG"
        lock_drop "$LOCKD"
        trap - EXIT
        return 0
      fi
      op_finish error "$PL_CODE" "$PL_MSG"
      lock_drop "$LOCKD"
      trap - EXIT
    fi
    if [ "$_su_try" -ge 5 ]; then
      cfg_load
      if [ "$C_SETUP" = pending ]; then
        C_SETUP=failed
        cfg_save
        set_description
        log ERROR "The first download failed after 5 attempts; open the WebUI to retry"
      fi
      return 0
    fi
    log WARN "First download attempt $_su_try failed; retrying later"
    sleep $((30 * _su_try))
    _su_try=$((_su_try + 1))
  done
}

boot_main() {
  MODE=boot
  ensure_dirs
  if [ -f "$OPF" ] && grep -q '^STATE=running$' "$OPF" 2>/dev/null; then
    op_load
    OP_STATE=error; OP_CODE=interrupted; OP_END=$(now)
    OP_MSG='⚠️ A task was interrupted by a reboot. Your hosts file is intact — run it again if needed.'
    op_save
  fi
  rm -rf "$LOCKD" "$METALOCK" "$RUND/www" 2>/dev/null
  rm -f "$RUND"/spawn.* "$RUND/cancel" "$RUND/dl.pid" "$RUND/token" "$RUND/httpd.pid" "$RUND/watchdog.pid" "$RUND/last_request" "$RUND"/last_request.* "$RUND/httpd.conf" "$RUND/manager" "$PENDF" 2>/dev/null
  rm -f "$METAD"/*.busy "$METAD"/*.tmp "$HOSTSD"/.hosts.sb* 2>/dev/null
  rm -rf "$TMPD" 2>/dev/null
  mkdir -p "$TMPD"
  cfg_load
  set_description
  list_info "$C_LIST"
  if [ "$C_SETUP" = pending ]; then
    log INFO "Boot: waiting for network to download $L_NAME"
    spawn "$RUND/setup.out" _setup || log ERROR "Could not start the first-boot download"
  elif [ "$C_ENABLED" = 1 ]; then
    log INFO "Boot: $L_NAME active with $(fmt_num "$C_DOMAINS") domains ($(applied_state))"
  else
    log INFO "Boot: blocker is disabled"
  fi
}

uninstall_main() {
  server_stop
  for _un in "$LOCKD" "$METALOCK"; do
    _un_p=$(lock_pid "$_un")
    pid_alive "$_un_p" && kill "$_un_p" 2>/dev/null
  done
  rm -rf "$DATA"
}

# ---------------------------------------------------------------- installer (called from customize.sh)

install_main() {
  MODE=install
  ensure_dirs
  rm -rf "$LOCKD" "$METALOCK" 2>/dev/null
  rm -f "$RUND"/spawn.* "$METAD"/*.busy 2>/dev/null
  detect_manager
  printf '🔎 Checking your setup…\n'
  if [ -n "$MGR_VER" ]; then
    printf '✅ Root manager: %s (%s)\n' "$MGR_NAME" "$MGR_VER"
  else
    printf '✅ Root manager: %s\n' "$MGR_NAME"
  fi
  if [ "$SB_BB" != none ]; then
    printf '✅ BusyBox: %s\n' "$SB_BB"
  else
    printf '⚠️ BusyBox not found — falling back to system tools\n'
  fi
  if dl_detect; then
    if [ "$DL_TOOL" = curl ]; then printf '✅ Downloader: curl\n'; else printf '✅ Downloader: BusyBox wget\n'; fi
  else
    printf '❌ No downloader found (curl or BusyBox wget)\n'
  fi
  if ! httpd_available; then
    printf '%s\n' "⚠️ BusyBox httpd not found — the Action button can’t open the WebUI in a browser"
  fi
  log INFO "Installing StevenBlock $SB_VER with $MGR_NAME $MGR_VER"

  printf '\n🧩 Looking for other hosts blockers…\n'
  _in_cf=0
  for _in_m in $(conflicts); do
    _in_cf=1
    if [ "$_in_m" = hosts ]; then
      printf '%s\n' "⚠️ Systemless hosts is enabled. Turn it off in your root manager (it’s the \"hosts\" module)."
    else
      printf '⚠️ The module "%s" also replaces /system/etc/hosts. Disable it to avoid conflicts.\n' "$_in_m"
    fi
    log WARN "Conflicting hosts module found: $_in_m"
  done
  if [ -d /data/data/org.adaway ]; then
    _in_cf=1
    printf '%s\n' "⚠️ AdAway is installed. Don’t use its root or systemless mode together with StevenBlock."
    log WARN "AdAway app detected"
  fi
  [ "$_in_cf" = 0 ] && printf '✅ No conflicting hosts blockers found\n'

  printf '\n🧹 Cleaning up older versions…\n'
  _in_old=
  _in_legacy=0
  if [ -f "$DATA/config.txt" ]; then
    _in_legacy=$(sed -n 's/^ACTIVE_LIST=//p' "$DATA/config.txt" 2>/dev/null | head -n 1)
    is_num "$_in_legacy" || _in_legacy=0
  fi
  for _in_f in config.txt hosts.bak hosts.tmp hosts.tmp.clean hosts.tmp.clean.sort; do
    if [ -e "$DATA/$_in_f" ]; then
      rm -f "$DATA/$_in_f"
      _in_old="$_in_old $_in_f"
    fi
  done
  if [ -n "$_in_old" ]; then
    printf '✅ Removed StevenBlock v5.0 leftovers:%s\n' "$_in_old"
    printf '✅ The old terminal menu is replaced by the new WebUI\n'
    log INFO "Removed legacy files:$_in_old"
  else
    printf '✅ Nothing to clean up\n'
  fi
  if [ "$_in_legacy" -gt 1 ] 2>/dev/null; then
    printf 'ℹ️ Energized lists are no longer offered, so StevenBlock starts with StevenBlack Main\n'
  fi

  printf '\n💾 Backing up the original hosts file…\n'
  if [ -s "$ORIGHOSTS" ]; then
    printf '✅ A copy of the original hosts file is already saved\n'
  elif [ -f "$SYS_HOSTS" ] && [ "$(wc -l < "$SYS_HOSTS")" -le 30 ] && ! grep -q '^0\.0\.0\.0 ' "$SYS_HOSTS" 2>/dev/null; then
    cp -f "$SYS_HOSTS" "$ORIGHOSTS" && printf '✅ Saved a copy of your original hosts file\n'
  else
    printf '127.0.0.1 localhost\n::1 ip6-localhost\n' > "$ORIGHOSTS"
    printf '%s\n' "ℹ️ The current hosts file comes from a blocker, so Android’s default hosts was saved instead"
  fi

  printf '\n📋 Preparing your blocklist…\n'
  cfg_load
  _in_keep=0
  if [ -f "$CFG" ] && [ "$C_SETUP" = ready ] && [ -s "$LISTCACHE" ]; then
    list_info "$C_LIST"
    if compile_into "$HOSTSD/.hosts.sbnew" "$C_ENABLED" "$LISTCACHE"; then
      if mv -f "$HOSTSD/.hosts.sbnew" "$HOSTS" && set_hosts_perm "$HOSTS" && verify_hosts "$CH_COUNT"; then
        _in_keep=1
        C_DOMAINS=$CH_COUNT
        cfg_save
        if [ "$C_ENABLED" = 1 ]; then
          printf '♻️ Keeping your current setup: %s • %s domains\n' "$L_NAME" "$(fmt_num "$CH_COUNT")"
        else
          printf '♻️ Keeping your current setup: %s (blocker disabled)\n' "$L_NAME"
        fi
        _in_r=$(($(count_lines "$ALLOWF") + $(count_lines "$BLOCKF")))
        if [ "$_in_r" = 1 ]; then
          printf '✅ 1 domain rule kept\n'
        elif [ "$_in_r" -gt 1 ]; then
          printf '✅ %s domain rules kept\n' "$_in_r"
        fi
        log INFO "Kept the existing setup: $L_NAME"
      fi
    fi
    rm -f "$HOSTSD/.hosts.sbnew"
  fi
  if [ "$_in_keep" = 0 ]; then
    C_LIST=stevenblack
    C_ENABLED=1
    C_SETUP=pending
    list_info stevenblack
    if [ "${BOOTMODE:-true}" != false ] && pipeline setup stevenblack; then
      printf '✅ Hosts file ready: %s domains blocked after reboot\n' "$(fmt_num "$PL_DOMAINS")"
    else
      if [ "${BOOTMODE:-true}" = false ]; then
        printf '⚠️ Installing from recovery: no network, so the list downloads after reboot\n'
        log WARN "Installed from recovery; the first download is postponed"
      else
        printf '⚠️ %s\n' "${PL_MSG#* }"
      fi
      write_clean_hosts
      cfg_load
      C_LIST=stevenblack
      C_ENABLED=1
      C_SETUP=pending
      cfg_save
      printf '🧩 Wrote a clean localhost-only hosts file for now\n'
      printf '%s\n' "🔁 StevenBlock will retry automatically after reboot, once you’re online"
      log WARN "The first download failed during install; it will be retried after reboot"
    fi
  fi
  set_hosts_perm "$HOSTS"
  mark_pending
  set_description

  printf '\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
  printf '🎉 StevenBlock %s is installed!\n' "$SB_VER"
  printf '🔁 Reboot your device to activate it.\n'
  case $MGR_NAME in
    KernelSU* | SukiSU* | APatch)
      printf '🖥️ After reboot, tap the WebUI button on the StevenBlock card.\n'
      printf '▶️ The Action button opens the same WebUI in your browser.\n'
      ;;
    *)
      printf '▶️ After reboot, tap the Action button on the StevenBlock card —\n'
      printf '   the WebUI opens in your browser.\n'
      printf '💡 KsuWebUI, MMRL or WebUI X can also open the WebUI.\n'
      ;;
  esac
  printf '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
}

# ---------------------------------------------------------------- entry point

[ -d "$TMPD" ] || ensure_dirs

case ${1:-} in
  cgi) cgi_main ;;
  _worker) worker_main "${2:-}" "${3:-}" ;;
  _meta) shift; meta_worker_main "$@" ;;
  _setup) setup_main ;;
  _serve) serve_main ;;
  _action) action_main ;;
  _install) install_main ;;
  _boot) boot_main ;;
  _uninstall) uninstall_main ;;
  *) dispatch "$@" ;;
esac
exit 0
