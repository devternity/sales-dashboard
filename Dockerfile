FROM ubuntu:16.04

RUN apt-get -y -q update && \
    apt-get -y -q upgrade

RUN apt-get -y -q install ruby ruby-dev nodejs g++ bundler

RUN mkdir -p /opt/smashing && \
    cd /opt/smashing && \
    gem install smashing && \
    gem install rspec

VOLUME /app
WORKDIR /app

EXPOSE 3030

CMD ["bash", "-c", "bundle install --path /tmp/bundle && smashing start -P /var/run/thin.pid"]
