
DevTernity Sales Dashboard
==========================

Dashing based dashboard for retrieving Firebase data.

Run within Docker
===========================

1. Create/decrypt configuration files inside the `config` directory with proper API keys and secrets.
2. `docker-compose up`. Subsequently `docker run --rm -it -p 3030:3030 -v $PWD:/app devternity/sales-dashboard` could be used, e.g. with pry-debug on..
3. Go to <http://127.0.0.1:3030/sales> (or use docker-machine ip)

Run within Vagrant
===========================

1. Create/decrypt configuration files inside the `config` directory with proper API keys and secrets.
2. `vagrant up`
3. Go to <http://192.168.111.201:3030/sales>
