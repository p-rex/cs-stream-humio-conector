#!/bin/bash

#if you set -e in this bash, you will get exit code 1 in grep.


## Set Environment Variables
TO_HUMIO_DIR='to_humio/'
TO_HUMIO_FILE_BASE='to_humio/baselog'
TO_HUMIO_FILE_SPLIT='to_humio/splitlog'
SPLIT_LOG_LINE=1000
SEND_LOG_INTERVAL=30


## Load functions
source functions.sh

## Initialize
rm -f {$TO_HUMIO_DIR}*


while true
do
        sleep $SEND_LOG_INTERVAL

        cs_log_file_num=$(ls $LOG_DIR | wc -l | tr -d ' ')
        if [ $cs_log_file_num -lt 2 ]; then
                log_msg "$0 - not enough logs yet"
                continue
        fi

        tgt_cs_log=$(ls -t $LOG_DIR | tail -n 1)
        tgt_cs_log=${LOG_DIR}${tgt_cs_log}

        ## Culc line num
        grep metadata $tgt_cs_log > $TO_HUMIO_FILE_BASE  # remove empty line
        rm $tgt_cs_log
        line_num=$(wc -l < $TO_HUMIO_FILE_BASE)
        log_msg "$0 - $tgt_cs_log line num == $line_num"

        ## if empty log
        if [ $line_num -eq 0 ]; then
	        log_msg "$0 - Skipped -- $tgt_cs_log is empty."
	        rm $TO_HUMIO_FILE_BASE
                continue
        fi

        # split log file because Humio doesn't receive large file 
        split -l $SPLIT_LOG_LINE $TO_HUMIO_FILE_BASE $TO_HUMIO_FILE_SPLIT
        rm $TO_HUMIO_FILE_BASE

        # send splitted logs
        ls_array=($(ls $TO_HUMIO_DIR))
        for eachFile in ${ls_array[@]}; do
                SEND_FILE=${TO_HUMIO_DIR}${eachFile}
                split_line_num=$(wc -l < $SEND_FILE)
                log_msg "$0 - ${SEND_FILE} : line num == $split_line_num - start"
                sendLogToHumio $INGEST_TOKEN $SEND_FILE
                rm $SEND_FILE
                echo "" # for line break
                log_msg "$0 - ${SEND_FILE} - finished"
        done

        log_msg "$0 - $tgt_cs_log was sent"

done





