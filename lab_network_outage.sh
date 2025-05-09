#!/usr/bin/env bash
# lab_network_outage.sh – LFCS DIY Lab: Network Mis‑configuration
#   • Corrupts default gateway in NetworkManager / netplan
#   • Leaves system reachable by console only
set -euo pipefail
BACK=/root/lab-network-backup
README=/root/lab_network_outage.md

[[ ${1:-""} == "--cleanup" ]] && { nmcli connection reload 2>/dev/null || true ; \
                                   netplan apply 2>/dev/null || true ; \
                                   [[ -d $BACK ]] && cp -a $BACK/* /etc/ && rm -rf $BACK ; \
                                   echo "Cleanup done."; exit 0; }

[[ $EUID -ne 0 ]] && { echo "Run as root"; exit 1; }
[[ -d $BACK ]] && { echo "Lab already applied"; exit 2; }

echo "Creating bad default gateway…"
mkdir -p $BACK

# NM‑based distros
if command -v nmcli &>/dev/null; then
  IF=$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: '$2!=""{print $1; exit}')
  nmcli connection modify "$IF" ipv4.gateway 192.0.2.254
  nmcli connection down "$IF" && nmcli connection up "$IF"
  nmcli connection show "$IF" > $BACK/nm_before.txt
# netplan (Ubuntu server)
elif [[ -d /etc/netplan ]]; then
  cp /etc/netplan/*.yaml $BACK/
  sed -i '/gateway4:/c\  gateway4: 192.0.2.254' /etc/netplan/*.yaml
  netplan apply
else
  echo "Unsupported network stack."
  exit 3
fi

cat > "$README" << 'EOF'
# LFCS Mock Lab – Network Outage

A bogus gateway (192.0.2.254) has been configured.  
Fix networking *permanently* using the native tool (nmcli or netplan).

Checkpoints:
* `ping -c3 8.8.8.8` succeeds
* Gateway persists after reboot (`ip route`)
EOF
echo "Bad gateway injected. Disconnect SSH and reconnect via console to troubleshoot. Good luck!"
