#!/bin/env bash
#
ES_HOST=""
DELETE_DATE=`date --date 'xx day ago' +%Y.%m.%d`
CURL_PATH="/path/to/curl"
MAIL_PATH="/path/to/mail"
# Require jq
JQ_PATH="/path/to/jq"
RSYNC_PATH="/path/to/rsync"
SOURCE_PATH=""
BACKUP_PATH=""
BACKUP_USER=""
ALERT_TO=""
#
function send_mail(){
  ${MAIL_PATH} -s "Elasticsearch Maintenance Failure." ${ALERT_TO}
}
#
function check_result(){
  if [ $? = "0" -o $? = "24" ];then
    echo "Elasticsearch ${1} success."
  elif [ $? = "24" ];then
    echo "Elasticsearch ${1} success and vanished files exists."
  else
    echo "Elasticsearch ${1} failure." | send_mail
    exit 1
  fi
}
#
function get_delete_index(){
  DELETE_INDICES=`${CURL_PATH} -s http://${ES_HOST}:9200/_status | \
  ${JQ_PATH} -r '.indices|keys[]' | \
  grep ${DELETE_DATE}`
}
#
function maintenance_index(){
  get_delete_index
  for index in ${DELETE_INDICES[@]};
  do
    echo "Delete Index ${index} ..."
    ${CURL_PATH} -s -XDELETE "http://${ES_HOST}:9200/${index}"
    check_result "Index Delete"
  done
}
#
function sync(){
  ${RSYNC_PATH} \
  # for test
  #--dry-run \
  -avz \
  -e ssh \
  ${BACKUP_USER}@${ES_HOST}:${SOURCE_PATH} ${BACKUP_PATH}
  check_result "Index Backup"
}

# Main
sync
maintenance_index

exit 0
