#!/usr/bin/env bash
# lab_selinux_denial.sh – LFCS DIY Lab: SELinux context issue
# Works on SELinux-enabled distros (AlmaLinux, RHEL, Fedora, CentOS Stream)

set -euo pipefail
[[ -f /etc/selinux/config ]] || { echo "SELinux not installed."; exit 1; }
BACK=/root/lab-selinux-backup
README=/root/lab_selinux_denial.md
DOCROOT=/srv/www_moved
PORT=8080

[[ ${1:-""} == "--cleanup" ]] && { mv /etc/httpd/conf.d/lab.conf{.bak,} 2>/dev/null || true ; \
                                   restorecon -R /var/www/html 2>/dev/null || true ; \
                                   systemctl restart httpd 2>/dev/null || true ; \
                                   rm -rf $DOCROOT $BACK; echo "Cleaned."; exit 0; }

[[ $EUID -ne 0 ]] && { echo "Run as root"; exit 1; }
command -v semanage &>/dev/null || { echo "Install policycoreutils-python-utils"; exit 2; }

mkdir -p $BACK $DOCROOT
cp -a /var/www/html/* $DOCROOT/ 2>/dev/null || echo "<h1>Lab</h1>" >$DOCROOT/index.html
mv /etc/httpd/conf.d/lab.conf{,.bak} 2>/dev/null || true

cat > /etc/httpd/conf.d/lab.conf <<EOF
<VirtualHost *:$PORT>
    DocumentRoot "$DOCROOT"
</VirtualHost>
EOF

systemctl restart httpd

# Intentionally leave wrong context
semanage port -a -t http_port_t -p tcp $PORT || true
echo "SELinux denial created (wrong context on $DOCROOT)."

cat > "$README" << EOF
# LFCS Mock Lab – SELinux Denial

Apache now serves \$DOCROOT on port $PORT, but SELinux blocks access.

Steps to fix:
1. Identify denial: \`ausearch -m AVC,USER_AVC -ts recent | tail\`
2. Apply correct context: \`semanage fcontext -a -t httpd_sys_content_t '$DOCROOT(/.*)?'\`
3. Restore: \`restorecon -R $DOCROOT\`

Verify with: \`curl http://localhost:$PORT/\`
EOF
