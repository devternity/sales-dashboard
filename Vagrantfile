
Vagrant.configure("2") do |config|
  
  config.vm.box = "aestasit/devops-ubuntu-16.04"
  config.vm.hostname = "docker-dev"  
  config.vm.network "private_network", ip: "192.168.111.201"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "docker-host"
    vb.customize ["modifyvm", :id, "--memory", "2048"]
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  end

  config.vm.provision "shell", inline: "sudo apt-get update -y"
  config.vm.provision "shell", inline: "sudo apt-get -y -q install ruby ruby-dev nodejs g++ bundler travis"
  config.vm.provision "shell", inline: "sudo gem install dashing"
  config.vm.provision "shell", inline: "sudo gem install rspec"
  config.vm.provision "shell", inline: "cd /vagrant && bundle install --path vendor/bundle"
  config.vm.provision "shell", inline: "sudo cp /vagrant/dashing.service /etc/systemd/system"
  config.vm.provision "shell", inline: "sudo systemctl enable dashing.service"
  config.vm.provision "shell", inline: "sudo service dashing start"

end


