#!/bin/bash
_RED=$(tput setaf 1)
_RESET=$(tput sgr0)

conf_msg(){
  echo "${_RED}[$0]${_RESET} $1" | sed -e 's/\.sh]/]/' -e 's;\[\./;[;'; }

conf_msg "This will configure CSUT on new location"

EXIT_CODE=0;
master="csut.sh"
module_Sijkl="modules/Sijkl/Sijkl-processing.sh"
module_eagle_claim="modules/cluster/eagle/claim_results.sh"
currentWorkDir=`pwd`
parentDirName=`pwd | sed 's;^.*/;;'`

updateFiles=( $master $module_Sijkl $module_eagle_claim );
updateFilesCount=${#updateFiles[@]}

if [ "${parentDirName}" = "src" ]; then
  i=0;
  while [ $i -lt ${updateFilesCount} ]; do
    u=${updateFiles[$i]}
    let iReal=i+1
    if [ -f ${u} ]; then
      conf_msg "($iReal/${updateFilesCount}) Updating $u"
      eval "sed -i 's;CSUT\_CORE=.*;CSUT\_CORE=\"${currentWorkDir}\";' ${u}"
      if [ ${#HOME} -gt 0 ]; then
        eval "sed -i 's;${HOME};\${HOME};' ${u}"
      fi
    else
      conf_msg "Missing ${u}"
      EXIT_CODE=1;
    fi
    (( i++ ))
  done
else
  conf_msg "Not running from 'src' directory. Check your location"
  EXIT_CODE=1;
fi

if [ $EXIT_CODE -eq 0 ]; then
  conf_msg "Finished"
else
  conf_msg "${_RED}Configure failed.${_RESET}"
fi
exit ${EXIT_CODE};
