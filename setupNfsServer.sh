#!/bin/bash -eux

systemctl enable nfs-server.service
systemctl start nfs-server.service

cat > /etc/exports << EOF
/export/k8s    192.168.120.0/24(rw,sync,no_root_squash,no_subtree_check,insecure)
EOF

mkdir -p                  /export/k8s/
chmod 755                 /export/k8s/
chown nfsnobody:nfsnobody /export/k8s/

exportfs -a
