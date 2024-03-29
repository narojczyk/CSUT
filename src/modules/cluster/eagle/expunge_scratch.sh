#!/bin/bash
## Author: Jakub W. Narojczyk <narojczyk@ifmpan.poznan.pl>
clear
SNAME=`echo $(basename $BASH_SOURCE)| sed 's/\.sh//'`

## Variables set automatically by configure.sh. ###############################
# This should be set prior to 1st useage.
CSUT_CORE="${HOME}/main/work/dev/scripts/CSUT/src"
CSUT_CORE_INC="${CSUT_CORE}/common"
CORE="${CSUT_CORE}/modules/cluster/eagle"

###############################################################################

# Surce top-level utility variables
source ${CSUT_CORE_INC}/settings/constants.sh

# Surce top-level IO functions
source ${CSUT_CORE_INC}/IOfunctions/basic_output.sh

# Surce top-level SQL functions
source ${CSUT_CORE_INC}/SQLfunctions/SQL_basics.sh

while getopts sv argv; do
    case "${argv}" in
        s) useSQL=1 ;;
        v) VERBOSE=0 ;;
    esac
done

# Display greetings
source ${CSUT_CORE_INC}/header.sh \
  "${_BLD}${_PRP}Inspect SCRATCH directory and erase old jobs${_RST}"

# Surce module-level resurce paths
source ${CORE}/init/set_module_resource_paths.sh

# get names of system-wide env. variables
env_dirs=( SCRATCH JOBSTARTER DBFOLDER )

# Verify that environment variables are set correctly
source ${CSUT_CORE_INC}/settings/check_environment_vars.sh\
  ${env_dirs[@]} ${script_dirs[@]} FPB

# Surce module-level utility variables
source ${INITIALS}/set_module_constants.sh

log="${SCRATCH}/${logFileName}"

# When enabled, test if SQL database is availiable
SQLtestHostname

# Test if DB is present
SQLDBpresent

# Set initial control array for printing progress bar (see IOfunctions)
dpctrl=( 0 0 66 ' ' )

# Off we go
cd ${SCRATCH}
if [ ${VERBOSE} -eq 1 ]; then
  echo " Log to file: ${_YEL}${_BLD}${logFileName}${_RST} on SCRATCH"
fi

# Query system for actual running jobs
jobIDs=(\
  `squeue -u ${USER} -o  "%.8i %8P %.24j %3T %.10M %.9L %8R" |\
  grep -v "PARTITIO" | sed 's/\ .*//' | sort` )
# Gen the lowest active job id
jobIDZero=${jobIDs[0]}
jobIDsN=${#jobIDs[@]}

# Get the list jobs that have been salvaged and reconfigured
if [ ${useSQL} -eq 1 ]; then
  jobsToExpire=( )
  SQLQUERRY="SELECT JOBDIR FROM ${SQLTABLE} WHERE STATUS LIKE 'reconfigured';"
  jobsReconfigured=( `SQLconnect "${SQLQUERRY}"` )
  jobsReconfiguredN=${#jobsReconfigured[@]}
  dpctrl[1]=${jobsReconfiguredN}
  WDTH=${#jobsReconfiguredN}
  printFormBar=" %s (%${WDTH}d/${jobsReconfiguredN})"
  i=0; while [ $i -lt ${jobsReconfiguredN} ]; do
    JB_Rec=${jobsReconfigured[$i]}
    SQLQUERRY="SELECT SCRATCHDIR FROM ${SQLTABLE} WHERE JOBDIR LIKE '${JB_Rec}';"
    jobScratchDir=`SQLconnect "${SQLQUERRY}"`
    if [ ${#jobScratchDir} -eq 0 ]; then
      jobScratchDir=`ls -1d SLID[0-9]*_${JB_Rec} 2>/dev/null`
    fi
    
    if [ ${#jobScratchDir} -gt 0 ]; then
      jobsToExpire=( ${jobsToExpire[@]} $jobScratchDir )
    fi
    (( i++ ))
    dpctrl[0]=${i}
    dpctrl[3]=`printf "${printFormBar}" "Prepare the list of SCRATCH directories" ${i}`
    display_progres
  done
  jobsToSave=""
else
  echo " Listing job directories on SCRATCH"
  ls -1d SLID[0-9]*_20??* >  $log
  echo " Reducing the list by active jobs"
  i=0; while [ $i -lt ${jobIDsN} ]; do
    eval "sed -i '/${jobIDs[$i]}/d' $log"
    (( i++ ))
  done
  inactiveJobs=(`cat $log | grep SLID | sort`)
  inactiveJobsN=${#inactiveJobs[@]}

  # Investigate inactive jobs had they been salvaged.
  dpctrl[1]=${inactiveJobsN}
  WDTH=${#inactiveJobsN}
  printFormBar=" %s (%${WDTH}d/${inactiveJobsN})"
  i=0; while [ $i -lt ${inactiveJobsN} ]; do
    cd ${SCRATCH}/${inactiveJobs[$i]}
    sha1sum *part* *chkp* *msnap* > JOB_safety_verification.sha1
    if [ -d ${JOBSTARTER}/${inactiveJobs[$i]#SLID*_} ]; then
      cp JOB_safety_verification.sha1 ${JOBSTARTER}/${inactiveJobs[$i]#SLID*_}
      cd ${JOBSTARTER}/${inactiveJobs[$i]#SLID*_}
      sha1sum -c JOB_safety_verification.sha1 --quiet #> /dev/null 2>&1
      if [ $? -ne 0 ]; then
        eval "sed -i '/${inactiveJobs[$i]}/d' $log"
        echo ${inactiveJobs[$i]} >> ${log}.save
        rm JOB_safety_verification.sha1
      fi
    else
      eval "sed -i '/${inactiveJobs[$i]}/d' $log"
      echo ${inactiveJobs[$i]} >> ${log}.save
    fi
    rm ${SCRATCH}/${inactiveJobs[$i]}/JOB_safety_verification.sha1

    (( i++ ))
    dpctrl[0]=${i}
    dpctrl[3]=`printf "${printFormBar}" "Verifying slavage" ${i}`
    display_progres
  done
  
  cd ${SCRATCH}
  # Directories left in log can be removed
  jobsToExpire=(`cat $log | grep SLID`)
  
  jobsToSave=(`cat ${log}.save | grep SLID`)
fi
echo

jobsToExpireN=${#jobsToExpire[@]}
jobsToSaveN=${#jobsToSave[@]}
WDTH=${#jobsToExpireN}

printf " Found:\n\t%${WDTH}d jobs to safely remove\n" $jobsToExpireN
printf "\t%${WDTH}d jobs saved for salvage\n" $jobToSaveN
printf " Proceed with removal of $jobsToExpireN directories [y/N] " 
userConfirm="N"; read userConfirm

if [ "${userConfirm}" == "y" ] || [ "${userConfirm}" == "Y" ]; then
  dpctrl[1]=${jobsToExpireN}
  printFormBar=" %s (%${WDTH}d/${jobsToExpireN})"
  i=0; while [ $i -lt ${jobsToExpireN} ]; do
    JBtoExp=${jobsToExpire[$i]}
    
    if [ -d ${JBtoExp} ]; then 
      rm -r $JBtoExp
      if [ ${useSQL} -ne 0 ]; then
        SQLQUERRY="UPDATE ${SQLTABLE} SET SCRATCHDIR='' WHERE JOBDIR LIKE '${JBtoExp#SLID[0-9]*_}';"
        SQLconnect "${SQLQUERRY}"
      fi
    else
      echo "${JBtoExp} directory NOT found"
    fi
    (( i++ ))
   
    dpctrl[0]=${i}
    dpctrl[3]=`printf "${printFormBar}" "Deleting job directories" ${i}`
    display_progres
  done
  echo
fi
exit 0


