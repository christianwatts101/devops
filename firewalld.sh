#!/usr/bin/env bash
set -e

### FireallD Zones array ###

declare -a zone=(["block"] ["dmz"] ["drop"] ["external"] ["home"] ["internal"] ["trusted"] ["work"])

### Set IP ###

DEV_PRIMARY=192.168.3.3
DEV_SECONDARY=192.168.3.5
DEV_QUEUE=192.168.3.4
DEV_WEB=192.168.3.6
DEV_NFS=192.168.3.1
DEV_COMPUTE=192.168.3.2

### Set Port Numbers ###

CHAT=3000
HTTP=80
HTTPS=443
DNS=53
SSH=22
SMTP=25
MONGO=27017
NFS=111


### check for Root user ###

if [ "$(whoami)" == "root" ] ; then
    echo "you are root"
else
    echo "you are not root, This script must be run as root"
    exit 1
fi

### Error Checking ###

error_check() {

if [ $? -eq 0 ]; then
   echo "$(tput setaf 2) [ OK ]  $(tput sgr0)"
	sleep 2
else
   echo "$(tput setaf 1) [ FAILED ]  $(tput sgr0)"
	sleep 2
fi
}

### No command line arguments ###

if [[ $# -eq 0 ]] ; then
    echo -e "\nUsage: $0 web nfs mail \n" 
    exit 0
fi


### Check which firewall is running ###

firewalld=`systemctl list-unit-files | grep firewalld | awk {'print $2'}`
iptables=`systemctl list-unit-files | grep iptables | awk {'print $2'}`


if [[ ${firewalld} == "enabled" ]]; then
    echo "FirewallD is enabled.."
else
    echo "Checking if iptables is enabled.."   
    if [[ ${iptables} == "enabled" ]]; then
        echo "iptables is enabled.....Disabling"
        systemctl stop iptables
        systemctl disable iptables
        echo "Starting FirewallD"
        systemctl enable firewalld
        systemctl start firewalld
	echo "FirewallD is now enabled"
    fi
fi

web() {

### Add Interfaces to zones ###

   firewall-cmd --zone=trusted --add-interface=lo
   error_check
   firewall-cmd --zone=public --add-interface=eth0
   error_check
   firewall-cmd --zone=internal --add-interface=eth2
   error_check

   firewall-cmd --get-active-zones

fi

### Add Ports to Public zone ###

   firewall-cmd --zone=public --add-port=${HTTP}/tcp --permanent
   error_check
   firewall-cmd --zone=public --add-port=${HTTPS}/tcp --permanent
   error_check   
   firewall-cmd --zone=public --add-port=${SSH}/tcp --permanent
   error_check
   firewall-cmd --zone=public --add-port=${DNS}/tcp --permanent
   error_check

### Add ports to Internal zone ###

   firewall-cmd --zone=internal --add-port=${MONGO}/tcp --permanent
   error_check
   firewall-cmd --zone=internal --add-port=${NFS}/tcp --permanent
   error_check
   firewall-cmd --zone=internal --add-port=${CHAT}/tcp --permanent
   error_check

### Reload firewall & List changes ###

   firewall-cmd --reload
   firewall-cmd --zone=public --list-all
   firewall-cmd --zone=internal --list-all


}

nfs() {

    echo "NFS"
}

mongo() {

    echo "MONGO"

}

q_client() {

    echo "QUEUE_CLIENT"

}

q_server() {

    echo "QUEUE_SERVER"

}

compute() {

    echo "COMPUTE"

}

case "$1" in
  (web) 
    web
    exit 0
    ;;
  (nfs) 
    nfs
    exit 0
    ;;
  (mongo) 
    mongo
    exit 0
    ;;
  (q_client) 
    q_client
    exit 0
    ;;
  (q_server) 
    q_server
    exit 0
    ;;
  (compute) 
    compute
    exit 0
    ;;
  (*)
    echo "Usage: $0 {web|mongo}"
    exit 2
    ;;
esac
