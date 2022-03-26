#!/bin/bash -ex
cd /tmp

update-ca-trust
[ -d openssl-* ]        || tar -xzf /vagrant/openssl-1.1.1k.tar.gz
cd openssl-*
./config --prefix=/usr --openssldir=/etc/ssl --libdir=lib no-shared zlib-dynamic
make -j2; make install_sw install_ssldirs

cat > /etc/profile.d/openssl.sh << EOF
export LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64
EOF

source /etc/profile.d/openssl.sh
openssl version
