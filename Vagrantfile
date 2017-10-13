
Vagrant.configure("2") do |config|
  
  config.vm.box = "aestasit/devops-ubuntu-14.04"
  config.vm.hostname = "devternity-dashing"  
  config.vm.network "private_network", ip: "192.168.111.201"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "devternity-dashing"
    vb.customize ["modifyvm", :id, "--memory", "2048"]
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  end

  config.vm.provision "shell", inline: "sudo rm -rf /var/lib/apt/lists/lock"
  config.vm.provision "shell", inline: "sudo rm -rf /var/cache/apt/archives/lock"
  config.vm.provision "shell", inline: "sudo rm -rf /var/lib/dpkg/lock"
  config.vm.provision "shell", inline: "sudo apt-add-repository ppa:brightbox/ruby-ng"
  config.vm.provision "shell", inline: "sudo apt-get -y -q update"
  config.vm.provision "shell", inline: "sudo apt-get -y -q install ruby2.4 ruby2.4-dev build-essential make curl bundler"
  config.vm.provision "shell", inline: "sudo gem install dashing"
  config.vm.provision "shell", inline: "sudo gem install rspec"
  config.vm.provision "shell", inline: "cd /vagrant && bundle install --path vendor/bundle"
  config.vm.provision "shell", inline: "sudo systemctl enable /vagrant/dashing.service"
  config.vm.provision "shell", inline: "sudo service dashing start"

end


