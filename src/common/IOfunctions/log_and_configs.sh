#!/bin/bash

load_config(){
  cfg="${STARTDIR}/${usrConfig}"
  if [ -f $cfg ] && [ -r $cfg ]; then
    echo " Loading user settings from $cfg"
    source $cfg
  fi
}

log_comment(){
  msg2log="[`date +"%F %H:%M:%S"`] ($SNAME unit $1) $2"
  if [ -z ${logFile:+x} ]; then
    echo $msg2log
  else
    echo $msg2log >> $logFile
  fi
}
