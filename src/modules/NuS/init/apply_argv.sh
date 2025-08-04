#!/bin/bash

thisUnitBaseName=`echo $(basename $BASH_SOURCE)`

# # Based on the value of opMode set according actions
# case "$opMode" in
#     "dev" )
#       hereANDnow=`date +"%F"`
#       debugMode=1
#       ;;
#
#     "aux" )
#       SCRATCH=$SCRATCH1
#       ;;
#
#     *)
#     if [ ${#opMode} -gt 0 ]; then
#       comment="Current value for opMode=$opMode has no effect"
#       log_comment "$thisUnitBaseName" "$comment"
#     fi
#       ;;
# esac
#
# # Based on the value of repoSource set the path to input data repository
# if [ $alternateRepositoryFlag -eq 1 ]; then
#   case "$repoSource" in
#     "archive" )
#       newRepoPath="$HOME/archive/work/sim/data"
#       ;;
#
#     "external" )
#       newRepoPath="/mdeia/external/work/sim/data"
#       ;;
#   esac
#
#   if [ ${#repoSource}  -gt 0 ] && \
#      [ ${#newRepoPath} -gt 0 ] && [ -d $newRepoPath ]; then
#     SIMDATA=$newRepoPath
#   elif [ ${#repoSource} -gt 0 ] &&  [ ${#newRepoPath} -eq 0 ]; then
#     comment="Repository $repoSource does not exist"
#     log_comment "$thisUnitBaseName" "$comment"
#   elif [ ${#repoSource} -eq 0 ]; then
#     comment="Value for -r option not recived"
#     log_comment "$thisUnitBaseName" "$comment"
#   fi
# fi
#
# # Something with excluding job ids from plotting
# if [ $plotWithoutExcluded -ne 0 ]; then
#   if [ -z ${excludeIDsFile:+x} ] || \
#      [ ! -f $excludeIDsFile ] || [ ! -r $excludeIDsFile ]; then
#     printf "\n [%s] Exclusion file not specified or not readable\n" $R_err
#     exit 1
#   fi
# fi


