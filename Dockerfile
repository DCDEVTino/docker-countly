FROM ubuntu:20.04

CMD ["/sbin/my_init"]

env  INSIDE_DOCKER 1

EXPOSE 80
# REPOS
run    add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) universe"
run    add-apt-repository -y ppa:chris-lea/node.js
run    add-apt-repository -y ppa:nginx/stable
run    apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10
run    echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | tee /etc/apt/sources.list.d/10gen.list
run    apt-get --yes update
run    apt-get --yes upgrade 

#SHIMS
run    dpkg-divert --local --rename --add /sbin/initctl
run    ln -s /bin/true /sbin/initctl

# TOOLS
run    apt-get install -y -q curl git wget

## MONGO
run    mkdir -p var/lib/mongodb
run    mkdir /etc/nginx/ssl
run    apt-get install -y -q mongodb-10gen
run    mkdir /etc/service/mongodb && 
run    mkdir /etc/service/nginx && 
run    mkdir /etc/service/countly-api
run    mkdir /etc/service/countly-dashboard
run    echo "" >> /etc/nginx/nginx.conf
run    echo "daemon off;" >> /etc/nginx/nginx.conf
run    chown mongodb /etc/service/mongodb/run
run    chown root /etc/service/nginx/run
run    chown -R countly:countly /opt/countly


## NODE
run    apt-get install -y -q nodejs
env   DEBIAN_FRONTEND dialog

## Countly required
run    apt-get --yes install supervisor imagemagick nginx build-essential  --force-yes

## Setup Countly
RUN useradd -r -M -U -d /opt/countly -s /bin/false countly && \
        echo "countly ALL=(ALL) NOPASSWD: /usr/bin/sv restart countly-api countly-dashboard" >> /etc/sudoers.d/countly && \
        /opt/countly/bin/countly.install.sh
run    mkdir -p var/data/log
run    cd /opt; git clone https://github.com/Countly/countly-server.git countly --depth 1
run    cd /opt/countly/api ; npm install time 
run    rm /etc/nginx/sites-enabled/default
run    cp /opt/countly/bin/config/nginx.server.conf /etc/nginx/sites-enabled/default

run    cp  /opt/countly/frontend/express/public/javascripts/countly/countly.config.sample.js  /opt/countly/frontend/express/public/javascripts/countly/countly.config.js
run    cp  /opt/countly/api/config.sample.js  /opt/countly/api/config.js
run    cp  /opt/countly/frontend/express/config.sample.js  /opt/countly/frontend/express/config.js

add    ./supervisor/supervisord.conf /etc/supervisor/supervisord.conf
add    ./supervisor/conf.d/nginx.conf /etc/supervisor/conf.d/nginx.conf
add    ./supervisor/conf.d/mongodb.conf /etc/supervisor/conf.d/mongodb.conf
add    ./supervisor/conf.d/countly.conf /etc/supervisor/conf.d/countly.conf

# Add services' run scripts
ADD ./bin/commands/docker/mongodb.sh /etc/service/mongodb/run
ADD ./bin/commands/docker/nginx.sh /etc/service/nginx/run
ADD ./bin/commands/docker/countly-api.sh /etc/service/countly-api/run
ADD ./bin/commands/docker/countly-dashboard.sh /etc/service/countly-dashboard/run


expose :80
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
volume ["/data"]
ENTRYPOINT ["/usr/bin/supervisord"]
