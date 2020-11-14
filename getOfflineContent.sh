#!/bin/bash -ex

version=1.19
mkdir -p /vagrant/{images,networking/rpms}
if true
then
yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

rpmDir=/vagrant/rpms
yumdownloader --assumeyes --destdir=$rpmDir/yum --resolve yum-utils
yumdownloader --assumeyes --destdir=$rpmDir/dm --resolve device-mapper-persistent-data
yumdownloader --assumeyes --destdir=$rpmDir/lvm2 --resolve lvm2
yumdownloader --assumeyes --destdir=$rpmDir/docker-ce --resolve docker-ce
yumdownloader --assumeyes --destdir=$rpmDir/se --resolve container-selinux

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF


yumdownloader --assumeyes --destdir=$rpmDir --resolve yum-utils kubeadm-$version.* kubelet-$version.* kubectl-$version.* ebtables

yum install -y docker-ce docker-ce-cli containerd.io


systemctl start docker
systemctl enable  docker

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
yumdownloader --assumeyes --destdir=$rpmDir/  --resolve yum-utils kubeadm-$version.* kubelet-$version.* kubectl-$version.* ebtables

yum install -y --cacheonly --disablerepo=* $rpmDir/*.rpm || true

kubeadm config images list | xargs -n 1 docker pull



cd /vagrant/networking
curl -O  https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
grep image /vagrant/networking/kube-flannel.yml | sort -u | awk '{print $2}' | xargs docker pull

fi

docker images -q | while read image; do docker save $image > /vagrant/images/$image.tar; done

cd /vagrant
tar czf    /vagrant/offline-$version.tgz images rpms
