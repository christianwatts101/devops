#!/usr/bin/env bash


if [ "$(whoami)" == "root" ] ; then
    echo "you are root"
else
    echo "you are not root, This script must be run as root"
    exit 1
fi


error_check() {

if [ ${?} -eq 0 ]; then
   echo "$(tput setaf 2) [ OK ]  $(tput sgr0)"
	sleep 2
else
   echo "$(tput setaf 1) [ FAILED ]  $(tput sgr0)"
	sleep 2
fi
}


declare -a zones=(block dmz drop external home internal trusted work)

DEV_PRIMARY=192.168.3.3
DEV_SECONDARY=192.168.3.5
DEV_QUEUE=192.168.3.4
DEV_WEB=192.168.3.6
DEV_NFS=192.168.3.1
DEV_COMPUTE=192.168.3.2


