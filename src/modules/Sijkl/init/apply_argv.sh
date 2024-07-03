#!/bin/bash

# Based on mode setting prepare the name of the work directory
case "$opMode" in
    "dev" )
      hereANDnow=`date +"%F"`
      debugMode=1
      ;;

    "aux" )
      SCRATCH=$SCRATCH1
      ;;

    *)
    if [ ${#opMode} -gt 0 ]; then
      comment="[`date +"%F_%H-%M-%S"`] ($SNAME unit `echo $(basename $BASH_SOURCE)`) Current value for opMode=$opMode has no effect"
      if [ -z ${logFile:+x} ]; then
          echo $comment
      else
          echo $comment >> $logFile
      fi
    fi
      ;;
esac

if [ $plotWithoutExcluded -ne 0 ]; then
  if [ -z ${excludeIDsFile:+x} ] || \
     [ ! -f $excludeIDsFile ] || [ ! -r $excludeIDsFile ]; then
    printf "\n [%s] Exclusion file not specified or not readable\n" $R_err
    exit 1
  fi
fi


