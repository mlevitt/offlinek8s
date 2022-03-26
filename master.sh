#!/bin/bash -eux

echo "$@"
mode=$1


source /vagrant/versionFile
perl -pe "s|__SEMVER__|$semanticVersion|" /vagrant/kubeconfig.yml.in > /vagrant/kubeconfig.yml

rpmDir=/vagrant/rpms
registryHostName=registry
registryHostIP=192.168.120.90
grep $registryHostIP /etc/hosts || {
	perl -ni -e 'm|127.0.0.1| || print' /etc/hosts
	cat >> /etc/hosts << EOF
192.168.120.90 registry
EOF
}

yum localinstall -y $rpmDir/*.rpm $rpmDir/*/*.rpm|| true
# yum -y install nfs-utils
grep registry /etc/fstab || {
  mkdir -p  /mnt/k8s
  cat >> /etc/fstab <<EOF
registry:/export/k8s  /mnt/k8s   nfs      rw,sync,hard,intr  0     0
EOF
  mount     /mnt/k8s
}

cp /vagrant/docker_reg_certs/domain.crt  /etc/pki/ca-trust/source/anchors/
update-ca-trust

mkdir -p /etc/docker
cat    > /etc/docker/daemon.json << EOF
{
  "exec-opts": ["native.cgroupdriver=cgroupfs"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

systemctl start docker
systemctl enable  docker


cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

sudo sed -i '/swap/d' /etc/fstab
sudo swapoff -a

if [ "$mode" == "minikube" ]
then
  echo in mini mode
  install /vagrant/minikube-linux-amd64 /usr/local/bin/minikube
else
  echo in full mode

  echo KUBELET_EXTRA_ARGS=--cgroup-driver=cgroupfs > /etc/sysconfig/kubelet 

  systemctl enable kubelet
  systemctl start  kubelet
  kubeadm --config /vagrant/kubeconfig.yml init

  mkdir -p $HOME/.kube
  cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  chown $(id -u):$(id -g) $HOME/.kube/config

  kubectl apply -f /vagrant/networking/kube-flannel.yml

  kubeadm token list | awk 'NR == 2 {print $1}' > /vagrant/joinToken
  kubeadm token create --print-join-command     > /vagrant/joincluster.sh
  kubectl config view --minify --flatten > /vagrant/kubeConfig
fi
