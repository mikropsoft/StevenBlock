#!/system/bin/sh

if [ "${SB_EXEC:-}" != "$$" ]; then
  for _bb in /data/adb/magisk/busybox /data/adb/ksu/bin/busybox /data/adb/ap/bin/busybox; do
    if [ -x "$_bb" ]; then
      SB_BB=$_bb
      SB_EXEC=$$
      ASH_STANDALONE=1
      export SB_BB SB_EXEC ASH_STANDALONE
      exec "$_bb" sh "$0" "$@"
    fi
  done
  SB_BB=none
  SB_EXEC=$$
  export SB_BB SB_EXEC
fi

umask 022
PATH=/system/bin:/system/xbin:/vendor/bin:${PATH:-/bin}
export PATH

SB_VER=v2.0
SB_VCODE=2000
SELF=$0
case $SELF in /*) ;; *) SELF=$(pwd)/$SELF ;; esac
MODDIR=${SB_MODDIR:-${SELF%/*}}
MODROOT=/data/adb/modules
DATA=/data/adb/stevenblock
CFG=$DATA/config
SEQF=$DATA/seq
PENDF=$DATA/reboot.pending
LOGF=$DATA/stevenblock.log
SRCF=$DATA/sources
SUMF=$DATA/hosts.sum
STATF=$DATA/stats
RULESD=$DATA/rules
ALLOWF=$RULESD/allow.list
BLOCKF=$RULESD/block.list
CACHED=$DATA/cache
LISTSD=$CACHED/lists
METAD=$CACHED/meta
OLDCACHE=$CACHED/list.domains
BACKUPD=$DATA/backup
ORIGHOSTS=$BACKUPD/hosts.original
RUND=$DATA/run
TMPD=$DATA/tmp
STAGED=$TMPD/stage
LOCKD=$RUND/lock
METALOCK=$RUND/meta.lock
OPF=$RUND/op
SCHEDPID=$RUND/sched.pid
SCHEDRETRY=$RUND/sched.retry
DLPART=$TMPD/download.part
DLHDR=$TMPD/download.hdr
HOSTSD=$MODDIR/system/etc
HOSTS=$HOSTSD/hosts
PROP=$MODDIR/module.prop
SYS_HOSTS=/system/etc/hosts
INIT_HOSTS=/proc/1/root/system/etc/hosts
INIT_NS=/proc/1/ns/mnt
MOUNT_TARGET=/system/etc/hosts
MOUNTF=$RUND/mount
PORT=9090
IDLE_LIMIT=600
MAX_BYTES=67108864
RULE_MAX=1000
CUSTOM_MAX=8
LOG_MAX=500
STALE_DAYS=7
SCHED_TICK=900
UA="StevenBlock/2.0 (+https://github.com/mikropsoft/StevenBlock)"
BASE_IDS="stevenblack hblock hagezi-light hagezi-normal hagezi-pro hagezi-proplus hagezi-ultimate"
ADDON_IDS="sb-fakenews sb-gambling sb-adult sb-social hz-doh hz-tif hz-xiaomi hz-samsung hz-huawei hz-oppo hz-vivo hz-amazon hz-tiktok hz-microsoft"
LOCAL_LINE='127.0.0.1 localhost'
LOCAL6_LINE='::1 localhost ip6-localhost'
MODE=cli
DL_TOOL=
DL_GZ=0
DL_PIDF=
NL='
'
CR=$(printf '\r')
TAB=$(printf '\t')
SB_RAW=https://raw.githubusercontent.com/StevenBlack/hosts/refs/heads/master
HZ_RAW=https://raw.githubusercontent.com/hagezi/dns-blocklists-legacy/refs/heads/main/hosts

list_info() {
  L_KIND=base; L_GROUP=; L_LEVEL=; L_LEVELTXT=; L_ICON=; L_WARN=; L_MIN=1000; L_CUSTOM=0
  case $1 in
    stevenblack)
      L_NAME='StevenBlack Main'; L_GROUP=unified; L_LEVEL=green; L_LEVELTXT=Balanced
      L_URL="$SB_RAW/hosts"
      L_DESC='Classic unified list for ads and malware, with very few false positives.' ;;
    hblock)
      L_NAME='hBlock'; L_GROUP=unified; L_LEVEL=blue; L_LEVELTXT=Mixed
      L_URL='https://hblock.molinero.dev/hosts'
      L_DESC='Merges dozens of public blocklists into one broad, all-purpose list.' ;;
    hagezi-light)
      L_NAME='HaGeZi Light'; L_GROUP=hagezi; L_LEVEL=green; L_LEVELTXT=Basic
      L_URL="$HZ_RAW/light.txt"
      L_DESC='Basic protection from ads, tracking and telemetry. Built to break nothing.' ;;
    hagezi-normal)
      L_NAME='HaGeZi Normal'; L_GROUP=hagezi; L_LEVEL=blue; L_LEVELTXT=All-round
      L_URL="$HZ_RAW/multi.txt"
      L_DESC='All-round protection from ads, tracking, phishing, malware and scams.' ;;
    hagezi-pro)
      L_NAME='HaGeZi Pro'; L_GROUP=hagezi; L_LEVEL=yellow; L_LEVELTXT=Extended
      L_URL="$HZ_RAW/pro.txt"
      L_DESC='Extended protection with many more trackers. May need an allow rule.' ;;
    hagezi-proplus)
      L_NAME='HaGeZi Pro++'; L_GROUP=hagezi; L_LEVEL=orange; L_LEVELTXT=Aggressive
      L_URL="$HZ_RAW/pro.plus.txt"
      L_DESC='Aggressive blocking. Some legitimate sites or app features may break.' ;;
    hagezi-ultimate)
      L_NAME='HaGeZi Ultimate'; L_GROUP=hagezi; L_LEVEL=red; L_LEVELTXT=Maximum
      L_URL="$HZ_RAW/ultimate.txt"
      L_DESC='The most aggressive list. Can restrict app and website features.' ;;
    sb-fakenews)
      L_KIND=addon; L_GROUP=content; L_ICON='🗞️'; L_MIN=100; L_NAME='Fake news'
      L_URL="$SB_RAW/alternates/fakenews-only/hosts"
      L_DESC='Sites known for publishing fabricated news stories.' ;;
    sb-gambling)
      L_KIND=addon; L_GROUP=content; L_ICON='🎰'; L_MIN=100; L_NAME='Gambling'
      L_URL="$SB_RAW/alternates/gambling-only/hosts"
      L_DESC='Online casinos, betting and lottery sites.' ;;
    sb-adult)
      L_KIND=addon; L_GROUP=content; L_ICON='🔞'; L_MIN=1000; L_NAME='Adult content'
      L_URL="$SB_RAW/alternates/porn-only/hosts"
      L_DESC='Pornography and other adult sites. A solid base for a family-safe device.' ;;
    sb-social)
      L_KIND=addon; L_GROUP=content; L_ICON='👥'; L_MIN=100; L_WARN=breaks; L_NAME='Social networks'
      L_URL="$SB_RAW/alternates/social-only/hosts"
      L_DESC='Blocks the social networks themselves, such as Facebook, Instagram and X.' ;;
    hz-doh)
      L_KIND=addon; L_GROUP=security; L_ICON='🔐'; L_MIN=100; L_WARN=dns; L_NAME='Encrypted DNS bypass'
      L_URL="$HZ_RAW/doh.txt"
      L_DESC='Blocks public DNS-over-HTTPS servers so apps can’t sidestep your hosts file.' ;;
    hz-tif)
      L_KIND=addon; L_GROUP=security; L_ICON='🦠'; L_MIN=1000; L_WARN=heavy; L_NAME='Threat Intelligence'
      L_URL="$HZ_RAW/tif.txt"
      L_DESC='Malware, phishing and scam domains. Very large, with over a million entries.' ;;
    hz-xiaomi)
      L_KIND=addon; L_GROUP=tracker; L_ICON='📱'; L_MIN=20; L_NAME='Xiaomi'
      L_URL="$HZ_RAW/native.xiaomi.txt"
      L_DESC='Telemetry and ad domains built into Xiaomi, Redmi and POCO devices.' ;;
    hz-samsung)
      L_KIND=addon; L_GROUP=tracker; L_ICON='📱'; L_MIN=20; L_NAME='Samsung'
      L_URL="$HZ_RAW/native.samsung.txt"
      L_DESC='Telemetry and ad domains built into Samsung devices.' ;;
    hz-huawei)
      L_KIND=addon; L_GROUP=tracker; L_ICON='📱'; L_MIN=20; L_NAME='Huawei'
      L_URL="$HZ_RAW/native.huawei.txt"
      L_DESC='Telemetry and ad domains built into Huawei and Honor devices.' ;;
    hz-oppo)
      L_KIND=addon; L_GROUP=tracker; L_ICON='📱'; L_MIN=20; L_NAME='OPPO & Realme'
      L_URL="$HZ_RAW/native.oppo-realme.txt"
      L_DESC='Telemetry and ad domains built into OPPO, Realme and OnePlus devices.' ;;
    hz-vivo)
      L_KIND=addon; L_GROUP=tracker; L_ICON='📱'; L_MIN=20; L_NAME='Vivo'
      L_URL="$HZ_RAW/native.vivo.txt"
      L_DESC='Telemetry and ad domains built into Vivo and iQOO devices.' ;;
    hz-amazon)
      L_KIND=addon; L_GROUP=tracker; L_ICON='📦'; L_MIN=20; L_NAME='Amazon'
      L_URL="$HZ_RAW/native.amazon.txt"
      L_DESC='Tracking built into Amazon devices and apps.' ;;
    hz-tiktok)
      L_KIND=addon; L_GROUP=tracker; L_ICON='🎵'; L_MIN=20; L_NAME='TikTok'
      L_URL="$HZ_RAW/native.tiktok.txt"
      L_DESC='Tracking and fingerprinting domains used by TikTok.' ;;
    hz-microsoft)
      L_KIND=addon; L_GROUP=tracker; L_ICON='🪟'; L_MIN=20; L_NAME='Microsoft'
      L_URL="$HZ_RAW/native.winoffice.txt"
      L_DESC='Telemetry from Windows, Office and other Microsoft apps.' ;;
    c-[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f])
      custom_info "$1" || return 1 ;;
    *) return 1 ;;
  esac
  return 0
}

custom_info() {
  [ -f "$SRCF" ] || return 1
  while IFS='|' read -r _cu_i _cu_u _cu_n; do
    [ "$_cu_i" = "$1" ] || continue
    L_KIND=addon; L_GROUP=custom; L_ICON='🔗'; L_MIN=1; L_CUSTOM=1
    L_URL=$_cu_u
    L_NAME=$_cu_n
    L_DESC=${_cu_u#https://}
    return 0
  done < "$SRCF"
  return 1
}

custom_ids() {
  R_CUSTOM=
  [ -f "$SRCF" ] || return 0
  while IFS='|' read -r _ci_i _ci_u _ci_n; do
    case $_ci_i in c-????????) R_CUSTOM="$R_CUSTOM $_ci_i" ;; esac
  done < "$SRCF"
  R_CUSTOM=${R_CUSTOM# }
}

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

AWK_ESC='
function esc(s,   o, i, c, n) {
  o = ""; n = length(s)
  for (i = 1; i <= n; i++) {
    c = substr(s, i, 1)
    if (c == "\\") o = o "\\\\"
    else if (c == "\"") o = o "\\\""
    else if (c >= " ") o = o c
  }
  return o
}'

AWK_RDOM='
function rdom(d,   n, i, L) {
  if (length(d) < 1 || length(d) > 253) return 0
  n = split(d, L, ".")
  if (n < 2) return 0
  for (i = 1; i <= n; i++) {
    if (length(L[i]) < 1 || length(L[i]) > 63) return 0
    if (i < n) { if (L[i] !~ /^[a-z0-9_]([a-z0-9_-]*[a-z0-9_])?$/) return 0 }
    else if (L[i] !~ /^[a-z][a-z]+$/ && L[i] !~ /^xn--[a-z0-9]([a-z0-9-]*[a-z0-9])?$/) return 0
  }
  return 1
}'

AWK_VALID="$AWK_RDOM"'
{ exit rdom($0) ? 0 : 1 }'

AWK_NORM='
function toolong(d,   n, i, L) {
  if (length(d) > 253) return 1
  n = split(d, L, ".")
  for (i = 1; i <= n; i++) if (length(L[i]) > 63) return 1
  return 0
}
{
  if (index($0, "\r")) gsub(/\r/, "")
  c = index($0, "#")
  if (c) $0 = substr($0, 1, c - 1)
  if (NF < 2) {
    if (NF == 0) next
    s = 1
    if (substr($1, 1, 2) == "||") {
      d = $1
      if (d !~ /^\|\|[^\/^$*|]+\^$/) next
      $1 = substr(d, 3, length(d) - 3)
    }
  } else if ($1 == "0.0.0.0" || $1 == "127.0.0.1" || index($1, ":") || $1 ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) s = 2
  else next
  for (f = s; f <= NF; f++) {
    d = tolower($f)
    if (d !~ /^([a-z0-9_]([a-z0-9_-]*[a-z0-9_])?\.)+[a-z]([a-z0-9-]*[a-z0-9])?$/) {
      if (substr(d, length(d)) != ".") continue
      d = substr(d, 1, length(d) - 1)
      if (d !~ /^([a-z0-9_]([a-z0-9_-]*[a-z0-9_])?\.)+[a-z]([a-z0-9-]*[a-z0-9])?$/) continue
    }
    if (seen[d]++) continue
    if (length(d) > 63 && toolong(d)) continue
    if (d == "localhost.localdomain") continue
    print d
    n++
  }
}
END { print n + 0 > cntf }'

AWK_COMPILE='
BEGIN {
  while ((getline l < allowf) > 0) {
    if (l == "") continue
    if (substr(l, 1, 2) == "*.") {
      l = substr(l, 3)
      AW[l] = 1
      naw++
      t = l
      while ((i = index(t, ".")) > 0) t = substr(t, i + 1)
      TL[t] = 1
    } else {
      A[l] = 1
      nae++
    }
  }
  close(allowf)
  while ((getline l < blockf) > 0) if (l != "" && !(l in B)) { B[l] = 1; BO[++nb] = l }
  close(blockf)
  G = ""
  if (guard != "" && !(guard in B)) G = guard
  plain = (G == "" && !nae && !naw && !nb)
  print local4
  print local6
}
plain {
  print "0.0.0.0 " $0
  n++
  next
}
{
  d = $0
  if (d == G) { g = 1; next }
  if (nae && (d in A)) { na++; next }
  if (naw && ($NF in TL)) {
    s = d
    hit = 0
    while (1) {
      if (s in AW) { hit = 1; break }
      i = index(s, ".")
      if (!i) break
      s = substr(s, i + 1)
    }
    if (hit) { na++; next }
  }
  if (nb && (d in B)) BS[d] = 1
  print "0.0.0.0 " d
  n++
}
END {
  for (i = 1; i <= nb; i++) {
    if (BO[i] in BS) continue
    print "0.0.0.0 " BO[i]
    n++
    nbr++
  }
  printf "TOTAL=%d\nALLOWED=%d\nBLOCKED=%d\nGUARDED=%d\n", n, na, nbr, g > statf
}'

AWK_MERGE='
BEGIN {
  ns = split(addons, SF, " ")
  for (i = 1; i <= ns; i++) {
    while ((getline l < SF[i]) > 0) if (l != "" && !(l in X)) X[l] = i
    close(SF[i])
  }
}
{
  nbase++
  if ($0 in X) X[$0] = 0
}
END {
  printf "" > outf
  for (i = 1; i <= ns; i++) {
    while ((getline l < SF[i]) > 0) {
      if (l == "" || X[l] != i) continue
      print l > outf
      X[l] = -1
      C[i]++
    }
    close(SF[i])
  }
  printf "BASE=%d\n", nbase > statf
  for (i = 1; i <= ns; i++) printf "ADDON%d=%d\n", i, C[i] + 0 > statf
}'

AWK_VERIFY='
NR == 1 { if ($0 != local4) { bad = 1; exit } next }
NR == 2 { if ($0 != local6) { bad = 1; exit } next }
{ if (NF != 2 || $1 != "0.0.0.0") { bad = 1; exit } }
END { exit (bad || NR != want + 2) ? 1 : 0 }'

AWK_RULES="$AWK_RDOM"'
function covered(d,   i, s) {
  s = d
  while (1) {
    if (s in AW) return s
    i = index(s, ".")
    if (!i) return ""
    s = substr(s, i + 1)
  }
}
function blockunder(b,   k, n) {
  n = length(b)
  for (k in B) if (k == b || (length(k) > n && substr(k, length(k) - n) == "." b)) return k
  return ""
}
function rej(why, ref) { lastrej = why; lastref = ref }
BEGIN {
  if (mode != "replace") {
    while ((getline l < allowf) > 0) {
      if (l == "" || (l in A)) continue
      A[l] = 1; AO[++na] = l
      if (substr(l, 1, 2) == "*.") AW[substr(l, 3)] = 1
    }
    close(allowf)
    while ((getline l < blockf) > 0) {
      if (l == "" || (l in B)) continue
      B[l] = 1; BO[++nb] = l
    }
    close(blockf)
  }
}
{
  t = $1
  d = tolower($2)
  if (NF != 2 || (t != "a" && t != "b")) { invalid++; rej("invalid", ""); next }
  if (substr(d, length(d)) == ".") d = substr(d, 1, length(d) - 1)
  w = (substr(d, 1, 2) == "*.")
  base = w ? substr(d, 3) : d
  if (!rdom(base) || (w && t == "b")) { invalid++; rej("invalid", d); next }
  if (t == "a") {
    if (d in A) { dup++; rej("exists", d); next }
    if (!w) {
      c = covered(base)
      if (c != "") { dup++; rej("covered", "*." c); next }
      if (d in B) { conflict++; rej("conflict", d); next }
    } else {
      c = blockunder(base)
      if (c != "") { conflict++; rej("covers", c); next }
    }
    if (na >= max) { limit++; rej("limit", d); next }
    A[d] = 1; AO[++na] = d; adda++
    if (w) AW[base] = 1
  } else {
    if (d in B) { dup++; rej("exists", d); next }
    if (d in A) { conflict++; rej("conflict", d); next }
    c = covered(d)
    if (c != "") { conflict++; rej("blocked_by_wildcard", "*." c); next }
    if (nb >= max) { limit++; rej("limit", d); next }
    B[d] = 1; BO[++nb] = d; addb++
  }
}
END {
  printf "" > outa
  printf "" > outb
  for (i = 1; i <= na; i++) print AO[i] > outa
  for (i = 1; i <= nb; i++) print BO[i] > outb
  printf "ADDED_A=%d\nADDED_B=%d\nINVALID=%d\nDUP=%d\nCONFLICT=%d\nLIMIT=%d\nLASTREJ=%s\nLASTREF=%s\n", adda, addb, invalid, dup, conflict, limit, lastrej, lastref
}'

AWK_HEAD='
{ l = $0; sub(/\r$/, "", l) }
l !~ /^[ \t]*[#!]/ { next }
{ x = tolower(l) }
cnt == "" && x ~ /(number of (unique )?(domains|entries)|blocked domains|total (domains|entries)|entries)[ \t]*:/ {
  v = l; sub(/^[^:]*:[ \t]*/, "", v); gsub(/[,. _]/, "", v)
  if (v ~ /^[0-9]+$/) cnt = v
}
dt == "" && x ~ /^[ \t]*[#!][ \t]*(date|last[ -]modified|last updated|updated)[ \t]*:/ {
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

AWK_HDR='
{ l = $0; sub(/\r$/, "", l); sub(/^[ \t]+/, "", l); x = tolower(l) }
x ~ /^http\/[0-9.]+[ \t]+[0-9][0-9][0-9]/ { split(l, p, /[ \t]+/); code = p[2]; cl = ""; tot = ""; et = ""; lm = ""; enc = ""; next }
x ~ /^content-length:/ { v = l; sub(/^[^:]*:[ \t]*/, "", v); if (v ~ /^[0-9]+$/) cl = v; next }
x ~ /^content-range:/ { v = l; sub(/^.*\//, "", v); if (v ~ /^[0-9]+$/) tot = v; next }
x ~ /^content-encoding:/ { v = x; sub(/^[^:]*:[ \t]*/, "", v); if (v != "identity") enc = v; next }
x ~ /^etag:/ { v = l; sub(/^[^:]*:[ \t]*/, "", v); sub(/^[Ww]\//, "", v); et = v; next }
x ~ /^last-modified:/ { v = l; sub(/^[^:]*:[ \t]*/, "", v); lm = v; next }
END { if (tot == "" && code == "200" && enc == "") tot = cl; print code; print cl; print tot; print et; print lm; print enc }'

AWK_OPJSON="$AWK_ESC"'
{ i = index($0, "="); if (i) O[substr($0, 1, i - 1)] = substr($0, i + 1) }
END {
  while ((getline l < hdr) > 0) {
    sub(/\r$/, "", l); sub(/^[ \t]+/, "", l); x = tolower(l)
    if (x ~ /^http\/[0-9.]+[ \t]+[0-9]/) { cl = ""; enc = "" }
    else if (x ~ /^content-length:/) { v = l; sub(/^[^:]*:[ \t]*/, "", v); if (v ~ /^[0-9]+$/) cl = v }
    else if (x ~ /^content-encoding:/) { v = x; sub(/^[^:]*:[ \t]*/, "", v); if (v != "identity") enc = v }
  }
  st = O["STATE"]; run = 0
  if (st == "running") { if (alive == 1) run = 1; else st = "interrupted" }
  ph = O["PHASE"]
  tot = O["TOTAL"] + 0
  if (!tot && cl != "" && enc == "") tot = cl + 0
  can = "false"
  if (run && (ph == "prepare" || ph == "check" || ph == "download" || ph == "verify" || ph == "optimize")) can = "true"
  printf "{\"running\":%s,\"state\":\"%s\",\"kind\":\"%s\",\"list\":\"%s\",\"phase\":\"%s\",\"code\":\"%s\",\"message\":\"%s\",\"seq\":%.0f,\"bytes\":%.0f,\"total\":%.0f,\"domains\":%.0f,\"reboot\":%s,\"live\":%s,\"started\":%.0f,\"ended\":%.0f,\"cancellable\":%s,\"cancelling\":%s,\"item\":%d,\"items\":%d,\"source\":\"%s\",\"sourceName\":\"%s\",\"warn\":%d}", (run ? "true" : "false"), esc(st), esc(O["KIND"]), esc(O["LIST"]), esc(ph), esc(O["CODE"]), esc(O["MSG"]), O["SEQ"] + 0, (run ? bytes + 0 : 0), tot, O["DOMAINS"] + 0, (O["REBOOT"] == "1" ? "true" : "false"), (O["LIVE"] == "1" ? "true" : "false"), O["START"] + 0, O["END"] + 0, can, (cancelling == 1 && run ? "true" : "false"), O["ITEM"] + 0, O["ITEMS"] + 0, esc(O["SRC"]), esc(O["SRCNAME"]), O["WARN"] + 0
}'

AWK_LOGS="$AWK_ESC"'
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
BEGIN { for (i = 32; i < 127; i++) H[sprintf("%02x", i)] = sprintf("%c", i) }
function dec(s,   o, i, c, h) {
  o = ""
  for (i = 1; i <= length(s); i++) {
    c = substr(s, i, 1)
    if (c == "%") {
      h = tolower(substr(s, i + 1, 2))
      if (!(h in H)) return "\001"
      c = H[h]; i += 2
    } else if (c == "+") c = " "
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
    if (k == "t" || k == "c" || k == "a" || k == "b" || k == "d") V[k] = dec(v)
  }
}
END { print V["t"]; print V["c"]; print V["a"]; print V["b"]; print V["d"] }'

AWK_JARR='
BEGIN { ORS = ""; printf "[" }
NF { printf "%s\"%s\"", (n++ ? "," : ""), $1 }
END { printf "]" }'

now() { date +%s; }
nap() { sleep "$1" 2>/dev/null || sleep 1; }
is_num() { case $1 in '' | *[!0-9]*) return 1 ;; esac; return 0; }
has() { command -v "$1" >/dev/null 2>&1; }
say() { [ "$MODE" = install ] && printf '%s\n' "$1"; return 0; }
fsize() { _fs=$(stat -c %s "$1" 2>/dev/null); is_num "$_fs" || _fs=0; printf '%s' "$_fs"; }
fmt_num() { printf '%s\n' "${1:-0}" | awk '{ n = $1 ""; o = ""; while (length(n) > 3) { o = "," substr(n, length(n) - 2) o; n = substr(n, 1, length(n) - 3) } print n o }'; }
fmt_mb() { awk -v b="${1:-0}" 'BEGIN { printf "%.1f MB", b / 1048576 }'; }
clean_val() { printf '%s' "$1" | tr -d '\000-\037\134\177' | cut -c1-200; }
boot_id() { cat /proc/sys/kernel/random/boot_id 2>/dev/null; }
plural() { if [ "$1" = 1 ]; then printf '%s' "$2"; else printf '%s' "$3"; fi; }

count_lines() {
  R_LINES=0
  [ -s "$1" ] || return 0
  R_LINES=$(grep -c . "$1" 2>/dev/null)
  is_num "$R_LINES" || R_LINES=0
}

word_in() {
  case " $2 " in *" $1 "*) return 0 ;; esac
  return 1
}

ensure_dirs() {
  mkdir -p "$RULESD" "$METAD" "$LISTSD" "$BACKUPD" "$RUND" "$TMPD" 2>/dev/null
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
  if is_num "$_lg_n" && [ "$_lg_n" -gt "$LOG_MAX" ]; then
    tail -n "$LOG_MAX" "$LOGF" > "$LOGF.trim.$$" 2>/dev/null && mv -f "$LOGF.trim.$$" "$LOGF"
    rm -f "$LOGF.trim.$$" 2>/dev/null
  fi
  return 0
}

js() {
  case $1 in
    *\\* | *\"* | *"$NL"* | *"$CR"* | *"$TAB"*) JS=$(printf '%s' "$1" | awk "$AWK_JESC") ;;
    *) JS="\"$1\"" ;;
  esac
}

jnum() { if is_num "$1"; then JN=$1; else JN=null; fi; }
jbool() { if [ "$1" = 1 ] || [ "$1" = true ]; then JB=true; else JB=false; fi; }

reply() {
  _rp_d=${4:-}
  [ -n "$_rp_d" ] || _rp_d='{}'
  js "$3"
  [ "$1" = true ] || SB_RC=1
  printf '{"ok":%s,"code":"%s","message":%s,"data":%s}\n' "$1" "$2" "$JS" "$_rp_d"
}

addons_clean() {
  R_ADDONS=
  for _ac in $1; do
    word_in "$_ac" "$R_ADDONS" && continue
    list_info "$_ac" || continue
    [ "$L_KIND" = addon ] || continue
    R_ADDONS="$R_ADDONS $_ac"
  done
  R_ADDONS=${R_ADDONS# }
}

cfg_load() {
  C_LIST=; C_ADDONS=; C_ENABLED=1; C_SETUP=; C_UPDATED=0; C_CHECKED=0; C_COUNT=0; C_DOMAINS=0
  C_LIVE=1; C_AUTO=0; C_GUARD=; C_ETAG=; C_SRCDATE=
  if [ -f "$CFG" ]; then
    while IFS= read -r _cf_l || [ -n "$_cf_l" ]; do
      _cf_v=${_cf_l#*=}
      case ${_cf_l%%=*} in
        LIST) C_LIST=$_cf_v ;;
        ADDONS) C_ADDONS=$_cf_v ;;
        ENABLED) C_ENABLED=$_cf_v ;;
        SETUP) C_SETUP=$_cf_v ;;
        UPDATED) C_UPDATED=$_cf_v ;;
        CHECKED) C_CHECKED=$_cf_v ;;
        COUNT) C_COUNT=$_cf_v ;;
        DOMAINS) C_DOMAINS=$_cf_v ;;
        LIVE) C_LIVE=$_cf_v ;;
        AUTO) C_AUTO=$_cf_v ;;
        GUARD) C_GUARD=$_cf_v ;;
        ETAG) C_ETAG=$_cf_v ;;
        SRCDATE) C_SRCDATE=$_cf_v ;;
      esac
    done < "$CFG"
  fi
  [ "$C_ENABLED" = 0 ] || C_ENABLED=1
  [ "$C_LIVE" = 0 ] || C_LIVE=1
  is_num "$C_UPDATED" || C_UPDATED=0
  is_num "$C_CHECKED" || C_CHECKED=0
  is_num "$C_COUNT" || C_COUNT=0
  is_num "$C_DOMAINS" || C_DOMAINS=0
  case $C_AUTO in 0 | 1 | 3 | 7) ;; *) C_AUTO=0 ;; esac
  case $C_SETUP in ready | pending | failed) ;; *) C_SETUP=ready ;; esac
  case $C_GUARD in *[!a-z0-9._-]*) C_GUARD= ;; esac
  addons_clean "$C_ADDONS"
  C_ADDONS=$R_ADDONS
  if ! list_info "$C_LIST" || [ "$L_KIND" != base ]; then
    C_LIST=stevenblack
    list_info "$C_LIST"
  fi
  return 0
}

cfg_save() {
  {
    printf 'LIST=%s\nADDONS=%s\nENABLED=%s\nSETUP=%s\n' "$C_LIST" "$C_ADDONS" "$C_ENABLED" "$C_SETUP"
    printf 'UPDATED=%s\nCHECKED=%s\nCOUNT=%s\nDOMAINS=%s\n' "$C_UPDATED" "$C_CHECKED" "$C_COUNT" "$C_DOMAINS"
    printf 'LIVE=%s\nAUTO=%s\nGUARD=%s\n' "$C_LIVE" "$C_AUTO" "$C_GUARD"
  } > "$CFG.tmp.$$" 2>/dev/null && mv -f "$CFG.tmp.$$" "$CFG"
}

src_load() {
  S_ETAG=; S_SRCDATE=; S_COUNT=0; S_SIZE=0; S_FETCHED=0
  [ -f "$LISTSD/$1.info" ] || return 1
  while IFS= read -r _sl_l || [ -n "$_sl_l" ]; do
    _sl_v=${_sl_l#*=}
    case ${_sl_l%%=*} in
      ETAG) S_ETAG=$_sl_v ;;
      SRCDATE) S_SRCDATE=$_sl_v ;;
      COUNT) S_COUNT=$_sl_v ;;
      SIZE) S_SIZE=$_sl_v ;;
      FETCHED) S_FETCHED=$_sl_v ;;
    esac
  done < "$LISTSD/$1.info"
  is_num "$S_COUNT" || S_COUNT=0
  is_num "$S_SIZE" || S_SIZE=0
  is_num "$S_FETCHED" || S_FETCHED=0
  return 0
}

src_write() {
  printf 'ETAG=%s\nSRCDATE=%s\nCOUNT=%s\nSIZE=%s\nFETCHED=%s\n' "$2" "$3" "$4" "$5" "$(now)" > "$1" 2>/dev/null
}

src_ready() { [ -s "$LISTSD/$1.domains" ]; }

src_file() {
  if [ -s "$STAGED/$1.domains" ]; then
    R_FILE=$STAGED/$1.domains
  elif [ -s "$LISTSD/$1.domains" ]; then
    R_FILE=$LISTSD/$1.domains
  else
    R_FILE=
    return 1
  fi
  return 0
}

sources_ready() {
  src_ready "$C_LIST" || return 1
  for _sr in $C_ADDONS; do src_ready "$_sr" || return 1; done
  return 0
}

migrate_data() {
  [ -f "$OLDCACHE" ] || return 0
  mkdir -p "$LISTSD" 2>/dev/null
  cfg_load
  if [ -s "$OLDCACHE" ] && [ ! -s "$LISTSD/$C_LIST.domains" ]; then
    ln "$OLDCACHE" "$LISTSD/$C_LIST.domains" 2>/dev/null || cp -f "$OLDCACHE" "$LISTSD/$C_LIST.domains" 2>/dev/null
    if [ -s "$LISTSD/$C_LIST.domains" ]; then
      src_write "$LISTSD/$C_LIST.info" "${C_ETAG#W/}" "$C_SRCDATE" "$C_COUNT" 0
      log INFO "Migrated the cached list from the v1 layout"
    fi
  fi
  [ "${1:-}" = keep ] || rm -f "$OLDCACHE"
  return 0
}

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

lock_wait() {
  _lw=0
  while ! lock_take "$1"; do
    op_running && return 1
    [ "$_lw" -ge "${2:-12}" ] && return 1
    nap 0.25
    _lw=$((_lw + 1))
  done
  return 0
}

lock_drop() { rm -rf "$1" 2>/dev/null; return 0; }
lock_drop_if_mine() { [ "$(lock_pid "$1")" = "$$" ] && rm -rf "$1" 2>/dev/null; return 0; }

busy_reply() { reply false busy '⏳ Another task is still running. Please wait until it finishes.'; }

op_load() {
  OP_KIND=; OP_LIST=; OP_PHASE=; OP_STATE=; OP_CODE=; OP_MSG=; OP_SEQ=0; OP_START=0; OP_END=0; OP_TOTAL=0
  OP_DOMAINS=0; OP_REBOOT=0; OP_LIVE=0; OP_ITEM=0; OP_ITEMS=0; OP_SRC=; OP_SRCNAME=; OP_WARN=0
  [ -f "$OPF" ] || return 0
  while IFS= read -r _ol_l || [ -n "$_ol_l" ]; do
    _ol_v=${_ol_l#*=}
    case ${_ol_l%%=*} in
      KIND) OP_KIND=$_ol_v ;;
      LIST) OP_LIST=$_ol_v ;;
      PHASE) OP_PHASE=$_ol_v ;;
      STATE) OP_STATE=$_ol_v ;;
      CODE) OP_CODE=$_ol_v ;;
      MSG) OP_MSG=$_ol_v ;;
      SEQ) OP_SEQ=$_ol_v ;;
      START) OP_START=$_ol_v ;;
      END) OP_END=$_ol_v ;;
      TOTAL) OP_TOTAL=$_ol_v ;;
      DOMAINS) OP_DOMAINS=$_ol_v ;;
      REBOOT) OP_REBOOT=$_ol_v ;;
      LIVE) OP_LIVE=$_ol_v ;;
      ITEM) OP_ITEM=$_ol_v ;;
      ITEMS) OP_ITEMS=$_ol_v ;;
      SRC) OP_SRC=$_ol_v ;;
      SRCNAME) OP_SRCNAME=$_ol_v ;;
      WARN) OP_WARN=$_ol_v ;;
    esac
  done < "$OPF"
}

op_save() {
  [ "$MODE" = install ] && return 0
  {
    printf 'KIND=%s\nLIST=%s\nPHASE=%s\nSTATE=%s\nCODE=%s\n' "$OP_KIND" "$OP_LIST" "$OP_PHASE" "$OP_STATE" "$OP_CODE"
    printf 'MSG=%s\nSEQ=%s\nSTART=%s\nEND=%s\nTOTAL=%s\n' "$OP_MSG" "$OP_SEQ" "$OP_START" "$OP_END" "$OP_TOTAL"
    printf 'DOMAINS=%s\nREBOOT=%s\nLIVE=%s\nITEM=%s\nITEMS=%s\n' "$OP_DOMAINS" "$OP_REBOOT" "$OP_LIVE" "$OP_ITEM" "$OP_ITEMS"
    printf 'SRC=%s\nSRCNAME=%s\nWARN=%s\n' "$OP_SRC" "$OP_SRCNAME" "$OP_WARN"
  } > "$OPF.tmp.$$" 2>/dev/null && mv -f "$OPF.tmp.$$" "$OPF"
}

op_begin() {
  _ob=0
  [ -f "$SEQF" ] && read -r _ob < "$SEQF"
  is_num "$_ob" || _ob=0
  _ob_n=$(now)
  if [ "$_ob_n" -gt "$_ob" ]; then _ob=$_ob_n; else _ob=$((_ob + 1)); fi
  echo "$_ob" > "$SEQF"
  OP_KIND=$1; OP_LIST=$2; OP_PHASE=prepare; OP_STATE=running; OP_CODE=; OP_MSG=
  OP_SEQ=$_ob; OP_START=$(now); OP_END=0; OP_TOTAL=0; OP_DOMAINS=0; OP_REBOOT=0; OP_LIVE=0
  OP_ITEM=0; OP_ITEMS=0; OP_SRC=; OP_SRCNAME=; OP_WARN=0
  rm -f "$DLPART" "$DLHDR" "$RUND/cancel"
  op_save
}

op_phase() { OP_PHASE=$1; op_save; }

op_finish() {
  OP_STATE=$1; OP_CODE=$2; OP_MSG=$3; OP_END=$(now)
  op_save
}

op_running() { [ -f "$OPF" ] && grep -q '^STATE=running$' "$OPF" 2>/dev/null; }

op_interrupt() {
  op_load
  OP_PHASE=; OP_STATE=error; OP_CODE=interrupted; OP_END=$(now); OP_MSG=$1
  op_save
}

op_reconcile() {
  op_running || return 0
  lock_alive "$LOCKD" && return 0
  op_interrupt '⚠️ The last task was interrupted. Your hosts file is intact — run it again to finish.'
  lock_drop "$LOCKD"
  log WARN "A background task stopped unexpectedly; its state was reset"
}

op_json() {
  op_reconcile
  if [ ! -f "$OPF" ]; then
    R_OP='{"running":false,"state":"idle","seq":0}'
    return 0
  fi
  _oj_b=0
  [ -f "$DLPART" ] && _oj_b=$(fsize "$DLPART")
  _oj_a=0
  lock_alive "$LOCKD" && _oj_a=1
  _oj_c=0
  [ -f "$RUND/cancel" ] && _oj_c=1
  R_OP=$(awk -v bytes="$_oj_b" -v alive="$_oj_a" -v cancelling="$_oj_c" -v hdr="$DLHDR" "$AWK_OPJSON" "$OPF" 2>/dev/null)
  case $R_OP in
    '{'*'}') ;;
    *)
      if [ "$_oj_a" = 1 ]; then R_OP='{"running":true,"state":"running","seq":0}'; else R_OP='{"running":false,"state":"idle","seq":0}'; fi
      ;;
  esac
}

cancel_requested() { [ -f "$RUND/cancel" ]; }

kill_tree() {
  is_num "$1" || return 0
  has pkill && pkill -P "$1" 2>/dev/null
  kill "$1" 2>/dev/null
  return 0
}

spawn() {
  _sp_out=$1
  shift
  _sp_mark=$RUND/spawn.$$.$(date +%s)
  rm -f "$_sp_mark"
  if has setsid; then
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

spawned() { [ -n "${SB_SPAWN_MARK:-}" ] && : > "$SB_SPAWN_MARK"; unset SB_SPAWN_MARK; return 0; }

dl_detect() {
  [ -n "$DL_TOOL" ] && [ "$DL_TOOL" != none ] && return 0
  DL_GZ=0
  if has curl && _dd=$(curl --version 2>/dev/null) && [ -n "$_dd" ]; then
    DL_TOOL=curl
    case $_dd in *libz* | *zlib*) DL_GZ=1 ;; esac
  elif wget --help 2>&1 | grep -qi -e '--header'; then
    DL_TOOL=wget
  else
    DL_TOOL=none
    return 1
  fi
  return 0
}

hdr_parse() {
  _hp=$(awk "$AWK_HDR" "$1" 2>/dev/null)
  { read -r DL_CODE; read -r DL_CL; read -r DL_TOTAL; read -r DL_ETAG; read -r DL_LASTMOD; read -r DL_ENC; } << EOF
$_hp
EOF
  is_num "$DL_CODE" || DL_CODE=
  is_num "$DL_CL" || DL_CL=
  is_num "$DL_TOTAL" || DL_TOTAL=
  DL_ETAG=$(clean_val "$DL_ETAG")
  DL_LASTMOD=$(clean_val "$DL_LASTMOD")
  case $DL_ENC in *[!a-z0-9-]*) DL_ENC=other ;; esac
}

dl_get() {
  _dg_u=$1; _dg_o=$2; _dg_h=$3; _dg_m=$4
  rm -f "$_dg_o" "$_dg_h.err"
  : > "$_dg_h"
  DL_FAIL=; DL_ERR=; DL_CODE=; DL_CL=; DL_TOTAL=; DL_ETAG=; DL_LASTMOD=; DL_ENC=
  case $DL_TOOL in
    curl)
      set -- -sS -L -g --proto '=https' --proto-redir '=https' --connect-timeout 15 --speed-limit 1024 --speed-time 30 --max-filesize "$MAX_BYTES" -A "$UA" -D "$_dg_h" -o "$_dg_o"
      if [ "$_dg_m" = peek ]; then
        set -- "$@" -r 0-8191
      elif [ "$DL_GZ" = 1 ]; then
        set -- "$@" --compressed
      fi
      curl "$@" "$_dg_u" 2> "$_dg_h.err" &
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
  if [ "$_dg_m" = full ] || [ "$DL_TOOL" = curl ]; then
    _dg_k=0
    while kill -0 "$_dg_p" 2>/dev/null; do
      if [ "$(fsize "$_dg_o")" -gt "$MAX_BYTES" ]; then
        kill_tree "$_dg_p"
        DL_FAIL=toolarge
        break
      fi
      if [ "$_dg_k" -lt 8 ]; then
        nap 0.05
        _dg_k=$((_dg_k + 1))
      else
        nap 0.2
      fi
    done
  fi
  wait "$_dg_p"
  _dg_rc=$?
  [ -n "$DL_PIDF" ] && rm -f "$DL_PIDF"
  if [ -z "$DL_FAIL" ] && [ "$(fsize "$_dg_o")" -gt "$MAX_BYTES" ]; then
    DL_FAIL=toolarge
  fi
  hdr_parse "$_dg_h"
  if [ "$DL_TOOL" = curl ]; then
    DL_ERR=$(head -n 1 "$_dg_h.err" 2>/dev/null)
  else
    DL_ERR=$(grep '^wget:' "$_dg_h" 2>/dev/null | grep -v 'certificate validation' | head -n 1)
  fi
  DL_ERR=$(clean_val "$DL_ERR")
  rm -f "$_dg_h.err"
  if [ -z "$DL_FAIL" ]; then
    if [ "$_dg_rc" = 63 ] && [ "$DL_TOOL" = curl ]; then
      DL_FAIL=toolarge
    elif [ -z "$DL_CODE" ]; then
      DL_FAIL=network
    elif [ "$DL_CODE" != 200 ] && [ "$DL_CODE" != 206 ]; then
      DL_FAIL=http
    elif [ "$_dg_rc" -ne 0 ] && [ "$_dg_m" = full ]; then
      DL_FAIL=incomplete
    fi
  fi
  [ -z "$DL_FAIL" ]
}

dl_reason() {
  case $DL_FAIL in
    http) printf 'HTTP %s' "$DL_CODE" ;;
    toolarge) printf 'the file is larger than %s MB' "$((MAX_BYTES / 1048576))" ;;
    incomplete) printf 'transfer interrupted%s' "${DL_ERR:+ ($DL_ERR)}" ;;
    *) printf 'no connection%s' "${DL_ERR:+ ($DL_ERR)}" ;;
  esac
}

dl_fetch() {
  _df_t=1
  while :; do
    dl_get "$1" "$2" "$3" "$4" && return 0
    case $DL_FAIL in
      toolarge) return 1 ;;
      http) case $DL_CODE in 408 | 425 | 429 | 5??) ;; *) return 1 ;; esac ;;
    esac
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

set_hosts_perm() {
  chmod 0644 "$1" 2>/dev/null
  chown 0:0 "$1" 2>/dev/null
  chcon u:object_r:system_file:s0 "$1" 2>/dev/null
  return 0
}

hosts_sane() {
  [ -s "$1" ] || return 1
  _hs_a=; _hs_b=
  { IFS= read -r _hs_a; IFS= read -r _hs_b; } < "$1"
  [ "$_hs_a" = "$LOCAL_LINE" ] && [ "$_hs_b" = "$LOCAL6_LINE" ]
}

sum_calc() {
  R_SUM=
  if has cksum; then
    R_SUM=$(cksum < "$1" 2>/dev/null)
    R_SUM=cksum:${R_SUM%% *}
  elif has md5sum; then
    R_SUM=$(md5sum < "$1" 2>/dev/null)
    R_SUM=md5:${R_SUM%% *}
  else
    R_SUM=size:$(fsize "$1")
  fi
  case $R_SUM in *:) R_SUM= ;; esac
}

sum_record() {
  sum_calc "$HOSTS"
  [ -n "$R_SUM" ] || { rm -f "$SUMF"; return 0; }
  printf 'SUM=%s\nCOUNT=%s\nSIZE=%s\n' "$R_SUM" "$1" "$(fsize "$HOSTS")" > "$SUMF.tmp.$$" 2>/dev/null && mv -f "$SUMF.tmp.$$" "$SUMF"
  return 0
}

sum_check() {
  _sc_s=; _sc_z=
  [ -f "$SUMF" ] || return 2
  while IFS= read -r _sc_l || [ -n "$_sc_l" ]; do
    case ${_sc_l%%=*} in
      SUM) _sc_s=${_sc_l#*=} ;;
      SIZE) _sc_z=${_sc_l#*=} ;;
    esac
  done < "$SUMF"
  [ -n "$_sc_s" ] || return 2
  [ "$(fsize "$HOSTS")" = "$_sc_z" ] || return 1
  case $_sc_s in
    cksum:*) has cksum || return 2 ;;
    md5:*) has md5sum || return 2 ;;
    size:*) return 0 ;;
    *) return 2 ;;
  esac
  sum_calc "$HOSTS"
  case $R_SUM in "${_sc_s%%:*}":*) ;; *) return 2 ;; esac
  [ "$R_SUM" = "$_sc_s" ]
}

stats_read() {
  ST_TOTAL=0; ST_BASE=0; ST_ALLOWED=0; ST_BLOCKED=0; ST_GUARDED=0; ST_ADDONS=; ST_IDS=; ST_LIST=
  for _st_f in "$CACHED/merge.info" "$STATF"; do
    [ -f "$_st_f" ] || continue
    while IFS= read -r _st_l || [ -n "$_st_l" ]; do
      _st_v=${_st_l#*=}
      case ${_st_l%%=*} in
        TOTAL) ST_TOTAL=$_st_v ;;
        BASE) ST_BASE=$_st_v ;;
        ALLOWED) ST_ALLOWED=$_st_v ;;
        BLOCKED) ST_BLOCKED=$_st_v ;;
        GUARDED) ST_GUARDED=$_st_v ;;
        ADDON[0-9]*) ST_ADDONS="$ST_ADDONS $_st_v" ;;
        IDS) ST_IDS=$_st_v ;;
        LIST) ST_LIST=$_st_v ;;
      esac
    done < "$_st_f"
  done
  ST_ADDONS=${ST_ADDONS# }
  is_num "$ST_TOTAL" || ST_TOTAL=0
  is_num "$ST_BASE" || ST_BASE=0
  is_num "$ST_ALLOWED" || ST_ALLOWED=0
  is_num "$ST_BLOCKED" || ST_BLOCKED=0
  is_num "$ST_GUARDED" || ST_GUARDED=0
  return 0
}

guard_detect() {
  R_GUARD=
  [ -x /system/bin/settings ] || return 0
  _gd_m=$(timeout 3 /system/bin/settings get global private_dns_mode 2>/dev/null)
  [ "$_gd_m" = hostname ] || return 0
  _gd_h=$(timeout 3 /system/bin/settings get global private_dns_specifier 2>/dev/null | tr '[:upper:]' '[:lower:]' | tr -d ' \r\n')
  case $_gd_h in '' | null | *[!a-z0-9._-]*) return 0 ;; esac
  printf '%s\n' "$_gd_h" | awk "$AWK_VALID" && R_GUARD=$_gd_h
  return 0
}

merge_fresh() {
  _mg_l=; _mg_i=
  [ -f "$1/merge.info" ] || return 1
  while IFS= read -r _mg_r || [ -n "$_mg_r" ]; do
    case ${_mg_r%%=*} in
      LIST) _mg_l=${_mg_r#*=} ;;
      IDS) _mg_i=${_mg_r#*=} ;;
    esac
  done < "$1/merge.info"
  [ "$_mg_l" = "$C_LIST" ] && [ "$_mg_i" = "$C_ADDONS" ] || return 1
  [ -z "$C_ADDONS" ] || [ -f "$1/extras.domains" ]
}

merge_sources() {
  _mg_d=$1
  src_file "$C_LIST" || return 1
  _mg_b=$R_FILE
  rm -f "$_mg_d/extras.domains" "$_mg_d/merge.info" "$_mg_d/merge.tmp"
  if [ -z "$C_ADDONS" ]; then
    _mg_n=$(grep -c . "$_mg_b" 2>/dev/null)
    is_num "$_mg_n" || return 1
    printf 'BASE=%s\nLIST=%s\nIDS=\n' "$_mg_n" "$C_LIST" > "$_mg_d/merge.info" 2>/dev/null || return 1
    return 0
  fi
  _mg_a=
  for _mg_x in $C_ADDONS; do
    src_file "$_mg_x" || return 1
    _mg_a="$_mg_a $R_FILE"
  done
  awk -v addons="${_mg_a# }" -v outf="$_mg_d/extras.domains" -v statf="$_mg_d/merge.tmp" "$AWK_MERGE" "$_mg_b" 2>/dev/null || { rm -f "$_mg_d/extras.domains" "$_mg_d/merge.tmp"; return 1; }
  [ -f "$_mg_d/extras.domains" ] && [ -s "$_mg_d/merge.tmp" ] || return 1
  printf 'LIST=%s\nIDS=%s\n' "$C_LIST" "$C_ADDONS" >> "$_mg_d/merge.tmp" 2>/dev/null || return 1
  mv -f "$_mg_d/merge.tmp" "$_mg_d/merge.info"
}

compile_into() {
  _ci_o=$1
  CH_COUNT=0
  rm -f "$TMPD/compile.stats"
  if [ "$2" != 1 ]; then
    printf '%s\n%s\n' "$LOCAL_LINE" "$LOCAL6_LINE" > "$_ci_o" 2>/dev/null || return 1
    return 0
  fi
  src_file "$C_LIST" || return 1
  _ci_b=$R_FILE
  _ci_x=
  if merge_fresh "$STAGED"; then
    _ci_x=$STAGED/extras.domains
  else
    merge_fresh "$CACHED" || merge_sources "$CACHED" || return 1
    _ci_x=$CACHED/extras.domains
  fi
  [ -n "$C_ADDONS" ] || _ci_x=
  case $MODE in
    boot) ;;
    *) guard_detect; C_GUARD=$R_GUARD ;;
  esac
  if [ -n "$_ci_x" ]; then
    awk -F. -v allowf="$ALLOWF" -v blockf="$BLOCKF" -v statf="$TMPD/compile.stats" -v guard="$C_GUARD" -v local4="$LOCAL_LINE" -v local6="$LOCAL6_LINE" "$AWK_COMPILE" "$_ci_b" "$_ci_x" > "$_ci_o" 2>/dev/null || return 1
  else
    awk -F. -v allowf="$ALLOWF" -v blockf="$BLOCKF" -v statf="$TMPD/compile.stats" -v guard="$C_GUARD" -v local4="$LOCAL_LINE" -v local6="$LOCAL6_LINE" "$AWK_COMPILE" "$_ci_b" > "$_ci_o" 2>/dev/null || return 1
  fi
  CH_COUNT=$(sed -n 's/^TOTAL=//p' "$TMPD/compile.stats" 2>/dev/null)
  is_num "$CH_COUNT" || return 1
  return 0
}

stats_commit() {
  if [ -f "$TMPD/compile.stats" ]; then
    mv -f "$TMPD/compile.stats" "$STATF" 2>/dev/null
  else
    rm -f "$STATF"
  fi
  return 0
}

put_hosts() {
  if [ "${2:-}" = inplace ] && [ "$MODE" != install ] && [ -f "$HOSTS" ]; then
    if cat "$1" > "$HOSTS" 2>/dev/null && [ "$(fsize "$1")" = "$(fsize "$HOSTS")" ]; then
      rm -f "$1"
      set_hosts_perm "$HOSTS"
      return 0
    fi
  fi
  set_hosts_perm "$1"
  if mv -f "$1" "$HOSTS"; then
    set_hosts_perm "$HOSTS"
    return 0
  fi
  rm -f "$1"
  return 1
}

write_clean_hosts() {
  mkdir -p "$HOSTSD"
  printf '%s\n%s\n' "$LOCAL_LINE" "$LOCAL6_LINE" > "$HOSTSD/.hosts.sbclean" && put_hosts "$HOSTSD/.hosts.sbclean" inplace && sum_record 0
}

backup_hosts() {
  hosts_sane "$HOSTS" || return 0
  rm -f "$BACKUPD/hosts.3" "$BACKUPD/hosts.3.gz"
  for _bk in 2 1; do
    for _bk_e in '' .gz; do
      [ -f "$BACKUPD/hosts.$_bk$_bk_e" ] && mv -f "$BACKUPD/hosts.$_bk$_bk_e" "$BACKUPD/hosts.$((_bk + 1))$_bk_e"
    done
  done
  if has gzip && gzip -c "$HOSTS" > "$BACKUPD/hosts.1.gz" 2>/dev/null && [ -s "$BACKUPD/hosts.1.gz" ]; then
    return 0
  fi
  rm -f "$BACKUPD/hosts.1.gz"
  cp -f "$HOSTS" "$BACKUPD/hosts.1" 2>/dev/null || rm -f "$BACKUPD/hosts.1"
  return 0
}

restore_backup() {
  for _rb in 1 2 3; do
    rm -f "$HOSTSD/.hosts.sbrestore"
    if [ -f "$BACKUPD/hosts.$_rb.gz" ]; then
      gzip -dc "$BACKUPD/hosts.$_rb.gz" > "$HOSTSD/.hosts.sbrestore" 2>/dev/null || continue
    elif [ -f "$BACKUPD/hosts.$_rb" ]; then
      cp -f "$BACKUPD/hosts.$_rb" "$HOSTSD/.hosts.sbrestore" 2>/dev/null || continue
    else
      continue
    fi
    hosts_sane "$HOSTSD/.hosts.sbrestore" || continue
    if put_hosts "$HOSTSD/.hosts.sbrestore" inplace; then
      rm -f "$SUMF"
      log WARN "Restored the previous hosts file from backup $_rb"
      return 0
    fi
  done
  rm -f "$HOSTSD/.hosts.sbrestore"
  write_clean_hosts
  log ERROR "No usable backup was found; wrote a clean localhost-only hosts file"
  return 1
}

verify_hosts() {
  hosts_sane "$HOSTS" || return 1
  _vh=$(wc -l < "$HOSTS" 2>/dev/null)
  is_num "$_vh" && [ "$_vh" -eq $(($1 + 2)) ]
}

verify_hosts_deep() {
  [ -s "$HOSTS" ] || return 1
  awk -v want="$1" -v local4="$LOCAL_LINE" -v local6="$LOCAL6_LINE" "$AWK_VERIFY" "$HOSTS" 2>/dev/null
}

install_hosts() {
  IH_CHANGED=1
  mkdir -p "$HOSTSD"
  if [ -f "$HOSTS" ] && [ "$(fsize "$1")" = "$(fsize "$HOSTS")" ] && cmp -s "$1" "$HOSTS"; then
    rm -f "$1"
    IH_CHANGED=0
    [ -f "$SUMF" ] || sum_record "$2"
    return 0
  fi
  [ "${3:-}" = backup ] && backup_hosts
  _ih=
  [ "$C_LIVE" = 1 ] && _ih=inplace
  if ! put_hosts "$1" "$_ih"; then
    restore_backup
    return 1
  fi
  if ! verify_hosts "$2"; then
    log ERROR "The new hosts file failed verification"
    restore_backup
    return 2
  fi
  sum_record "$2"
  return 0
}

live_hosts() {
  if head -c 1 "$INIT_HOSTS" > /dev/null 2>&1; then R_LIVE=$INIT_HOSTS; else R_LIVE=$SYS_HOSTS; fi
}

hosts_live() {
  [ -f "$HOSTS" ] || return 1
  live_hosts
  [ "$R_LIVE" -ef "$HOSTS" ] && return 0
  cmp -s "$R_LIVE" "$HOSTS"
}

mark_pending() { boot_id > "$PENDF.tmp" 2>/dev/null && mv -f "$PENDF.tmp" "$PENDF"; return 0; }

pending_flag() {
  [ -f "$PENDF" ] || return 1
  [ "$(cat "$PENDF" 2>/dev/null)" = "$(boot_id)" ]
}

repair_hosts() {
  if hosts_sane "$HOSTS"; then
    [ "${1:-}" = deep ] || return 0
    sum_check
    case $? in
      0) return 0 ;;
      2) cfg_load; sum_record "$C_DOMAINS"; return 0 ;;
    esac
    log WARN "The hosts file didn’t match its checksum; rebuilding it"
  fi
  mkdir -p "$HOSTSD"
  rm -f "$HOSTSD/.hosts.sbnew"
  cfg_load
  _rh=0
  if [ "$C_ENABLED" != 1 ]; then
    compile_into "$HOSTSD/.hosts.sbnew" 0 && _rh=1
  elif [ "$C_SETUP" = ready ] && sources_ready; then
    compile_into "$HOSTSD/.hosts.sbnew" 1 && _rh=1
  fi
  if [ "$_rh" = 1 ] && hosts_sane "$HOSTSD/.hosts.sbnew"; then
    if put_hosts "$HOSTSD/.hosts.sbnew" inplace; then
      C_DOMAINS=$CH_COUNT
      cfg_save
      stats_commit
      sum_record "$CH_COUNT"
      log WARN "The hosts file was missing or damaged; rebuilt it from the cached lists"
      return 0
    fi
  fi
  rm -f "$HOSTSD/.hosts.sbnew"
  write_clean_hosts || return 1
  log WARN "The hosts file was missing or damaged; wrote a clean localhost-only file"
  return 0
}

in_init_ns() {
  _ns_s=$(readlink /proc/self/ns/mnt 2>/dev/null)
  [ -n "$_ns_s" ] && [ "$_ns_s" = "$(readlink "$INIT_NS" 2>/dev/null)" ]
}

bind_hosts() {
  if in_init_ns; then
    mount -o bind "$HOSTS" "$MOUNT_TARGET" 2>/dev/null && return 0
  fi
  if [ "$SB_BB" != none ]; then
    "$SB_BB" nsenter -t 1 -m -- "$SB_BB" mount -o bind "$HOSTS" "$MOUNT_TARGET" 2>/dev/null && return 0
  fi
  if [ -x /system/bin/nsenter ]; then
    /system/bin/nsenter -t 1 -m -- /system/bin/mount -o bind "$HOSTS" "$MOUNT_TARGET" 2>/dev/null && return 0
  fi
  in_init_ns || mount -o bind "$HOSTS" "$MOUNT_TARGET" 2>/dev/null
}

mount_record() {
  printf '%s\n%s\n' "$(boot_id)" "$1" > "$MOUNTF.tmp.$$" 2>/dev/null && mv -f "$MOUNTF.tmp.$$" "$MOUNTF"
  return 0
}

mount_mode() {
  _mm_b=; R_MOUNT=
  [ -f "$MOUNTF" ] && { read -r _mm_b; read -r R_MOUNT; } < "$MOUNTF"
  [ "$_mm_b" = "$(boot_id)" ] || R_MOUNT=
}

conflicts_scan() {
  R_CONF=
  for _cf_d in "$MODROOT"/*; do
    [ -d "$_cf_d" ] || continue
    _cf_i=${_cf_d##*/}
    [ "$_cf_i" = stevenblock ] && continue
    [ -f "$_cf_d/system/etc/hosts" ] || continue
    [ -f "$_cf_d/disable" ] && continue
    [ -f "$_cf_d/remove" ] && continue
    case $_cf_i in *[!A-Za-z0-9._-]*) continue ;; esac
    R_CONF="$R_CONF $_cf_i"
  done
  R_CONF=${R_CONF# }
}

ensure_mounted() {
  [ -f "$HOSTS" ] || return 0
  mount_mode
  if hosts_live; then
    case $R_MOUNT in manager | self) ;; *) mount_record manager ;; esac
    return 0
  fi
  conflicts_scan
  if [ -n "$R_CONF" ]; then
    [ "${1:-}" = quiet ] && return 1
    [ "$R_MOUNT" = conflict ] || log WARN "Another module also replaces /system/etc/hosts ($R_CONF), so StevenBlock left it alone"
    mount_record conflict
    return 1
  fi
  set_hosts_perm "$HOSTS"
  if bind_hosts && hosts_live; then
    mount_record self
    log INFO "The root manager didn’t apply StevenBlock’s hosts file, so StevenBlock mounted it directly"
    return 0
  fi
  [ "${1:-}" = quiet ] && return 1
  [ "$R_MOUNT" = failed ] || log ERROR "Couldn’t mount the hosts file onto /system/etc/hosts"
  mount_record failed
  return 1
}

apply_now() {
  IH_LIVE=0
  [ "$MODE" = install ] && return 1
  if hosts_live; then
    IH_LIVE=1
    rm -f "$PENDF"
    return 0
  fi
  [ "$C_LIVE" = 1 ] || return 1
  if ensure_mounted quiet; then
    IH_LIVE=1
    rm -f "$PENDF"
    return 0
  fi
  return 1
}

settle_change() {
  if apply_now; then
    flush_dns
    return 0
  fi
  mark_pending
  return 1
}

applied_state() {
  if [ ! -f "$HOSTS" ]; then R_APPLIED=unknown; return 0; fi
  if hosts_live; then
    R_APPLIED=applied
  elif pending_flag; then
    R_APPLIED=pending
  else
    conflicts_scan
    if [ -n "$R_CONF" ]; then R_APPLIED=overridden; else R_APPLIED=inactive; fi
  fi
}

describe() {
  cfg_load
  case $C_SETUP in
    pending) R_DESC="🛡️ ⏳ Setup pending • $L_NAME downloads automatically once you are online"; return 0 ;;
    failed) R_DESC='🛡️ ❌ Setup incomplete • Open the WebUI and tap Download now to finish setup'; return 0 ;;
  esac
  applied_state
  _ds_x=
  if [ -n "$C_ADDONS" ]; then
    set -- $C_ADDONS
    _ds_x=" + $# $(plural "$#" add-on add-ons)"
  fi
  if [ "$R_APPLIED" = pending ]; then
    if [ "$C_ENABLED" = 1 ]; then
      R_DESC="🛡️ 🟡 Reboot required • $L_NAME$_ds_x • $(fmt_num "$C_DOMAINS") domains ready"
    else
      R_DESC='🛡️ 🟡 Reboot required • Blocking will be turned off'
    fi
  elif [ "$C_ENABLED" != 1 ]; then
    R_DESC="🛡️ 🔴 Disabled • $L_NAME is paused"
  elif [ "$R_APPLIED" = overridden ]; then
    R_DESC='🛡️ ⚠️ Overridden • Another module replaces /system/etc/hosts'
  elif [ "$R_APPLIED" = inactive ]; then
    R_DESC="🛡️ 🔴 Not active • Reboot to activate $L_NAME"
  else
    R_DESC="🛡️ 🟢 Active • $L_NAME$_ds_x • $(fmt_num "$C_DOMAINS") domains blocked"
  fi
}

set_description() {
  [ -f "$PROP" ] || return 0
  describe
  awk -v d="$R_DESC" 'BEGIN { f = 0 } /^description=/ { if (!f) print "description=" d; f = 1; next } { print } END { if (!f) print "description=" d }' "$PROP" > "$PROP.sbtmp" 2>/dev/null && mv -f "$PROP.sbtmp" "$PROP"
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
  [ -n "$_fd" ] && log INFO "DNS cache flushed ($_fd)"
  return 0
}

detect_manager() {
  MGR_NAME=; MGR_VER=; MGR_HTTPD=
  _dm_b=$(boot_id)
  if [ -f "$RUND/manager" ]; then
    { read -r _dm_c; read -r MGR_NAME; read -r MGR_VER; read -r MGR_HTTPD; } < "$RUND/manager"
    [ "$_dm_c" = "$_dm_b" ] && [ -n "$MGR_NAME" ] && [ -n "$MGR_HTTPD" ] && return 0
  fi
  _dm=
  if [ "${APATCH:-}" = true ]; then _dm=apatch
  elif [ "${KSU:-}" = true ]; then _dm=ksu
  elif [ -n "${MAGISK_VER:-}" ]; then _dm=magisk
  elif has magisk; then _dm=magisk
  elif [ -x /data/adb/apd ]; then _dm=apatch
  elif [ -x /data/adb/ksud ]; then _dm=ksu
  elif [ -d /data/adb/magisk ]; then _dm=magisk
  fi
  case $_dm in
    apatch)
      MGR_NAME=APatch
      MGR_VER=${APATCH_VER:-$(timeout 3 /data/adb/apd -V 2>/dev/null | head -n 1)}
      ;;
    ksu)
      if [ -d /data/data/com.sukisu.ultra ]; then
        MGR_NAME='SukiSU Ultra'
      elif [ -d /data/data/com.rifsxd.ksunext ]; then
        MGR_NAME='KernelSU Next'
      else
        MGR_NAME=KernelSU
      fi
      MGR_VER=${KSU_VER:-$(timeout 3 /data/adb/ksud -V 2>/dev/null | head -n 1)}
      ;;
    magisk)
      MGR_NAME=Magisk
      MGR_VER=${MAGISK_VER:-$(timeout 3 magisk -v 2>/dev/null | head -n 1)}
      MGR_VER=${MGR_VER%%:*}
      ;;
    *) MGR_NAME=Unknown ;;
  esac
  case $MGR_VER in *' '*) MGR_VER=${MGR_VER##* } ;; esac
  MGR_VER=$(clean_val "$MGR_VER")
  MGR_HTTPD=no
  [ "$SB_BB" != none ] && "$SB_BB" --list 2>/dev/null | grep -qx httpd && MGR_HTTPD=yes
  [ -d "$RUND" ] && printf '%s\n%s\n%s\n%s\n' "$_dm_b" "$MGR_NAME" "$MGR_VER" "$MGR_HTTPD" > "$RUND/manager" 2>/dev/null
  return 0
}

httpd_available() {
  [ -n "${MGR_HTTPD:-}" ] || detect_manager
  [ "$MGR_HTTPD" = yes ]
}

device_addon() {
  R_DEVADDON=
  _da_b=$(boot_id)
  if [ -f "$RUND/device" ]; then
    { read -r _da_c; read -r R_DEVADDON; } < "$RUND/device"
    [ "$_da_c" = "$_da_b" ] && return 0
  fi
  _da=$(getprop ro.product.brand 2>/dev/null; getprop ro.product.manufacturer 2>/dev/null)
  _da=$(printf '%s' "$_da" | tr '[:upper:]\n' '[:lower:] ')
  R_DEVADDON=
  case $_da in
    *xiaomi* | *redmi* | *poco*) R_DEVADDON=hz-xiaomi ;;
    *samsung*) R_DEVADDON=hz-samsung ;;
    *huawei* | *honor*) R_DEVADDON=hz-huawei ;;
    *oppo* | *realme* | *oneplus*) R_DEVADDON=hz-oppo ;;
    *vivo* | *iqoo*) R_DEVADDON=hz-vivo ;;
    *amazon*) R_DEVADDON=hz-amazon ;;
  esac
  [ -d "$RUND" ] && printf '%s\n%s\n' "$_da_b" "$R_DEVADDON" > "$RUND/device" 2>/dev/null
  return 0
}

open_url() {
  [ -x /system/bin/am ] || return 1
  _ou=$(/system/bin/am start -a android.intent.action.VIEW -d "$1" 2>&1) || return 1
  case $_ou in *Error* | *error:* | *Exception*) return 1 ;; esac
  return 0
}

meta_load() {
  M_COUNT=; M_EPOCH=; M_RAW=; M_ERR=; M_FETCHED=0; M_SIZE=
  [ -f "$METAD/$1" ] || return 1
  while IFS= read -r _ml_l || [ -n "$_ml_l" ]; do
    _ml_v=${_ml_l#*=}
    case ${_ml_l%%=*} in
      COUNT) M_COUNT=$_ml_v ;;
      EPOCH) M_EPOCH=$_ml_v ;;
      RAW) M_RAW=$_ml_v ;;
      ERR) M_ERR=$_ml_v ;;
      FETCHED) M_FETCHED=$_ml_v ;;
      SIZE) M_SIZE=$_ml_v ;;
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

meta_ids() {
  custom_ids
  R_META="$BASE_IDS $ADDON_IDS${R_CUSTOM:+ $R_CUSTOM}"
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
    if [ -z "$_mf_c" ] && ! looks_html "$_mf_b"; then
      _mf_full=0
      [ -n "$DL_TOTAL" ] && [ "$(fsize "$_mf_b")" = "$DL_TOTAL" ] && _mf_full=1
      if [ "$_mf_full" = 0 ] && [ "$L_KIND" = base ]; then
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
    if [ -z "$_mf_c" ] && [ "$L_KIND" = addon ] && src_load "$1" && [ "$S_COUNT" -gt 0 ]; then
      _mf_c=$S_COUNT
    fi
    if [ -n "$_mf_c" ]; then
      meta_save "$1" "$_mf_c" "$(date_epoch "$_mf_d")" "$_mf_d" '' "$_mf_s"
    elif [ "$L_KIND" = addon ]; then
      meta_save "$1" '' "$(date_epoch "$_mf_d")" "$_mf_d" '' "$_mf_s"
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
  _mw_n=0
  for _mw in "$@"; do
    list_info "$_mw" || continue
    (
      trap - EXIT TERM INT HUP
      meta_fetch_one "$_mw"
    ) &
    _mw_n=$((_mw_n + 1))
    if [ "$_mw_n" -ge 6 ]; then
      wait
      _mw_n=0
    fi
  done
  wait
}

addon_added() {
  R_ADDED=
  _aa_n=0
  _aa_f=0
  for _aa_x in $ST_IDS; do
    _aa_n=$((_aa_n + 1))
    if [ "$_aa_x" = "$1" ]; then _aa_f=1; break; fi
  done
  [ "$_aa_f" = 1 ] || return 0
  _aa_k=0
  for _aa_v in $ST_ADDONS; do
    _aa_k=$((_aa_k + 1))
    if [ "$_aa_k" = "$_aa_n" ]; then R_ADDED=$_aa_v; return 0; fi
  done
}

list_item_json() {
  list_info "$1"
  meta_load "$1"
  _li_host=${L_URL#*://}
  _li_host=${_li_host%%/*}
  js "$L_NAME"; _li_1=$JS
  js "$L_LEVELTXT"; _li_2=$JS
  js "$L_DESC"; _li_3=$JS
  js "$_li_host"; _li_4=$JS
  js "$M_RAW"; _li_5=$JS
  js "$M_ERR"; _li_6=$JS
  jnum "$M_COUNT"; _li_7=$JN
  jnum "$M_EPOCH"; _li_8=$JN
  jnum "$M_SIZE"; _li_9=$JN
  jnum "$M_FETCHED"
  R_ITEM="{\"id\":\"$1\",\"name\":$_li_1,\"group\":\"$L_GROUP\",\"level\":\"$L_LEVEL\",\"levelText\":$_li_2,\"desc\":$_li_3,\"host\":$_li_4,\"count\":$_li_7,\"date\":$_li_8,\"dateRaw\":$_li_5,\"size\":$_li_9,\"error\":$_li_6,\"fetched\":$JN,\"busy\":$2}"
}

addon_item_json() {
  list_info "$1"
  meta_load "$1"
  _ai_host=${L_URL#*://}
  _ai_host=${_ai_host%%/*}
  _ai_on=false
  _ai_inst=null
  _ai_add=null
  if word_in "$1" "$C_ADDONS"; then
    _ai_on=true
    addon_added "$1"
    jnum "$R_ADDED"; _ai_add=$JN
  fi
  if src_ready "$1" && src_load "$1"; then _ai_inst=$S_COUNT; fi
  _ai_sug=false
  [ "$1" = "$R_DEVADDON" ] && _ai_sug=true
  _ai_cus=false
  _ai_url='""'
  if [ "$L_CUSTOM" = 1 ]; then
    _ai_cus=true
    js "$L_URL"; _ai_url=$JS
  fi
  js "$L_NAME"; _ai_1=$JS
  js "$L_DESC"; _ai_3=$JS
  js "$_ai_host"; _ai_4=$JS
  js "$M_ERR"; _ai_6=$JS
  jnum "$M_COUNT"; _ai_7=$JN
  jnum "$M_EPOCH"; _ai_8=$JN
  jnum "$M_SIZE"; _ai_9=$JN
  R_ITEM="{\"id\":\"$1\",\"name\":$_ai_1,\"icon\":\"$L_ICON\",\"group\":\"$L_GROUP\",\"desc\":$_ai_3,\"host\":$_ai_4,\"count\":$_ai_7,\"date\":$_ai_8,\"size\":$_ai_9,\"error\":$_ai_6,\"busy\":$2,\"enabled\":$_ai_on,\"installed\":$_ai_inst,\"added\":$_ai_add,\"warn\":\"$L_WARN\",\"suggested\":$_ai_sug,\"custom\":$_ai_cus,\"url\":$_ai_url}"
}

pl_set() { PL_CODE=$1; PL_MSG=$2; }

pl_cancelled() {
  pl_set cancelled '✖️ Cancelled. Nothing was changed.'
  log INFO "Cancelled by the user; nothing was changed"
}

pl_download_error() {
  case $DL_FAIL in
    http) pl_set http_error "🌐 The list server answered with HTTP $DL_CODE for $FS_NAME. Nothing was changed — please try again later." ;;
    toolarge) pl_set too_large "🐘 $FS_NAME is larger than $((MAX_BYTES / 1048576)) MB, so it was not downloaded. Nothing was changed." ;;
    incomplete) pl_set download_interrupted "✂️ The download of $FS_NAME was interrupted. Nothing was changed — please try again." ;;
    *) pl_set network_error "🌐 Couldn’t reach the list server. Check your connection and try again." ;;
  esac
  log ERROR "Download of $FS_NAME failed: $(dl_reason)"
}

pl_cleanup() {
  rm -f "$DLPART" "$DLHDR" "$DLHDR.err" "$TMPD/norm.count" "$TMPD/peek.body" "$TMPD/peek.hdr" "$TMPD/peek.hdr.err" "$TMPD/compile.stats" "$RUND/cancel" "$RUND/dl.pid" 2>/dev/null
  rm -rf "$STAGED" 2>/dev/null
  rm -f "$HOSTSD"/.hosts.sb* 2>/dev/null
  return 0
}

fetch_source() {
  list_info "$1" || return 1
  _fs_id=$1
  FS_NAME=$L_NAME
  _fs_url=$L_URL
  _fs_min=$L_MIN
  OP_SRC=$_fs_id
  OP_SRCNAME=$L_NAME
  OP_TOTAL=0
  op_phase check
  if [ "$2" = check ]; then
    say "🔎 Checking $FS_NAME for updates…"
    log INFO "Checking $FS_NAME for updates"
  fi
  _fs_et=; _fs_sd=; _fs_hc=; _fs_total=; _fs_have=0
  if dl_fetch "$_fs_url" "$TMPD/peek.body" "$TMPD/peek.hdr" peek; then
    head_info "$TMPD/peek.body"
    _fs_et=$DL_ETAG
    _fs_sd=$HI_DATE
    [ -n "$_fs_sd" ] || _fs_sd=$DL_LASTMOD
    _fs_hc=$HI_COUNT
    _fs_total=$DL_TOTAL
    [ -n "$DL_TOTAL" ] && [ "$(fsize "$TMPD/peek.body")" = "$DL_TOTAL" ] && _fs_have=1
  elif [ "$DL_FAIL" != http ] || [ "$DL_CODE" != 416 ]; then
    cancel_requested && return 3
    pl_download_error
    return 1
  fi
  if [ "$2" = check ] && src_ready "$_fs_id" && src_load "$_fs_id"; then
    _fs_same=0
    if [ -n "$_fs_et" ] && [ -n "$S_ETAG" ]; then
      [ "$_fs_et" = "$S_ETAG" ] && _fs_same=1
    elif [ -n "$_fs_sd" ] && [ -n "$S_SRCDATE" ]; then
      [ "$_fs_sd" = "$S_SRCDATE" ] && _fs_same=1
    fi
    if [ "$_fs_same" = 1 ]; then
      rm -f "$TMPD/peek.body" "$TMPD/peek.hdr"
      log INFO "$FS_NAME is already up to date"
      return 2
    fi
  fi
  cancel_requested && return 3

  _fs_need=51200
  if is_num "$_fs_total"; then
    _fs_est=$((_fs_total * 4 / 1024))
    [ "$_fs_est" -gt "$_fs_need" ] && _fs_need=$_fs_est
  fi
  _fs_free=$(free_kb "$DATA")
  if is_num "$_fs_free" && [ "$_fs_free" -lt "$_fs_need" ]; then
    pl_set no_space "💾 Not enough free storage. About $((_fs_need / 1024)) MB is needed, $((_fs_free / 1024)) MB is available."
    log ERROR "Not enough free storage: need ${_fs_need} KB, ${_fs_free} KB available"
    return 1
  fi

  OP_TOTAL=${_fs_total:-0}
  op_phase download
  say "⬇️ Downloading $FS_NAME…"
  log INFO "Downloading $FS_NAME"
  if [ "$_fs_have" = 1 ]; then
    mv -f "$TMPD/peek.body" "$DLPART"
    mv -f "$TMPD/peek.hdr" "$DLHDR"
    _fs_code=200
    _fs_cl=
    _fs_enc=
    _fs_fet=$_fs_et
  else
    rm -f "$TMPD/peek.body" "$TMPD/peek.hdr"
    DL_PIDF=$RUND/dl.pid
    if ! dl_fetch "$_fs_url" "$DLPART" "$DLHDR" full; then
      DL_PIDF=
      cancel_requested && return 3
      pl_download_error
      return 1
    fi
    DL_PIDF=
    _fs_code=$DL_CODE
    _fs_cl=$DL_CL
    _fs_enc=$DL_ENC
    _fs_fet=$DL_ETAG
    [ -n "$_fs_et" ] || _fs_et=$DL_ETAG
    [ -n "$_fs_sd" ] || _fs_sd=$DL_LASTMOD
  fi
  cancel_requested && return 3

  op_phase verify
  _fs_size=$(fsize "$DLPART")
  if [ "$_fs_code" != 200 ]; then
    pl_set http_error "🌐 The list server answered with HTTP $_fs_code instead of the list. Nothing was changed."
    log ERROR "Unexpected HTTP status $_fs_code for $FS_NAME"
    return 1
  fi
  if [ "$_fs_size" -eq 0 ]; then
    pl_set empty_file "📭 The server sent an empty file for $FS_NAME. Nothing was changed."
    log ERROR "Downloaded file for $FS_NAME was empty"
    return 1
  fi
  if looks_html "$DLPART"; then
    pl_set html_page '🧱 The server sent a web page instead of a hosts list. Nothing was changed.'
    log ERROR "Downloaded file for $FS_NAME was an HTML page"
    return 1
  fi
  _fs_want=
  if [ -z "$_fs_enc" ] && [ -n "$_fs_cl" ]; then
    _fs_want=$_fs_cl
  elif [ -n "$_fs_enc" ] && is_num "$_fs_total" && [ -n "$_fs_fet" ] && [ "$_fs_fet" = "$_fs_et" ]; then
    _fs_want=$_fs_total
  fi
  if [ -n "$_fs_want" ] && [ "$_fs_want" != "$_fs_size" ]; then
    pl_set size_mismatch "✂️ The download was incomplete ($(fmt_mb "$_fs_size") of $(fmt_mb "$_fs_want")). Nothing was changed."
    log ERROR "Incomplete download for $FS_NAME: $_fs_size of $_fs_want bytes"
    return 1
  fi
  say "✅ Downloaded $(fmt_mb "$_fs_size")"
  if [ -z "$_fs_hc" ] || [ -z "$_fs_sd" ]; then
    head_info "$DLPART"
    [ -n "$_fs_hc" ] || _fs_hc=$HI_COUNT
    [ -n "$_fs_sd" ] || _fs_sd=$HI_DATE
  fi
  cancel_requested && return 3

  op_phase optimize
  say "🧹 Cleaning and optimizing entries…"
  rm -f "$TMPD/norm.count"
  mkdir -p "$STAGED"
  if ! awk -v cntf="$TMPD/norm.count" "$AWK_NORM" "$DLPART" > "$STAGED/$_fs_id.domains" 2>/dev/null; then
    rm -f "$STAGED/$_fs_id.domains"
    pl_set process_failed "❌ $FS_NAME could not be processed. Nothing was changed."
    log ERROR "Processing $FS_NAME failed"
    return 1
  fi
  _fs_n=0
  [ -f "$TMPD/norm.count" ] && read -r _fs_n < "$TMPD/norm.count"
  is_num "$_fs_n" || _fs_n=0
  rm -f "$DLPART" "$DLHDR" "$TMPD/norm.count"
  if [ "$_fs_n" -lt "$_fs_min" ]; then
    rm -f "$STAGED/$_fs_id.domains"
    pl_set too_few_entries "📉 Only $(fmt_num "$_fs_n") valid entries were found in $FS_NAME (at least $(fmt_num "$_fs_min") are required). Nothing was changed."
    log ERROR "$FS_NAME had only $_fs_n valid entries"
    return 1
  fi
  say "✅ Verified $(fmt_num "$_fs_n") unique domains"
  src_write "$STAGED/$_fs_id.info" "$_fs_et" "$_fs_sd" "$_fs_n" "$_fs_size"
  meta_save "$_fs_id" "${_fs_hc:-$_fs_n}" "$(date_epoch "$_fs_sd")" "$_fs_sd" '' "$_fs_size"
  cancel_requested && return 3
  return 0
}

pipeline() {
  PL_KIND=$1; PL_BASE=$2; PL_CODE=; PL_MSG=; PL_REBOOT=0; PL_LIVE=0; PL_DOMAINS=0; PL_WARN=0
  if ! list_info "$PL_BASE" || [ "$L_KIND" != base ]; then
    pl_set invalid_list '❌ Unknown list.'
    return 1
  fi
  PL_NAME=$L_NAME
  addons_clean "$3"
  PL_ADDONS=$R_ADDONS
  ensure_dirs
  pl_cleanup
  mkdir -p "$STAGED"
  op_phase prepare

  _pl_plan=
  _pl_items=0
  for _pl_id in $PL_BASE $PL_ADDONS; do
    _pl_mode=
    if src_ready "$_pl_id"; then
      case $PL_KIND in update | auto | setup) _pl_mode=check ;; esac
    else
      _pl_mode=full
    fi
    [ -n "$_pl_mode" ] || continue
    _pl_plan="$_pl_plan $_pl_id:$_pl_mode"
    _pl_items=$((_pl_items + 1))
  done
  OP_ITEMS=$_pl_items
  if [ "$_pl_items" -gt 0 ] && ! dl_detect; then
    pl_set no_downloader '❌ No downloader available. StevenBlock needs curl or BusyBox wget with HTTPS support.'
    log ERROR "No downloader available (curl or BusyBox wget)"
    pl_cleanup
    return 1
  fi

  _pl_i=0
  _pl_new=0
  for _pl_e in $_pl_plan; do
    _pl_id=${_pl_e%%:*}
    _pl_i=$((_pl_i + 1))
    OP_ITEM=$_pl_i
    fetch_source "$_pl_id" "${_pl_e##*:}"
    case $? in
      0) _pl_new=$((_pl_new + 1)) ;;
      2) ;;
      3)
        pl_cancelled
        pl_cleanup
        return 1
        ;;
      *)
        if [ "$_pl_id" != "$PL_BASE" ] && src_ready "$_pl_id"; then
          PL_WARN=$((PL_WARN + 1))
          rm -f "$STAGED/$_pl_id.domains" "$STAGED/$_pl_id.info"
          log WARN "$FS_NAME couldn’t be refreshed; its previous version stays in use"
        else
          pl_cleanup
          return 1
        fi
        ;;
    esac
  done
  OP_SRC=; OP_SRCNAME=; OP_TOTAL=0
  if cancel_requested; then
    pl_cancelled
    pl_cleanup
    return 1
  fi

  cfg_load
  case $PL_KIND in
    update | auto)
      if [ "$_pl_new" = 0 ] && [ "$PL_WARN" = 0 ] && [ "$C_LIST" = "$PL_BASE" ] && [ "$C_ADDONS" = "$PL_ADDONS" ] && hosts_sane "$HOSTS"; then
        C_CHECKED=$(now)
        cfg_save
        PL_DOMAINS=$C_DOMAINS
        pl_set up_to_date "✅ Already up to date — nothing has changed since your last update."
        log INFO "Everything is already up to date"
        pl_cleanup
        return 0
      fi
      ;;
  esac

  op_phase install
  rm -f "$RUND/cancel"
  C_LIST=$PL_BASE
  C_ADDONS=$PL_ADDONS
  if ! merge_sources "$STAGED" || ! compile_into "$HOSTSD/.hosts.sbnew" 1; then
    pl_set write_failed "❌ Couldn’t build the new hosts file. Nothing was changed."
    log ERROR "Could not build the hosts file for $PL_NAME"
    pl_cleanup
    return 1
  fi
  install_hosts "$HOSTSD/.hosts.sbnew" "$CH_COUNT" backup
  case $? in
    1)
      pl_set write_failed "❌ Couldn’t write the hosts file. Your previous hosts file was restored."
      log ERROR "Could not write the hosts file for $PL_NAME"
      pl_cleanup
      return 1
      ;;
    2)
      pl_set verify_failed '❌ The new hosts file failed verification. Your previous hosts file was restored.'
      pl_cleanup
      return 1
      ;;
  esac

  for _pl_f in "$STAGED"/*.domains; do
    [ -f "$_pl_f" ] || continue
    _pl_id=${_pl_f##*/}
    _pl_id=${_pl_id%.domains}
    mv -f "$_pl_f" "$LISTSD/$_pl_id.domains"
    mv -f "$STAGED/$_pl_id.info" "$LISTSD/$_pl_id.info" 2>/dev/null
  done
  for _pl_f in "$LISTSD"/*.domains; do
    [ -f "$_pl_f" ] || continue
    _pl_id=${_pl_f##*/}
    _pl_id=${_pl_id%.domains}
    word_in "$_pl_id" "$PL_BASE $PL_ADDONS" && continue
    rm -f "$_pl_f" "$LISTSD/$_pl_id.info"
  done
  rm -f "$CACHED/extras.domains"
  [ -f "$STAGED/extras.domains" ] && mv -f "$STAGED/extras.domains" "$CACHED/extras.domains"
  mv -f "$STAGED/merge.info" "$CACHED/merge.info"
  src_load "$PL_BASE"
  C_ENABLED=1
  C_COUNT=$S_COUNT
  C_DOMAINS=$CH_COUNT
  C_SETUP=ready
  C_CHECKED=$(now)
  if [ "$_pl_new" -gt 0 ] || [ "$C_UPDATED" = 0 ]; then C_UPDATED=$C_CHECKED; fi
  cfg_save
  stats_commit

  op_phase finish
  PL_DOMAINS=$CH_COUNT
  _pl_n=$(fmt_num "$CH_COUNT")
  case $PL_KIND in
    update | auto) _pl_msg="✅ $PL_NAME updated — $_pl_n domains." ;;
    enable) _pl_msg="🟢 Blocking is back on with $PL_NAME — $_pl_n domains." ;;
    addons) _pl_msg="✅ Add-ons updated — $_pl_n domains." ;;
    *) _pl_msg="✅ $PL_NAME is ready — $_pl_n domains." ;;
  esac
  if [ "$IH_CHANGED" = 1 ]; then
    if settle_change; then
      PL_LIVE=1
      _pl_msg="$_pl_msg Active now — no reboot needed."
    else
      PL_REBOOT=1
      _pl_msg="$_pl_msg Reboot to activate it."
    fi
    _pl_code=applied
  else
    apply_now
    _pl_msg="✅ $PL_NAME is up to date — the hosts file didn’t change."
    _pl_code=unchanged
  fi
  if [ "$PL_WARN" -gt 0 ]; then
    _pl_msg="$_pl_msg ⚠️ $PL_WARN $(plural "$PL_WARN" add-on add-ons) couldn’t be refreshed and kept the previous version."
  fi
  set_description
  pl_set "$_pl_code" "$_pl_msg"
  set -- $PL_ADDONS
  log INFO "$PL_NAME installed with $# $(plural "$#" add-on add-ons): $_pl_n domains$( [ "$PL_LIVE" = 1 ] && printf ', applied live')$( [ "$PL_REBOOT" = 1 ] && printf ', reboot required')"
  pl_cleanup
  return 0
}

rebuild() {
  RB_CHANGED=0; RB_STATE=ok; RB_LIVE=0
  cfg_load
  if [ "$C_ENABLED" != 1 ]; then RB_STATE=disabled; return 0; fi
  if [ "$C_SETUP" != ready ] || ! sources_ready; then RB_STATE=nocache; return 0; fi
  if ! compile_into "$HOSTSD/.hosts.sbnew" 1; then
    rm -f "$HOSTSD/.hosts.sbnew" "$TMPD/compile.stats"
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
  stats_commit
  if [ "$RB_CHANGED" = 1 ]; then
    settle_change && RB_LIVE=1
  fi
  set_description
  return 0
}

change_note() {
  if [ "$RB_CHANGED" != 1 ]; then R_NOTE=
  elif [ "$RB_LIVE" = 1 ]; then R_NOTE=' Active now.'
  else R_NOTE=' Reboot to apply.'
  fi
}

extract_domain() {
  _ed=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
  _ed=${_ed#"${_ed%%[! 	]*}"}
  _ed=${_ed%"${_ed##*[! 	]}"}
  _ed_w=
  case $_ed in '*.'*) _ed_w='*.'; _ed=${_ed#'*.'} ;; esac
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
  printf '%s' "$_ed_w${_ed%.}"
}

domain_problem() {
  _dp=$1
  if [ -z "$_dp" ]; then printf '✏️ Enter a domain first.'; return 0; fi
  case $_dp in
    '*.'*)
      if [ "$2" != allow ]; then
        printf "🚫 Hosts files can’t block wildcards. Enter the exact domain to block."
        return 0
      fi
      _dp=${_dp#'*.'}
      ;;
  esac
  case $_dp in
    *"$NL"* | *"$CR"*) printf "🚫 That doesn’t look like a valid domain. Example: ads.example.com"; return 0 ;;
    *' '* | *"$TAB"*) printf "🚫 Spaces aren’t allowed in a domain."; return 0 ;;
    *'*'*) printf "🚫 A wildcard only works at the start of an allow rule, like *.example.com."; return 0 ;;
    \[* | *:*) printf "🚫 Ports and IPv6 addresses aren’t allowed. Enter just the domain, like example.com."; return 0 ;;
  esac
  case $_dp in *[!0-9.]*) ;; *) printf "🚫 IP addresses aren’t allowed. Enter a domain name instead."; return 0 ;; esac
  if ! printf '%s\n' "$_dp" | awk "$AWK_VALID"; then
    printf "🚫 That doesn’t look like a valid domain. Example: ads.example.com"
  fi
  return 0
}

rules_json() {
  _rj_a='[]'
  _rj_b='[]'
  [ -s "$ALLOWF" ] && _rj_a=$(awk "$AWK_JARR" "$ALLOWF")
  [ -s "$BLOCKF" ] && _rj_b=$(awk "$AWK_JARR" "$BLOCKF")
  R_RULES="{\"allow\":$_rj_a,\"block\":$_rj_b}"
}

rules_engine() {
  RE_ADDED_A=0; RE_ADDED_B=0; RE_INVALID=0; RE_DUP=0; RE_CONFLICT=0; RE_LIMIT=0; RE_LASTREJ=; RE_LASTREF=
  rm -f "$TMPD/rules.a.new" "$TMPD/rules.b.new"
  _re=$(awk -v mode="$1" -v allowf="$ALLOWF" -v blockf="$BLOCKF" -v outa="$TMPD/rules.a.new" -v outb="$TMPD/rules.b.new" -v max="$RULE_MAX" "$AWK_RULES" "$2" 2>/dev/null) || return 1
  [ -f "$TMPD/rules.a.new" ] && [ -f "$TMPD/rules.b.new" ] || return 1
  while IFS= read -r _re_l; do
    _re_v=${_re_l#*=}
    case ${_re_l%%=*} in
      ADDED_A) RE_ADDED_A=$_re_v ;;
      ADDED_B) RE_ADDED_B=$_re_v ;;
      INVALID) RE_INVALID=$_re_v ;;
      DUP) RE_DUP=$_re_v ;;
      CONFLICT) RE_CONFLICT=$_re_v ;;
      LIMIT) RE_LIMIT=$_re_v ;;
      LASTREJ) RE_LASTREJ=$_re_v ;;
      LASTREF) RE_LASTREF=$_re_v ;;
    esac
  done << EOF
$_re
EOF
  return 0
}

rules_commit() {
  cp -f "$ALLOWF" "$ALLOWF.undo" 2>/dev/null
  cp -f "$BLOCKF" "$BLOCKF.undo" 2>/dev/null
  if ! mv -f "$TMPD/rules.a.new" "$ALLOWF" || ! mv -f "$TMPD/rules.b.new" "$BLOCKF"; then
    rules_rollback
    return 1
  fi
  return 0
}

rules_rollback() {
  [ -f "$ALLOWF.undo" ] && mv -f "$ALLOWF.undo" "$ALLOWF"
  [ -f "$BLOCKF.undo" ] && mv -f "$BLOCKF.undo" "$BLOCKF"
  rm -f "$TMPD/rules.a.new" "$TMPD/rules.b.new"
  return 0
}

rules_done() { rm -f "$ALLOWF.undo" "$BLOCKF.undo" "$TMPD/rules.a.new" "$TMPD/rules.b.new" "$TMPD/rules.in"; return 0; }

sched_alive() {
  _sa=
  [ -f "$SCHEDPID" ] && read -r _sa < "$SCHEDPID"
  is_num "$_sa" && [ -d "/proc/$_sa" ] && grep -q '_sched' "/proc/$_sa/cmdline" 2>/dev/null
}

sched_stop() {
  _ss=
  [ -f "$SCHEDPID" ] && read -r _ss < "$SCHEDPID"
  if is_num "$_ss" && [ -d "/proc/$_ss" ] && grep -q '_sched' "/proc/$_ss/cmdline" 2>/dev/null; then
    kill "$_ss" 2>/dev/null
  fi
  rm -f "$SCHEDPID" "$SCHEDRETRY"
  return 0
}

sched_sync() {
  if [ "$C_AUTO" -gt 0 ]; then
    sched_alive && return 0
    spawn "$RUND/sched.out" _sched
    return
  fi
  sched_stop
}

words_json() {
  R_WORDS='['
  for _wj in $1; do
    R_WORDS="$R_WORDS\"$_wj\","
  done
  R_WORDS="${R_WORDS%,}]"
}

cmd_status() {
  op_json
  cfg_load
  _st_name=$L_NAME; _st_level=$L_LEVEL; _st_ltxt=$L_LEVELTXT
  detect_manager
  applied_state
  conflicts_scan
  mount_mode
  words_json "$R_CONF"; _st_cfj=$R_WORDS
  jbool "$C_ENABLED"; _st_en=$JB
  _st_rb=false; [ "$R_APPLIED" = pending ] && _st_rb=true
  _st_hd=false; [ "$MGR_HTTPD" = yes ] && _st_hd=true
  _st_aa=false; [ -d /data/data/org.adaway ] && _st_aa=true
  jbool "$C_LIVE"; _st_lv=$JB
  _st_sc=false; sched_alive && _st_sc=true
  count_lines "$ALLOWF"; _st_al=$R_LINES
  count_lines "$BLOCKF"; _st_bl=$R_LINES
  stats_read
  _st_ad=
  for _st_i in $C_ADDONS; do
    list_info "$_st_i" || continue
    addon_added "$_st_i"
    jnum "$R_ADDED"
    js "$L_NAME"
    _st_ad="$_st_ad{\"id\":\"$_st_i\",\"name\":$JS,\"icon\":\"$L_ICON\",\"added\":$JN},"
  done
  _st_ad="[${_st_ad%,}]"
  S_SRCDATE=
  src_load "$C_LIST"
  js "$_st_name"; _st_1=$JS
  js "$_st_ltxt"; _st_2=$JS
  js "$MGR_NAME"; _st_3=$JS
  js "$MGR_VER"; _st_4=$JS
  js "$S_SRCDATE"; _st_5=$JS
  _st_hs=0
  [ -f "$HOSTS" ] && _st_hs=$(fsize "$HOSTS")
  reply true status '' "{\"version\":\"$SB_VER\",\"versionCode\":$SB_VCODE,\"manager\":$_st_3,\"managerVersion\":$_st_4,\"enabled\":$_st_en,\"list\":\"$C_LIST\",\"listName\":$_st_1,\"level\":\"$_st_level\",\"levelText\":$_st_2,\"domains\":$C_DOMAINS,\"listCount\":$C_COUNT,\"allow\":$_st_al,\"block\":$_st_bl,\"updated\":$C_UPDATED,\"checked\":$C_CHECKED,\"sourceDate\":$_st_5,\"reboot\":$_st_rb,\"applied\":\"$R_APPLIED\",\"mount\":\"$R_MOUNT\",\"setup\":\"$C_SETUP\",\"conflicts\":$_st_cfj,\"adaway\":$_st_aa,\"httpd\":$_st_hd,\"addons\":$_st_ad,\"live\":$_st_lv,\"autoupdate\":$C_AUTO,\"sched\":$_st_sc,\"guard\":\"$C_GUARD\",\"hostsSize\":$_st_hs,\"staleDays\":$STALE_DAYS,\"now\":$(now),\"stats\":{\"base\":${ST_BASE:-0},\"allowed\":${ST_ALLOWED:-0},\"blocked\":${ST_BLOCKED:-0},\"guarded\":${ST_GUARDED:-0}},\"op\":$R_OP}"
}

cmd_progress() { op_json; reply true progress '' "$R_OP"; }

cmd_wait() {
  _wt=${1:-600}
  is_num "$_wt" || _wt=600
  [ "$_wt" -gt 3600 ] && _wt=3600
  _wt_e=$(($(now) + _wt))
  while :; do
    op_json
    case $R_OP in *'"running":true'*) ;; *) break ;; esac
    [ "$(now)" -ge "$_wt_e" ] && break
    nap 0.5
  done
  case $R_OP in
    *'"running":true'*) reply false timeout '⏳ The task is still running.' "$R_OP" ;;
    *'"state":"error"'* | *'"state":"interrupted"'*) reply false failed '' "$R_OP" ;;
    *) reply true finished '' "$R_OP" ;;
  esac
}

cmd_lists() {
  _cl_now=$(now)
  _cl_stale=
  meta_ids
  _cl_ids=$R_META
  for _cl_id in $_cl_ids; do
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
    meta_start $_cl_stale && _cl_ref=true
  fi
  cfg_load
  device_addon
  stats_read
  _cl_items=
  for _cl_id in $BASE_IDS; do
    _cl_busy=false
    [ "$_cl_ref" = true ] && [ -f "$METAD/$_cl_id.busy" ] && _cl_busy=true
    list_item_json "$_cl_id" "$_cl_busy"
    _cl_items="$_cl_items$R_ITEM,"
  done
  _cl_add=
  for _cl_id in $ADDON_IDS $R_CUSTOM; do
    _cl_busy=false
    [ "$_cl_ref" = true ] && [ -f "$METAD/$_cl_id.busy" ] && _cl_busy=true
    addon_item_json "$_cl_id" "$_cl_busy"
    _cl_add="$_cl_add$R_ITEM,"
  done
  jbool "$C_ENABLED"
  reply true lists '' "{\"lists\":[${_cl_items%,}],\"addons\":[${_cl_add%,}],\"refreshing\":$_cl_ref,\"active\":\"$C_LIST\",\"enabled\":$JB,\"setup\":\"$C_SETUP\",\"customMax\":$CUSTOM_MAX}"
}

cmd_meta_refresh() {
  if [ -n "$1" ]; then
    if ! list_info "$1"; then reply false invalid_list '❌ Unknown list.'; return 0; fi
    _mr=$1
  else
    meta_ids
    _mr=$R_META
  fi
  if lock_alive "$METALOCK"; then
    reply true refreshing '🔄 Already refreshing list details…' '{"refreshing":true}'
    return 0
  fi
  if meta_start $_mr; then
    reply true refreshing '🔄 Refreshing list details…' '{"refreshing":true}'
  else
    reply false refresh_failed "❌ Couldn’t start refreshing list details. Please try again." '{"refreshing":false}'
  fi
}

start_job() {
  op_begin "$1" "$2"
  if spawn "$RUND/worker.out" _worker "$1" "$2" "$3"; then
    return 0
  fi
  op_finish error spawn_failed "❌ Couldn’t start the background task. Please try again."
  lock_drop "$LOCKD"
  log ERROR "Could not start a background task"
  return 1
}

job_reply() {
  op_json
  reply true started "$1" "{\"op\":$R_OP}"
}

spawn_failed_reply() { reply false spawn_failed "❌ Couldn’t start the background task. Please try again."; }

cmd_apply() {
  if ! list_info "$1" || [ "$L_KIND" != base ]; then reply false invalid_list '❌ Unknown list.'; return 0; fi
  _ap_id=$1
  cfg_load
  if [ "$C_ENABLED" != 1 ]; then reply false blocker_disabled '⏻ Enable the blocker first.'; return 0; fi
  if [ "$C_LIST" = "$_ap_id" ] && [ "$C_SETUP" = ready ] && src_ready "$_ap_id"; then
    reply false already_active '⚠️ This list is already active. Use Update Lists instead.'
    return 0
  fi
  lock_take "$LOCKD" || { busy_reply; return 0; }
  list_info "$_ap_id"
  log INFO "Switching to $L_NAME"
  if start_job apply "$_ap_id" "$C_ADDONS"; then
    job_reply "⬇️ Downloading $L_NAME…"
  else
    spawn_failed_reply
  fi
}

cmd_update() {
  cfg_load
  if [ "$C_ENABLED" != 1 ]; then reply false blocker_disabled '⏻ Enable the blocker first.'; return 0; fi
  lock_take "$LOCKD" || { busy_reply; return 0; }
  _up_kind=update
  [ "$C_SETUP" = ready ] && src_ready "$C_LIST" || _up_kind=setup
  _up_name=$L_NAME
  if start_job "$_up_kind" "$C_LIST" "$C_ADDONS"; then
    job_reply "🔄 Checking $_up_name for updates…"
  else
    spawn_failed_reply
  fi
}

cmd_addons() {
  case $1 in
    *[!a-z0-9,\ -]*) reply false invalid_list '❌ Unknown add-on.'; return 0 ;;
  esac
  _ad_new=
  for _ad in $(printf '%s' "$1" | tr ',' ' '); do
    if ! list_info "$_ad" || [ "$L_KIND" != addon ]; then
      reply false invalid_list '❌ Unknown add-on.'
      return 0
    fi
    word_in "$_ad" "$_ad_new" || _ad_new="$_ad_new $_ad"
  done
  _ad_new=${_ad_new# }
  cfg_load
  if [ "$C_ENABLED" != 1 ]; then reply false blocker_disabled '⏻ Enable the blocker first.'; return 0; fi
  if [ "$C_SETUP" != ready ] || ! src_ready "$C_LIST"; then
    reply false setup_pending '⏳ Download your main list first, then add add-ons.'
    return 0
  fi
  _ad_same=1
  for _ad in $_ad_new; do word_in "$_ad" "$C_ADDONS" || _ad_same=0; done
  for _ad in $C_ADDONS; do word_in "$_ad" "$_ad_new" || _ad_same=0; done
  if [ "$_ad_same" = 1 ] && sources_ready; then
    reply false unchanged '✅ These add-ons are already active.'
    return 0
  fi
  lock_take "$LOCKD" || { busy_reply; return 0; }
  set -- $_ad_new
  log INFO "Changing add-ons to: ${_ad_new:-none}"
  if start_job addons "$C_LIST" "$_ad_new"; then
    job_reply "🧩 Applying $# $(plural "$#" add-on add-ons)…"
  else
    spawn_failed_reply
  fi
}

custom_id_for() {
  if has md5sum; then
    R_CID=$(printf '%s' "$1" | md5sum 2>/dev/null | cut -c1-8)
  else
    R_CID=$(printf '%s' "$1" | cksum 2>/dev/null | awk '{ printf "%08x", $1 }')
  fi
  case $R_CID in [0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]) R_CID=c-$R_CID; return 0 ;; esac
  R_CID=
  return 1
}

cmd_source_add() {
  _sa_u=$1
  _sa_raw=${2:-}
  case $_sa_u in
    https://*) ;;
    *) reply false source_invalid '🚫 Enter a full HTTPS address, like https://example.com/hosts.txt'; return 0 ;;
  esac
  case $_sa_u in
    *[!A-Za-z0-9._~:/?\&=%+,@-]*) reply false source_invalid '🚫 That address contains characters that aren’t allowed.'; return 0 ;;
  esac
  if [ "${#_sa_u}" -gt 300 ]; then reply false source_invalid '🚫 That address is too long.'; return 0; fi
  _sa_h=${_sa_u#https://}
  _sa_h=${_sa_h%%/*}
  _sa_h=${_sa_h%%\?*}
  case $_sa_h in *@*) reply false source_invalid '🚫 Addresses with a user name aren’t allowed.'; return 0 ;; esac
  case $_sa_h in *:*) _sa_p=${_sa_h##*:}; _sa_h=${_sa_h%:*}; is_num "$_sa_p" || _sa_h= ;; esac
  _sa_h=$(printf '%s' "$_sa_h" | tr '[:upper:]' '[:lower:]')
  if [ -z "$_sa_h" ] || ! printf '%s\n' "$_sa_h" | awk "$AWK_VALID"; then
    reply false source_invalid '🚫 The address needs a real domain name. IP addresses and local hosts aren’t allowed.'
    return 0
  fi
  for _sa_i in $BASE_IDS $ADDON_IDS; do
    list_info "$_sa_i"
    if [ "$L_URL" = "$_sa_u" ]; then
      reply false source_exists "⚠️ That address is already built in as $L_NAME."
      return 0
    fi
  done
  custom_ids
  set -- $R_CUSTOM
  if [ -f "$SRCF" ] && grep -qF "|$_sa_u|" "$SRCF" 2>/dev/null; then
    reply false source_exists '⚠️ That list is already in your custom lists.'
    return 0
  fi
  if [ "$#" -ge "$CUSTOM_MAX" ]; then
    reply false source_limit "📦 You can add up to $CUSTOM_MAX custom lists. Remove one first."
    return 0
  fi
  if ! custom_id_for "$_sa_u" || custom_info "$R_CID"; then
    reply false source_invalid '❌ Couldn’t register that address. Please try a different one.'
    return 0
  fi
  _sa_n=$(printf '%s' "$_sa_raw" | tr -cd 'A-Za-z0-9 ._()+-' | cut -c1-40)
  _sa_n=${_sa_n#"${_sa_n%%[! ]*}"}
  _sa_n=${_sa_n%"${_sa_n##*[! ]}"}
  [ -n "$_sa_n" ] || _sa_n=$_sa_h
  lock_take "$LOCKD" || { busy_reply; return 0; }
  if ! printf '%s|%s|%s\n' "$R_CID" "$_sa_u" "$_sa_n" >> "$SRCF"; then
    lock_drop "$LOCKD"
    reply false write_failed "❌ Couldn’t save the custom list. Please try again."
    return 0
  fi
  log INFO "Custom list added: $_sa_n ($_sa_h)"
  cfg_load
  if [ "$C_ENABLED" = 1 ] && [ "$C_SETUP" = ready ] && src_ready "$C_LIST"; then
    if start_job addons "$C_LIST" "$C_ADDONS $R_CID"; then
      op_json
      reply true started "⬇️ Downloading $_sa_n…" "{\"id\":\"$R_CID\",\"op\":$R_OP}"
    else
      spawn_failed_reply
    fi
    return 0
  fi
  lock_drop "$LOCKD"
  reply true source_added "🔗 $_sa_n was added. Turn it on in Add-ons once the blocker is ready." "{\"id\":\"$R_CID\"}"
}

cmd_source_del() {
  case $1 in
    c-[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]) ;;
    *) reply false invalid_list '❌ Unknown custom list.'; return 0 ;;
  esac
  if ! custom_info "$1"; then reply false invalid_list '❌ Unknown custom list.'; return 0; fi
  _sd_n=$L_NAME
  lock_wait "$LOCKD" || { busy_reply; return 0; }
  cfg_load
  _sd_note=
  if word_in "$1" "$C_ADDONS"; then
    _sd_keep=
    for _sd_i in $C_ADDONS; do [ "$_sd_i" = "$1" ] || _sd_keep="$_sd_keep $_sd_i"; done
    _sd_old=$C_ADDONS
    C_ADDONS=${_sd_keep# }
    cfg_save
    if ! rebuild; then
      cfg_load
      C_ADDONS=$_sd_old
      cfg_save
      lock_drop "$LOCKD"
      reply false "$RB_STATE" "❌ Couldn’t rebuild the hosts file, so the custom list was kept."
      return 0
    fi
    change_note
    _sd_note=$R_NOTE
  fi
  grep -v "^$1|" "$SRCF" > "$SRCF.tmp.$$" 2>/dev/null
  mv -f "$SRCF.tmp.$$" "$SRCF" 2>/dev/null
  rm -f "$LISTSD/$1.domains" "$LISTSD/$1.info" "$METAD/$1" "$METAD/$1.busy"
  lock_drop "$LOCKD"
  log INFO "Custom list removed: $_sd_n"
  reply true source_removed "🗑️ Removed $_sd_n.$_sd_note"
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
      kill_tree "$_cc"
      log INFO "Cancel requested"
      reply true cancelling '✖️ Cancelling…'
      ;;
    *)
      reply false too_late "⏳ Almost done — the new hosts file is being installed and can’t be cancelled now."
      ;;
  esac
}

cmd_rules() { rules_json; reply true rules '' "$R_RULES"; }

rule_names() {
  case $1 in
    allow) RF=$ALLOWF; RF_KEY=a; RF_NAME=Allow; RF_OTHERNAME=Block ;;
    block) RF=$BLOCKF; RF_KEY=b; RF_NAME=Block; RF_OTHERNAME=Allow ;;
    *) return 1 ;;
  esac
  return 0
}

cmd_rule_add() {
  if ! rule_names "$1"; then reply false invalid_type '❌ Unknown rule type.'; return 0; fi
  _ra=$(extract_domain "$2")
  _ra_p=$(domain_problem "$_ra" "$1")
  if [ -n "$_ra_p" ]; then reply false rule_invalid "$_ra_p"; return 0; fi
  lock_wait "$LOCKD" || { busy_reply; return 0; }
  printf '%s\t%s\n' "$RF_KEY" "$_ra" > "$TMPD/rules.in"
  if ! rules_engine merge "$TMPD/rules.in"; then
    rules_done
    lock_drop "$LOCKD"
    reply false write_failed "❌ Couldn’t save the rule. Please try again."
    return 0
  fi
  if [ "$((RE_ADDED_A + RE_ADDED_B))" != 1 ]; then
    rules_done
    lock_drop "$LOCKD"
    case $RE_LASTREJ in
      exists) reply false rule_exists "⚠️ $_ra is already in your $RF_NAME list." ;;
      covered) reply false rule_exists "⚠️ $_ra is already allowed by your rule $RE_LASTREF." ;;
      conflict) reply false rule_conflict "⚠️ Already in $RF_OTHERNAME list. Remove $_ra there first." ;;
      covers) reply false rule_conflict "⚠️ $_ra would also allow $RE_LASTREF, which is in your Block list. Remove it there first." ;;
      blocked_by_wildcard) reply false rule_conflict "⚠️ $_ra is covered by your allow rule $RE_LASTREF. Remove that rule first." ;;
      limit) reply false rule_limit "📦 You’ve reached the limit of $(fmt_num "$RULE_MAX") rules for this list. Remove some first." ;;
      *) reply false rule_invalid "🚫 That doesn’t look like a valid domain. Example: ads.example.com" ;;
    esac
    return 0
  fi
  if ! rules_commit; then
    rules_done
    lock_drop "$LOCKD"
    reply false write_failed "❌ Couldn’t save the rule. Please try again."
    return 0
  fi
  if ! rebuild; then
    rules_rollback
    lock_drop "$LOCKD"
    log ERROR "Rebuilding the hosts file failed after adding $_ra; the rule was rolled back"
    reply false "$RB_STATE" "❌ Couldn’t rebuild the hosts file, so the rule was not added. Your previous hosts file is in place."
    return 0
  fi
  rules_done
  lock_drop "$LOCKD"
  if [ "$1" = allow ]; then _ra_e='✅'; _ra_v=allowed; else _ra_e='⛔'; _ra_v=blocked; fi
  case $RB_STATE in
    disabled) _ra_m="$_ra_e $_ra saved to your $RF_NAME list. It applies when you enable the blocker." ;;
    nocache) _ra_m="$_ra_e $_ra saved to your $RF_NAME list. It applies once your list is downloaded." ;;
    *)
      change_note
      if [ "$RB_CHANGED" = 1 ]; then
        _ra_m="$_ra_e $_ra $_ra_v.$R_NOTE"
      elif [ "$1" = allow ]; then
        _ra_m="$_ra_e $_ra allowed. It isn’t on your current lists, so nothing changes right now."
      else
        _ra_m="$_ra_e $_ra blocked. Your current lists already block it."
      fi
      ;;
  esac
  log INFO "$RF_NAME rule added: $_ra"
  rules_json
  jbool "$RB_CHANGED"; _ra_c=$JB
  jbool "$RB_LIVE"
  reply true rule_added "$_ra_m" "{\"rules\":$R_RULES,\"changed\":$_ra_c,\"live\":$JB}"
}

cmd_rule_del() {
  if ! rule_names "$1"; then reply false invalid_type '❌ Unknown rule type.'; return 0; fi
  _rd=$(extract_domain "$2")
  case $_rd in
    '' | *[!a-z0-9._*-]*) _rd= ;;
  esac
  if [ -z "$_rd" ] || ! grep -qxF -e "$_rd" "$RF" 2>/dev/null; then
    reply false rule_missing "⚠️ That domain isn’t in your $RF_NAME list."
    return 0
  fi
  lock_wait "$LOCKD" || { busy_reply; return 0; }
  cp -f "$ALLOWF" "$ALLOWF.undo" 2>/dev/null
  cp -f "$BLOCKF" "$BLOCKF.undo" 2>/dev/null
  grep -vxF -e "$_rd" "$RF" > "$RF.tmp" 2>/dev/null
  if [ $? -gt 1 ] || ! mv -f "$RF.tmp" "$RF"; then
    rm -f "$RF.tmp"
    rules_done
    lock_drop "$LOCKD"
    reply false write_failed "❌ Couldn’t remove the rule. Please try again."
    return 0
  fi
  if ! rebuild; then
    rules_rollback
    lock_drop "$LOCKD"
    log ERROR "Rebuilding the hosts file failed after removing $_rd; the rule was restored"
    reply false "$RB_STATE" "❌ Couldn’t rebuild the hosts file, so the rule was kept. Your previous hosts file is in place."
    return 0
  fi
  rules_done
  lock_drop "$LOCKD"
  log INFO "$RF_NAME rule removed: $_rd"
  change_note
  rules_json
  jbool "$RB_CHANGED"; _rd_c=$JB
  jbool "$RB_LIVE"
  reply true rule_removed "🗑️ Removed $_rd from your $RF_NAME list.$R_NOTE" "{\"rules\":$R_RULES,\"changed\":$_rd_c,\"live\":$JB}"
}

cmd_rules_import() {
  _ri_mode=merge
  [ "${3:-}" = replace ] && _ri_mode=replace
  if [ -z "$1$2" ] && [ "$_ri_mode" != replace ]; then
    reply false import_empty '✏️ There is nothing to import.'
    return 0
  fi
  lock_wait "$LOCKD" || { busy_reply; return 0; }
  {
    printf '%s' "$1" | tr ', ' '\n\n' | awk 'NF { print "a\t" $1 }'
    printf '%s' "$2" | tr ', ' '\n\n' | awk 'NF { print "b\t" $1 }'
  } > "$TMPD/rules.in" 2>/dev/null
  if ! rules_engine "$_ri_mode" "$TMPD/rules.in"; then
    rules_done
    lock_drop "$LOCKD"
    reply false write_failed "❌ Couldn’t import the rules. Nothing was changed."
    return 0
  fi
  _ri_add=$((RE_ADDED_A + RE_ADDED_B))
  _ri_skip=$((RE_INVALID + RE_DUP + RE_CONFLICT + RE_LIMIT))
  _ri_d="\"added\":$_ri_add,\"addedAllow\":$RE_ADDED_A,\"addedBlock\":$RE_ADDED_B,\"invalid\":$RE_INVALID,\"duplicate\":$RE_DUP,\"conflict\":$RE_CONFLICT,\"limit\":$RE_LIMIT"
  if [ "$_ri_add" = 0 ] && [ "$_ri_mode" != replace ]; then
    rules_done
    lock_drop "$LOCKD"
    rules_json
    reply false import_nothing "ℹ️ Nothing new to import — $_ri_skip $(plural "$_ri_skip" entry entries) skipped." "{$_ri_d,\"rules\":$R_RULES}"
    return 0
  fi
  if ! rules_commit; then
    rules_done
    lock_drop "$LOCKD"
    reply false write_failed "❌ Couldn’t import the rules. Nothing was changed."
    return 0
  fi
  if ! rebuild; then
    rules_rollback
    lock_drop "$LOCKD"
    log ERROR "Rebuilding the hosts file failed after importing rules; the import was rolled back"
    reply false "$RB_STATE" "❌ Couldn’t rebuild the hosts file, so nothing was imported. Your previous hosts file is in place."
    return 0
  fi
  rules_done
  lock_drop "$LOCKD"
  change_note
  if [ "$_ri_mode" = replace ]; then
    _ri_m="📥 Rules replaced — $_ri_add $(plural "$_ri_add" rule rules) imported."
  else
    _ri_m="📥 Imported $_ri_add $(plural "$_ri_add" rule rules)."
  fi
  [ "$_ri_skip" -gt 0 ] && _ri_m="$_ri_m $_ri_skip skipped."
  log INFO "Rules imported ($_ri_mode): $RE_ADDED_A allow, $RE_ADDED_B block, $_ri_skip skipped"
  rules_json
  jbool "$RB_CHANGED"; _ri_c=$JB
  jbool "$RB_LIVE"
  reply true rules_imported "$_ri_m$R_NOTE" "{$_ri_d,\"rules\":$R_RULES,\"changed\":$_ri_c,\"live\":$JB}"
}

cmd_lookup() {
  _lk=$(extract_domain "$1")
  case $_lk in '*.'*) _lk=${_lk#'*.'} ;; esac
  if [ -z "$_lk" ]; then reply false lookup_invalid '✏️ Enter a domain or a keyword first.'; return 0; fi
  cfg_load
  applied_state
  jbool "$C_ENABLED"; _lk_en=$JB
  _lk_p=$(domain_problem "$_lk" block)
  if [ -n "$_lk_p" ]; then
    case $_lk in
      *[!a-z0-9-]* | ?? | ?) reply false lookup_invalid "$_lk_p"; return 0 ;;
    esac
    _lk_n=0
    _lk_m='[]'
    if [ "$C_ENABLED" = 1 ] && [ -f "$HOSTS" ]; then
      _lk_o=$(grep -F -e "$_lk" "$HOSTS" 2>/dev/null | awk '$1 == "0.0.0.0" { n++; if (n <= 40) print $2 } END { print n + 0 }')
      _lk_n=${_lk_o##*"$NL"}
      is_num "$_lk_n" || _lk_n=0
      [ "$_lk_n" -gt 0 ] && _lk_m=$(printf '%s\n' "$_lk_o" | awk -v n="$_lk_n" 'NR <= 40 && NR <= n' | awk "$AWK_JARR")
    fi
    if [ "$_lk_n" = 0 ]; then
      _lk_msg="🔍 No blocked domain contains “$_lk”."
    else
      _lk_msg="🔍 $(fmt_num "$_lk_n") blocked $(plural "$_lk_n" domain domains) contain “$_lk”."
    fi
    reply true lookup "$_lk_msg" "{\"type\":\"keyword\",\"query\":\"$_lk\",\"matchCount\":$_lk_n,\"matches\":$_lk_m,\"enabled\":$_lk_en,\"applied\":\"$R_APPLIED\"}"
    return 0
  fi
  _lk_rule=
  _lk_ref=
  if grep -qxF -e "$_lk" "$ALLOWF" 2>/dev/null; then
    _lk_rule=allow
    _lk_ref=$_lk
  else
    _lk_s=$_lk
    while :; do
      if grep -qxF -e "*.$_lk_s" "$ALLOWF" 2>/dev/null; then
        _lk_rule=allow
        _lk_ref="*.$_lk_s"
        break
      fi
      case $_lk_s in *.*) _lk_s=${_lk_s#*.} ;; *) break ;; esac
    done
  fi
  if [ -z "$_lk_rule" ] && grep -qxF -e "$_lk" "$BLOCKF" 2>/dev/null; then
    _lk_rule=block
    _lk_ref=$_lk
  fi
  _lk_src=
  _lk_names=
  for _lk_i in $C_LIST $C_ADDONS; do
    [ -s "$LISTSD/$_lk_i.domains" ] || continue
    grep -qxF -e "$_lk" "$LISTSD/$_lk_i.domains" 2>/dev/null || continue
    list_info "$_lk_i"
    js "$L_NAME"
    _lk_src="$_lk_src$JS,"
    _lk_names="$_lk_names${_lk_names:+, }$L_NAME"
  done
  _lk_src="[${_lk_src%,}]"
  _lk_in=false
  [ "$C_ENABLED" = 1 ] && grep -qxF -e "0.0.0.0 $_lk" "$HOSTS" 2>/dev/null && _lk_in=true
  _lk_n=0
  _lk_m='[]'
  if [ "$C_ENABLED" = 1 ] && [ -f "$HOSTS" ]; then
    _lk_o=$(grep -F -e ".$_lk" "$HOSTS" 2>/dev/null | awk -v s=".$_lk" '$1 == "0.0.0.0" && length($2) > length(s) && substr($2, length($2) - length(s) + 1) == s { n++; if (n <= 8) print $2 } END { print n + 0 }')
    _lk_n=${_lk_o##*"$NL"}
    is_num "$_lk_n" || _lk_n=0
    [ "$_lk_n" -gt 0 ] && _lk_m=$(printf '%s\n' "$_lk_o" | awk -v n="$_lk_n" 'NR <= 8 && NR <= n' | awk "$AWK_JARR")
  fi
  if [ "$C_ENABLED" != 1 ]; then
    _lk_st=disabled
    _lk_msg="🔴 The blocker is off, so $_lk isn’t blocked right now."
  elif [ "$_lk_in" = true ]; then
    _lk_st=blocked
    if [ "$_lk_rule" = block ]; then
      _lk_msg="⛔ $_lk is blocked by your Block rule."
    else
      _lk_msg="⛔ $_lk is blocked by ${_lk_names:-your lists}."
    fi
  elif [ "$_lk_rule" = allow ]; then
    _lk_st=allowed
    if [ -n "$_lk_names" ]; then
      _lk_msg="✅ $_lk is allowed by your rule $_lk_ref. Without it, $_lk_names would block it."
    else
      _lk_msg="✅ $_lk is allowed by your rule $_lk_ref."
    fi
  else
    _lk_st=clear
    _lk_msg="✅ $_lk isn’t blocked."
  fi
  reply true lookup "$_lk_msg" "{\"type\":\"domain\",\"query\":\"$_lk\",\"domain\":\"$_lk\",\"status\":\"$_lk_st\",\"rule\":\"$_lk_rule\",\"ref\":\"$_lk_ref\",\"sources\":$_lk_src,\"subCount\":$_lk_n,\"subs\":$_lk_m,\"enabled\":$_lk_en,\"applied\":\"$R_APPLIED\"}"
}

cmd_disable() {
  cfg_load
  if [ "$C_ENABLED" != 1 ]; then reply false already_disabled '🔴 The blocker is already disabled.'; return 0; fi
  lock_wait "$LOCKD" || { busy_reply; return 0; }
  if ! compile_into "$HOSTSD/.hosts.sbnew" 0; then
    rm -f "$HOSTSD/.hosts.sbnew"
    lock_drop "$LOCKD"
    reply false write_failed "❌ Couldn’t write the hosts file. Nothing was changed."
    return 0
  fi
  if ! install_hosts "$HOSTSD/.hosts.sbnew" 0; then
    lock_drop "$LOCKD"
    reply false write_failed "❌ Couldn’t write the hosts file. Your previous hosts file was restored."
    return 0
  fi
  C_ENABLED=0
  cfg_save
  _ds_live=0
  if [ "$IH_CHANGED" = 1 ]; then
    settle_change && _ds_live=1
  else
    apply_now && _ds_live=1
  fi
  set_description
  lock_drop "$LOCKD"
  log INFO "Blocker disabled; lists and rules are kept"
  if [ "$_ds_live" = 1 ]; then
    reply true disabled '🔴 Blocker disabled. Blocking is off now — your lists and rules are kept.' '{"live":true}'
  else
    reply true disabled '🔴 Blocker disabled. Reboot to stop blocking. Your lists and rules are kept.' '{"live":false}'
  fi
}

cmd_enable() {
  cfg_load
  if [ "$C_ENABLED" = 1 ]; then reply false already_enabled '🟢 The blocker is already enabled.'; return 0; fi
  lock_wait "$LOCKD" || { busy_reply; return 0; }
  _en_name=$L_NAME
  if [ "$C_SETUP" = ready ] && sources_ready; then
    C_ENABLED=1
    if ! compile_into "$HOSTSD/.hosts.sbnew" 1; then
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
    stats_commit
    _en_live=0
    if [ "$IH_CHANGED" = 1 ]; then
      settle_change && _en_live=1
    else
      apply_now && _en_live=1
    fi
    set_description
    lock_drop "$LOCKD"
    log INFO "Blocker enabled with $_en_name ($(fmt_num "$CH_COUNT") domains)"
    if [ "$_en_live" = 1 ]; then
      reply true enabled "🟢 Blocker enabled — $(fmt_num "$CH_COUNT") domains. Active now." '{"live":true}'
    else
      reply true enabled "🟢 Blocker enabled — $(fmt_num "$CH_COUNT") domains. Reboot to apply." '{"live":false}'
    fi
    return 0
  fi
  log INFO "Blocker enable requested; a cached list is missing, downloading it again"
  if start_job enable "$C_LIST" "$C_ADDONS"; then
    job_reply "⬇️ Downloading $_en_name to turn blocking back on…"
  else
    spawn_failed_reply
  fi
}

settings_json() {
  jbool "$C_LIVE"; _sj_l=$JB
  _sj_s=false; sched_alive && _sj_s=true
  R_SETTINGS="{\"live\":$_sj_l,\"autoupdate\":$C_AUTO,\"sched\":$_sj_s}"
}

cmd_settings() { cfg_load; settings_json; reply true settings '' "$R_SETTINGS"; }

cmd_set() {
  case $1 in
    live)
      case $2 in 0 | 1) ;; *) reply false invalid_value '❌ Unknown value.'; return 0 ;; esac
      lock_wait "$LOCKD" || { busy_reply; return 0; }
      cfg_load
      C_LIVE=$2
      cfg_save
      if [ "$2" = 1 ]; then
        _se_m='⚡ Live apply is on. Changes take effect right away whenever your device allows it.'
        if [ "$C_SETUP" = ready ] && ! hosts_live; then
          if apply_now; then
            flush_dns
            _se_m='⚡ Live apply is on — your pending changes are active now.'
          else
            _se_m='⚡ Live apply is on. Your pending changes still need one reboot.'
          fi
        fi
      else
        _se_m='🔁 Live apply is off. Changes take effect after a reboot.'
      fi
      set_description
      lock_drop "$LOCKD"
      log INFO "Live apply turned $([ "$2" = 1 ] && printf on || printf off)"
      settings_json
      reply true setting_saved "$_se_m" "$R_SETTINGS"
      ;;
    autoupdate)
      case $2 in 0 | 1 | 3 | 7) ;; *) reply false invalid_value '❌ Unknown value.'; return 0 ;; esac
      lock_wait "$LOCKD" || { busy_reply; return 0; }
      cfg_load
      C_AUTO=$2
      cfg_save
      lock_drop "$LOCKD"
      sched_sync
      case $2 in
        0) _se_m='🔕 Auto-update is off.' ;;
        1) _se_m='🔄 Auto-update is on. Your lists are checked every day.' ;;
        *) _se_m="🔄 Auto-update is on. Your lists are checked every $2 days." ;;
      esac
      log INFO "Auto-update set to $2 $(plural "$2" day days)"
      settings_json
      reply true setting_saved "$_se_m" "$R_SETTINGS"
      ;;
    *) reply false invalid_setting '❌ Unknown setting.' ;;
  esac
}

diag_add() {
  js "$3"; _dg_t=$JS
  js "$4"
  DG="$DG{\"id\":\"$2\",\"level\":\"$1\",\"title\":$_dg_t,\"detail\":$JS},"
  case $1 in
    ok) DG_OK=$((DG_OK + 1)) ;;
    warn) DG_WARN=$((DG_WARN + 1)) ;;
    err) DG_ERR=$((DG_ERR + 1)) ;;
  esac
}

cmd_diag() {
  DG=; DG_OK=0; DG_WARN=0; DG_ERR=0
  cfg_load
  _dg_name=$L_NAME
  _dg_url=$L_URL
  detect_manager
  applied_state
  conflicts_scan
  mount_mode
  _dg_now=$(now)

  if [ "$C_SETUP" != ready ]; then
    diag_add warn setup '⏳ Setup' "The first list hasn’t been downloaded yet. Tap Download now."
  elif [ "$C_ENABLED" != 1 ]; then
    diag_add warn blocker '🛡️ Blocker' 'The blocker is turned off, so nothing is blocked.'
  else
    diag_add ok blocker '🛡️ Blocker' "On with $_dg_name and $(fmt_num "$C_DOMAINS") blocked domains."
  fi

  if [ ! -f "$HOSTS" ]; then
    diag_add err integrity '🧾 Hosts file' 'The hosts file is missing. Tap Repair to rebuild it.'
  else
    _dg_want=$C_DOMAINS
    [ "$C_ENABLED" = 1 ] && [ "$C_SETUP" = ready ] || _dg_want=0
    if ! verify_hosts_deep "$_dg_want"; then
      diag_add err integrity '🧾 Hosts file' 'The hosts file doesn’t match what StevenBlock built. Tap Repair to rebuild it.'
    else
      sum_check
      case $? in
        1) diag_add err integrity '🧾 Hosts file' 'The checksum doesn’t match. Tap Repair to rebuild it.' ;;
        *) diag_add ok integrity '🧾 Hosts file' "Verified: $(fmt_num "$_dg_want") entries, $(fmt_mb "$(fsize "$HOSTS")"), checksum matches." ;;
      esac
    fi
  fi

  case $R_APPLIED in
    applied)
      case $R_MOUNT in
        self) diag_add ok applied '🧪 Applied to the system' 'Android is using StevenBlock’s hosts file. StevenBlock mounted it directly.' ;;
        *) diag_add ok applied '🧪 Applied to the system' 'Android is using StevenBlock’s hosts file.' ;;
      esac
      ;;
    pending) diag_add warn applied '🧪 Applied to the system' 'Your latest changes become active after a reboot.' ;;
    overridden) diag_add err applied '🧪 Applied to the system' "Another module provides /system/etc/hosts: $R_CONF. Disable it and reboot." ;;
    inactive) diag_add err applied '🧪 Applied to the system' 'Android isn’t using StevenBlock’s hosts file. Reboot, or tap Repair to mount it now.' ;;
    *) diag_add warn applied '🧪 Applied to the system' 'The system hosts file couldn’t be checked.' ;;
  esac

  if [ -n "$R_CONF" ] && [ "$R_APPLIED" != overridden ]; then
    diag_add warn conflicts '🧩 Other hosts modules' "These modules also carry a hosts file: $R_CONF."
  elif [ -z "$R_CONF" ]; then
    if [ -d /data/data/org.adaway ]; then
      diag_add warn conflicts '🧩 Other hosts modules' 'AdAway is installed. Don’t use its root mode together with StevenBlock.'
    else
      diag_add ok conflicts '🧩 Other hosts modules' 'No conflicting hosts module was found.'
    fi
  fi

  if [ "$C_SETUP" = ready ]; then
    _dg_miss=
    for _dg_i in $C_LIST $C_ADDONS; do
      src_ready "$_dg_i" && continue
      list_info "$_dg_i"
      _dg_miss="$_dg_miss${_dg_miss:+, }$L_NAME"
    done
    if [ -n "$_dg_miss" ]; then
      diag_add warn caches '🗂️ Cached lists' "Missing from the cache: $_dg_miss. Tap Update Lists to download again."
    else
      set -- $C_ADDONS
      diag_add ok caches '🗂️ Cached lists' "$_dg_name and $# $(plural "$#" add-on add-ons) are cached for instant rebuilds."
    fi
    _dg_age=$(((_dg_now - C_UPDATED) / 86400))
    if [ "$C_UPDATED" = 0 ]; then
      diag_add warn freshness '🕒 List age' 'The lists have never been updated.'
    elif [ "$_dg_age" -ge "$STALE_DAYS" ]; then
      diag_add warn freshness '🕒 List age' "Last updated $_dg_age days ago. Tap Update Lists, or turn on auto-update."
    else
      diag_add ok freshness '🕒 List age' "Last updated $_dg_age $(plural "$_dg_age" day days) ago."
    fi
  fi

  if [ "$C_AUTO" -gt 0 ]; then
    if sched_alive; then
      diag_add ok scheduler '🔄 Auto-update' "On, every $C_AUTO $(plural "$C_AUTO" day days). The scheduler is running."
    else
      diag_add warn scheduler '🔄 Auto-update' 'On, but the scheduler isn’t running. It starts again at the next boot, or when you save the setting again.'
    fi
  else
    diag_add info scheduler '🔄 Auto-update' 'Off. Lists only update when you tap Update Lists.'
  fi

  if [ "$C_LIVE" = 1 ]; then
    diag_add info live '⚡ Live apply' 'On. Changes are written in place and take effect without a reboot when possible.'
  else
    diag_add info live '⚡ Live apply' 'Off. Changes take effect after a reboot.'
  fi

  if dl_detect; then
    if [ "$DL_TOOL" = curl ]; then
      if [ "$DL_GZ" = 1 ]; then
        diag_add ok downloader '⬇️ Downloader' 'curl with compressed transfers.'
      else
        diag_add ok downloader '⬇️ Downloader' 'curl.'
      fi
    else
      diag_add ok downloader '⬇️ Downloader' 'BusyBox wget.'
    fi
    if dl_get "$_dg_url" "$TMPD/diag.body" "$TMPD/diag.hdr" peek; then
      diag_add ok network '🌐 List server' "Reachable (HTTP $DL_CODE)."
    else
      diag_add warn network '🌐 List server' "Couldn’t reach the server of $_dg_name: $(dl_reason)."
    fi
    rm -f "$TMPD/diag.body" "$TMPD/diag.hdr" "$TMPD/diag.hdr.err"
  else
    diag_add err downloader '⬇️ Downloader' 'Neither curl nor BusyBox wget is available, so lists can’t be downloaded.'
  fi

  if [ "$SB_BB" = none ]; then
    diag_add warn busybox '🧰 BusyBox' 'No root manager BusyBox was found. StevenBlock is using system tools.'
  elif [ "$MGR_HTTPD" = yes ]; then
    diag_add ok busybox '🧰 BusyBox' "$SB_BB with httpd for the browser WebUI."
  else
    diag_add warn busybox '🧰 BusyBox' "$SB_BB has no httpd, so the Action button can’t open the WebUI in a browser."
  fi

  _dg_free=$(free_kb "$DATA")
  if is_num "$_dg_free"; then
    if [ "$_dg_free" -lt 51200 ]; then
      diag_add warn storage '💾 Storage' "Only $((_dg_free / 1024)) MB free. Updates need at least 50 MB."
    else
      diag_add ok storage '💾 Storage' "$((_dg_free / 1024)) MB free."
    fi
  fi

  guard_detect
  if [ -n "$R_GUARD" ]; then
    live_hosts
    if grep -qxF -e "0.0.0.0 $R_GUARD" "$R_LIVE" 2>/dev/null; then
      diag_add err privatedns '🔏 Private DNS' "Your Private DNS provider $R_GUARD is blocked right now. Tap Repair to fix it."
    else
      diag_add ok privatedns '🔏 Private DNS' "Your provider $R_GUARD is protected from being blocked."
    fi
  fi

  count_lines "$ALLOWF"; _dg_a=$R_LINES
  count_lines "$BLOCKF"; _dg_b=$R_LINES
  diag_add info rules '🧩 Domain rules' "$_dg_a allow and $_dg_b block $(plural "$((_dg_a + _dg_b))" rule rules)."

  _dg_v=
  [ -n "$MGR_VER" ] && _dg_v=" $MGR_VER"
  diag_add info environment '📦 Environment' "StevenBlock $SB_VER ($SB_VCODE) on $MGR_NAME$_dg_v, Android $(getprop ro.build.version.release 2>/dev/null)."

  reply true diag '' "{\"checks\":[${DG%,}],\"summary\":{\"ok\":$DG_OK,\"warn\":$DG_WARN,\"err\":$DG_ERR}}"
}

cmd_repair() {
  lock_wait "$LOCKD" || { busy_reply; return 0; }
  cfg_load
  rm -f "$SUMF"
  _rp_ok=1
  if [ "$C_ENABLED" != 1 ]; then
    if compile_into "$HOSTSD/.hosts.sbnew" 0 && install_hosts "$HOSTSD/.hosts.sbnew" 0; then :; else _rp_ok=0; fi
    rm -f "$HOSTSD/.hosts.sbnew"
  elif [ "$C_SETUP" = ready ] && sources_ready; then
    if compile_into "$HOSTSD/.hosts.sbnew" 1 && install_hosts "$HOSTSD/.hosts.sbnew" "$CH_COUNT"; then
      C_DOMAINS=$CH_COUNT
      cfg_save
      stats_commit
    else
      _rp_ok=0
    fi
    rm -f "$HOSTSD/.hosts.sbnew"
  else
    hosts_sane "$HOSTS" || write_clean_hosts || _rp_ok=0
  fi
  if [ "$_rp_ok" = 0 ]; then
    lock_drop "$LOCKD"
    log ERROR "Repair failed: the hosts file could not be rebuilt"
    reply false write_failed "❌ Couldn’t rebuild the hosts file. Check 📜 Logs for details."
    return 0
  fi
  [ -f "$SUMF" ] || sum_record "$C_DOMAINS"
  _rp_live=false
  if apply_now; then
    _rp_live=true
    flush_dns
  else
    mark_pending
  fi
  set_description
  lock_drop "$LOCKD"
  log INFO "Repair finished: the hosts file was rebuilt and checked"
  if [ "$C_SETUP" != ready ]; then
    reply true repaired '🛠️ Repaired. Tap Download now to fetch your list.' "{\"live\":$_rp_live}"
  elif [ "$_rp_live" = true ]; then
    reply true repaired '🛠️ Repaired — the hosts file was rebuilt and is active.' "{\"live\":$_rp_live}"
  else
    reply true repaired '🛠️ Repaired — the hosts file was rebuilt. Reboot to activate it.' "{\"live\":$_rp_live}"
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
  if has setsid; then
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

cmd_help() {
  cat << EOF
🛡️ StevenBlock $SB_VER — command line
Usage: sh $SELF <command> [arguments]
Every command except help prints one line of JSON and exits 0 on success, 1 on failure.

  status                     overall state
  lists                      catalog of lists and add-ons
  apply <list>               switch the main list
  update                     check every active list and download what changed
  addons <id,id,...>         set the active add-ons (empty turns all off)
  source-add <https-url> [name]   add and enable a custom list
  source-del <id>            remove a custom list
  progress                   state of the running task
  wait [seconds]             block until the running task has finished
  cancel                     cancel the running download
  rules                      show allow and block rules
  rule-add <allow|block> <domain>
  rule-del <allow|block> <domain>
  rules-import <allow,csv> <block,csv> [replace]
  lookup <domain|keyword>    explain whether and why a domain is blocked
  enable | disable           turn blocking on or off
  settings                   show settings
  set live <0|1>             apply changes without a reboot
  set autoupdate <0|1|3|7>   check for updates every N days
  diag                       run the health check
  repair                     rebuild the hosts file and re-check the mount
  logs | logs-clear
  reboot
EOF
}

dispatch() {
  case ${1:-} in
    status) cmd_status ;;
    progress) cmd_progress ;;
    wait) cmd_wait "${2:-}" ;;
    lists) cmd_lists ;;
    meta-refresh) cmd_meta_refresh "${2:-}" ;;
    apply) cmd_apply "${2:-}" ;;
    update) cmd_update ;;
    addons) cmd_addons "${2:-}" ;;
    source-add) cmd_source_add "${2:-}" "${3:-}" ;;
    source-del) cmd_source_del "${2:-}" ;;
    cancel) cmd_cancel ;;
    rules) cmd_rules ;;
    rule-add) cmd_rule_add "${2:-}" "${3:-}" ;;
    rule-del) cmd_rule_del "${2:-}" "${3:-}" ;;
    rules-import) cmd_rules_import "${2:-}" "${3:-}" "${4:-}" ;;
    lookup) cmd_lookup "${2:-}" ;;
    disable) cmd_disable ;;
    enable) cmd_enable ;;
    settings) cmd_settings ;;
    set) cmd_set "${2:-}" "${3:-}" ;;
    diag) cmd_diag ;;
    repair) cmd_repair ;;
    logs) cmd_logs ;;
    logs-clear) cmd_logs_clear ;;
    reboot) cmd_reboot ;;
    open) cmd_open "${2:-}" ;;
    ping) reply true pong '' ;;
    help | -h | --help) cmd_help ;;
    *) reply false unknown_command '❓ Unknown command. Run help to see what is available.' ;;
  esac
}

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
  ( umask 077; gen_token > "$RUND/token" )
  chmod 0600 "$RUND/token"
  [ "$(wc -c < "$RUND/token")" -eq 32 ]
}

touch_activity() {
  date +%s > "$RUND/last_request.$$" 2>/dev/null && mv -f "$RUND/last_request.$$" "$RUND/last_request"
  rm -f "$RUND/last_request.$$" 2>/dev/null
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
  wait "$_sv_h" 2>/dev/null
  server_cleanup
}

cgi_headers() {
  printf 'Content-Type: application/json; charset=utf-8\r\nCache-Control: no-store\r\nX-Content-Type-Options: nosniff\r\nX-Frame-Options: DENY\r\nReferrer-Policy: no-referrer\r\n\r\n'
}

cgi_deny() {
  printf 'HTTP/1.0 403 Forbidden\r\n'
  cgi_headers
  reply false unauthorized "$1"
}

cgi_main() {
  case ${REQUEST_METHOD:-GET} in
    GET)
      _cg_q=${QUERY_STRING:-}
      if [ "${#_cg_q}" -gt 4096 ]; then cgi_deny '🚫 Request rejected.'; return 0; fi
      ;;
    POST)
      _cg_n=${CONTENT_LENGTH:-0}
      if ! is_num "$_cg_n" || [ "$_cg_n" -gt 262144 ]; then cgi_deny '🚫 Request rejected.'; return 0; fi
      _cg_q=
      [ "$_cg_n" -gt 0 ] && _cg_q=$(head -c "$_cg_n")
      ;;
    *)
      cgi_deny '🚫 Request rejected.'
      return 0
      ;;
  esac
  _cg_p=$(printf '%s\n' "$_cg_q" | awk "$AWK_QUERY")
  { IFS= read -r Q_T; IFS= read -r Q_C; IFS= read -r Q_A; IFS= read -r Q_B; IFS= read -r Q_D; } << EOF
$_cg_p
EOF
  _cg_t=
  [ -f "$RUND/token" ] && read -r _cg_t < "$RUND/token"
  if [ "${#_cg_t}" -ne 32 ] || [ "$Q_T" != "$_cg_t" ]; then
    cgi_deny '🔑 This session has expired. Press the Action button on StevenBlock in your root manager to open a new one.'
    return 0
  fi
  case ${HTTP_HOST:-} in
    '' | "127.0.0.1:$PORT" | "localhost:$PORT") ;;
    *) cgi_deny '🚫 Request rejected.'; return 0 ;;
  esac
  case ${HTTP_REFERER:-} in
    '' | "http://127.0.0.1:$PORT/"* | "http://localhost:$PORT/"*) ;;
    *) cgi_deny '🚫 Request rejected.'; return 0 ;;
  esac
  touch_activity
  cgi_headers
  dispatch "$Q_C" "$Q_A" "$Q_B" "$Q_D"
}

action_main() {
  MODE=action
  ensure_dirs
  detect_manager
  printf '\n🛡️ StevenBlock %s\n' "$SB_VER"
  printf '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
  describe
  printf '%s\n\n' "${R_DESC#🛡️ }"
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

run_job() {
  if pipeline "$1" "$2" "$3"; then
    OP_DOMAINS=$PL_DOMAINS
    OP_REBOOT=$PL_REBOOT
    OP_LIVE=$PL_LIVE
    OP_WARN=$PL_WARN
    op_finish success "$PL_CODE" "$PL_MSG"
    return 0
  fi
  if [ "$PL_CODE" = cancelled ]; then
    op_finish cancelled "$PL_CODE" "$PL_MSG"
    return 2
  fi
  op_finish error "$PL_CODE" "$PL_MSG"
  return 1
}

worker_exit() {
  pl_cleanup
  op_running && op_interrupt '⚠️ The task was stopped before it finished. Your hosts file is intact.'
  lock_drop_if_mine "$LOCKD"
}

worker_main() {
  MODE=worker
  echo "$$" > "$LOCKD/pid" 2>/dev/null
  op_load
  spawned
  trap 'worker_exit' EXIT
  trap 'exit 143' TERM INT HUP
  run_job "$1" "$2" "$3"
}

wait_boot() {
  _wb=0
  while [ "$(getprop sys.boot_completed 2>/dev/null)" != 1 ] && [ "$_wb" -lt 300 ]; do
    sleep 5
    _wb=$((_wb + 5))
  done
}

setup_main() {
  MODE=worker
  spawned
  wait_boot
  _su_try=1
  while :; do
    cfg_load
    [ "$C_SETUP" = pending ] || return 0
    if lock_take "$LOCKD"; then
      trap 'worker_exit' EXIT
      trap 'exit 143' TERM INT HUP
      op_begin setup "$C_LIST"
      run_job setup "$C_LIST" "$C_ADDONS"
      _su_rc=$?
      lock_drop "$LOCKD"
      trap - EXIT
      [ "$_su_rc" = 1 ] || return 0
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

sched_due() {
  cfg_load
  [ "$C_AUTO" -gt 0 ] || return 1
  [ "$C_ENABLED" = 1 ] && [ "$C_SETUP" = ready ] || return 1
  _sd_now=$(now)
  _sd_last=$C_CHECKED
  [ "$C_UPDATED" -gt "$_sd_last" ] && _sd_last=$C_UPDATED
  [ "$_sd_now" -ge $((_sd_last + C_AUTO * 86400)) ] || return 1
  _sd_r=0
  [ -f "$SCHEDRETRY" ] && read -r _sd_r < "$SCHEDRETRY"
  is_num "$_sd_r" || _sd_r=0
  [ "$_sd_now" -ge "$_sd_r" ]
}

sched_main() {
  MODE=worker
  _sm_tick=$1
  is_num "$_sm_tick" && [ "$_sm_tick" -gt 0 ] || _sm_tick=$SCHED_TICK
  echo "$$" > "$SCHEDPID"
  spawned
  _sm_s=
  trap 'kill $_sm_s 2>/dev/null; lock_drop_if_mine "$LOCKD"; [ "$(cat "$SCHEDPID" 2>/dev/null)" = "$$" ] && rm -f "$SCHEDPID"; exit 0' TERM INT HUP
  log INFO "Auto-update scheduler started"
  wait_boot
  while :; do
    _sm_p=
    [ -f "$SCHEDPID" ] && read -r _sm_p < "$SCHEDPID"
    [ "$_sm_p" = "$$" ] || break
    cfg_load
    [ "$C_AUTO" -gt 0 ] || break
    if sched_due && lock_take "$LOCKD"; then
      log INFO "Auto-update: checking for new list versions"
      op_begin auto "$C_LIST"
      if run_job auto "$C_LIST" "$C_ADDONS"; then
        rm -f "$SCHEDRETRY"
      else
        echo $(($(now) + 3600)) > "$SCHEDRETRY"
        log WARN "Auto-update didn’t finish; trying again in about an hour"
      fi
      pl_cleanup
      lock_drop "$LOCKD"
    fi
    sleep "$_sm_tick" &
    _sm_s=$!
    wait "$_sm_s"
    _sm_s=
  done
  [ "$(cat "$SCHEDPID" 2>/dev/null)" = "$$" ] && rm -f "$SCHEDPID"
  log INFO "Auto-update scheduler stopped"
}

boot_main() {
  MODE=boot
  ensure_dirs
  op_running && op_interrupt '⚠️ A task was interrupted by a reboot. Your hosts file is intact — run it again if needed.'
  rm -rf "$LOCKD" "$METALOCK" "$RUND/www" 2>/dev/null
  rm -f "$RUND"/spawn.* "$RUND/cancel" "$RUND/dl.pid" "$RUND/token" "$RUND/httpd.pid" "$RUND/watchdog.pid" "$RUND/last_request" "$RUND"/last_request.* "$RUND/httpd.conf" "$RUND/manager" "$RUND/device" "$SCHEDPID" "$SCHEDRETRY" "$PENDF" 2>/dev/null
  rm -f "$METAD"/*.busy "$METAD"/*.tmp "$HOSTSD"/.hosts.sb* "$RULESD"/*.undo "$RULESD"/*.tmp 2>/dev/null
  rm -rf "$TMPD" 2>/dev/null
  mkdir -p "$TMPD"
  migrate_data
  cfg_load
  if [ ! -f "$CFG" ]; then
    C_SETUP=pending
    cfg_save
    log WARN "Settings were missing; the default list will be downloaded again"
  elif [ "$C_SETUP" = failed ]; then
    C_SETUP=pending
    cfg_save
  elif [ "$C_SETUP" = ready ] && ! sources_ready; then
    C_SETUP=pending
    cfg_save
    log WARN "A cached list was missing; it will be downloaded again"
  fi
  repair_hosts deep
  ensure_mounted
  set_description
  cfg_load
  if [ "$C_SETUP" = pending ]; then
    log INFO "Boot: waiting for network to download $L_NAME"
    spawn "$RUND/setup.out" _setup || log ERROR "Could not start the first-boot download"
  elif [ "$C_ENABLED" = 1 ]; then
    applied_state
    log INFO "Boot: $L_NAME active with $(fmt_num "$C_DOMAINS") domains ($R_APPLIED)"
  else
    log INFO "Boot: blocker is disabled"
  fi
  if [ "$C_AUTO" -gt 0 ]; then
    spawn "$RUND/sched.out" _sched || log ERROR "Could not start the auto-update scheduler"
  fi
}

mount_main() {
  MODE=boot
  ensure_dirs
  repair_hosts
  ensure_mounted
  return 0
}

uninstall_main() {
  server_stop
  sched_stop
  for _un in "$LOCKD" "$METALOCK"; do
    _un_p=$(lock_pid "$_un")
    pid_alive "$_un_p" && kill_tree "$_un_p"
  done
  rm -rf "$DATA"
}

install_main() {
  MODE=install
  ensure_dirs
  rm -rf "$LOCKD" "$METALOCK" "$STAGED" 2>/dev/null
  rm -f "$RUND"/spawn.* "$RUND/manager" "$METAD"/*.busy 2>/dev/null
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
    if [ "$DL_TOOL" = curl ]; then
      if [ "$DL_GZ" = 1 ]; then printf '✅ Downloader: curl (compressed transfers)\n'; else printf '✅ Downloader: curl\n'; fi
    else
      printf '✅ Downloader: BusyBox wget\n'
    fi
  else
    printf '❌ No downloader found (curl or BusyBox wget)\n'
  fi
  if ! httpd_available; then
    printf '%s\n' "⚠️ BusyBox httpd not found — the Action button can’t open the WebUI in a browser"
  fi
  log INFO "Installing StevenBlock $SB_VER with $MGR_NAME $MGR_VER"

  printf '\n🧩 Looking for other hosts blockers…\n'
  _in_cf=0
  conflicts_scan
  for _in_m in $R_CONF; do
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
  _in_v1=0
  [ -f "$OLDCACHE" ] && _in_v1=1
  migrate_data keep
  rm -f "$BACKUPD/hosts.1" "$BACKUPD/hosts.2" "$BACKUPD/hosts.3" 2>/dev/null
  if [ -n "$_in_old" ]; then
    printf '✅ Removed StevenBlock v5.0 leftovers:%s\n' "$_in_old"
    log INFO "Removed legacy files:$_in_old"
  fi
  if [ "$_in_v1" = 1 ]; then
    printf '✅ Moved your v1.0 data to the v2.0 layout\n'
  fi
  [ -z "$_in_old" ] && [ "$_in_v1" = 0 ] && printf '✅ Nothing to clean up\n'
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
  if [ -f "$CFG" ] && [ "$C_SETUP" = ready ] && sources_ready; then
    _in_name=$L_NAME
    rm -f "$HOSTSD/.hosts.sbnew"
    if compile_into "$HOSTSD/.hosts.sbnew" "$C_ENABLED"; then
      if mv -f "$HOSTSD/.hosts.sbnew" "$HOSTS" && set_hosts_perm "$HOSTS" && verify_hosts "$CH_COUNT"; then
        _in_keep=1
        [ "$C_ENABLED" = 1 ] && C_DOMAINS=$CH_COUNT
        cfg_save
        [ "$C_ENABLED" = 1 ] && stats_commit
        if [ "$C_ENABLED" = 1 ]; then
          printf '♻️ Keeping your current setup: %s • %s domains\n' "$_in_name" "$(fmt_num "$CH_COUNT")"
        else
          printf '♻️ Keeping your current setup: %s (blocker disabled)\n' "$_in_name"
        fi
        set -- $C_ADDONS
        [ "$#" -gt 0 ] && printf '✅ %s %s kept\n' "$#" "$(plural "$#" add-on add-ons)"
        count_lines "$ALLOWF"; _in_r=$R_LINES
        count_lines "$BLOCKF"; _in_r=$((_in_r + R_LINES))
        [ "$_in_r" -gt 0 ] && printf '✅ %s domain %s kept\n' "$_in_r" "$(plural "$_in_r" rule rules)"
        log INFO "Kept the existing setup: $_in_name"
      fi
    fi
    rm -f "$HOSTSD/.hosts.sbnew" "$TMPD/compile.stats"
  fi
  if [ "$_in_keep" = 0 ]; then
    cfg_load
    C_ENABLED=1
    C_SETUP=pending
    cfg_save
    _in_name=$L_NAME
    if [ "${BOOTMODE:-true}" != false ] && pipeline setup "$C_LIST" "$C_ADDONS"; then
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
      C_ENABLED=1
      C_SETUP=pending
      cfg_save
      printf '🧩 Wrote a clean localhost-only hosts file for now\n'
      printf '%s\n' "🔁 StevenBlock will retry automatically after reboot, once you’re online"
      log WARN "The first download failed during install; it will be retried after reboot"
    fi
  fi
  set_hosts_perm "$HOSTS"
  rm -f "$SUMF"
  mark_pending
  set_description

  printf '\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
  printf '🎉 StevenBlock %s is installed!\n' "$SB_VER"
  printf '🔁 Reboot your device to activate it.\n'
  printf '⚡ New in v2.0: live apply, add-on lists, auto-update and more.\n'
  case $MGR_NAME in
    KernelSU* | SukiSU* | APatch)
      printf '🔗 Works with or without a metamodule: StevenBlock checks the mount at every boot.\n'
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

[ -d "$TMPD" ] && [ -d "$LISTSD" ] || ensure_dirs
SB_RC=0

case ${1:-} in
  cgi) cgi_main; SB_RC=0 ;;
  _worker) worker_main "${2:-}" "${3:-}" "${4:-}" ;;
  _meta) shift; meta_worker_main "$@" ;;
  _setup) setup_main ;;
  _sched) sched_main "${2:-}" ;;
  _serve) serve_main ;;
  _action) action_main ;;
  _install) install_main ;;
  _boot) boot_main ;;
  _mount) mount_main ;;
  _uninstall) uninstall_main ;;
  *) dispatch "$@" ;;
esac
exit "$SB_RC"
