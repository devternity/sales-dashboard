
Vagrant.configure("2") do |config|
  
  config.vm.box = "aestasit/devops-ubuntu-16.04"
  config.vm.hostname = "devternity-dashing"  
  config.vm.network "private_network", ip: "192.168.111.201"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "devternity-dashing"
    vb.customize ["modifyvm", :id, "--memory", "2048"]
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  end

  config.vm.provision "shell", inline: "sudo apt-get update -y"
  config.vm.provision "shell", inline: "sudo apt-get -y -q install ruby ruby-dev nodejs g++ bundler travis"
  config.vm.provision "shell", inline: "sudo gem install dashing"
  config.vm.provision "shell", inline: "sudo gem install rspec"
  config.vm.provision "shell", inline: "cd /vagrant && bundle install --path vendor/bundle"
  config.vm.provision "shell", inline: "sudo systemctl enable /vagrant/dashing.service"
  config.vm.provision "shell", inline: "sudo service dashing start"

end


