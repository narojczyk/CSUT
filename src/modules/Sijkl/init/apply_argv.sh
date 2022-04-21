#!/bin/bash

# Based on mode setting prepare the name of the work directory
if [ "$opMode" = "dev" ]; then
  hereANDnow=`date +"%F"`
  debugMode=1
elif [ "$opMode" = "aux" ]; then
  scratch=$SCRATCH1
else
    comment="Current value for opMode=$opMode has no effect"
    if [ -z ${logFile:+x} ]; then 
        echo $comment 
    else
        echo $comment >> $logFile
    fi
fi


