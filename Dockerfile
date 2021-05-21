
FROM ubuntu:20.04

CMD ["/sbin/my_init"]

## Setup Countly
ENV INSIDE_DOCKER 1

EXPOSE 80


# REPOS
run    wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
run    sudo apt-get update
run    sudo apt-get -y upgrade

#SHIMS
run    dpkg-divert --local --rename --add /sbin/initctl
run    ln -s /bin/true /sbin/initctl

# TOOLS
run    sudo apt-get install git
run    sudo apt-get install wget
run    sudo apt-get install unzip
run    sudo apt-get install docker-compose 

## MONGO
run    mkdir -p /data/db
run    apt-get install -y -q mongodb

## NODE
run    apt-get install -y -q nodejs
env   DEBIAN_FRONTEND dialog

## County required
run    apt-get --yes install supervisor imagemagick nginx build-essential  --force-yes

## Setup Countly
run    mkdir -p /data/log
run    cd /opt; git clone https://github.com/Countly/countly-server.git countly --depth 1
run    cd /opt/countly/api ; npm install time 
run    rm /etc/nginx/sites-enabled/default
run    cp  /opt/countly/bin/config/nginx.server.conf /etc/nginx/sites-enabled/default

run    cp  /opt/countly/frontend/express/public/javascripts/countly/countly.config.sample.js  /opt/countly/frontend/express/public/javascripts/countly/countly.config.js
run    cp  /opt/countly/api/config.sample.js  /opt/countly/api/config.js
run    cp  /opt/countly/frontend/express/config.sample.js  /opt/countly/frontend/express/config.js

add    ./supervisor/supervisord.conf /etc/supervisor/supervisord.conf
add    ./supervisor/conf.d/nginx.conf /etc/supervisor/conf.d/nginx.conf
add    ./supervisor/conf.d/mongodb.conf /etc/supervisor/conf.d/mongodb.conf
add    ./supervisor/conf.d/countly.conf /etc/supervisor/conf.d/countly.conf

expose :80
volume ["/data"]
ENTRYPOINT ["/usr/bin/supervisord"]
