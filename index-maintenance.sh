#!/bin/bash
#
ES_HOST=""
DELETE_DATE=`date --date 'xx day ago' +%Y.%m.%d`
MAINTE_DATE=`date +%Y.%m.%d`
CURL_PATH="/path/to/curl"
MAIL_PATH="/path/to/mail"
# Require jq
JQ_PATH="/path/to/jq"
RSYNC_PATH="/path/to/rsync"
SOURCE_PATH=""
BACKUP_PATH=""
BACKUP_USER=""
ALERT_TO="your_mail_addresss"
#
function send_mail(){
 ${MAIL_PATH} -s "Elasticsearch Maintenance Failure(${MAINTE_DATE})" ${ALERT_TO}
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
function delete_index(){
  for index in ${DELETE_INDICES[@]};
  do
    echo "Deleting index ${index} ..."
    ${CURL_PATH} -s -XDELETE "http://${ES_HOST}:9200/${index}"
    echo "done ..."
  done
}
#
function maintenance_index(){
  get_delete_index
  if [ -n "${DELETE_INDICES}" ];then
    delete_index
    check_result "index delete"
  else
    echo ""
    check_result "delete index does not exist... maintenance"
  fi
}
#
function sync(){
  /usr/bin/rsync \
  -avz \
  -e ssh \
  ${BACKUP_USER}@${ES_HOST}:${SOURCE_PATH} ${BACKUP_PATH}
  check_result "index backup"
}

# Main
sync
maintenance_index

exit 0
