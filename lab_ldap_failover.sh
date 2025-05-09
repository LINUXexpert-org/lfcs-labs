#!/usr/bin/env bash
# lab_ldap_failover.sh – LFCS DIY Lab: sssd + LDAP primary/secondary
# Uses docker containers for slapd servers.

set -euo pipefail
[[ $EUID -ne 0 ]] && { echo "Run as root"; exit 1; }
command -v docker &>/dev/null || { echo "Docker required."; exit 2; }

BASE_DN="dc=example,dc=com"
PASS=supersecret
PRIMARY_NAME=ldap-primary
SECONDARY_NAME=ldap-secondary
SSSD_CONF=/etc/sssd/sssd.conf
README=/root/lab_ldap_failover.md

cleanup() {
  docker rm -f $PRIMARY_NAME $SECONDARY_NAME &>/dev/null || true
  authselect select sssd none --force 2>/dev/null || true
  rm -f $SSSD_CONF
  systemctl restart sssd 2>/dev/null || true
  echo "Cleanup done."
  exit 0
}
[[ ${1:-""} == "--cleanup" ]] && cleanup

docker run -d --name $PRIMARY_NAME --env LDAP_ORGANISATION="Example" \
  --env LDAP_DOMAIN="example.com" --env LDAP_ADMIN_PASSWORD="$PASS" \
  osixia/openldap:1.5.0

docker run -d --name $SECONDARY_NAME --env LDAP_ORGANISATION="Example" \
  --env LDAP_DOMAIN="example.com" --env LDAP_ADMIN_PASSWORD="$PASS" \
  osixia/openldap:1.5.0

sleep 8
PRIP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $PRIMARY_NAME)
SECIP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $SECONDARY_NAME)

echo "[*] Configuring sssd with primary=$PRIP secondary=$SECIP"
authselect select sssd --force
cat > $SSSD_CONF <<EOF
[sssd]
services = nss, pam
domains = EXAMPLE

[domain/EXAMPLE]
id_provider = ldap
auth_provider = ldap
ldap_uri = ldap://$PRIP,ldap://$SECIP
ldap_search_base = $BASE_DN
enumerate = true
cache_credentials = false
EOF
chmod 600 $SSSD_CONF
systemctl restart sssd

cat > "$README" << EOF
# LFCS Mock Lab – LDAP Fail‑over

Two slapd containers act as primary ($PRIP) and secondary ($SECIP).  
*Task:* Stop the primary container (`docker stop $PRIMARY_NAME`) and reconfigure sssd or its cache to authenticate via the secondary without downtime.

Verify:
\`getent passwd admin\` (use default OpenLDAP admin DN) should succeed after primary outage.

Cleanup: \`sudo $0 --cleanup\`
EOF

echo "LDAP fail‑over lab ready. Try 'id admin' to test."
