#!/bin/bash -ex
cd /tmp

update-ca-trust

[ -e openssl-1.1.1k.tar.gz ] || wget https://ftp.openssl.org/source/openssl-1.1.1k.tar.gz
[ -d openssl-1.1.1k ]        || tar -xzvf openssl-1.1.1k.tar.gz
cd openssl-1.1.1k
./config --prefix=/usr --openssldir=/etc/ssl --libdir=lib no-shared zlib-dynamic
make; make install

cat > /etc/profile.d/openssl.sh << EOF
export LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64
EOF

source /etc/profile.d/openssl.sh
openssl version
