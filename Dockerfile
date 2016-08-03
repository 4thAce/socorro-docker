FROM local/c7-systemd
MAINTAINER "Richard Magahiz" <richard.magahiz@daqri.com>

RUN rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch 
RUN yum -y update && \
  yum -y install epel-release
COPY elasticsearch.repo /etc/yum.repos.d/
RUN rpm -ivh https://s3-us-west-2.amazonaws.com/org.mozilla.crash-stats.packages-public/el/7/noarch/socorro-public-repo-1-1.el7.centos.noarch.rpm && \
  yum -y install consul \
    envconsul \
    elasticsearch \
    java-1.7.0-openjdk \
    nginx \
    python-virtualenv \
    socorro  && \
  systemctl enable nginx elasticsearch 
COPY server.json /etc/consul/
RUN  mkdir /root/socorro-config && \
  mkdir /root/symboldir
COPY collector.conf /root/socorro-config/
COPY processor.conf /root/socorro-config/
COPY common.conf /root/socorro-config/
COPY socorro-collector.conf /etc/nginx/conf.d/
COPY socorro-analysis.conf /etc/nginx/conf.d/
COPY socorro-middleware.conf /etc/nginx/conf.d/
COPY socorro-webapp.conf /etc/nginx/conf.d/
COPY startdocker.sh /root/
WORKDIR /root/socorro-config
EXPOSE 80
ONBUILD systemctl start nginx elasticsearch
ONBUILD systemctl restart consul
ONBUILD systemctl enable socorro-collector socorro-processor
ONBUILD systemctl start socorro-collector socorro-processor
ONBUILD /root/socorro-config/setup-socorro.sh consul 
ONBUILD  envconsul -prefix socorro env 
ONBUILD  /root/socorro-config/setup-socorro.sh elasticsearch 
ONBUILD  /root/socorro-config/setup-socorro.sh consul
CMD ["/root/startdocker.sh"]
