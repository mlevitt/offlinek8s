#!/bin/bash -ex
set -o pipefail

version=1.22

[ -e /vagrant/offline-$version.tgz ] && exit

mkdir -p /vagrant/{images,networking/rpms,rpms}

yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
EOF

rpmDir=/vagrant/rpms
yumdownloader --assumeyes --destdir=$rpmDir/yum --resolve yum-utils nfs-utils make gcc \
	perl-core pcre-devel wget zlib-devel ca-certificates vim
yumdownloader --assumeyes --destdir=$rpmDir/dm --resolve device-mapper-persistent-data
yumdownloader --assumeyes --destdir=$rpmDir/lvm2 --resolve lvm2
yumdownloader --assumeyes --destdir=$rpmDir/docker-ce --resolve docker-ce
yumdownloader --assumeyes --destdir=$rpmDir/se --resolve container-selinux
yumdownloader --assumeyes --destdir=$rpmDir/misc --resolve wget binutils gcc make zlib-devel nfs-utils nfs-utils-lib


yumdownloader --assumeyes --destdir=$rpmDir/kub --resolve yum-utils kubeadm-$version.* kubelet-$version.* kubectl-$version.* ebtables

yum install -y --cacheonly --disablerepo=* $rpmDir/*.rpm $rpmDir/*/*.rpm|| true

systemctl start docker
systemctl enable  docker

kubeadm config images list | xargs -n 1 docker pull
docker pull registry

cd /vagrant/networking
curl -O  https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
grep image /vagrant/networking/kube-flannel.yml | sort -u | awk '{print $2}' | xargs -n 1 docker pull

docker images --format " {{.Repository}}:{{.Tag}}" | \
	while read -r name ; do docker save -o /vagrant/images/"$(mktemp image.XXXXXXX.tar)" $name; done

cd /vagrant
[ -e openssl-1.1.1k.tar.gz ] || wget --no-check-certificate https://ftp.openssl.org/source/openssl-1.1.1k.tar.gz

tar czf    /vagrant/offline-$version.tgz images rpms networking openssl*.tar.gz
exit 1
