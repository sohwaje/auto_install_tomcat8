# Tomcat8 자동 설치

## [1] 사용 방법
```
git clone https://github.com/sohwaje/auto_install_tomcat8.git
cd auto_install_tomcat8
chmod +x install_tomcat8.sh
./install_tomcat8.sh
```
## [2] 환경 설정 수정 부분
> 자신의 서비스에 알맞게 다음 부분을 수정하여 사용할 수 있음.

### install_tomcat8.sh
- SOURCE_DIR=""
- TOMCAT_USER=""
- CATALINA_BASE_NAME=""

### server.xml
- 각 서비스 포트를 변수처리하였음.

### setenv.sh
- server.xml에서 변수처리 된 포트를 지정할 수 있음.
- 그 밖에 JVM 옵션, JAVA 옵션을 설정할 수 있음.

## [3] 설치 화면
![alt text](/readme-img/install.JPG)
