#!/bin/bash
_RED=$(tput setaf 1)
_RESET=$(tput sgr0)

conf_msg(){
  echo "${_RED}[$0]${_RESET} $1" | sed -e 's/\.sh]/]/' -e 's;\[\./;[;'; }

conf_msg "This will configure CSUT on new location"

EXIT_CODE=0;
master="csut.sh"
currentWorkDir=`pwd`
parentDirName=`pwd | sed 's;^.*/;;'`

if [ "${parentDirName}" = "src" ] && [ -f ${master} ]; then
  eval "sed -i 's;CSUT\_CORE=.*;CSUT\_CORE=\"${currentWorkDir}\";' ${master}"
  if [ ${#HOME} -gt 0 ]; then
    eval "sed -i 's;${HOME};\${HOME};' ${master}"
  fi
  conf_msg "Finished"
  exit ${EXIT_CODE};
elif [ ! -f ${master} ]; then
  conf_msg "Missing ${master}"
  EXIT_CODE=1;
elif [ "${parentDirName}" != "src" ]; then
  conf_msg "Not running from 'src' directory. Check your location"
  EXIT_CODE=1;
fi

conf_msg "${_RED}Configure failed.${_RESET}"
exit ${EXIT_CODE};
