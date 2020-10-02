FROM tomcat:8.5-jre8

MAINTAINER Sohwaje <sohwaje@gmail.com>

RUN rm -rf /usr/local/tomcat/webapps/ROOT

RUN mkdir /usr/local/tomcat/logs/gclog

ADD webapps/sample.war /usr/local/tomcat/webapps/ROOT.war

ADD conf/setenv.sh /usr/local/tomcat/bin

ADD conf/server.xml /usr/local/tomcat/conf

ADD conf/ROOT.xml /usr/local/tomcat/conf/Catalina/localhost

ADD conf/tomcat-users.xml /usr/local/tomcat/conf

ADD lib/mysql-connector-java-8.0.21.jar /usr/local/tomcat/lib

ADD lib/tomcat-extensions.jar /usr/local/tomcat/lib

RUN chmod +x /usr/local/tomcat/bin/setenv.sh

CMD ["catalina.sh", "run"]
