FROM ubuntu:20.04

CMD ["/sbin/my_init"]

## Setup Countly
ENV INSIDE_DOCKER 1

EXPOSE 80

run apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
run echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/3.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.0.list
run apt-get --yes update
run apt-get --yes upgrade --force-yes


#SHIMS
run  dpkg-divert --local --rename --add /sbin/initctl
run  ln -sf /bin/true /sbin/initctl


## MONGO
run mkdir -p /data/db
run apt-get --yes install mongodb

## NODE
run apt-get --yes install -q nodejs
env DEBIAN_FRONTEND dialog

## County required
run apt-get --yes install supervisor imagemagick nginx build-essential  --force-yes

## Setup Countly
run mkdir -p /data/log
run cd /opt; git clone https://github.com/Countly/countly-server.git countly --depth 1
run cd /opt/countly/api ; npm install time 
run rm /etc/nginx/sites-enabled/default
run cp /opt/countly/bin/config/nginx.server.conf /etc/nginx/sites-enabled/default

run cp /opt/countly/frontend/express/public/javascripts/countly/countly.config.sample.js  /opt/countly/frontend/express/public/javascripts/countly/countly.config.js
run cp /opt/countly/api/config.sample.js  /opt/countly/api/config.js
run cp /opt/countly/frontend/express/config.sample.js  /opt/countly/frontend/express/config.js

add ./supervisor/supervisord.conf /etc/supervisor/supervisord.conf
add ./supervisor/conf.d/nginx.conf /etc/supervisor/conf.d/nginx.conf
add ./supervisor/conf.d/mongodb.conf /etc/supervisor/conf.d/mongodb.conf
add ./supervisor/conf.d/countly.conf /etc/supervisor/conf.d/countly.conf

expose :80
volume ["/data"]
ENTRYPOINT ["/usr/bin/supervisord"]
