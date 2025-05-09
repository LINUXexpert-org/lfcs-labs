#!/usr/bin/env bash
# lab_disk_full.sh – LFCS DIY Lab: /var/log filled up

set -euo pipefail
BACK=/root/lab-diskfull-backup
README=/root/lab_disk_full.md
LOGDIR=/var/log/fakefill
CHUNK_MB=50
TARGET_PCT=95

[[ ${1:-""} == "--cleanup" ]] && { rm -rf "$LOGDIR"; echo "Cleanup done." ; exit 0; }
[[ $EUID -ne 0 ]] && { echo "Run as root"; exit 1; }
[[ -d $LOGDIR ]] && { echo "Lab already applied"; exit 2; }

mkdir -p $LOGDIR
echo "Filling /var filesystem to ~${TARGET_PCT}%…"
FILL() {
  dd if=/dev/urandom of="$LOGDIR/blob$(date +%s).dat" bs=1M count=$CHUNK_MB status=none
}
while :; do
  USAGE=$(df -P /var | awk 'NR==2{print $5+0}')
  (( USAGE >= TARGET_PCT )) && break
  FILL
done

cat > "$README" << 'EOF'
# LFCS Mock Lab – Disk Full

The `/var` filesystem is critically full.  
Tasks:

1. Identify which directory is consuming space (`du -x --max-depth=1 -h /var`).
2. Rotate/compress or delete logs responsibly.
3. Prevent recurrence (logrotate, max‑size, or move logs to separate LV).

Pass criteria: `/var` usage < 70 %.
EOF

echo "Disk full scenario ready. Hint: try 'du -shx /var/* | sort -h'."
