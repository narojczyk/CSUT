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
  "${_BLD}${_PRP}Sync information about running jobs with SQL${_RST}"


# Script variables
useSQL=1
scrLog="scratch.log"
sqlLog="sqlRecords.txt"
deadLog="notactive_jobs.txt"
liveLog="active_jobs.txt"

# Surce module-level utility variables
source ${CORE}/init/set_module_constants.sh

while getopts v argv
do
    case "${argv}" in
        v) VERBOSE=1 ;;
    esac
done

# define script-wide env. variables
source ${CORE}/init/declare_environment_vars.sh

# get names of system-wide env. variables
env_dirs=( SCRATCH JOBSTARTER DBFOLDER )

# Verify that environment variables are set correctly
source ${CSUT_CORE_INC}/settings/check_environment_vars.sh\
  ${env_dirs[@]} ${script_dirs[@]} FPB

# When enabled, test if SQL database is availiable
if [ ${useSQL} -eq 1 ] && [[ `uname -n` = "eagle.man.poznan.pl" ]]; then
  echo " ${_RED}SQL funcionality required, cannot run on the head node${_RST}"
  exit 1
fi

if [ $VERBOSE -eq 1 ]; then
  printf " Using %s\n" ${SQLDB##/*/}
fi

# Off we go
cd ${SCRATCH}

# Query system for actual running jobs
jobIDs=(\
  `squeue -u ${USER} -o  "%.8i %8P %.24j %3T %.10M %.9L %8R" |\
  grep RUN | sed 's/\ .*//'` )
jobIDsN=${#jobIDs[@]}

# Query SQL for recorded jobs
SQLJobCount=`${SQL} ${SQLDB} \
  "SELECT COUNT(ID) FROM JOBS WHERE STATUS LIKE 'started';"`

if [ $VERBOSE -eq 1 ]; then
  # Set common printing parameters
  if [ ${#jobIDsN} -gt ${#SQLJobCount} ]; then
    printWidth=${#jobIDsN}
  else
    printWidth=${#SQLJobCount}
  fi

  printf "${printForm}" "Actual running jobs" ${jobIDsN}
  printf "${printForm}" "Running jobs indicated in DB" ${SQLJobCount}
  echo -ne " Reading SCRATCH contents"\\r
fi

# Get the list of all present job directories, prep the list of dead jobs and
# clear the list of active jobs
ls -1d SLID* > ${scrLog}
cp ${scrLog} ${deadLog}
echo > ${liveLog}

# Get the list of job directories present on scratch
srcJBs=(`cat ${scrLog}`)
srcJBsCount=${#srcJBs[@]}

if [ $VERBOSE -eq 1 ]; then
  # Set common printing parameters
  if [ ${printWidth} -lt ${#srcJBsCount} ]; then
    printWidth=${#srcJBsCount}
  fi
  printForm=" %-55s : %${printWidth}d\n"
  printFormBar=" %-24s (%${printWidth}d/%${printWidth}d) %s"
  let FPBlength=22-printWidth-printWidth+2
fi


# Generate the lists of active and dead jobs
i=0; while [ $i -lt ${jobIDsN} ]; do
  eval "sed -i '/${jobIDs[$i]}/d' ${deadLog}"
  cat ${scrLog} | grep ${jobIDs[$i]} >> ${liveLog}
  (( i++ ))
  if [ $VERBOSE -eq 1 ]; then
    progress_bar=`$FPB ${i} ${jobIDsN} ${FPBlength}`
    progress_msg=`printf "${printFormBar}" \
      "Reading SCRATCH contents" $i ${jobIDsN} "${progress_bar}"`
    # Display progress bar
    echo -ne "${progress_msg}"\\r
  fi
done

if [ $VERBOSE -eq 1 ]; then
  echo
fi

# Inspect dead jobs
unset deadJBs
deadJBs=(`cat ${deadLog}`)
deadJBsCount=${#deadJBs[@]}
notFoundInSQL=0
# w=${#deadJBsCount}
# let FPBlength=45-w-w+2

if [ $deadJBsCount -ne 0 ]; then
  i=0; while [ $i -lt $deadJBsCount ]; do
    dJB=${deadJBs[$i]}
    dJB_ID=`echo $dJB | sed -e 's/SLID//' -e 's/_.*$//'`
    dJB_JD=`echo $dJB | sed 's/^SLID[0-9]*_//'`

    sqlID=`${SQL} ${SQLDB} \
      "SELECT ID FROM JOBS WHERE (JOBID=${dJB_ID} OR JOBDIR LIKE '${dJB_JD}' );"`

    if [ ${#sqlID} -gt 0 ]; then
    # The job has been found in the register

    # Check progress of the dead job
    target=`cat ${dJB}/*.ini |\
      grep "Number of data blocks" | sed 's/^.*:\ *//'`
    present=`ls -1d ${dJB}/*part* |wc -l`
    dJB_prog=`bc -l <<< $present/$target |\
      sed -e 's/00*$/0/' -e 's/^\./0\./'`

    # Update SQL record
    ${SQL} ${SQLDB} \
            "UPDATE ${SQLTABLE} SET PROGRES='${dJB_prog}', STATUS='terminated' WHERE ID=${sqlID};"
    else
      (( notFoundInSQL++ ))
    fi
    (( i++ ))
    if [ $VERBOSE -eq 1 ]; then
      # Prepare progress bar
      progress_bar=`$FPB ${i} ${deadJBsCount} ${FPBlength}`
      progress_msg=`printf "${printFormBar}"\
        "Checking terminated jobs" ${i} ${deadJBsCount} "${progress_bar}"`
      # Display progress bar
      echo -ne "${progress_msg}"\\r
    fi
  done

  if [ $VERBOSE -eq 1 ]; then
    echo
#     printf "${printForm}" "Terminated jobs found" $deadJBsCount
    if [ $notFoundInSQL -gt 0 ]; then
      printf "${printForm}" \
        "Terminated jobs not registered in SQL" $notFoundInSQL
    fi
  fi
fi

# Inspect dead jobs
unset liveJBs
liveJBs=(`cat ${liveLog}`)
liveJBsCount=${#liveJBs[@]}
# w=${#liveJBsCount}
# let FPBlength=45-w-w+2

notFoundInSQL=0
if [ $liveJBsCount -ne 0 ]; then
#   if [ $VERBOSE -eq 1 ]; then
#     printf "${printForm}" "Active jobs found" $liveJBsCount
#   fi
  i=0; while [ $i -lt $liveJBsCount ]; do
    lvJB=${liveJBs[$i]}
    lvJB_ID=`echo $lvJB | sed -e 's/SLID//' -e 's/_.*$//'`
    lvJB_JD=`echo $lvJB | sed 's/^SLID[0-9]*_//'`

    sqlID=`${SQL} ${SQLDB} \
      "SELECT ID FROM JOBS WHERE (JOBID=${lvJB_ID} OR JOBDIR LIKE '${lvJB_JD}' );"`

    if [ ${#sqlID} -gt 0 ]; then
      # The job has been found in the register

      # Check progress of the live job
      target=`cat ${lvJB}/*.ini |\
        grep "Number of data blocks" | sed 's/^.*:\ *//'`
      present=`ls -1d ${lvJB}/*part* |wc -l`
      lvJB_prog=`bc -l <<< $present/$target |\
        sed -e 's/00*$/0/' -e 's/^\./0\./'`

      # Update SQL record
      ${SQL} ${SQLDB} \
        "UPDATE ${SQLTABLE} SET PROGRES='${lvJB_prog}', STATUS='started' WHERE ID=${sqlID};"
      else
        (( notFoundInSQL++ ))
    fi
    (( i++ ))

    if [ $VERBOSE -eq 1 ]; then
      # Prepare progress bar
      progress_bar=`$FPB ${i} ${liveJBsCount} ${FPBlength}`
      progress_msg=`printf "${printFormBar}"\
        "Updating active jobs" ${i} ${liveJBsCount} "${progress_bar}"`
      # Display progress bar
      echo -ne "${progress_msg}"\\r
    fi
  done

  if [ $VERBOSE -eq 1 ];then
    echo
    if [ $notFoundInSQL -gt 0 ]; then
      printf "${printForm}" "Active jobs not registered in SQL" $notFoundInSQL
    fi
  fi
fi


# List SQL active records
${SQL} ${SQLDB} \
  "SELECT JOBDIR FROM JOBS WHERE STATUS LIKE 'started';"  > $sqlLog

# Remove present job directories from the SQL list log
# srcJBs=(`cat ${scrLog}`)
# srcJBsCount=${#srcJBs[@]}
# w=${#srcJBsCount}
# let FPBlength=45-w-w+2
i=0; while [ $i -lt ${srcJBsCount} ]; do
  sJB_JD=`echo ${srcJBs[$i]} | sed 's/^SLID[0-9]*_//'`
  eval "sed -i '/${sJB_JD}/d' ${sqlLog}"
  (( i++ ))
  if [ $VERBOSE -eq 1 ]; then
    # Prepare progress bar
    progress_bar=`$FPB ${i} ${srcJBsCount} ${FPBlength}`
    progress_msg=`printf "${printFormBar}"\
      "Looking for ghosts in DB" ${i} ${srcJBsCount} "${progress_bar}"`
    # Display progress bar
    echo -ne "${progress_msg}"\\r
  fi
done

if [ $VERBOSE -eq 1 ]; then
  echo
fi

# Ghost missing job directories in SQL records
ghsJBs=(`cat ${sqlLog}`)
ghsJBsCount=${#ghsJBs[@]}
# w=${#ghsJBsCount}
# let FPBlength=45-w-w+2

if [ $ghsJBsCount -ne 0 ]; then
  if [ $VERBOSE -eq 1 ]; then
    printf "${printForm}" "Ghosts in SQL found" $ghsJBsCount
  fi
  i=0; while [ $i -lt $ghsJBsCount ]; do
    ghsJB=${ghsJBs[$i]}
    # Update SQL record
#    ${SQL} ${SQLDB} \
#      "UPDATE ${SQLTABLE} SET STATUS='ghost' WHERE JOBDIR LIKE '${ghsJB}';"
    (( i++ ))

    if [ $VERBOSE -eq 1 ]; then
      # Prepare progress bar
      progress_bar=`$FPB ${i} ${ghsJBsCount} ${FPBlength}`
      progress_msg=`printf "${printFormBar}"\
        "Marking ghosts in DB" ${i} ${ghsJBsCount} "${progress_bar}"`
      # Display progress bar
      echo -ne "${progress_msg}"\\r
    fi
  done

  if [ $VERBOSE -eq 1 ];then
    echo
  fi
fi

# Remove logs
rm $scrLog $deadLog $liveLog $sqlLog

exit 0
