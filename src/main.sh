#!/bin/bash -e

## Set Environment Variables. Some are set by .env
#export CS_CLIENT_ID=
#export CS_CLIENT_SECRET=
#export CS_APIURL=https://api.crowdstrike.com
#export APPID=
#export INGEST_TOKEN=
#export HUMIO_URL=https://cloud.community.humio.com/api/v1/ingest/hec/raw
export LOG_DIR=from_cs/
export LOG_PATH=${LOG_DIR}stream.log
export LOG_ROTATE_INTERVAL=60
export STREAM_REFRESH_INTERVAL=1500 # 1500 sec == 25 min 
export MAX_STREAM_LOG_FILE_CNT=100
export OFFSET_FILE=offset/offset.txt


## Load functions
source functions.sh


## Initialize
rm -f ${LOG_DIR}*

if [ -n "$CS_STREAMING_OFFSET" ]; then
    query_offset="&offset=${CS_STREAMING_OFFSET}"
fi

# if there is a offset file, override $query_offset.
if [ -e $OFFSET_FILE ]; then
    last_offset_num=$(cat $OFFSET_FILE)
    if [ -n "$last_offset_num" ]; then
        next_offset_num=`expr $last_offset_num + 1`
        query_offset="&offset=${next_offset_num}"
    fi
fi

## Get OAuth2 Token
log_msg "getting oauth2 token"
FALCON_API_BEARER_TOKEN=`getBearerToken`


## Get streaming URL
log_msg "getting streaming url"
DATAFEED_URL="${CS_APIURL}/sensors/entities/datafeed/v2?format=json&appId=${APPID}"

RESP_JSON=$(curl -s -f -X GET -H "authorization: Bearer ${FALCON_API_BEARER_TOKEN}" $DATAFEED_URL )
export dataFeedURL=$(echo $RESP_JSON | jq -r '.resources[].dataFeedURL' )
export dataFeedToken=$(echo $RESP_JSON | jq -r '.resources[].sessionToken.token' )
export dataFeedExpiration=$(echo $RESP_JSON | jq -r '.resources[].sessionToken.expiration' )
export refresh_active_session_url=$(echo $RESP_JSON | jq -r '.resources[0].refreshActiveSessionURL' )



### 3 processes run in parallel
## Process 1 - stream
trap 'kill $(jobs -p)' EXIT
log_msg "streaming start"
curl -s -f -k -N -X GET ${dataFeedURL}${query_offset} -H "Accept: application/json" -H "Authorization: Token ${dataFeedToken}" | rotatelogs -n $MAX_STREAM_LOG_FILE_CNT -p ./rotate_msg.sh $LOG_PATH $LOG_ROTATE_INTERVAL &
#https://serverfault.com/questions/558957/rotatelogs-rotating-log-files-mid-log-entry



## Process 2 - post to humio
./post_to_humio.sh &


## Process 3 - refresh stream session. 
# This loop is also responsible for keeping the container running.
# If this refresh fails, the "bash -e" option terminates this script, as a result container stops.
while true
do
    sleep $STREAM_REFRESH_INTERVAL
    log_msg "reflesh active session"
    FALCON_API_BEARER_TOKEN=`getBearerToken`
    
    curl -f -X POST \
    $refresh_active_session_url \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json' \
    -H "Authorization: Bearer ${FALCON_API_BEARER_TOKEN}"
done
