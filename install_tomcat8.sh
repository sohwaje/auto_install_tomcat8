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
########################### Check user and group ###############################
# Color functions
end="\033[0m"
red="\033[0;31m"
green="\033[0;32m"
yellow="\033[0;33m"
blue="\033[0;34m"

function red {
  echo -e "${red}${1}${end}"
}

function green {
  echo -e "${green}${1}${end}"
}

function yellow {
  echo -e "${yellow}${1}${end}"
}

function blue {
  echo -e "${blue}${1}${end}"
}

install_success_fail()
{
  if [[ -z `sudo cat /home/$TOMCAT_USER/${CATALINA_BASE_NAME}/logs/catalina.out | grep -E "SQLException|failure"` ]];then
    green "[Installed]"
  else
    red "[Failed]"
    exit 9
  fi
}

ok_fail()
{
  if [[ $? -eq 0 ]];then
    blue "[OK]"
  else
    red "[Failed]"
  fi
}
check_group()
{
  if getent group "$1" >/dev/null 2>&1; then
    yellow "=====> [TOMCAT group already exist]"
  else
    yellow "=====> [Create TOMCAT group]"
    sudo groupadd $1
  fi
}
check_user()
{
  if getent passwd "$1" >/dev/null 2>&1; then
    yellow "=====> [TOMCAT user already exist]"
  else
    yellow "=====> [Create TOMCAT user]"
    sudo useradd -g $1 -s /usr/sbin/nologin/ $1
    sudo chmod 755 /home/$1
  fi
}
############################## compress indicator ##############################
# usage: tar xvfz *.tar.gz | _extract
_extract()
{
  while read -r line; do
    x=$((x+1))
    echo -en "\e[1;36;40m [$x] extracted\r \e[0m"
    sleep 0.05
  done
  yellow "=====> Successfully extracted"
}
################################### Check JDK ##################################
_jdk()
{
  if ! rpm -qa | grep $1 > /dev/null
  then
    yellow "$1 was not found. Install JDK"
    sudo yum install -y $1
  else
    yellow "[$1 already installed]"
  fi
}
################ if tomcat directory exist, backup tomcat directory ############
if_tomcat_dir()
{
  local list_=($(ls /home/$TOMCAT_USER))
  if [[ "${list_[@]}" =~ "$1" ]];then
    blue "=======> Check if a directory exists $1"
    for value in "${list_[@]}"
    do
      if [[ $value == $1 ]];then
        sudo mv /home/$TOMCAT_USER/$1 /home/$TOMCAT_USER/${1}-$date_
        yellow "$1 directory does already exist.     =====> Backup $1"
      fi
    done
  fi
}
############################ tomcat 엔진, 인스턴스 설치 ##########################
tomcat_user()
{
  cd /home/$TOMCAT_USER
  sudo wget https://archive.apache.org/dist/tomcat/tomcat-8/v8.5.50/bin/${CATALINA_HOME_NAME}.tar.gz >& /dev/null
  blue "Downloading and Extract"
  sleep 1
  sudo tar xvfz ${CATALINA_HOME_NAME}.tar.gz 2>&1 | _extract
  sudo cp -ar ${CATALINA_HOME_NAME} ${CATALINA_BASE_NAME} && sudo rm -f ${CATALINA_HOME_NAME}.tar.gz
  sudo mkdir -p /home/$TOMCAT_USER/${SOURCE_DIR}/${CATALINA_BASE_NAME}
  sudo mkdir -p /home/$TOMCAT_USER/${CATALINA_BASE_NAME}/logs/gclog
  sudo mkdir -p /home/$TOMCAT_USER/${CATALINA_BASE_NAME}/conf/Catalina/localhost
}
################################ tomcat start ##################################
start_tomcat()
{
  sudo systemctl daemon-reload && sudo systemctl start tomcat && sudo systemctl enable tomcat || red "[Failed]"
}
########################## Create a tomcat User and Group ######################
green "[1] Create a Tomcat User and Group"

check_group ${TOMCAT_USER}
check_user ${TOMCAT_USER}
################################ if_tomcat_dir() ###############################
green "[2] If tomcat directory exist, backup and recreate tomcat directory"

DIR=( "${CATALINA_BASE_NAME}" "${SOURCE_DIR}" "${CATALINA_HOME_NAME}" )
for i in "${DIR[@]}"
do
  if_tomcat_dir $i
done
echo ""
yellow "Completing the Task.  =====> Continue working."
echo ""
sleep 1
################################ JDK8 install ##################################
green "[2] Check JDK "

_jdk ${JDK}
########################### Create Tomcat_user dir #############################
green "[3] Create Tomcat_user dir"

if [[ -d /home/${TOMCAT_USER} ]];then
  yellow "[/home/${TOMCAT_USER} directory already exist.]"
  tomcat_user
else
  yellow "/home/${TOMCAT_USER} directory does not exist. Create ${TOMCAT_USER} directory"
  sudo mkdir -p /home/${TOMCAT_USER}
  tomcat_user
fi
########################## Copy mysql-connector-java ###########################
green "[4] Download mysql-connector-java"

if [[ ! -f /home/$TOMCAT_USER/$CATALINA_HOME_NAME/lib/mysql-connector-java ]];then
sudo curl -Ls "https://github.com/sohwaje/auto_install_tomcat8/raw/master/mysql-connector-java-8.0.21.jar?raw=true" \
-o "/home/$TOMCAT_USER/$CATALINA_HOME_NAME/lib/mysql-connector-java-8.0.21.jar"
else
  yellow "=====> mysql-connector-java already exist"
fi
# Copy server.xml in /home/$TOMCAT_USER/$CATALINA_BASE_NAME/conf/
green "[5] Copy server.xml"

sudo rm -f "/home/$TOMCAT_USER/$CATALINA_BASE_NAME/conf/server.xml"
sudo wget -P \
  "/home/$TOMCAT_USER/$CATALINA_BASE_NAME/conf" ${server_xml} -q & >& /dev/null | ok_fail
#######################/conf/Catalina/localhost/ROOT.xml########################
green "[6] Set DB "

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
</Context>" | sudo tee -a "/home/$TOMCAT_USER/$CATALINA_BASE_NAME/conf/Catalina/localhost/ROOT.xml" > /dev/null | ok_fail
# 톰캣 환경 변수 설정
green "[7] Set variables"

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
export SERVER_NAME="instance01"
export JAVA_OPTS="$JAVA_OPTS -Dserver=instance01"
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
''' | sudo tee -a "/home/$TOMCAT_USER/$CATALINA_BASE_NAME/bin/setenv.sh" > /dev/null | ok_fail
sudo chmod +x "/home/$TOMCAT_USER/$CATALINA_BASE_NAME/bin/setenv.sh"

# Change permission tomcat Directory
sudo chown -R $TOMCAT_USER:$TOMCAT_USER /home/$TOMCAT_USER

# add systemctl tomcat service
green "[8] Create Tomcat start script"

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
EOF" | ok_fail
# Create test index.jsp
# echo -e "\e[1;32;40m[9] Create test index.jsp \e[0m"
echo "TEST PAGE-$HOSTNAME" | sudo tee -a "/home/$TOMCAT_USER/$SOURCE_DIR/$CATALINA_BASE_NAME/index.jsp" > /dev/null

green "[9] Tomcat start....."

start_tomcat
sleep 3
install_success_fail
