FROM vaxiom/AXIOJAVA8:latest
MAINTAINER David Morris, morridm@gmail.com

#VARIABLES
ENV TOMCAT_VERSION 7.0.53
ENV CATALINA_HOME /opt/tomcat7
ENV JAVA_HEAP_SIZE 512
ENV JAVA_HOME /usr/java/jdk1.8.0_05
ENV PATH $PATH:$CATALINA_HOME/bin
ENV PATH $PATH:$JAVA_HOME/bin

RUN yum update -y

#Install Tomcat 7.0.53
RUN wget --no-verbose http://archive.apache.org/dist/tomcat/tomcat-7/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz -O /tmp/tomcat.tar.gz
RUN tar -xzvf /tmp/tomcat.tar.gz -C /opt
RUN ln -s /opt/apache-tomcat-${TOMCAT_VERSION} /opt/tomcat7
RUN rm -f /tmp/tomcat.tar.gz
RUN mkdir /usr/share/tomcat7

# Add roles and security
RUN sed -i "s#</tomcat-users>##g" /opt/apache-tomcat-${TOMCAT_VERSION}/conf/tomcat-users.xml; \
        echo '  <role rolename="manager-gui"/>' >>  /opt/apache-tomcat-${TOMCAT_VERSION}/conf/tomcat-users.xml; \
        echo '  <role rolename="manager-script"/>' >>  /opt/apache-tomcat-${TOMCAT_VERSION}/conf/tomcat-users.xml; \
        echo '  <role rolename="manager-jmx"/>' >>  /opt/apache-tomcat-${TOMCAT_VERSION}/conf/tomcat-users.xml; \
        echo '  <role rolename="manager-status"/>' >>  /opt/apache-tomcat-${TOMCAT_VERSION}/conf/tomcat-users.xml; \
        echo '  <role rolename="admin-gui"/>' >>  /opt/apache-tomcat-${TOMCAT_VERSION}/conf/tomcat-users.xml; \
        echo '  <role rolename="admin-script"/>' >>  /opt/apache-tomcat-${TOMCAT_VERSION}/conf/tomcat-users.xml; \
        echo '  <user username="jenkins" password="ChAngeThis1" roles="manager-gui, manager-script, manager-jmx, manager-status, admin-gui, admin-script"/>' >> /opt/apache-tomcat-${TOMCAT_VERSION}/conf/tomcat-users.xml; \
        echo '</tomcat-users>' >> /opt/apache-tomcat-${TOMCAT_VERSION}/conf/tomcat-users.xml

RUN echo '#!/bin/bash' > /etc/init.d/tomcat7; \
        echo '# description: Tomcat Start Stop Restart' >> /etc/init.d/tomcat7; \
        echo '# processname: tomcat' >> /etc/init.d/tomcat7; \
        echo '# chkconfig: 234 20 80' >> /etc/init.d/tomcat7; \
        echo 'JAVA_HOME=/usr/java/jdk1.8.0_05' >> /etc/init.d/tomcat7; \
        echo 'export JAVA_HOME' >> /etc/init.d/tomcat7; \
        echo 'PATH=$PATH' >> /etc/init.d/tomcat7; \
        echo 'export PATH' >> /etc/init.d/tomcat7; \
        echo 'CATALINA_HOME=/opt/tomcat7' >> /etc/init.d/tomcat7; \
        echo '' >> /etc/init.d/tomcat7; \
        echo 'case $1 in' >> /etc/init.d/tomcat7; \
        echo 'start)' >> /etc/init.d/tomcat7; \
        echo 'sh $CATALINA_HOME/bin/startup.sh' >> /etc/init.d/tomcat7; \
        echo ';; ' >> /etc/init.d/tomcat7; \
        echo 'stop)' >> /etc/init.d/tomcat7; \
        echo 'sh $CATALINA_HOME/bin/shutdown.sh' >> /etc/init.d/tomcat7; \
        echo ';; ' >> /etc/init.d/tomcat7; \
        echo 'restart)' >> /etc/init.d/tomcat7; \
        echo 'sh $CATALINA_HOME/bin/shutdown.sh' >> /etc/init.d/tomcat7; \
        echo 'sh $CATALINA_HOME/bin/startup.sh' >> /etc/init.d/tomcat7; \
        echo ';; ' >> /etc/init.d/tomcat7; \
        echo 'esac' >> /etc/init.d/tomcat7; \
        echo 'exit 0' >> /etc/init.d/tomcat7

## Configure https
RUN sed -i "s#</Server>##g" /opt/apache-tomcat-${TOMCAT_VERSION}/conf/server.xml; \
        sed -i "s#  </Service>##g" /opt/apache-tomcat-${TOMCAT_VERSION}/conf/server.xml; \
        echo '<Connector port="443" protocol="HTTP/1.1" SSLEnabled="true" maxThreads="150" scheme="https" secure="true" clientAuth="false" sslProtocol="TLS" keyAlias="tomcat7" keyPass="ChAngeThis1" keystoreFile="/usr/share/tomcat7/.keystore" keystorePass="ChAngeThis1" />' >> /opt/apache-tomcat-${TOMCAT_VERSION}/conf/server.xml; \
        echo '  </Service>' >> /opt/apache-tomcat-${TOMCAT_VERSION}/conf/server.xml; \
        echo '</Server>' >> /opt/apache-tomcat-${TOMCAT_VERSION}/conf/server.xml

RUN chown -R daemon /opt/apache-tomcat-${TOMCAT_VERSION}/
RUN chown -R daemon /opt/tomcat7/
RUN chown -R daemon /usr/share/tomcat7/
RUN chown daemon /etc/init.d/tomcat7
RUN chmod 755 /etc/init.d/tomcat7
RUN chkconfig --add tomcat7
RUN chkconfig --level 234 tomcat7 on
RUN chkconfig --list tomcat7
RUN keytool -genkey -keyalg RSA -alias tomcat7 -keypass ChAngeThis1 -storepass ChAngeThis1 -dname "CN=dmo, OU=IT, O=Little Rock, L=Arkansas, ST=AR, C=USA" -keystore /usr/share/tomcat7/.keystore
RUN touch /etc/sysconfig/network

ADD src/launch_tomcat.sh /opt/launch_tomcat.sh
RUN chmod +x /opt/launch_tomcat.sh
RUN chmod +x /opt/tomcat7/bin/startup.sh
RUN chmod +x /opt/tomcat7/bin/shutdown.sh

EXPOSE 80 8080 8005 8443 443
##EXPOSE 80 443 3306 4444 4567 4568 27017 27018 27019 28017

###CMD service tomcat7 start && tail -F /opt/tomcat7/logs/*

ENTRYPOINT /opt/launch_tomcat.sh
