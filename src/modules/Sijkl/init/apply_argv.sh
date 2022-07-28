#!/bin/bash

# Based on mode setting prepare the name of the work directory
if [ "$opMode" = "dev" ]; then
  hereANDnow=`date +"%F"`
  debugMode=1
elif [ "$opMode" = "aux" ]; then
  SCRATCH=$SCRATCH1
else
    comment="Current value for opMode=$opMode has no effect"
    if [ -z ${logFile:+x} ]; then 
        echo $comment 
    else
        echo $comment >> $logFile
    fi
fi

if [ $plotWithoutExcluded -ne 0 ]; then
  if [ -z ${excludeIDsFile:+x} ] || \
     [ ! -f $excludeIDsFile ] || [ ! -r $excludeIDsFile ]; then
    printf "\n [%s] Exclusion file not specified of not readable\n" $R_err
    exit 1
  fi
fi


