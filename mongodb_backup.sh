#!/usr/bin/env bash
 
MONGO_DATABASE=""
APP_NAME=""

MONGO_HOST=""
MONGO_PORT=""
DATE=`date +%F-%H%M`
MD_BIN_PATH="/usr/bin/mongodump"
BACKUP_DIR="/home/mdb_backup/${APP_NAME}"
DUMP_NAME="$APP_NAME-$TIMESTAMP"
 
# mongo admin --eval "printjson(db.fsyncLock())"
# $MONGODUMP_PATH -h $MONGO_HOST:$MONGO_PORT -d $MONGO_DATABASE
${MD_BIN_PATH} -d $MONGO_DATABASE
# mongo admin --eval "printjson(db.fsyncUnlock())"
 
mkdir -p ${BACKUP_DIR}
mv dump ${DUMP_NAME}

rm -rf $DUMP_NAME
env GZIP=-9 tar cvzf file.tar.gz /path/to/directory

rm -rf ${DUMP_NAME}