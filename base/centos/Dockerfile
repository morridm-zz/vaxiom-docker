# Base centos image
#
# VERSION 1.0
# DOCKER-VERSION 0.9x
#
# Usage: docker run -d -p 0.0.0.0:49153:22 -p 0.0.0.0:49154:27018 -p 0.0.0.0:49155:28017 -p 0.0.0.0:49156:3306 -p 0.0.0.0:49157:4444 -p 0.0.0.0:49158:4567 -p 0.0.0.0:49159:80 -p 0.0.0.0:49160:27017 -p 0.0.0.0:49161:27019 -p 0.0.0.0:49162:443 -p 0.0.0.0:49163:4568 vaxiom/centos:latest
# ssh -p 49154 dmorris@172.17.42.1
# tag: latest
FROM centos:latest
MAINTAINER David Morris <morridm@gmail.com>

RUN yum -y update
RUN echo 'root:root123' | chpasswd
RUN yum -y install openssh-server openssh-clients which sudo libaio git
RUN yum -y install httpd wget tar nc passwd vim bzip2

RUN wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
RUN rpm -Uvh epel*
RUN rm -f *.rpm

# unsafe
#RUN sed -ri 's/#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config

RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config
RUN sed -ri 's/#UsePAM no/UsePAM no/g' /etc/ssh/sshd_config

RUN mkdir -p /root/.ssh; chmod 700 /root/.ssh
ADD src/id_rsa.pub /root/.ssh/authorized_keys
RUN chown root.root /root/.ssh/*; chmod 600 /root/.ssh/*
ADD src/nopasswd /etc/sudoers.d/nopasswd
RUN chown root.root /etc/sudoers.d/*

RUN useradd -m dmorris
RUN echo "dmorris:dmorris123" | chpasswd
RUN mkdir -p /home/dmorris/.ssh/
RUN chown -R dmorris:dmorris /home/dmorris/.ssh/
ADD src/id_rsa.pub /home/dmorris/.ssh/authorized_keys
RUN echo "dmorris        ALL=(ALL)       ALL" >> /etc/sudoers.d/dmorris
RUN chmod 700 /home/dmorris/.ssh
RUN chown dmorris:dmorris /home/dmorris/.ssh/authorized_keys
RUN chmod 600 /home/dmorris/.ssh/authorized_keys

# supervisord for sshd
RUN yum -y install python-setuptools
RUN easy_install supervisor
ADD src/supervisord.conf /etc/
RUN chown root.root /etc/supervisord.conf

##EXPOSE 22 80 443 3306 4444 4567 4568 27017 27018 27019 28017

EXPOSE 22

ADD src/init.sh /opt/init.sh
RUN chown root.root /opt/init.sh
CMD ["/bin/bash", "/opt/init.sh"]
