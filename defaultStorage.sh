#!/bin/bash -eux
helm install nfs-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
	--set nfs.server=192.168.120.90 \
	--set nfs.path=/export/k8s \
	--set storageClass.name=nfs-provisioner \
	--set storageClass.defaultClass=true \
	--set image.tag=v4.0.0
# kubectl patch storageclass nfs-provisioner -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
