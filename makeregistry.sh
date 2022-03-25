#!/bin/bash -eux


registryHostName=registry
registryHostIP=192.168.120.90

ls /vagrant/images || {
    cd /vagrant/
    tar xzf /vagrant/offline-*.22.tgz
}

# from https://medium.com/@ifeanyiigili/how-to-setup-a-private-docker-registry-with-a-self-sign-certificate-43a7407a1613
export rpmDir=/vagrant/rpms
yum localinstall -y $rpmDir/*.rpm $rpmDir/*/*.rpm|| true

cd /vagrant/
mkdir -p docker_reg_certs
[ -e docker_reg_certs/domain.key ] || { \
	# standard rpm is too old :|
	/vagrant/installOpenssl.sh
	openssl req     -newkey rsa:4096 -nodes -sha256 \
           -keyout docker_reg_certs/domain.key \
           -x509 \
	   -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=$registryHostName"  -days 365 \
           -addext "subjectAltName = DNS:$registryHostName" \
           -out docker_reg_certs/domain.crt

}
grep $registryHostIP /etc/hosts || echo $registryHostIP $registryHostName >> /etc/hosts 
cp docker_reg_certs/domain.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust

systemctl enable docker
systemctl restart docker

docker images | grep registry  | grep pause || {
    cd /vagrant/
    ls /vagrant/images/* | while read tar; do docker load -i $tar; done
}

ls /vagrant/images/* | while read tar; do docker load -i $tar; done
docker images --format " {{.Repository}}:{{.Tag}}" | \
	grep -v $registryHostName | \
	perl -pe "s|([^/]*/)(.*)|\1\2\t$registryHostName:5000/\2|" | \
	while read i l; do docker tag $i $l; done

docker images  --format " {{.Repository}}:{{.Tag}}" | grep k8s.gcr && {
	docker tag k8s.gcr.io/coredns/coredns:v1.8.4 registry:5000/coredns:v1.8.4
} 

perl -pi -e 's|image: rancher/|image: registry:5000/|' /vagrant/networking/kube-flannel.yml

docker stop registry || true
docker rm   registry || true
docker run -d -p 5000:5000 \
   --restart=always --name registry \
   -v $PWD/docker_reg_certs:/certs \
   -v /mnt/reg:/var/lib/registry \
   -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
   -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
    registry

docker images --format " {{.Repository}}:{{.Tag}}" | \
	perl -pe "s|([^/]*/)(.*)|\1\2\t$registryHostName:5000/\2|" | \
	grep $registryHostName:5000 | \
	while read i l; do docker push $l; done

docker push registry:5000/coredns:v1.8.4

docker images  --format " {{.Repository}}:{{.Tag}}" | grep $registryHostName
curl -sX GET https://$registryHostName:5000/v2/_catalog

/vagrant/setupNfsServer.sh
