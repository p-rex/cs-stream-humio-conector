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


function sendLogToHumio(){
    curl -s -f $HUMIO_URL \
    -X POST \
    -H "Content-Type: application/json; charset=utf-8" \
    -H "Authorization: Bearer ${1}" \
    --data-binary @${2}
}