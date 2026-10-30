#!/bin/bash
 
ALWAYS_SKIP="whiteteam dd-agent ddagentuser"

APPLY=0; SHOW=0; EXTRA_SKIP=""
while [ $# -gt 0 ]; do
  case "$1" in
    --apply) APPLY=1 ;;
    --show)  SHOW=1 ;;
    --skip)  shift; EXTRA_SKIP="$(echo "$1" | tr ',' ' ')" ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
  shift
done

[ "$(id -u)" -eq 0 ] || { echo "Run as root (sudo)."; exit 1; }
mkdir -p /root/ir; OUT=/root/ir/new_passwords.txt
touch "$OUT"; chmod 600 "$OUT"

is_skipped() {   # exact match against skip lists, plus anything with 'datadog' in the name
  for s in $ALWAYS_SKIP $EXTRA_SKIP; do [ "$1" = "$s" ] && return 0; done
  case "$1" in *datadog*) return 0 ;; esac
  return 1
}

[ "$APPLY" -eq 0 ] && echo "=== DRY RUN (nothing will change). Add --apply to do it. ==="

for user in $(awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd); do
  if is_skipped "$user"; then echo "[skip] $user"; continue; fi
  if [ "$APPLY" -eq 0 ]; then echo "[dry]  would change $user"; continue; fi

  newpass="$(openssl rand -base64 24 | tr -d '/+=\n' | cut -c1-16)"
  if echo "$user:$newpass" | chpasswd; then
    echo "$(date +%H:%M:%S) $user:$newpass" >> "$OUT"
    if [ "$SHOW" -eq 1 ]; then echo "[ok]   $user : $newpass"; else echo "[ok]   $user"; fi
  else
    echo "[FAIL] $user (password not changed)"
  fi
done

[ "$APPLY" -eq 1 ] && echo "[+] Done. Passwords in $OUT"
exit 0
