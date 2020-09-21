#!/bin/sh
### Name    : install-tomcat8.sh
### Author  : sohwaje
### Version : 1.0
### Date    : 2020-09-21
############################## Set variables ###################################
# Tomcat configuration
## 변수 설정
SOURCE_DIR="webapps"
CATALINA_HOME_NAME="apache-tomcat-8.5.50" # engine home dir
CATALINA_BASE_NAME="instance01" # instance home dir
TOMCAT_USER="sigongweb"
JDK="java-1.8.0-openjdk"
date_=$(date "+%Y%m%d%H%M%S")
server_xml="https://raw.githubusercontent.com/sohwaje/auto_install_tomcat8/master/server.xml"
############################## compress indicator ##############################
# usage: tar xvfz *.tar.gz | _extract
_extract()
{
  while read -r line; do
    x=$((x+1))
    echo -en "\e[1;36;40m [$x] extracted\r \e[0m"
  done
  echo -e "\e[1;33;40m Successfully extracted \e[0m"
}

################ if tomcat directory exist, backup tomcat directory ############
if_tomcat_dir()
{
  local list_=($(ls /home/$TOMCAT_USER))
  if [[ "${list_[@]}" =~ "$1" ]];then # "=~ 문자열 비교"
    echo "$1 directory does already exist. Backup $1"
    sudo mv /home/$TOMCAT_USER/$1 /home/$TOMCAT_USER/${1}-$date_
    # sudo mkdir -p /home/$TOMCAT_USER/$1
  else
    echo "$1 directory does not exist. Continue working"
  fi
}

############################## tomcat 엔진, 인스턴스 설치 ###########################
tomcat_user()
{
  cd /home/$TOMCAT_USER
  sudo wget https://archive.apache.org/dist/tomcat/tomcat-8/v8.5.50/bin/${CATALINA_HOME_NAME}.tar.gz >& /dev/null
  echo -en "\e[1;36;40m    Downloading.....\e[0m"
  sudo tar xvfz ${CATALINA_HOME_NAME}.tar.gz 2>&1 | _extract
  sudo cp -ar ${CATALINA_HOME_NAME} ${CATALINA_BASE_NAME} && sudo rm -f ${CATALINA_HOME_NAME}.tar.gz
  sudo mkdir -p /home/$TOMCAT_USER/${SOURCE_DIR}/${CATALINA_BASE_NAME}
}

################################ JDK install ###################################
if ! rpm -qa | grep ${JDK} > /dev/null
then
  echo -e "\e[0;33;47m ${JDK} was not found. Install JDK \e[0m"
  sudo yum install -y ${JDK}
else
  echo -e "\e[1;40m [${JDK} already installed] \e[0m"
fi
########################### Create a tomcat User and Group ######################
echo -e "\e[1;32;40m[1] Create a Tomcat User and Group \e[0m"
# Check tomcat group
GROUP=$(cat /etc/group | grep ${TOMCAT_USER} | awk -F ':' '{print $1}')
if [[ ${GROUP} != ${TOMCAT_USER} ]];then
  sudo groupadd ${TOMCAT_USER}
else
  echo -e "\e[1;33;40m [${TOMCAT_USER} group already exist] \e[0m"
fi
# Check tomcat user
ACCOUNT=$(cat /etc/passwd | grep ${TOMCAT_USER} | awk -F ':' '{print $1}')
if [[ ${ACCOUNT} != ${TOMCAT_USER} ]];then
  sudo useradd -g ${TOMCAT_USER} -s /usr/sbin/nologin/ ${TOMCAT_USER}
else
  echo -e "\e[1;33;40m [${TOMCAT_USER} user already exist] \e[0m"
fi
sleep 1

sudo chmod 755 /home/${TOMCAT_USER}

# if tomcat directory exist, backup tomcat directory and create tomcat directory
declare -a DIR
DIR=( "${CATALINA_BASE_NAME}" "${SOURCE_DIR}" "${CATALINA_HOME_NAME}" )
for i in "${DIR[@]}"
do
  if_tomcat_dir $i
done

################################## Install tomcat8 #############################
echo -e "\e[1;32;40m[2] Install tomcat8 \e[0m"
if [[ -d /home/${TOMCAT_USER} ]];then
  echo "/home/${TOMCAT_USER} directory does exist."
  tomcat_user
else
  echo -e "\e[0;31;47m /home/${TOMCAT_USER} directory does not exist. Create ${TOMCAT_USER} directory\e[0m"
  sudo mkdir -p /home/${TOMCAT_USER}
  tomcat_user
fi

sleep 1
echo -e "\e[1;32;40m Create gc directory \e[0m"
if [[ ! -d /home/$TOMCAT_USER/$CATALINA_BASE_NAME/logs/gclog ]];then
  sudo mkdir -p "/home/$TOMCAT_USER/$CATALINA_BASE_NAME/logs/gclog"
else
  echo -e "\e[0;31;47m /home/$TOMCAT_USER/$CATALINA_BASE_NAME/logs/gclog directory does exist\e[0m"
fi

# server.xml 복사
echo -e "\e[1;32;40m Copy server.xml \e[0m"
sudo rm -f "/home/$TOMCAT_USER/$CATALINA_BASE_NAME/conf/server.xml"
sudo wget -P \
  "/home/$TOMCAT_USER/$CATALINA_BASE_NAME/conf" ${server_xml} -q & >& /dev/null
########################### /conf/Catalina/localhost ###########################
if [[ ! -d /home/$TOMCAT_USER/${CATALINA_BASE_NAME}/conf/Catalina/localhost ]];then
  sudo mkdir -p "/home/$TOMCAT_USER/$CATALINA_BASE_NAME/conf/Catalina/localhost";
else
  echo -e "\e[0;31;47m /home/$TOMCAT_USER/$SOURCE_DIR/$CATALINA_BASE_NAME directory does exist. Bacup and recreate \e[0m"
  sudo mv "/home/$TOMCAT_USER/$CATALINA_BASE_NAME/conf/Catalina/localhost" \
  "/home/$TOMCAT_USER/$CATALINA_BASE_NAME/conf/Catalina/localhost-$date_"
fi

#######################/conf/Catalina/localhost/ROOT.xml########################
echo -e "\e[1;32;40m[3] Set DB \e[0m"
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
  <!-- 1. 소스 경로 -->
<Context path=\"\" docBase="\"/home/$TOMCAT_USER"/"$SOURCE_DIR"/"$CATALINA_BASE_NAME"\" reloadable=\"false\"
         privileged=\"true\" antiResourceLocking=\"false\" antiJARLocking=\"false\">
<!-- 2. DB 정보 -->
    <Resource name=\"jdbc/tomcat8MDS\" auth=\"Container\"
              type=\"javax.sql.DataSource\"
              driverClassName=\"com.mysql.jdbc.Driver\"
              validationQuery=\"SELECT 1\"
              validationInterval=\"30000\"
              url=\"jdbc:mysql://localhost:3306/tomcat8?useUnicode=true&amp;characterEncoding=UTF-8&amp;characterSetResults=UTF-8&amp;useSSL=true&amp;serverTimezone=Asia/Seoul\"
              username=\"tomcat\"
              password=\"tlrhdaleldj!@#\"
              maxActive=\"100\" maxIdle=\"50\" initialSize=\"30\" maxWait=\"-1\"/>
</Context>" | sudo tee -a "/home/$TOMCAT_USER/$CATALINA_BASE_NAME/conf/Catalina/localhost/ROOT.xml" > /dev/null

########################## Copy mysql-connector-java ###########################
if [[ ! -f /home/$TOMCAT_USER/$CATALINA_HOME_NAME/lib/mysql-connector-java ]];then
sudo curl -L "https://github.com/sohwaje/auto_install_tomcat8/raw/master/mysql-connector-java-8.0.21.jar?raw=true" \
-o "/home/$TOMCAT_USER/$CATALINA_HOME_NAME/lib/mysql-connector-java-8.0.21.jar"
else
  echo -e "\e[0;31;47m mysql-connector-java already exist \e[0m"
fi

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
export SERVER_NAME="gneerbank"
export JAVA_OPTS="$JAVA_OPTS -Dserver=gneerbank"
export JAVA_HOME="/etc/alternatives/jre_1.8.0_openjdk"
export LOG_HOME=$CATALINA_BASE/logs
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CATALINA_HOME/lib
# export SCOUTER_AGENT_DIR="/home/sigongweb/work/agent.java"

#[5] JVM Options : Memory
export JAVA_OPTS="$JAVA_OPTS -Xms4096m"
export JAVA_OPTS="$JAVA_OPTS -Xmx4096m"
export JAVA_OPTS="$JAVA_OPTS -XX:MetaspaceSize=256m -XX:MaxMetaspaceSize=256m"

#[6] G1 GC OPTIONS ###
export JAVA_OPTS="$JAVA_OPTS -XX:+UseG1GC"
export JAVA_OPTS="$JAVA_OPTS -Dfile.encoding=\"utf-8\""
export JAVA_OPTS="$JAVA_OPTS -XX:+UnlockDiagnosticVMOptions"
export JAVA_OPTS="$JAVA_OPTS -XX:+G1SummarizeConcMark"
export JAVA_OPTS="$JAVA_OPTS -XX:InitiatingHeapOccupancyPercent=45"

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
''' | sudo tee -a "/home/$TOMCAT_USER/$CATALINA_BASE_NAME/bin/setenv.sh" > /dev/null
sudo chmod +x "/home/$TOMCAT_USER/$CATALINA_BASE_NAME/bin/setenv.sh"

# Change permission tomcat Directory
sudo chown -R $TOMCAT_USER:$TOMCAT_USER /home/$TOMCAT_USER

# add systemctl tomcat service
sudo bash -c "cat << EOF > /etc/systemd/system/tomcat.service
[Unit]
Description=tomcat8
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

################################ tomcat start ##################################
start_tomcat()
{
  sudo systemctl daemon-reload && sudo systemctl start tomcat && sudo systemctl enable tomcat
}

start_tomcat
