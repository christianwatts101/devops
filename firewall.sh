#!/bin/bash

declare -A server_parts

ssh_port=22123
mongo_port=27017
mail_port=465
mail_gmail=587
zabbix_client=10050
zabbix_server=10051


server_parts=( ["web"]="ssh chat dns http https mail mongo_client queue_client jump_server nfs_client web" ["mongo"]="ssh mongo_server" \
["nfs"]="ssh nfs_server mongo_server" ["queue"]="ssh queue_server" ["compute"]="ssh queue_client nfs_client mongo_client rdp") \
["zabbix"]="ssh zabbix"

config_file=$2
source $config_file

yum -y update
yum install -y iptables-services
systemctl stop firewalld
systemctl start iptables
systemctl start ip6tables
systemctl disable firewalld
systemctl mask firewalld
systemctl enable iptables
systemctl enable ip6tables

# Clear out previous rules
iptables -P INPUT ACCEPT
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X

# Protect from certain types of attacks
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
iptables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP

# Accept everything on the loopback address
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# OUTPUT and dport combination stands for those packets leaving the system and destined for port 443 of remote system.
# INPUT and sport combination stands for those packets arriving to the system and originating from port 443 of remote system.

# OUTPUT and sport combination will be applicable for those packets leaving port 443 of your system.
# INPUT and dport combination will be applicable to packets destined for port 443 of your system.

echo "server parts: ${server_parts[$1]}"

if [[ "${server_parts[$1]}" =~ "web" ]]; then
	iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT -m state --state NEW,ESTABLISHED
	iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT -m state --state NEW,ESTABLISHED
fi

if [[ "${server_parts[$1]}" =~ "http" ]]; then
	iptables -A INPUT -p tcp --dport 80 -j ACCEPT -m state --state NEW,ESTABLISHED
	iptables -A INPUT -p tcp --dport 8080 -j ACCEPT -m state --state NEW,ESTABLISHED
	iptables -A OUTPUT -p tcp --sport 80 -j ACCEPT -m state --state ESTABLISHED
	iptables -A OUTPUT -p tcp --sport 8080 -j ACCEPT -m state --state ESTABLISHED
	iptables -A PREROUTING -t nat -i $web_external_net_interface -p tcp --dport 80 -j REDIRECT --to-port 8080
fi

if [[ "${server_parts[$1]}" =~ "chat" ]]; then
	iptables -A INPUT -p tcp --dport $chat_port -j ACCEPT -m state --state NEW,ESTABLISHED
	iptables -A OUTPUT -p tcp --sport $chat_port -j ACCEPT -m state --state ESTABLISHED
fi

if [[ "${server_parts[$1]}" =~ "https" ]]; then
	iptables -A INPUT -p tcp --dport 443 -j ACCEPT -m state --state NEW,ESTABLISHED
	iptables -A INPUT -p tcp --dport 8443 -j ACCEPT -m state --state NEW,ESTABLISHED
	iptables -A OUTPUT -p tcp --sport 443 -j ACCEPT -m state --state ESTABLISHED
	iptables -A OUTPUT -p tcp --sport 8443 -j ACCEPT -m state --state ESTABLISHED
	iptables -A PREROUTING -t nat -i $web_external_net_interface -p tcp --dport 443 -j REDIRECT --to-port 8443
fi

if [[ "${server_parts[$1]}" =~ "dns" ]]; then
	iptables -A OUTPUT -p udp -d $dns_servers --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
	iptables -A INPUT  -p udp -s $dns_servers --sport 53 -m state --state ESTABLISHED     -j ACCEPT
	iptables -A OUTPUT -p tcp -d $dns_servers --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
	iptables -A INPUT  -p tcp -s $dns_servers --sport 53 -m state --state ESTABLISHED     -j ACCEPT
fi

if [[ "${server_parts[$1]}" =~ "ssh" ]]; then
	iptables -A INPUT -p tcp --dport $ssh_port -j ACCEPT
	iptables -A OUTPUT -p tcp --sport $ssh_port -j ACCEPT
fi


if [[ "${server_parts[$1]}" =~ "jump_server" ]]; then
	iptables -A OUTPUT -p tcp --dport $ssh_port -j ACCEPT
fi

if [[ "${server_parts[$1]}" =~ "mongo_server" ]]; then
	iptables -A INPUT -s $mongo_clients -p tcp -m multiport --dports $mongo_port -m state --state NEW,ESTABLISHED -j ACCEPT
	iptables -A OUTPUT -d $mongo_clients -p tcp -m multiport --sports $mongo_port -m state --state ESTABLISHED -j ACCEPT

	iptables -A INPUT -s $mongo_servers -p tcp -m multiport --dports $mongo_port -j ACCEPT
	iptables -A INPUT -s $mongo_servers -p tcp -m multiport --sports $mongo_port -j ACCEPT
	iptables -A OUTPUT -d $mongo_servers -p tcp -m multiport --dports $mongo_port -j ACCEPT
	iptables -A OUTPUT -d $mongo_servers -p tcp -m multiport --sports $mongo_port -j ACCEPT
fi

if [[ "${server_parts[$1]}" =~ "rdp" ]]; then
	iptables -A INPUT -s $unity_compute -p tcp -m multiport --sports $rdp_port -m state --state ESTABLISHED -j ACCEPT
	iptables -A OUTPUT -d $unity_compute -p tcp -m multiport --dports $rdp_port -m state --state NEW,ESTABLISHED -j ACCEPT
fi

if [[ "${server_parts[$1]}" =~ "mongo_client" ]]; then
	# TODO: How does this deal with replica sets ?
	iptables -A INPUT -s $mongo_servers -p tcp -m multiport --sports $mongo_port -m state --state ESTABLISHED -j ACCEPT
	iptables -A OUTPUT -d $mongo_servers -p tcp -m multiport --dports $mongo_port -m state --state NEW,ESTABLISHED -j ACCEPT
fi

if [[ "${server_parts[$1]}" =~ "nfs_server" ]]; then
    iptables -A INPUT -m state --state NEW,ESTABLISHED -p tcp -m multiport --dports 111,662,875,892,2049,32803 -s $nfs_clients -j ACCEPT
    iptables -A INPUT -m state --state NEW,ESTABLISHED -p udp -m multiport --dports 111,662,875,892,32769 -s $nfs_clients -j ACCEPT
    iptables -A OUTPUT -m state --state ESTABLISHED -p tcp -m multiport --sports 111,662,875,892,2049,32803 -d $nfs_clients -j ACCEPT
    iptables -A OUTPUT -m state --state ESTABLISHED -p udp -m multiport --sports 111,662,875,892,32769 -d $nfs_clients -j ACCEPT
fi

if [[ "${server_parts[$1]}" =~ "nfs_client" ]]; then
    iptables -A OUTPUT -m state --state NEW,ESTABLISHED -p tcp -m multiport --dports 111,662,875,892,2049,32803 -d $nfs_ip -j ACCEPT
    iptables -A OUTPUT -m state --state NEW,ESTABLISHED -p udp -m multiport --dports 111,662,875,892,32769 -d $nfs_ip -j ACCEPT
    iptables -A INPUT -m state --state ESTABLISHED -p tcp -m multiport --sports 111,662,875,892,2049,32803 -s $nfs_ip -j ACCEPT
    iptables -A INPUT -m state --state ESTABLISHED -p udp -m multiport --sports 111,662,875,892,32769 -s $nfs_ip -j ACCEPT
fi

if [[ "${server_parts[$1]}" =~ "mail" ]]; then
	iptables -A OUTPUT -p tcp --dport $mail_port -m state --state NEW,ESTABLISHED -j ACCEPT
fi

if [[ "${server_parts[$1]}" =~ "queue_client" ]]; then
	iptables -A OUTPUT -d $queue_hostname -p tcp --dport $queue_port -m state --state NEW,ESTABLISHED -j ACCEPT
	iptables -A INPUT -s $queue_hostname -p tcp --sport $queue_port -m state --state ESTABLISHED -j ACCEPT
fi

if [[ "${server_parts[$1]}" =~ "queue_server" ]]; then
	iptables -A OUTPUT -d $queue_clients -p tcp --sport $queue_port -m state --state ESTABLISHED -j ACCEPT
	iptables -A INPUT -s $queue_clients -p tcp --dport $queue_port -m state --state NEW,ESTABLISHED -j ACCEPT
fi


if [[ "${server_parts[$1]}" =~ "zabbix" ]]; then
	iptables -A OUTPUT -d $queue_clients -p tcp --sport $zabbix_client -m state --state ESTABLISHED -j ACCEPT
    iptables -A OUTPUT -d $queue_clients -p tcp --sport $zabbix_server -m state --state ESTABLISHED -j ACCEPT
	iptables -A INPUT -s $queue_clients -p tcp --dport $mail_gmail -m state --state NEW,ESTABLISHED -j ACCEPT
    iptables -A INPUT -s $queue_clients -p tcp --dport $zabbix_client -m state --state NEW,ESTABLISHED -j ACCEPT
    iptables -A INPUT -s $queue_clients -p tcp --dport $zabbix_server -m state --state NEW,ESTABLISHED -j ACCEPT
fi


iptables -I INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -j LOGGING
iptables -A OUTPUT -j LOGGING
iptables -A LOGGING -m limit --limit 2/min -j LOG --log-prefix "IPTables-Dropped: " --log-level 4
iptables -A LOGGING -j DROP

iptables -P OUTPUT DROP
iptables -P INPUT DROP
iptables -P FORWARD DROP


iptables -N LOGGING
service iptables save
service iptables restart