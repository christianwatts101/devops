#!/usr/bin/env bash

EMAIL="support@3drepo.log"
MESSAGE="IO has stopped running. Check service has restarted correctly  - https://www.3drepo.io/"

### Find Process ID of node

pidof node > /dev/null


### Check if Process is running ###

if [[ $? -ne 0 ]] ; then
        echo "Restarting IO:     $(date)" >> /var/log/io.txt
        /bin/3drepo start &
        echo ${MESSAGE} | mail -s "IO has crashed !!" ${EMAIL}
fi
