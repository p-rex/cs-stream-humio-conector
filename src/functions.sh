#!/bin/bash

function log_msg(){
        echo "$(date) --- ${1}"
}

function getBearerToken(){
    FALCON_API_BEARER_TOKEN=$(curl -f \
    --data "client_id=${CS_CLIENT_ID}&client_secret=${CS_CLIENT_SECRET}" \
    --request POST \
    --silent \
    ${CS_APIURL}/oauth2/token | jq -r '.access_token')

    echo $FALCON_API_BEARER_TOKEN
}


function sendLogToLogScale(){
    curl -s -f $LS_URL \
    -X POST \
    -H "Content-Type: application/json; charset=utf-8" \
    -H "Authorization: Bearer ${1}" \
    --data-binary @${2}
}


# --------------------------------------------------
# Check the value is some number or not.
# --------------------------------------------------
isNumeric() {
    expr "$1" + 1 >/dev/null 2>&1
    if [ $? -ge 2 ]; then
        return 1
    else
        return 0
    fi
}

# $1 == log file, $2 == offset file
function saveOffset(){
    offset=$(tail -1 $1 | jq -r .metadata.offset)

    if isNumeric $offset ; then
        echo $offset > $2
    else
        log_msg "$offset is not numeric"
    fi
}


function setQueryOffset(){
    if [ -n "$CS_STREAM_OFFSET" ]; then
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

    echo $query_offset
}