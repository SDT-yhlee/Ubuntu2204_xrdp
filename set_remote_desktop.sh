#!/bin/bash

# Title : Ubuntu 22.04 Rdp 설정
# Author : 이윤호 (yhlee@sdt.inc)
# Date : 2026-01-24

# 색상 코드 (출력용)
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# xrdp, dbus-x11, ufw 패키지 설치
echo -e "${BLUE}<< Install xrdp, dbus-x11, ufw, xorgxrdp packages... >>${NC}"
sudo apt update && sudo apt install xrdp dbus-x11 ufw xorgxrdp -y

# xrdp 설정 파일 백업 생성
echo -e "${BLUE}<< Backup config files... /etc/xrdp/startwm.sh, /etc/xrdp/xrdp.ini >>${NC}"
sudo cp /etc/xrdp/startwm.sh /etc/xrdp/startwm.sh.bak
sudo cp /etc/xrdp/xrdp.ini /etc/xrdp/xrdp.ini.bak

# xrdp 설정 파일(/etc/xrdp/startwm.sh 에 설정 추가)
echo -e "${BLUE}<< Add some parameters to startwm.sh >>${NC}"
sudo sed -i '/properly./a\\nexport GNOME_SHELL_SESSION_MODE=ubuntu\nexport XDG_CURRENT_DESKTOP=ubuntu:GNOME\nexport LANG=en_US.UTF-8' /etc/xrdp/startwm.sh
sudo sed -i '/test -x/i\unset DBUS_SESSION_BUS_ADDRESS\nunset XDG_RUNTIME_DIR\n' /etc/xrdp/startwm.sh

# xrdp tcp send 버퍼 크기 수정
echo -e "${BLUE}<< Set tcp send buffer size = 1MB >>${NC}"
sudo sed -i '/tcp_send_buffer_bytes/a tcp_send_buffer_bytes=1048576' /etc/xrdp/xrdp.ini

# xrdp 계정을 특정 그룹에 추가(adm, vboxusers(존재한다면), ${USER}, ssl-cert)
echo -e "${BLUE}<< Add xrdp account to adm group. >>${NC}"
sudo usermod -aG adm xrdp
echo -e "${BLUE}<< Add xrdp account to ${USER} group. >>${NC}"
sudo usermod -aG ${USER} xrdp
echo -e "${BLUE}<< Add xrdp account to ssl-cert group. >>${NC}"
sudo usermod -aG ssl-cert xrdp
if id "vboxusers" &>/dev/null; then
    echo -e "${BLUE}<< Add xrdp account to vboxusers group. >>${NC}"
    sudo usermod -aG vboxusers xrdp
else
    echo "No user name with vboxusers."
fi

# 방화벽 3389 포트 해제 (원격 프로그램 포트)
echo -e "${BLUE}<< Allow 3389 port for RDP. >>${NC}"
sudo ufw allow from any to any port 3389

# SSH 포트 해제
echo -e "${BLUE}<< Allow 22 port for SSH. >>${NC}"
sudo ufw allow 22/tcp

# xrdp 시작 및 시작프로그램 등록
echo -e "${BLUE}<< Register xrdp service and restart xrdp service. >>${NC}"
sudo systemctl enable xrdp
sudo systemctl restart xrdp

#dbus 실행
echo -e "${BLUE}<< Run dbus-launch. >>${NC}"
dbus-launch

# Snap 버전 firefox 제거 및 apt 버전 firefox 브라우저 설치
echo -e "${BLUE}<< Remove snap ver. Firefox Browser >>${NC}"
sudo snap remove firefox
sudo apt autoremove firefox --purge -y

# ipv6 네트워크 우선순위 낮추기
sudo sed -i 's/^#\s*precedence ::ffff:0:0\/96\s*100/precedence ::ffff:0:0\/96  100/' /etc/gai.conf

echo -e "${BLUE}<< Add Mozilla Team PPA repository >> ${NC}"
sudo add-apt-repository ppa:mozillateam/ppa -y
# sudo apt update

# Mozilla PPA 우선순위 설정
echo '
Package: *
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 900
' | sudo tee /etc/apt/preferences.d/mozilla

# apt 버전 파이어폭스 설치
echo -e "${BLUE}<< Install Apt ver. Firefox Browser >> ${NC}"
sudo apt update
sudo apt install firefox -y