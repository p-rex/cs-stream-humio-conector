#!/bin/bash

#if you set -e in this bash, you will get exit code 1 in grep.


## Set Environment Variables
TO_LOGSCALE_DIR=to_logscale/
TO_LOGSCALE_FILE_BASE=${TO_LOGSCALE_DIR}baselog
TO_LOGSCALE_FILE_SPLIT=${TO_LOGSCALE_DIR}splitlog
SPLIT_LOG_LINE=1000
SEND_LOG_INTERVAL=30



## Load functions
source functions.sh

## Initialize
rm -f {$TO_LOGSCALE_DIR}*


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
        grep metadata $tgt_cs_log > $TO_LOGSCALE_FILE_BASE  # remove empty line
        rm $tgt_cs_log
        line_num=$(wc -l < $TO_LOGSCALE_FILE_BASE)
        log_msg "$0 - $tgt_cs_log line num == $line_num"



        ## if empty log
        if [ $line_num -eq 0 ]; then
	        log_msg "$0 - Skipped -- $tgt_cs_log is empty."
	        rm $TO_LOGSCALE_FILE_BASE
                continue
        fi



        # split log file because Humio doesn't receive large file 
        split -l $SPLIT_LOG_LINE $TO_LOGSCALE_FILE_BASE $TO_LOGSCALE_FILE_SPLIT
        rm $TO_LOGSCALE_FILE_BASE

        # send splitted logs
        ls_array=($(ls $TO_LOGSCALE_DIR))
        for eachFile in ${ls_array[@]}; do
                SEND_FILE=${TO_LOGSCALE_DIR}${eachFile}
                split_line_num=$(wc -l < $SEND_FILE)
                log_msg "$0 - ${SEND_FILE} : line num == $split_line_num - start"
                sendLogToHumio $LS_INGEST_TOKEN $SEND_FILE

                # save offset for resume
               saveOffset $SEND_FILE $OFFSET_FILE

                rm $SEND_FILE
                echo "" # for line break
                log_msg "$0 - ${SEND_FILE} - finished"
        done

        log_msg "$0 - $tgt_cs_log was sent"

done





