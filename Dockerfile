FROM ubuntu

RUN apt-get -y -q update && \
    apt-get -y -q upgrade

RUN apt-get -y -q install ruby ruby-dev nodejs g++ bundler

RUN mkdir -p /opt/dashing && \
    cd /opt/dashing && \
    gem install dashing && \
    gem install rspec

VOLUME /app
WORKDIR /app

EXPOSE 3030

CMD ["bash", "-c", "bundle install --path /tmp/bundle && dashing start -P /var/run/thin.pid"]
