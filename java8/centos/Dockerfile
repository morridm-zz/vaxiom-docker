FROM vaxiom/centos:latest
MAINTAINER David Morris, morridm@gmail.com

#VARIABLES
ENV JAVA_HEAP_SIZE 512
ENV JAVA_HOME /usr/java/jdk1.8.0_05
ENV PATH $PATH:$JAVA_HOME/bin

RUN yum update -y

#Install Java 1.8
RUN cd /opt/
RUN wget --no-verbose --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u5-b13/jdk-8u5-linux-x64.rpm"
RUN yum install -y jdk-8u5-linux-x64.rpm poppler-utils curl vim-enhanced perl memcached
RUN update-alternatives --install /usr/bin/java java /usr/java/jdk1.8*/bin/java 1065
RUN update-alternatives --install /usr/bin/javac javac /usr/java/jdk1.8*/bin/javac 1065
RUN update-alternatives --install /usr/bin/jar jar /usr/java/jdk1.8*/bin/jar 1065
RUN update-alternatives --install /usr/bin/javaws javaws /usr/java/jdk1.8*/bin/javaws 1065
RUN echo "JAVA_HOME=/usr/java/jdk1.8.0_05" >> /etc/environment
