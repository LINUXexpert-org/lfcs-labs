#!/usr/bin/env bash
# lab_broken_boot.sh – LFCS DIY Lab: Broken Boot (GRUB/UUID)
#   • Adds wrong root UUID to GRUB cmdline
#   • Removes quiet & adds 'debug' to make recovery noisier
#   • Updates GRUB and prompts reboot
# Cleanup restores original grub.cfg and grubenv

set -euo pipefail
BACKUP_DIR=/root/lab-broken-boot-backup
README=/root/lab-broken_boot.md

usage() { echo "Usage: $0 [--cleanup]"; exit 1; }
[[ ${1:-""} == "--help" ]] && usage

# -------- Helpers -----------------------------------------------------------
cleanup() {
  if [[ -d $BACKUP_DIR ]]; then
    echo "[*] Restoring GRUB configuration…"
    cp -a $BACKUP_DIR/* /
    grub2-mkconfig -o /boot/grub2/grub.cfg 2>/dev/null || update-grub
    echo "[+] Cleanup complete – system should boot normally."
    rm -rf $BACKUP_DIR
  else
    echo "No lab artifacts found; nothing to clean."
  fi
}

# -------- Trigger Cleanup ---------------------------------------------------
[[ ${1:-""} == "--cleanup" ]] && cleanup && exit 0

# -------- Safety Checks -----------------------------------------------------
if [[ $EUID -ne 0 ]]; then echo "Run as root."; exit 2; fi
[[ -d $BACKUP_DIR ]] && { echo "Lab already applied. Run --cleanup first."; exit 3; }

echo "This lab will intentionally break the boot loader."
read -rp "Continue? [type YES] " ans
[[ $ans != "YES" ]] && { echo "Aborted."; exit 0; }

# -------- Backup Files ------------------------------------------------------
mkdir -p $BACKUP_DIR
cp -a /etc/default/grub $BACKUP_DIR/
cp -a /boot/grub2/grub.cfg $BACKUP_DIR/ 2>/dev/null || true
cp -a /boot/grub/grub.cfg $BACKUP_DIR/ 2>/dev/null || true

# -------- Introduce Failure -------------------------------------------------
FAULT_UUID="deadbeef-dead-beef-dead-beefdeadbeef"
sed -i.bak -E "s|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"root=UUID=$FAULT_UUID debug\"|" /etc/default/grub

grub2-mkconfig -o /boot/grub2/grub.cfg 2>/dev/null || update-grub

# -------- README ------------------------------------------------------------
cat > "$README" << 'EOF'
# LFCS Mock Lab – Broken Boot

Your system now contains a bad root UUID in GRUB.  
Goal: Boot into **rescue mode**, identify the wrong UUID, correct `/etc/default/grub`, regenerate GRUB config, and restore normal boot.

**Hints**

* `lsblk -f` to view real UUIDs  
* `grub2-mkconfig` (RHEL) or `update-grub` (Debian)  
* Use chroot from a live ISO if system won't boot

EOF
echo "[+] Lab ready. Reboot to test your recovery skills!"
