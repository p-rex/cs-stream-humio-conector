#!/bin/bash

while true
do
    process_cnt=$(ps -e | grep main.sh | wc -l)
    if [ $process_cnt -eq 0 ]; then
        ./main.sh
    fi

    sleep $PROCESS_CHECK_INTERVAL
done
