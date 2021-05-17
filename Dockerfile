FROM ubuntu:20.04

CMD ["/sbin/my_init"]

env  INSIDE_DOCKER 1

EXPOSE 80

# REPOS
run    add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) universe"
run    add-apt-repository -y "deb https://nginx.org/packages/ubuntu/ xenial nginx"
run    add-apt-repository -y "deb-src https://nginx.org/packages/ubuntu/ xenial nginx"
run    apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10
run    echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | tee /etc/apt/sources.list.d/10gen.list
run    apt-get --yes update
run    apt-get --yes upgrade --force-yes

#SHIMS
run    dpkg-divert --local --rename --add /sbin/initctl
run    ln -s /bin/true /sbin/initctl

# TOOLS
run    apt-get install -y -q curl git wget

## MONGO
run    mkdir -p var/lib/mongodb
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

## County required
run    apt-get --yes install supervisor imagemagick nginx build-essential  --force-yes

## Setup Countly
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

expose :80
volume ["/data"]
ENTRYPOINT ["/usr/bin/supervisord"]
