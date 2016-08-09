FROM ubuntu:15.10

RUN apt-get update && \
    apt-get -y install git zip unzip \
        libxml2-dev libxslt-dev libcurl4-openssl-dev \
        build-essential zlib1g-dev libssl-dev libreadline6-dev libyaml-dev \
        tree file curl wget bzr jq \
    && apt-get clean

# install ruby & required gems/CLIs
RUN cd \
      && wget http://ftp.ruby-lang.org/pub/ruby/2.2/ruby-2.2.5.tar.gz \
      && tar -xzvf ruby-2.2.5.tar.gz \
      && cd ruby-2.2.5/ \
      && ./configure \
      && make \
      && make install \
      && ruby -v \
      && gem install bundler bosh_cli license_finder fog mime-types --no-rdoc --no-ri

ADD https://github.com/geofffranks/spruce/releases/download/v1.6.0/spruce-linux-amd64 /usr/bin/spruce
RUN chmod 755 /usr/bin/spruce

ADD https://cli.run.pivotal.io/stable?release=linux64-binary&version=6.21.0 /tmp/cf.tgz
RUN tar xzf /tmp/cf.tgz -C /usr/bin && rm /tmp/cf.tgz
