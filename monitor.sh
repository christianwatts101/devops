#!/usr/bin/env bash



### Open firewall port ###

echo "Which port do you want opened on the firewall? : "
read port

sudo firewall-cmd --zone=public --add-port=${port}/tcp
sudo firewall-cmd --reload


