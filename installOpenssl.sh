#!/bin/bash -ex
cd /tmp

update-ca-trust
[ -d openssl-* ]        || tar -xzvf /vagrant/openssl-1.1.1k.tar.gz
cd openssl-*
./config --prefix=/usr --openssldir=/etc/ssl --libdir=lib no-shared zlib-dynamic
make; make install

cat > /etc/profile.d/openssl.sh << EOF
export LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64
EOF

source /etc/profile.d/openssl.sh
openssl version
