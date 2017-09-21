#!/usr/bin/env bash

USER=chrisian
SERVER=134.213.210.63
PORT=22123
LOG_DIR="/home/node/.forever"
KEY=/home/christian/.ssh/dev/key

ssh -i /home/christian/.ssh/dev/key -p ${PORT} ${USER}@${SERVER}
