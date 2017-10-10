FROM ubuntu

RUN apt-get -y -q update && \
    apt-get -y -q upgrade

RUN apt-get -y -q install ruby ruby-dev nodejs g++ bundler

RUN mkdir -p /opt/dashing && \
    cd /opt/dashing && \
    gem install dashing && \
    gem install rspec

RUN apt-get -y -q install python python-pip && \
    pip install --upgrade pip && \
    pip install --user firebase-admin

VOLUME /app
WORKDIR /app

EXPOSE 3030

CMD ["bash", "-c", "bundle install && dashing start"]
#CMD ["bash", "-c", "dashing start"]
