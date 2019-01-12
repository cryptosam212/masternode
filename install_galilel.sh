#!/bin/bash

TMP_FOLDER=$(mktemp -d)
CONFIG_FILE='galilel.conf'
CONFIGFOLDER='/root/.galilel'
COIN_DAEMON='galileld'
COIN_CLI='galilel-cli'
COIN_PATH='/usr/local/bin/'
COIN_NAME='galilel'
COIN_NAMECEK='galilel'
COIN_PORT=36001
WALLET_VER='3010000'
#RPC_PORT=36002
COIN_NAME1='GALILEL'
MNCOUNT=0
NODEIP=$(curl -s4 icanhazip.com)
ALIASES="$(find /root/.galilel* -maxdepth 0 -type d | wc -l)"
BLUE="\033[0;34m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m" 
PURPLE="\033[0;35m"
RED="\033[0;31m"
GREEN="\033[0;32m"
NC='\033[0m'
MAG='\e[1;35m'

purgeOldInstallation() {
    echo -e "${GREEN}Searching and removing old $COIN_NAME files and configurations${NC}"
        if [ -d "$CONFIGFOLDER" ]; then
    echo -e "${RED} ERROR : $COIN_NAME already installed${NC}";
    exit 1
    fi
}

function download_node() 
{
cd $COIN_PATH >/dev/null 2>&1
#if [ ! -f $COIN_DAEMON ]
#then
  echo -e "${GREEN}Downloading and Installing Wallet $WALLET_VER for $COIN_NAME Daemon${NC}"

#cd /usr/local/bin >/dev/null 2>&1
#rm -r galilel*
 
 cd /root/ >/dev/null 2>&1

wget -c https://github.com/Galilel-Project/galilel/releases/download/v3.1.0/galilel-v3.1.0-lin64.tar.gz >/dev/null 2>&1
  compile_error
  tar -xvzf galilel-v3.1.0-lin64.tar.gz >/dev/null 2>&1

cd /root/galilel-v3.1.0-lin64/usr/bin/ >/dev/null 2>&1
chmod +x $COIN_DAEMON $COIN_CLI >/dev/null 2>&1

  cp -r -p $COIN_DAEMON $COIN_CLI $COIN_PATH
  cd  >/dev/null 2>&1
  rm -R galilel-v3.1.0-lin64* >/dev/null 2>&1
  echo -e "$COIN_NAME Wallet $WALLET_VER installed"
#fi
}

function configure_systemd() 
{
  cat << EOF > /etc/systemd/system/$COIN_NAME.service
[Unit]
Description=$COIN_NAME service
After=network.target

[Service]
User=root
Group=root

Type=forking
#PIDFile=$CONFIGFOLDER/$COIN_NAME.pid

ExecStart=$COIN_PATH$COIN_DAEMON -daemon -conf=$CONFIGFOLDER/$CONFIG_FILE -datadir=$CONFIGFOLDER
ExecStop=-$COIN_PATH$COIN_CLI -conf=$CONFIGFOLDER/$CONFIG_FILE -datadir=$CONFIGFOLDER stop

Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  sleep 3
  systemctl enable $COIN_NAME.service >/dev/null 2>&1
  systemctl restart $COIN_NAME.service >/dev/null 2>&1

  if [[ -z "$(ps axo cmd:100 | egrep $COIN_DAEMON)" ]]; then
    echo -e "${RED}$COIN_NAME is not running${NC}, please investigate. You should start by running the following commands as root:"
    echo -e "${GREEN}systemctl start $COIN_NAME.service"
    echo -e "systemctl status $COIN_NAME.service"
    echo -e "less /var/log/syslog${NC}"
    exit 1
  fi
}

function snapshot_sync() 
{
if [ ! -f bootstrap-latest.tar.gz ]
then
echo -e "Setup snapshot bootstrap, please wait untill finished"
cd  >/dev/null 2>&1
wget -c https://galilel.cloud/bootstrap-latest.tar.gz >/dev/null 2>&1
echo -e "bootstrap successful downloaded"
fi
}

function stop_daemon()
{
echo "Stop daemon $COIN_NAME"
systemctl stop $COIN_NAME.service >/dev/null 2>&1
sleep 5
$COIN_CLI -datadir=$CONFIGFOLDER stop
}
function delete_lama()
{
echo -e "Delete unused old files"
cd $CONFIGFOLDER >/dev/null 2>&1
rm -r blocks
rm -r chainstate
rm -r sporks
rm -r zerocoin
rm -r backups
rm -r .lock
rm budget.dat
rm fee_estimates.dat
rm mnpayments.dat
rm mncache.dat
rm peers.dat
rm db.log
rm debug.log

echo "Replace addnode to $COIN_NAME official addnode to $CONFIG_FILE"
sed -i "/\b\(addnode\)\b/d" $CONFIG_FILE

cat << EOF >> $CONFIG_FILE
addnode=seed1.galilel.cloud
addnode=seed2.galilel.cloud
addnode=seed3.galilel.cloud
addnode=seed4.galilel.cloud
addnode=seed5.galilel.cloud
addnode=seed6.galilel.cloud
addnode=seed7.galilel.cloud
addnode=seed8.galilel.cloud
EOF
}

function snapshot_syncmn() 
{
echo -e "copy snapshot to $CONFIGFOLDER"
cd  >/dev/null 2>&1
tar xvzf bootstrap-latest.tar.gz -C $CONFIGFOLDER  >/dev/null 2>&1
echo -e "bootstrap successful downloaded"
}

function create_config() 
{
  mkdir $CONFIGFOLDER >/dev/null 2>&1
  RPCUSER=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w10 | head -n1)
  RPCPASSWORD=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w22 | head -n1)
  cat << EOF > $CONFIGFOLDER/$CONFIG_FILE
rpcuser=$RPCUSER
rpcpassword=$RPCPASSWORD
rpcport=$RPC_PORT
rpcallowip=127.0.0.1
listen=0
EOF
}

YELLOWMENU='${YELLOW}'
NCMENU='${NC}'
CYANMENU='${CYAN}'
OPTMENU='${options[@]}'
REPLYMENU='$REPLY'
optMENU='$opt'
function create_menu(){
echo -e "Create Menu  for ${MENU_NAME}"
cd >/dev/null 2>&1
  cat << EOF > $MENUNYA
#!/bin/bash

YELLOW="\033[0;33m"
CYAN="\033[0;36m"
NC='\033[0m'

clear
echo -e "${YELLOWMENU} ${MENU_NAME} Masternode Menu ${NCMENU}"
echo -e "${CYANMENU}=============================================== ${NCMENU}"
echo ""
PS3='Please enter number of your choice for ${MENU_NAME} (enter to show menu) : '
options=("start" "stop" "getinfo" "edit config" "mnsync status" "masternode status" "Quit")
select opt in "$OPTMENU"
do
    case $optMENU in
        "start")
         systemctl start ${COIN_NAME}
         echo -e "${YELLOWMENU}starting node ${MENU_NAME} ${NCMENU}";
         sleep 3
        echo "";
            ;;
        "stop")
         systemctl stop ${COIN_NAME}
         echo -e "${YELLOWMENU}stopping node ${MENU_NAME} ${NCMENU}";
         sleep 3
        echo "";
            ;;
        "getinfo")
        echo -e "${YELLOWMENU}INFO ${MENU_NAME}: ${NCMENU}";
        ${COIN_CLI} -datadir=${CONFIGFOLDER} getinfo
        echo "";
            ;;
         "edit config")
        nano ${CONFIGFOLDER}/${CONFIG_FILE}
        echo "";
            ;;
         "mnsync status")
        echo -e "${YELLOWMENU}mnsync status ${MENU_NAME}: ${NCMENU}";
        ${COIN_CLI} -datadir=${CONFIGFOLDER} mnsync status
        echo "";
        echo "";
            ;;
        "masternode status")
        echo -e "${YELLOWMENU} masternode status ${MENU_NAME}: ${NCMENU}";
        ${COIN_CLI} -datadir=${CONFIGFOLDER} masternode status
    echo "";
    echo "";
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLYMENU"
         clear
           ;;
    esac
done
EOF

chmod +x $MENUNYA >/dev/null 2>&1
echo -e "Create Menu  for ${MENU_NAME} Successful"
}

function create_key() {
  echo -e "${YELLOW}Enter your ${RED}$COIN_NAME Masternode GEN Key${NC}. Press ENTER to auto generate"
  read -e COINKEY
  if [[ -z "$COINKEY" ]]; then
  $COIN_PATH$COIN_DAEMON -daemon -datadir=$CONFIGFOLDER
  sleep 30
  if [ -z "$(ps axo cmd:100 | grep $COIN_DAEMON)" ]; then
   echo -e "${RED}$COIN_NAME server couldn not start. Check /var/log/syslog for errors.{$NC}"
   exit 1
  fi
  COINKEY=$($COIN_PATH$COIN_CLI -datadir=$CONFIGFOLDER masternode genkey)
  if [ "$?" -gt "0" ];
    then
    echo -e "${RED}Wallet not fully loaded. Let us wait and try again to generate the GEN Key${NC}"
    sleep 30
    COINKEY=$($COIN_PATH$COIN_CLI masternode genkey)
  fi
  $COIN_PATH$COIN_CLI -datadir=$CONFIGFOLDER stop
fi
KEYA+=($COINKEY)
}

function update_config() {
sed -i "/\b\(listen=0\)\b/d" $CONFIGFOLDER/$CONFIG_FILE
  cat << EOF >> $CONFIGFOLDER/$CONFIG_FILE
listen=1
server=1
daemon=1
staking=0
logintimestamps=1
maxconnections=64
masternode=1

port=$COIN_PORT
bind=$NODEIP:$COIN_PORT
externalip=$NODEIP:$COIN_PORT
masternodeprivkey=$COINKEY

#ADDNODES
addnode=seed1.galilel.cloud
addnode=seed2.galilel.cloud
addnode=seed3.galilel.cloud
addnode=seed4.galilel.cloud
addnode=seed5.galilel.cloud
addnode=seed6.galilel.cloud
addnode=seed7.galilel.cloud
addnode=seed8.galilel.cloud
EOF
}


function enable_firewall() 
{
  echo -e "Setup firewall port $COIN_NAME"
  ufw allow $COIN_PORT/tcp comment "$COIN_NAME MN port" >/dev/null
  ufw allow ssh comment "SSH" >/dev/null 2>&1
  ufw limit ssh/tcp >/dev/null 2>&1
  ufw default allow outgoing >/dev/null 2>&1
  echo "y" | ufw enable >/dev/null 2>&1

echo -e "Setup firewall done"
}

function get_ip6() {
INSTALOK="$(cat /root/bin/galilel_installed | wc -l)"
INSTALOK=$((INSTALOK+1))
#echo "INstallOK = $INSTALOK"
#exit 1
#for i in {0..511}; do printf "2607:f4a0:3:0:250:56ff:feac:%.4x\n" $((i+0x0001)); done
face="$(lshw -C network | grep "logical name:" | sed -e 's/logical name:/logical name: /g' | awk '{print $3}'|head -1)"
gateway1=$(/sbin/route -A inet6 | grep -v ^fe80 | grep -v ^ff00 | grep -w "$face")
gateway2=${gateway1:0:26}
gateway3="$(echo -e "${gateway2}" | tr -d '[:space:]')"
if [[ $gateway3 = *"128"* ]]; then
  gateway=${gateway3::-5}
fi
if [[ $gateway3 = *"64"* ]]; then
  gateway=${gateway3::-3}
fi
MASK="/64"

echo "up /sbin/ip -6 addr add ${gateway}$INSTALOK$MASK dev $face # $COIN_NAME" >> /etc/network/interfaces
NODEIP="[${gateway}$INSTALOK]"
cd >/dev/null 2>&1
/sbin/ip -6 addr add ${gateway}$INSTALOK$MASK dev $face >/dev/null 2>&1
systemctl restart networking >/dev/null 2>&1
#exit 1
IPA+=($NODEIP)
}

function get_ip() {
  declare -a NODE_IPS
  for ips in $(netstat -i | awk '!/Kernel|Iface|lo/ {print $1," "}')
  do
    NODE_IPS+=($(curl --interface $ips --connect-timeout 2 -s4 icanhazip.com))
  done

  if [ ${#NODE_IPS[@]} -gt 1 ]
    then
for (( c=0; c<1;))
do
      echo -e "${GREEN}Detect more than one IP${NC}"
      echo ""
INDEX=0

echo "List IP already used"
for (( i=0; i<${#IPCEK1A[@]}; ++i ))
do
echo -e "${CYAN}IP = ${IPCEK1A[$i]} ${NC}"
done

echo ""
echo -e "${YELLOW}Please type 0 to use the first IP, 1 for the second and so on...${NC}"
      for ip in "${NODE_IPS[@]}"
      do
        echo ${INDEX} "for IP" $ip
        let INDEX=${INDEX}+1
      done
      read -e choose_ip
      NODEIP=${NODE_IPS[$choose_ip]}
        y=0
        while [ $y -lt ${#IPCEK1A[@]} ]; do
        #echo "CEK IP ARRAY = ${IPCEK1A[$y]}"
        #echo "PILIHAN IP = $NODEIP"
                if [ $NODEIP = "${IPCEK1A[$y]}" ]
                then
                #echo "PILIHAN SAMA"
                PAKAI='OK'
                #echo "LOOP PAKAI: $PAKAI"
                y="${#IPCEK1A[@]}"
                else
                PAKAI=0
                y=$(($y+1))
                fi
        done
#echo "LOOP ERROR IP = $y"
#echo "total IP digunakan : ${#IPCEK1A[@]}"
#echo " uNTUk LOOP : "$PAKAI
#echo "cek a: $a"
        if [ $PAKAI = "OK" ]
        then
        echo -e "${RED}ERROR: IP $NODEIP already used${NC}"
        echo ""
        c="0"
        fi
        if [ $PAKAI = "0" ]
        then
        c=1
        fi
done
echo "IP pilihan= $NODEIP"

  else
    NODEIP=${NODE_IPS[0]}
fi
IPA+=($NODEIP)
}

function get_ipnum() {
  declare -a NODE_IPS
  for ips in $(netstat -i | awk '!/Kernel|Iface|lo/ {print $1," "}')
  do
    NODE_IPS+=($(curl --interface $ips --connect-timeout 2 -s4 icanhazip.com))
  done

  if [ ${#NODE_IPS[@]} -gt 1 ]
    then
      INDEX=0
      for ip in "${NODE_IPS[@]}"
      do
        let INDEX=${INDEX}+1
      done
MAKSIMUM=$INDEX
  else
MAKSIMUM=1
fi

}
function compile_error() {
if [ "$?" -gt "0" ];
 then
  echo -e "${RED}Failed to compile $COIN_NAME. Please investigate.${NC}"
  exit 1
fi
}


function checks() {
if [[ $(lsb_release -d) != *16.04* ]]; then
  echo -e "${RED}You are not running Ubuntu 16.04. Installation is cancelled.${NC}"
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   exit 1
fi

##if [ -n "$(pidof $COIN_DAEMON)" ] || [ -e "$COIN_DAEMOM" ] ; then
##  echo -e "${RED}$COIN_NAME is already installed.${NC}"
##  exit 1
##fi
}

function prepare_system() {
echo -e "Preparing the VPS to setup. ${CYAN}$COIN_NAME${NC} ${RED}Masternode${NC}"
apt-get update >/dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get update > /dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y -qq upgrade >/dev/null 2>&1
apt install -y software-properties-common >/dev/null 2>&1
apt-get install unzip nano -y >/dev/null 2>&1
echo -e "${PURPLE}Adding bitcoin PPA repository"
apt-add-repository -y ppa:bitcoin/bitcoin >/dev/null 2>&1
echo -e "Installing required packages, it may take some time to finish.${NC}"
apt-get update >/dev/null 2>&1
apt-get install libzmq3-dev -y >/dev/null 2>&1
apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" make software-properties-common \
build-essential libtool autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev libboost-program-options-dev \
libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git wget curl libdb4.8-dev bsdmainutils libdb4.8++-dev \
libminiupnpc-dev libgmp3-dev ufw pkg-config libevent-dev  libdb5.3++ unzip libzmq5 >/dev/null 2>&1
if [ "$?" -gt "0" ];
  then
    echo -e "${RED}Not all required packages were installed properly. Try to install them manually by running the following commands:${NC}\n"
    echo "apt-get update"
    echo "apt -y install software-properties-common"
    echo "apt-add-repository -y ppa:bitcoin/bitcoin"
    echo "apt-get update"
    echo "apt install -y make build-essential libtool software-properties-common autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev \
libboost-program-options-dev libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git curl libdb4.8-dev \
bsdmainutils libdb4.8++-dev libminiupnpc-dev libgmp3-dev ufw pkg-config libevent-dev libdb5.3++ unzip libzmq5"
 exit 1
fi
echo -e "install repository done"
clear
}
function donasi() {
 echo -e "${BLUE}=================================================================================${NC}"
 echo -e "${YELLOW}Thank you for your donation for support us. "
 echo -e "GALI: Ucf6bgz52jE6fPbNFhfSnJqRcRqHfmg9AG "
 echo -e "BTC: 1MamGc3yH5qCe74XgX5dkCj7y3nn7teBwa "
 echo -e "LTC: LLz9EH4vCfTYH1uyGwHJKUJKAeqTirHmGL "
 echo -e "DOGE: DBmgChHwG6GLXtQkhRUdGCpEvGwjMC2xdA  ${NC}"
 echo -e "${BLUE}=================================================================================${NC}"

 }


function important_information() {
 echo -e "${BLUE}=================================================================================${NC}"
 echo -e "VPS_IP:PORT ${GREEN}$NODEIP:$COIN_PORT${NC}"
 echo -e "MASTERNODE GENKEY is: ${RED}$COINKEY${NC}"
 echo -e ""
 echo -e "Use ${YELLOW} ./$MENUNYA ${NC} for run Masternode Menu"

 }

function setup_node() {
  get_ip
  create_config
  snapshot_sync
  create_key
  update_config
  enable_firewall
  configure_systemd
  important_information
}


##### Main #####
clear

#purgeOldInstallation
checks

for (( ax=0; ax<1;))
do

echo "Script for masternode $COIN_NAME1"
echo "1 - Create new nodes"
echo "2 - Delete an existing node"
echo "3 - Upgrade to Wallet $WALLET_VER or repair an existing node"
echo "4 - Add 4GB SWAP Memory to VPS"
#echo "5 - Create new nodes for IPv6 (Use this option if IPv4 already maximum and your vps has IPv6)"
echo "9 - clean old bootstrap file"
echo "10 - Create Menu for Masternode"
echo "99 - EXIT script"
echo ""
echo -e "${YELLOW}What would you like to do? type number of your choice${NC}"
read PILIH

echo ""

 if [ $PILIH = "99" ]
then
donasi
exit 1
 fi

 if [ $PILIH = "10" ]
 then

for (( c=0; c<1;))
do
echo -e "${YELLOW}List of installed $COIN_NAME1 Masternode${NC}"
for i in $(find ${CONFIGFOLDER}* -maxdepth 0 -type d | cut -c8-) ; do
MENUCEK=$(find /root/ -name "$i.sh" | cut -c7-  2> /dev/null)
#MENUCEK="$(find  /root/$i.sh -maxdepth 0 | cut -c7- 2> /dev/null)"
if [ ! $MENUCEK = ''  ]
then
MENUCEK1="for run Menu: ./"$MENUCEK
fi
echo -e " ${CYAN} $i${NC} 	$MENUCEK1" ;
MENUCEK=""
MENUCEK1=""
done

echo ""
echo -e "${YELLOW}Write Node that want to create MENU or write EXIT to exit : ${NC}"
read MENU1
	if [[ $MENU1 =~ "EXIT"|"exit" ]] ;
	then
	 exit 1
	fi
let COUNTB=0
for i in $(find /root/.$MENU1 -maxdepth 0 -type d) ; do
COUNTB=$((COUNTB+1))
done
if [ $COUNTB = "0" ]
then
c=0
echo "ERROR : No masternode for $MENU1"
echo ""
else
COIN_NAME="$MENU1"
COIN_TICKER="$MENU1"
MENUNYA="$MENU1.sh"
MENU_NAME="$MENU1"
create_menu
echo ""
fi
done
 fi


 if [ $PILIH = "9" ]
 then
cd >/dev/null 2>&1
rm bootstrap-latest.tar.gz >/dev/null 2>&1
apt-get clean  >/dev/null 2>&1
echo "Old bootstrap deleted"
echo ""

fi
 if [ $PILIH = "4" ]
then
echo -e "Choose add 4GB Swap"
echo "Proccessing add swap"
sudo fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
sudo echo "/swapfile none swap sw 0 0" >> /etc/fstab
echo "Add swap done"
echo ""

 fi

 if [ $PILIH = "3" ]
then
echo -e "Choose Upgrade Wallet $WALLET_VER or Repair existing Node"
echo -e "${YELLOW}List of installed $COIN_NAME1 Masternode${NC}"
echo ""
let COUNTA=0
for i in $(find ${CONFIGFOLDER}* -maxdepth 0 -type d | cut -c8-) ; do
VERSINYA="$(${COIN_CLI} -datadir=/root/.${i} getinfo | grep "version"|head -1)"

    echo -e " ${CYAN} $i${NC}   ${VERSINYA}" ;
COUNTA=$((COUNTA+1))

done
echo ""
if [ $COUNTA = "0" ]
then
echo -e "${RED}ERROR:${NC} No installed masternode $COIN_NAME1 "
echo ""
else
echo -e "${YELLOW}Write Node that want to UPGRADE/REPAIR or write EXIT to exit : ${NC}"
read DEL2
if [[ $DEL2 = "" ]]
then
DEL2="kosong"
fi
DEL1='.'"$DEL2"
if [[ $DEL2 =~ "EXIT"|"exit" ]] ;
then
 exit 1
else
for (( c=0; c<1;))
do
DEL1='.'"$DEL2"
let COUNTB=0
for i in $(find /root/$DEL1 -maxdepth 0 -type d) ; do
COUNTB=$((COUNTB+1))
done
if [ $COUNTB = "0" ]
then
c=0
echo -e "${RED}ERROR:${NC} No masternode for $DEL2"

echo -e "${YELLOW}List of installed $COIN_NAME1 Masternode${NC}"
echo ""
for i in $(find ${CONFIGFOLDER}* -maxdepth 0 -type d | cut -c8-) ; do
    echo -e " ${CYAN} $i${NC}" ;
COUNTA=$((COUNTA+1))
done
echo ""
DEL2=''
echo -e "${YELLOW}Write Node that want to UPGRADE/REPAIR or write EXIT to exit : ${NC}"
read DEL3
if [[ $DEL3 = "" ]]
then
DEL3="kosong"
fi
if [[ $DEL3 =~ "EXIT"|"exit" ]] ;
then
 exit 1
fi
DEL2=${DEL3}
c='0'
else
echo -e "${YELLOW}Do you want to upgrade to wallet $WALLET_VER ? [y/n] Type n if your wallet already Ver. $WALLET_VER ${NC}"
read WALLETNYA
if [[ $WALLETNYA =~ "Y"|"y" ]] ;
then
cd >/dev/null 2>&1
rm galilel-v3.1.0-lin64.tar.gz >/dev/null 2>&1
download_node
fi
echo -e "${YELLOW}Do you already have latest bootstrap files? [y/n] Type n if not sure ${NC}"
read FILEBARU
if [[ $FILEBARU =~ "N"|"n" ]] ;
then
cd >/dev/null 2>&1
rm bootstrap-latest.tar.gz >/dev/null 2>&1
snapshot_sync
fi
c='1'
echo "$DEL2"
echo -e " Upgrade/Repair node $DEL2"
ALIAS=${DEL2}
COIN_NAME="$ALIAS"
COIN_TICKER="GALI_$ALIAS"
MENUNYA="galilel_$ALIAS.sh"
MENU_NAME="GALILEL $ALIAS"
CONFIG_FILE='galilel.conf'
CONFIGFOLDER="/root/.$ALIAS"
stop_daemon
delete_lama
snapshot_syncmn
systemctl start $ALIAS.service
echo "Upgrade/ Repair Node $ALIAS Done"
echo ""

fi

done
 fi
fi
 fi

 if [ $PILIH = "2" ]
then
echo -e "you choose Delete Existing Node"
echo -e "${YELLOW}List of installed $COIN_NAME1 Masternode${NC}"
echo ""
let COUNTA=0
for i in $(find ${CONFIGFOLDER}* -maxdepth 0 -type d | cut -c8-) ; do
    echo -e " ${CYAN} $i${NC}" ;
COUNTA=$((COUNTA+1))
done
echo ""
if [ $COUNTA = "0" ]
then
echo -e "${RED}ERROR: ${NC} No installed masternode $COIN_NAME1"
echo ""
else
echo -e "${YELLOW}Write Node that want to DELETE or write EXIT to exit : ${NC}"
read DEL2
if [[ $DEL2 = "" ]]
then
DEL2="kosong"
fi
DEL1='.'"$DEL2"
if [[ $DEL2 =~ "EXIT"|"exit" ]] ;
then
 exit 1
else
for (( c=0; c<1;))
do
DEL1='.'"$DEL2"
let COUNTB=0
for i in $(find /root/$DEL1 -maxdepth 0 -type d) ; do
COUNTB=$((COUNTB+1))
done
if [ $COUNTB = "0" ]
then
c=0
echo -e "${RED}ERROR:${NC} No masternode for $DEL2"

echo -e "${YELLOW}List of installed $COIN_NAME1 Masternode${NC}"
echo ""
for i in $(find ${CONFIGFOLDER}* -maxdepth 0 -type d | cut -c8-) ; do
    echo -e " ${CYAN} $i${NC}" ;
COUNTA=$((COUNTA+1))
done
echo ""
echo -e "${YELLOW}Write Node that want to DELETE or write EXIT to exit : ${NC}"
read DEL3
if [[ $DEL3 = "" ]]
then
DEL3="kosong"
fi
DEL2=${DEL3}
c='0'
else
c='1'
echo -e "Removing service $DEL2. Note: ${CYAN}Don't worry for error message while proccesing${NC}"
echo ""
systemctl stop $DEL2
systemctl disable $DEL2
rm /etc/systemd/system/${DEL2}.service
systemctl daemon-reload
systemctl reset-failed
echo -e " Stopping node $DEL2"
${COIN_CLI} -datadir=/root/${DEL1} stop
sleep 5
echo "Removing directory /root/$DEL1"
cd
rm -r /root/$DEL1
rm ${DEL2}.sh
sleep 1
echo -e "${YELLOW}Node $DEL2 deleted ${NC}"
echo ""

fi

done
 fi
fi
 fi

 if [ $PILIH = "5" ]
then
echo -e "${YELLOW}List of installed $COIN_NAME1 Masternode${NC}"
let COUNTA=0
for i in $(find ${CONFIGFOLDER}* -maxdepth 0 -type d | cut -c8-) ; do
IPCEK=$(grep  "externalip" /root/.$i/galilel.conf | cut -c12-  2> /dev/null)
IPCEK1=$(echo "$IPCEK" | rev | cut -c 7- | rev)
IPCEK1A+=($IPCEK1)
echo -e " ${CYAN} $i${NC}       $IPCEK1" ;
COUNTA=$((COUNTA+1))
done
echo ""
echo -e "${RED}$COUNTA installed masternode${NC}"
echo ""

 if [ $COUNTA = "0" ]
then
echo -e "${RED} ERROR: Must choose install new masternode for IPv4 first before use this"
else
echo -e "${YELLOW}How many $COIN_NAME1 nodes do you want to install use IPv6?  Min:1${NC}"
read MNTOTAL

 fi
fi


 if [ $PILIH = "1" ]
then
echo -e "${YELLOW}List of installed $COIN_NAME1 Masternode${NC}"
let COUNTA=0
for i in $(find ${CONFIGFOLDER}* -maxdepth 0 -type d | cut -c8-) ; do
IPCEK=$(grep  "externalip" /root/.$i/galilel.conf | cut -c12-  2> /dev/null)
IPCEK1=$(echo "$IPCEK" | rev | cut -c 7- | rev)
IPCEK1A+=($IPCEK1)
echo -e " ${CYAN} $i${NC}	$IPCEK1" ;
COUNTA=$((COUNTA+1))
done
echo ""
echo -e "${RED}$COUNTA installed masternode${NC}"
echo ""
#echo -e "You choose Install $COIN_NAME1 New Node"
echo -e "${YELLOW}Do you want to install all needed dependencies? n if you did it before [y/n] ${NC}"
read INSTALL
if [[ $INSTALL =~ "Y"|"y" ]] ;
then
prepare_system
fi

echo -e "${YELLOW}Do you want to install wallet $COIN_NAME $WALLET_VER? n if you did it before [y/n] ${NC}"
read INSTAL_DAEMON
if [[ $INSTAL_DAEMON =~ "Y"|"y" ]] ;
then
download_node
fi
#enable_firewall
echo -e "${YELLOW}Do you want to download latest bootstrap? n if you did it before [y/n] ${NC}"
read INSTAL_SNAPSHOT
if [[ $INSTAL_SNAPSHOT =~ "Y"|"y" ]] ;
then
snapshot_sync
fi

get_ipnum

if [[ $MAKSIMUM = "1" && $COUNTA = '0' ]]
then
clear
COIN_NAME="galilel"
COIN_TICKER="GALI"
CONFIG_FILE='galilel.conf'
CONFIGFOLDER="/root/.galilel"
COIN_PORT=36001
RPC_PORT=360010
MENUNYA="galilel.sh"
MENU_NAME="GALILEL"

echo -e "${YELLOW}First node must be ipv4. Installing Masternode $COIN_NAME1 ${NC}"

  get_ip
  create_config

echo -e "copy snapshot to $CONFIGFOLDER"
cd  >/dev/null 2>&1
tar xvzf bootstrap-latest.tar.gz -C $CONFIGFOLDER  >/dev/null 2>&1
echo -e "bootstrap successful downloaded"

  create_key
  update_config
  configure_systemd
  create_menu
  enable_firewall
  important_information
echo "1" >> /root/bin/galilel_installed
donasi
exit 1

else
if [ $COUNTA -ge $MAKSIMUM ]
then
IPV6="IPv6"
fi

echo -e "${YELLOW}How many $IPV6 $COIN_NAME1 nodes do you want to install ?  Min:1 ${NC}"
read MNTOTAL
#if [[ $MNTOTAL > "$MAKSIMUM" ]];
#then
#echo "Maximum install node $MAKSIMUM"
#echo "How many nodes do you want to install? Min:1 Max:$MAKSIMUM"
#read MNTOTAL
#fi
let COUNTER=0
#echo "$COUNTER , TOTAL $MNTOTAL"
while [ $COUNTER -lt $MNTOTAL ]; do

let COUNTA=0
CONFIGFOLDER="/root/.galilel"
echo -e "${YELLOW}List of installed $COIN_NAME1 Masternode${NC}"
for i in $(find ${CONFIGFOLDER}* -maxdepth 0 -type d | cut -c8-) ; do
IPCEK=$(grep  "externalip" /root/.$i/galilel.conf | cut -c12-  2> /dev/null)
IPCEK1=$(echo "$IPCEK" | rev | cut -c 7- | rev)
IPCEK1A+=($IPCEK1)
echo -e " ${CYAN} $i${NC}	$IPCEK1" ;
COUNTA=$((COUNTA+1))
done
echo ""

MNCOUNT='1'
MNCOUNT=$(($MNCOUNT+$COUNTA))
echo -e "${YELLOW}Enter alias for new node $COIN_NAME1 $MNCOUNT (alias name must without text $COIN_NAMECEK, ex: MN2)${NC}"
read ALIAS

COIN_NAME="galilel_$ALIAS"
COIN_TICKER="GALI_$ALIAS"
MENUNYA="galilel_$ALIAS.sh"
MENU_NAME="GALILEL $ALIAS"
CONFIG_FILE='galilel.conf'
CONFIGFOLDER="/root/.galilel_$ALIAS"
COIN_PORT=36001
#COIN_PORT=$((36001+$COUNTA))
RPC_PORT=$((360010+$COUNTA))

ALIASCEK=$(find ${CONFIGFOLDER} -maxdepth 0 -type d  2> /dev/null)
if [ ! $ALIASCEK = '' ]
then
echo -e "${RED}ERROR: $ALIAS already exist${NC}"
echo ""
else
if [ $COUNTA -lt $MAKSIMUM ]
then
  get_ip
else
 get_ip6
fi
#exit 1
  create_config

echo -e "copy snapshot to $CONFIGFOLDER"
cd  >/dev/null 2>&1
tar xvzf bootstrap-latest.tar.gz -C $CONFIGFOLDER  >/dev/null 2>&1
echo -e "bootstrap successful downloaded"

ALIASA+=($ALIAS)
PORTA+=($COIN_PORT)
  create_key
  update_config
  configure_systemd
  create_menu

COUNTER=$((COUNTER+1))
COUNTA=$((COUNTA+1))
MNCOUNT=$(($MNCOUNT+1))
echo "1" >> /root/bin/galilel_installed
fi

done

clear

for (( i=0; i<$MNTOTAL; ++i ))
do
echo -e "${BLUE}=================================================================================${NC}"
echo "ALIAS NODE= ${ALIASA[$i]}"
echo "Private Key= ${KEYA[$i]}"
echo "IP:Port= ${IPA[$i]}:${PORTA[$i]}"
echo "Run Menu= ./galilel_${ALIASA[$i]}.sh"
echo ""

done
donasi
exit 1
fi


 fi

done
