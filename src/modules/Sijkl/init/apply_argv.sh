#!/bin/bash

# Based on the value of opMode set according actions
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

# Based on the value of repoSource set the path to input data repository
case "$repoSource" in
  "archive" )
    newRepoPath="$HOME/archive/work/sim/data"
    ;;

  "external" )
    newRepoPath="/mdeia/external/work/sim/data"
    ;;
esac

if [ -d $newRepoPath ]; then
  SIMDATA=$newRepoPath
else
  comment="[`date +"%F_%H-%M-%S"`] ($SNAME unit `echo $(basename $BASH_SOURCE)`) Repository $newRepoPath does not exist"
  if [ -z ${logFile:+x} ]; then
    echo $comment
  else
    echo $comment >> $logFile
  fi
fi


# Something with excluding job ids from plotting
if [ $plotWithoutExcluded -ne 0 ]; then
  if [ -z ${excludeIDsFile:+x} ] || \
     [ ! -f $excludeIDsFile ] || [ ! -r $excludeIDsFile ]; then
    printf "\n [%s] Exclusion file not specified or not readable\n" $R_err
    exit 1
  fi
fi


