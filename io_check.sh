#!/usr/bin/env bash

EMAIL="jozef.dobos@3drepo.org, carmen.fan@3drepo.org, christian.watts@3drepo.org, james.milner@3drepo.org, andrew.norrie@3drepo.org, pavol.knapo@3drepo.org, charence.wong@3drepo.org"
MESSAGE="IO has stopped. Check service has restarted correctly  - https://www.3drepo.io/"

### Find Process ID of node

pidof node > /dev/null


### Check if Process is running ###

if [[ $? -ne 0 ]] ; then
        echo "Restarting IO:     $(date)" >> /var/log/io.txt
        /bin/3drepo start &
        echo ${MESSAGE} | mail -s "IO crashed !! TESTING" ${EMAIL}
fi
