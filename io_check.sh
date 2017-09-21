#!/usr/bin/env bash

EMAIL="devops@3drepo.org"
MESSAGE="IO has stopped running. Check service has restarted correctly  - https://www.3drepo.io/"

### Find Process ID of node

pidof node > /dev/null


### Check if Process is running ###

if [[ $? -ne 0 ]] ; then
        echo "Restarting IO:     $(date)" >> /home/node/scripts/io_logs/io_services.log
        /bin/3drepo start &
        echo ${MESSAGE} | mail -s "IO has crashed !!" ${EMAIL}
fi
