# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'ipaddr'
require 'yaml'

required_plugins = [ "vagrant-hostmanager" ]
required_plugins.each do |plugin|
  if not Vagrant.has_plugin?(plugin)
    raise "The vagrant plugin #{plugin} is required. Please run `vagrant plugin install #{plugin}`"
  end
end

x = YAML.load_file(File.join(File.dirname(__FILE__), 'config.yaml'))

$private_nic_type = x.fetch('net').fetch('private_nic_type')

Vagrant.configure(2) do |config|
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = false
  config.hostmanager.manage_guest = true
  config.hostmanager.ignore_private_ip = false
  config.hostmanager.include_offline = true

  registryServer_ip = IPAddr.new(x.fetch('ip').fetch('registryServer'))
  (1..x.fetch('registry').fetch('count')).each do |i|
    c = x.fetch('registry')
    hostname = "registry"
    config.vm.define hostname do |registry|
      registry.vm.box   = "bento/centos-7.8"
      registry.vm.network x.fetch('net').fetch('network_type'), ip: IPAddr.new(registryServer_ip.to_i + i - 1, Socket::AF_INET).to_s
      registry.vm.hostname = hostname
      registry.vm.provision "shell", path: "getOfflineContent.sh", args: [x.fetch('ip').fetch('nfsServer'), x.fetch('admin_password')]
      registry.vm.provision "shell", path: "makeRegistry.sh", args: [x.fetch('ip').fetch('nfsServer'), x.fetch('admin_password')]
      registry.vm.provider "virtualbox" do |v|
        v.cpus = c.fetch('cpus')
        v.linked_clone = true if Gem::Version.new(Vagrant::VERSION) >= Gem::Version.new('1.8.0') and x.fetch('linked_clones')
        v.memory = c.fetch('memory')
        v.name = hostname
      end
    end
  end

  master_ip = IPAddr.new(x.fetch('ip').fetch('master'))
  (1..x.fetch('master').fetch('count')).each do |i|
    c = x.fetch('master')
    hostname = "master-%02d" % i
    config.vm.define hostname do |master|
      master.vm.box   = "bento/centos-7.8"
      master.vm.network x.fetch('net').fetch('network_type'), ip: IPAddr.new(master_ip.to_i + i - 1, Socket::AF_INET).to_s
      master.vm.hostname = hostname
      master.vm.provider "virtualbox" do |v|
        v.cpus = c.fetch('cpus')
        v.linked_clone = true if Gem::Version.new(Vagrant::VERSION) >= Gem::Version.new('1.8.0') and x.fetch('linked_clones')
        v.memory = c.fetch('memory')
        v.name = hostname
      end
      master.vm.provision "shell", path: "master.sh", args: [c.fetch('mode'),x.fetch('ip').fetch('nfsServer'), x.fetch('admin_password')]
    end
  end

  worker_ip = IPAddr.new(x.fetch('ip').fetch('worker'))
  (1..x.fetch('worker').fetch('count')).each do |i|
    c = x.fetch('worker')
    hostname = "worker-%02d" % i
    config.vm.define hostname do |worker|
      worker.vm.box   = "bento/centos-7.8"
      worker.vm.network x.fetch('net').fetch('network_type'), ip: IPAddr.new(worker_ip.to_i + i - 1, Socket::AF_INET).to_s
      worker.vm.hostname = hostname
      worker.vm.provider "virtualbox" do |v|
        v.cpus = c.fetch('cpus')
        v.linked_clone = true if Gem::Version.new(Vagrant::VERSION) >= Gem::Version.new('1.8.0') and x.fetch('linked_clones')
        v.memory = c.fetch('memory')
        v.name = hostname
      end
      worker.vm.provision "shell", path: "worker.sh", args: [x.fetch('ip').fetch('nfsServer'), x.fetch('admin_password')]
    end
  end

end
