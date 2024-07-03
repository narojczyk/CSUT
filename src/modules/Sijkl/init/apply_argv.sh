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
      log_comment "$comment"
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
  *)
    newRepoPath=""
    ;;
esac

if [ ${#newRepoPath} -gt 0 ] && [ -d $newRepoPath ]; then
  SIMDATA=$newRepoPath
elif [ ${#newRepoPath} -eq 0 ] || [ ! -d $newRepoPath ]; then
  comment="[`date +"%F_%H-%M-%S"`] ($SNAME unit `echo $(basename $BASH_SOURCE)`) Repository $repoSource does not exist"
  log_comment "$comment"
fi


# Something with excluding job ids from plotting
if [ $plotWithoutExcluded -ne 0 ]; then
  if [ -z ${excludeIDsFile:+x} ] || \
     [ ! -f $excludeIDsFile ] || [ ! -r $excludeIDsFile ]; then
    printf "\n [%s] Exclusion file not specified or not readable\n" $R_err
    exit 1
  fi
fi


