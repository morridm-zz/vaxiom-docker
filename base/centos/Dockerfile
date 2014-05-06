# Base centos image
#
# VERSION 1.0
# DOCKER-VERSION 0.9x
#
# Usage: docker run -d -p 0.0.0.0:49153:22 -p 0.0.0.0:49154:27018 -p 0.0.0.0:49155:28017 -p 0.0.0.0:49156:3306 -p 0.0.0.0:49157:4444 -p 0.0.0.0:49158:4567 -p 0.0.0.0:49159:80 -p 0.0.0.0:49160:27017 -p 0.0.0.0:49161:27019 -p 0.0.0.0:49162:443 -p 0.0.0.0:49163:4568 vaxiom/centos:latest
#  docker run -d -P vaxiom/centos:latest "/usr/bin/supervisord -c /etc/supervisord.conf"
#  ssh -p 49155 dmorris@172.17.42.1
# tag: latest
FROM centos:latest
MAINTAINER David Morris morridm@gmail.com

RUN yum -y update
RUN yum -y install openssh-server openssh-clients
RUN yum -y install which sudo libaio git
RUN yum -y install httpd wget tar nc passwd vim bzip2
RUN wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
RUN rpm -Uvh epel* && \
RUN rm -f *.rpm
RUN yum -y update && yum -y upgrade
RUN yum -y install sudo which man curl make

#Install Supervisor
RUN yum -y install python-pip
RUN yum -y install python-setuptools
RUN pip install pip --upgrade
RUN pip install supervisor
RUN mkdir -p /var/log/supervisor
RUN mkdir -p /etc/supervisor/conf.d
ADD src/supervisord.conf /etc/supervisord.conf
ADD src/sshd.sv.conf /etc/supervisor/conf.d/
ADD src/start_sshd_service.sh /opt/start_sshd_service.sh
RUN chmod +x /opt/start_sshd_service.sh

#Setup SSH
RUN mkdir -p /var/run/sshd && \
	echo 'root:root123' | chpasswd
ADD src/sshd_config /etc/ssh/sshd_config
RUN mkdir -p /root/.ssh; chmod 700 /root/.ssh
ADD src/id_rsa.pub /root/.ssh/authorized_keys
RUN chown root.root /root/.ssh/*; chmod 600 /root/.ssh/*
ADD src/nopasswd /etc/sudoers.d/nopasswd
RUN chown root.root /etc/sudoers.d/*
RUN useradd -m dmorris && \
	echo "dmorris:dmorris123" | chpasswd && \
	mkdir -p /home/dmorris/.ssh/ && \
	chown -R dmorris:dmorris /home/dmorris/.ssh/
ADD src/id_rsa.pub /home/dmorris/.ssh/authorized_keys
RUN echo "dmorris        ALL=(ALL)       ALL" >> /etc/sudoers.d/dmorris && \
	chmod 700 /home/dmorris/.ssh && \
	chown dmorris:dmorris /home/dmorris/.ssh/authorized_keys && \
	chmod 600 /home/dmorris/.ssh/authorized_keys
	
VOLUME /var/log/supervisor
EXPOSE 22

#RUN find /opt -iname "*.sh" | xargs chmod +x
#ENTRYPOINT ["/usr/bin/supervisord", "-n"]
##ENTRYPOINT /opt/start_sshd_service.sh
####RUN easy_install supervisor
###RUN chown root.root /etc/supervisord.conf
###RUN chown root.root /opt/start_sshd_service.sh