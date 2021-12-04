# -*- mode: ruby -*-
# vi: set ft=ruby :

$vm_memory ||= 2048
$vm_cpus ||= 2

Vagrant.configure("2") do |config|
  config.vm.box = "bento/centos-7.8"
  config.vm.provider :virtualbox do |vb|
        vb.memory = $vm_memory
        vb.cpus = $vm_cpus
        vb.linked_clone = true
  end

  config.vm.network "private_network", ip: "192.168.120.100"

  # config.vm.provision "shell", path: "getOfflineContent.sh"
  config.vm.provision "shell", path: "master.sh"
end
