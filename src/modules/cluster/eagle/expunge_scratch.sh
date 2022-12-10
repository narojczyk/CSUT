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

# Display greetings
source ${CSUT_CORE_INC}/header.sh \
  "${_BLD}${_PRP}Inspect SCRATCH directory and erase old jobs${_RST}"

# Script variables
useSQL=0
# mask="*"
logfile=`echo ${SNAME} | sed 's;^.*/;;'`
logmarker=`eval date +%F`
logsuffix=`date +%s`
FPBlength=30

# Surce module-level utility variables
source ${CORE}/init/set_module_constants.sh

# define script-wide env. variables
source ${CORE}/init/declare_environment_vars.sh

# get names of system-wide env. variables
env_dirs=( SCRATCH JOBSTARTER DBFOLDER )

# Verify that environment variables are set correctly
source ${CSUT_CORE_INC}/settings/check_environment_vars.sh\
  ${env_dirs[@]} ${script_dirs[@]} FPB

log="${SCRATCH}/${logfile}_${logmarker}_${logsuffix}.log"

while getopts sv argv; do
    case "${argv}" in
        s) useSQL=1 ;;
        v) VERBOSE=0 ;;
    esac
done

# When enabled, test if SQL database is availiable
if [ ${useSQL} -eq 1 ]; then
  if [[ `uname -n` = "eagle.man.poznan.pl" ]]; then
    useSQL=0
    echo " ${_RED}Cannot use SQL funcionality at the head node${_RST}"
    printf " run:\n\tsrun -pstandard --pty /bin/bash\n"
    printf " or continue in non-SQL mode"; read trash
  fi
fi
if [ ${useSQL} -eq 1 ] && [ ! -f ${SQLDB} ]; then
  useSQL=0
  printf " Selected DB (%s) not found. Swithing to non-SQL mode\n" ${SQLDB##/*/}
elif [ ${useSQL} -eq 1 ] && [ -f ${SQLDB} ]; then
  printf " Running with SQL enabled. Using %s\n" ${SQLDB##/*/}
fi

# Off we go
cd ${SCRATCH}

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
  jobsReconfigured=(\
    `${SQL} ${SQLDB}\
      "SELECT JOBDIR FROM JOBS WHERE STATUS LIKE 'reconfigured';" `)
  printFormBar=" Reading SQL setting scratchdir names (%d/%d) %s"
  i=0; while [ $i -lt ${#jobsReconfigured[@]} ]; do
    jobScratchDir=`${SQL} ${SQLDB}\
      "SELECT SCRATCHDIR FROM JOBS WHERE JOBDIR LIKE '${jobsReconfigured[$i]}';" `
    if [ ${#jobScratchDir} -eq 0 ]; then
      jobScratchDir=`ls -1d SLID[0-9]*_${jobsReconfigured[$i]}`
    fi
    jobsToExpire=( ${jobsToExpire[@]} $jobScratchDir )
    (( i++ ))
    # Prepare progress bar
    progress_bar=`$FPB ${i} ${#jobsReconfigured[@]} ${FPBlength}`
    progress_msg=`printf "${printFormBar}" $i ${#jobsReconfigured[@]} "${progress_bar}"`
    # Display progress bar
    echo -ne "${progress_msg}"\\r
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
  printFormBar=" verifying slavage (%${#inactiveJobsN}d/${inactiveJobsN}) %s"
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
    # Prepare progress bar
    progress_bar=`$FPB ${i} ${inactiveJobsN} ${FPBlength}`
    progress_msg=`printf "${printFormBar}" $i "${progress_bar}"`
    # Display progress bar
    echo -ne "${progress_msg}"\\r
  done
  
  cd ${SCRATCH}
  # Directories left in log can be removed
  jobsToExpire=(`cat $log | grep SLID`)
  
  jobsToSave=(`cat ${log}.save | grep SLID`)
fi
echo

jobsToExpireN=${#jobsToExpire[@]}
jobsToSaveN=${#jobsToSave[@]}
printW=${#jobsToExpireN}

printf " Found:\n\t%${printW}d jobs to safely remove\n" $jobsToExpireN
printf "\t%${printW}d jobs saved for salvage\n" $jobToSaveN
printf " Proceed with removal of $jobsToExpireN directories [y/N] " 
userConfirm="N"; read userConfirm

if [ "${userConfirm}" == "y" ] || [ "${userConfirm}" == "Y" ]; then
  printFormBar=" Deleting job directories (%${#jobsToExpireN}d/${jobsToExpireN}) %s"
  i=0; while [ $i -lt ${jobsToExpireN} ]; do
    JBtoExp=${jobsToExpire[$i]}
    
    if [ -d ${JBtoExp} ]; then 
      rm -r $JBtoExp
      if [ ${useSQL} -ne 0 ]; then
        ${SQL} ${SQLDB} \
          "UPDATE ${SQLTABLE} SET SCRATCHDIR='' WHERE JOBDIR LIKE '${JBtoExp#SLID[0-9]*_}';"
      fi
    # else
      # TODO: log that dir not found
    fi
    (( i++ ))
   
    # Prepare progress bar
    progress_bar=`$FPB ${i} ${jobsToExpireN} ${FPBlength}`
    progress_msg=`printf "${printFormBar}" $i "${progress_bar}"`
    # Display progress bar
    echo -ne "${progress_msg}"\\r
  done
  echo
fi
exit 0


