FROM ubuntu:16.04

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

CMD ["bash", "-c", \
  "echo Setting up dependencies && \
   bundle install --path /app/vendor && \
   echo && \
   echo Starting up dashing on http://127.0.0.1:3030/sales && \
   dashing start -P /var/run/thin.pid"]