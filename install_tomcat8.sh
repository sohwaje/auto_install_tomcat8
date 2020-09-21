#!/bin/sh
### Name    : install-tomcat8.sh
### Author  : sohwaje
### Version : 1.0
### Date    : 2020-09-21
############################## Set variables ###################################
# Tomcat configuration
## 변수 설정
SOURCE_DIR="webapps"
CATALINA_HOME_NAME="apache-tomcat-7.0.90" # engine home dir
CATALINA_BASE_NAME="gneerbank" # instance home dir
TOMCAT_USER="sigongweb"
JDK=("java-1.8.0-openjdk" "java-1.8.0-openjdk-devel")

############################## compress indicator ##############################
# usage: tar xvfz *.tar.gz | _extract
_extract(){
  while read -r line; do
    x=$((x+1))
    echo -en "\e[1;36;40m [$x] extracted\r \e[0m"
  done
  echo -e "\e[1;33;40m Successfully extracted \e[0m"
}

# JDK install
if ! rpm -qa | grep ${JDK[0]} || rpm -qa | grep ${JDK[1]} > /dev/null;then
  echo -e "\e[0;33;47m JDK was not found. Install JDK \e[0m"
  sudo yum install -y ${JDK[@]}
else
  echo -e "\e[1;40m [JDK already installed] \e[0m"
fi

########################### Create a tomcat User and Group ######################
echo -e "\e[1;32;40m[1] Create a mysql User and Group \e[0m"
# Check tomcat group
GROUP=`cat /etc/group | grep $TOMCAT_USER | awk -F ':' '{print $1}'`
if [[ $GROUP != $TOMCAT_USER ]];then
  sudo groupadd $TOMCAT_USER
else
  echo -e "\e[1;33;40m [$TOMCAT_USER group already exits] \e[0m"
fi
# Check tomcat user
ACCOUNT=`cat /etc/passwd | grep $MYSQL_USER | awk -F ':' '{print $1}'`
if [[ $ACCOUNT != $MYSQL_USER ]];then
  sudo useradd -g $TOMCAT_USER -s /usr/sbin/nologin/ $TOMCAT_USER
else
  echo -e "\e[1;33;40m [$TOMCAT_USER user already exits] \e[0m"
fi

################################## Install tomcat8 #############################
if [[ -d "/home/$TOMCAT_USER" ]];then
cd /home/$TOMCAT_USER; \
sudo wget https://archive.apache.org/dist/tomcat/tomcat-8/v8.5.38/bin/$CATALINA_HOME_NAME.tar.gz; \
 sudo tar xvfz "$CATALINA_HOME_NAME".tar.gz | _extrac; \
 sudo cp -ar "$CATALINA_HOME_NAME" "$CATALINA_BASE_NAME"; \
 sudo rm -f "$CATALINA_HOME_NAME".tar.gz
else
  echo -e "\e[0;31;47m /home/$TOMCAT_USER directory does not exits\e[0m"
  exit 9
fi

# gclog 디렉토리 생성
if [[ ! -d "/home/$TOMCAT_USER/$CATALINA_BASE_NAME/logs/gclog" ]];then
  sudo mkdir -p "/home/$TOMCAT_USER/$CATALINA_BASE_NAME/logs/gclog"
else
  echo -e "\e[0;31;47m /home/$TOMCAT_USER/$CATALINA_BASE_NAME/logs/gclog directory cannot create\e[0m"
  exit 9
fi

# server.xml 복사
sudo rm -f "/home/$TOMCAT_USER/$CATALINA_BASE_NAME/conf/server.xml"
sudo wget -P \
  "/home/$TOMCAT_USER/$CATALINA_BASE_NAME/conf" https://raw.githubusercontent.com/sohwaje/auto_install_tomcat8/master/server.xml

# tomcat database 설정
sudo mkdir -p "/home/$TOMCAT_USER/$SOURCE_DIR/$CATALINA_BASE_NAME"; \
 sudo mkdir -p "/home/$TOMCAT_USER/$CATALINA_BASE_NAME/conf/Catalina/localhost"; \
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
  <!-- 1. 소스 경로 -->
<Context path=\"\" docBase="\"/home/$TOMCAT_USER"/"$SOURCE_DIR"/"$CATALINA_BASE_NAME"\" reloadable=\"false\"
         privileged=\"true\" antiResourceLocking=\"false\" antiJARLocking=\"false\">
<!-- 2. DB 정보 -->
    <Resource name=\"jdbc/elLetterMDS\" auth=\"Container\"
              type=\"javax.sql.DataSource\"
              driverClassName=\"com.mysql.jdbc.Driver\"
              validationQuery=\"SELECT 1\"
              validationInterval=\"30000\"
              url=\"jdbc:mysql://10.1.3.4:3306/hiclass_stage_db?useUnicode=true&amp;characterEncoding=UTF-8&amp;characterSetResults=UTF-8&amp;useSSL=true&amp;serverTimezone=Asia/Seoul\"
              username=\"class_user_stage\"
              password=\"class@1904\"
              maxActive=\"100\" maxIdle=\"50\" initialSize=\"30\" maxWait=\"-1\"/>
</Context>" | sudo tee -a "/home/$TOMCAT_USER/$CATALINA_BASE_NAME/conf/Catalina/localhost/ROOT.xml"

# mysql-connector 복사
sudo curl -L "https://github.com/sohwaje/ncloud_terraform/blob/master/mysql-connector-java-8.0.21.jar?raw=true" -o "/home/$TOMCAT_USER/$CATALINA_HOME_NAME/lib/mysql-connector-java-8.0.21.jar"


# 톰캣 환경 변수 설정
sudo bash -c "echo 'export CATALINA_BASE=/home/$TOMCAT_USER/$CATALINA_BASE_NAME' >> /home/$TOMCAT_USER/$CATALINA_BASE_NAME/bin/setenv.sh"
sudo bash -c "echo 'export CATALINA_HOME=/home/$TOMCAT_USER/$CATALINA_HOME_NAME' >> /home/$TOMCAT_USER/$CATALINA_BASE_NAME/bin/setenv.sh"
echo '''export DATE=`date +%Y%m%d%H%M%S`
#[2] TOMCAT Port & values
# Tomcat Port 설정
export PORT_OFFSET=0
export HTTP_PORT=$(expr 8080 + $PORT_OFFSET)
export AJP_PORT=$(expr 8009 + $PORT_OFFSET)
export SSL_PORT=$(expr 8443 + $PORT_OFFSET)
export SHUTDOWN_PORT=$(expr 8005 + $PORT_OFFSET)

# Tomcat Threads 설정
export JAVA_OPTS="$JAVA_OPTS -DmaxThreads=300"
export JAVA_OPTS="$JAVA_OPTS -DminSpareThreads=50"
export JAVA_OPTS="$JAVA_OPTS -DacceptCount=10"
export JAVA_OPTS="$JAVA_OPTS -DmaxKeepAliveRequests=-1"
export JAVA_OPTS="$JAVA_OPTS -DconnectionTimeout=30000"

#[4] Directory Setup #####
export SERVER_NAME=gneerbank
export JAVA_OPTS="$JAVA_OPTS -Dserver=gneerbank"
export JAVA_HOME="/etc/alternatives/jre_1.8.0_openjdk"
export LOG_HOME=$CATALINA_BASE/logs
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CATALINA_HOME/lib
# export SCOUTER_AGENT_DIR="/home/sigongweb/work/agent.java"

#[5] JVM Options : Memory
export JAVA_OPTS="$JAVA_OPTS -Xms4096m"
export JAVA_OPTS="$JAVA_OPTS -Xmx4096m"
export JAVA_OPTS="$JAVA_OPTS -XX:MetaspaceSize=256m -XX:MaxMetaspaceSize=256m"
export JAVA_OPTS="$JAVA_OPTS -Xss512k"

#[6] G1 GC OPTIONS ###
export JAVA_OPTS="$JAVA_OPTS -XX:+UseG1GC "
export JAVA_OPTS="$JAVA_OPTS -Dfile.encoding=\"utf-8\""
export JAVA_OPTS="JAVA_OPTS -XX:+UnlockDiagnosticVMOptions"
export JAVA_OPTS="JAVA_OPTS -XX:+InitiatingHeapOccupancyPercent=35"

#[7] JVM Option GCi log, Stack Trace, Dump
export JAVA_OPTS="$JAVA_OPTS -verbose:gc"
export JAVA_OPTS="$JAVA_OPTS -XX:+PrintGCTimeStamps"
export JAVA_OPTS="$JAVA_OPTS -XX:+PrintGCDetails "
export JAVA_OPTS="$JAVA_OPTS -Xloggc:$LOG_HOME/gclog/gc_$DATE.log"
export JAVA_OPTS="$JAVA_OPTS -XX:+HeapDumpOnOutOfMemoryError"
export JAVA_OPTS="$JAVA_OPTS -XX:HeapDumpPath=$LOG_HOME/gclog/java_pid.hprof"
export JAVA_OPTS="$JAVA_OPTS -XX:+DisableExplicitGC"
export JAVA_OPTS="$JAVA_OPTS -Djava.security.egd=file:/dev/./urandom"
export JAVA_OPTS="$JAVA_OPTS -Djava.awt.headless=true"
export JAVA_OPTS="$JAVA_OPTS -Djava.net.preferIPv4Stack=true"

export JAVA_OPTS="$JAVA_OPTS -Dhttp.port=$HTTP_PORT"
export JAVA_OPTS="$JAVA_OPTS -Dajp.port=$AJP_PORT"
export JAVA_OPTS="$JAVA_OPTS -Dssl.port=$SSL_PORT"
export JAVA_OPTS="$JAVA_OPTS -Dshutdown.port=$SHUTDOWN_PORT"
export JAVA_OPTS="$JAVA_OPTS -Djava.library.path=$CATALINA_HOME/lib/"
export JAVA_OPTS
echo "================================================"
echo "JAVA_HOME=$JAVA_HOME"
echo "CATALINA_HOME=$CATALINA_HOME"
echo "SERVER_HOME=$CATALINA_BASE"
echo "HTTP_PORT=$HTTP_PORT"
echo "SSL_PORT=$SSL_PORT"
echo "AJP_PORT=$AJP_PORT"
echo "SHUTDOWN_PORT=$SHUTDOWN_PORT"
echo "================================================"
''' | sudo tee -a "/home/$TOMCAT_USER/$CATALINA_BASE_NAME/bin/setenv.sh"
sudo chmod +x "/home/$TOMCAT_USER/$CATALINA_BASE_NAME/bin/setenv.sh"

# Change permission tomcat Directory
sudo chown -R $TOMCAT_USER:$TOMCAT_USER /home/$TOMCAT_USER

# add systemctl tomcat service
sudo bash -c "cat << EOF > /etc/systemd/system/tomcat.service
[Unit]
Description=tomcat7
After=network.target syslog.target

[Service]
Type=forking
User=$TOMCAT_USER
Group=$TOMCAT_USER
ExecStart=/home/$TOMCAT_USER/$CATALINA_BASE_NAME/bin/startup.sh
ExecStop=/home/$TOMCAT_USER/$CATALINA_BASE_NAME/bin/shutdown.sh

[Install]
WantedBy=multi-user.target
EOF"

# Create test index.jsp
echo "TEST PAGE-$HOSTNAME" | sudo tee -a "/home/$TOMCAT_USER/$SOURCE_DIR/$CATALINA_BASE_NAME/index.jsp"

# tomcat start
sudo systemctl daemon-reload && sudo systemctl start tomcat && sudo systemctl enable tomcat
