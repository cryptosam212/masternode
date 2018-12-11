#!/bin/bash

CONFIGFOLDER='/root/.galilel'
COIN_DAEMON='galileld'
COIN_CLI='galilel-cli'
COIN_PATH='/usr/local/bin/'
COIN_NAME='galilel'

NODEIP=$(curl -s4 icanhazip.com)

BLUE="\033[0;34m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
PURPLE="\033[0;35m"
RED='\033[0;31m'
GREEN="\033[0;32m"
NC='\033[0m'
MAG='\e[1;35m'

purgeOldInstallation() {
    echo -e "${GREEN}Searching and removing old $COIN_NAME files and configurations${NC}"
systemctl disable $COIN_NAME.service > /dev/null 2>&1
systemctl stop $COIN_NAME.service > /dev/null 2>&1
$COIN_CLI stop > /dev/null 2>&1
killall -9 $COIN_DAEMON
echo -e "kill galileld"

sleep 15

PROCESSCOUNT=$(ps -ef |grep -v grep |grep -cw $COIN_DAEMON )
if [ $PROCESSCOUNT -eq 0 ]
then
echo "ok"
else
{
echo "kill $COIN_DAEMON"
killall -9 $COIN_DAEMON > /dev/null 2>&1
}
fi
sleep 10

PROCESSCOUNT=$(ps -ef |grep -v grep |grep -cw $COIN_DAEMON )
if [ $PROCESSCOUNT -eq 0 ]
then
echo "Daemon stop, OK"
else
{
echo -e "try manual kill or stop galileld"
exit 1
}
fi


 #   cd /usr/local/bin && sudo rm galilel-cli galilel-tx galileld > /dev/null 2>&1 && cd
    echo -e "${GREEN}* Done${NONE}";
}
function download_node() {
  echo -e "${GREEN}Start upgrade $COIN_NAME Daemon${NC}"
echo -e "${NC}download new wallet"
# wget https://github.com/Galilel-Project/galilel/releases/download/v3.0.0/galilel-v3.0.0-lin64.tar.gz >/dev/null 2>&1
wget -c https://github.com/Galilel-Project/galilel/releases/download/v3.1.0/galilel-v3.1.0-lin64.tar.gz >/dev/null 2>&1
  compile_error
  tar -xvzf galilel-v3.1.0-lin64.tar.gz >/dev/null 2>&1

cd /root/galilel-v3.1.0-lin64/usr/bin/ >/dev/null 2>&1
chmod +x $COIN_DAEMON $COIN_CLI >/dev/null 2>&1

echo -e "copy new wallet to usr/local/bin"
  cp -r -p $COIN_DAEMON $COIN_CLI $COIN_PATH >/dev/null 2>&1
  cd  >/dev/null 2>&1
 rm -r galilel-v3.1.0-lin64* >/dev/null 2>&1

echo -e "Delete unused file and replace with new file"
cd $CONFIGFOLDER >/dev/null 2>&1
rm -r blocks
rm -r chainstate
rm -r sporks
rm -r zerocoin
rm -r backups
rm -r .lock
rm  budget.dat
rm  fee_estimates.dat
rm  mnpayments.dat
rm  mncache.dat
rm  peers.dat
rm db.log
rm debug.log

#cp -r -p wallet.dat backupwallet.bak >/dev/null 2>&1
#wget -c https://galilel.cloud/bootstrap-latest.tar.gz >/dev/null 2>&1
wget --load-cookies /tmp/cookies.txt "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate 'https://docs.google.com/uc?export=download&id=1A57xlrRk56vvdsFpN4qRiZNgYTPCe9mP' -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=1A57xlrRk56vvdsFpN4qRiZNgYTPCe9mP" -O galilel-286199.zip && rm -rf /tmp/cookies.txt >/dev/null 2>&1
unzip galilel-286199.zip >/dev/null 2>&1
compile_error
rm -r galilel-286199.zip >/dev/null 2>&1
echo -e "run daemon"
sytemctl enable galilel >/dev/null 2>&1
systemctl start galilel >/dev/null 2>&1
sleep 5
PROCESSCOUNT=$(ps -ef |grep -v grep |grep -cw $COIN_DAEMON )
if [ $PROCESSCOUNT -eq 0 ]
then
echo "start $COIN_DAEMON"
$COIN_DAEMON -daemon
fi

 echo -e "${BLUE}============================================================================================================================${NC}"
 echo -e "${YELLOW}UPGRADE COMPLETED ${NC}"
 echo -e ""
 echo -e "${BLUE}=============================================================================================================================${NC}"

}
function compile_error() {
if [ "$?" -gt "0" ];
 then
  echo -e "${RED}Failed to download new wallet.${NC}"
  exit 1
fi
}



##### Main #####
clear

purgeOldInstallation
download_node
