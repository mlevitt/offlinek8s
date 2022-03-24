#!/bin/bash -ex

version=1.22
mkdir -p /vagrant/{images,networking/rpms}

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


yumdownloader --assumeyes --destdir=$rpmDir/kub --resolve yum-utils kubeadm-$version.* kubelet-$version.* kubectl-$version.* ebtables

yum install -y --cacheonly --disablerepo=* $rpmDir/*.rpm $rpmDir/*/*.rpm|| true

systemctl start docker
systemctl enable  docker

kubeadm config images list | xargs -n 1 docker pull

cd /vagrant/networking
curl -O  https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
grep image /vagrant/networking/kube-flannel.yml | sort -u | awk '{print $2}' | xargs -n 1 docker pull

docker images  | grep -vP 'IMAGE|none' | awk '{print $1 ":" $2 " " $3}' | while read name sha; do docker save -o /vagrant/images/$sha.tar $name; done

cd /vagrant
tar czf    /vagrant/offline-$version.tgz images rpms
