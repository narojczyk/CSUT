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

while getopts v argv
do
    case "${argv}" in
        v) VERBOSE=0 ;;
    esac
done

# Display greetings
source ${CSUT_CORE_INC}/header.sh \
  "${_BLD}${_PRP}Sync information about running jobs with SQL${_RST}"

# Script variables
useSQL=1

# Surce module-level resource paths
source ${CORE}/init/set_module_resource_paths.sh

# get names of system-wide env. variables
env_dirs=( SCRATCH JOBSTARTER DBFOLDER )

# Verify that environment variables are set correctly
source ${CSUT_CORE_INC}/settings/check_environment_vars.sh\
  ${env_dirs[@]} ${script_dirs[@]} FPB

# Surce module-level utility variables
source ${INITIALS}/set_module_constants.sh

# When enabled, test if SQL database is availiable
SQLavailStrictMode=1
SQLtestHostname

# Test if DB is present
SQLDBpresent

# Off we go
cd ${SCRATCH}

# Query system for actual running jobs
jobIDs=(\
  `squeue -u ${USER} -o  "%.8i %8P %.24j %3T %.10M %.9L %8R" |\
  grep RUN | sed 's/\ .*//'` )
jobIDsN=${#jobIDs[@]}

# Query SQL for recorded jobs
SQLQUERRY="SELECT COUNT(ID) FROM JOBS WHERE STATUS LIKE 'started';"
SQLJobCount=`SQLconnect "${SQLQUERRY}"`

if [ $VERBOSE -eq 1 ]; then
  # Set common printing parameters
  if [ ${#jobIDsN} -gt ${#SQLJobCount} ]; then
    WDTH=${#jobIDsN}
  else
    WDTH=${#SQLJobCount}
  fi

  printForm=" %-56s : %${WDTH}d\n"

  # Set initial control array for printing progress bar (see IOfunctions)
  dpctrl=( 0 0 66 ' ' )

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
  if [ ${WDTH} -lt ${#srcJBsCount} ]; then
    WDTH=${#srcJBsCount}
  fi
  printForm=" %-56s : %${WDTH}d\n"
  printFormBar=" %-24s (%${WDTH}d/%${WDTH}d)"
fi


# Generate the lists of active and dead jobs
dpctrl[1]=${jobIDsN}
i=0; while [ $i -lt ${jobIDsN} ]; do
  eval "sed -i '/${jobIDs[$i]}/d' ${deadLog}"
  cat ${scrLog} | grep ${jobIDs[$i]} >> ${liveLog}
  (( i++ ))
  dpctrl[0]=${i}
  dpctrl[3]=`printf "${printFormBar}" "Reading SCRATCH contents" ${i} ${jobIDsN}`
  display_progres
done

if [ $VERBOSE -eq 1 ]; then
  echo
fi

# Inspect dead jobs
unset deadJBs
deadJBs=(`cat ${deadLog}`)
deadJBsCount=${#deadJBs[@]}
notFoundInSQL=0

if [ $deadJBsCount -ne 0 ]; then
  dpctrl[1]=${deadJBsCount}
  i=0; while [ $i -lt $deadJBsCount ]; do
    dJB=${deadJBs[$i]}
    dJB_ID=`echo $dJB | sed -e 's/SLID//' -e 's/_.*$//'`
    dJB_JD=`echo $dJB | sed 's/^SLID[0-9]*_//'`

    SQLQUERRY="SELECT ID FROM JOBS WHERE (JOBID=${dJB_ID} OR JOBDIR LIKE '${dJB_JD}' );"
    sqlID=`SQLconnect "${SQLQUERRY}"`

    if [ ${#sqlID} -gt 0 ]; then
      # The job has been found in the register

      # Check progress of the dead job
      target=`cat ${dJB}/*.ini |\
        grep "Number of data blocks" | sed 's/^.*:\ *//'`
      present=`ls -1d ${dJB}/*part* |wc -l`
      dJB_prog=`bc -l <<< $present/$target |\
        sed -e 's/00*$/0/' -e 's/^\./0\./'`

      # Update SQL record
      SQLQUERRY="UPDATE ${SQLTABLE} SET PROGRES='${dJB_prog}', STATUS='terminated' WHERE ID=${sqlID};"
      SQLconnect "${SQLQUERRY}"
    else
      (( notFoundInSQL++ ))
    fi
    (( i++ ))
    dpctrl[0]=${i}
    dpctrl[3]=`printf "${printFormBar}" "Checking terminated jobs" ${i} ${deadJBsCount}`
    display_progres
  done

  if [ $VERBOSE -eq 1 ]; then
    echo
    if [ $notFoundInSQL -gt 0 ]; then
      printf "${printForm}" \
        "Terminated jobs not registered in SQL" $notFoundInSQL
    fi
  fi
fi

# Inspect live jobs
unset liveJBs
liveJBs=(`cat ${liveLog}`)
liveJBsCount=${#liveJBs[@]}

notFoundInSQL=0
if [ $liveJBsCount -ne 0 ]; then
  dpctrl[1]=${liveJBsCount}
  i=0; while [ $i -lt $liveJBsCount ]; do
    lvJB=${liveJBs[$i]}
    lvJB_ID=`echo $lvJB | sed -e 's/SLID//' -e 's/_.*$//'`
    lvJB_JD=`echo $lvJB | sed 's/^SLID[0-9]*_//'`

    SQLQUERRY="SELECT ID FROM JOBS WHERE (JOBID=${lvJB_ID} OR JOBDIR LIKE '${lvJB_JD}' );"
    sqlID=`SQLconnect "${SQLQUERRY}"`

    if [ ${#sqlID} -gt 0 ] && [ -d ${lvJB} ]; then
      # The job has been found in the register
      # Check progress of the live job
      target=`cat ${lvJB}/*.ini |\
        grep "Number of data blocks" | sed 's/^.*:\ *//'`
      present=`ls -1d ${lvJB}/*part* 2>/dev/null |wc -l`
      lvJB_prog=`bc -l <<< $present/$target |\
        sed -e 's/00*$/0/' -e 's/^\./0\./'`

      # Update SQL record
      SQLQUERRY="UPDATE ${SQLTABLE} SET PROGRES='${lvJB_prog}', STATUS='started' WHERE ID=${sqlID};"
      SQLconnect "${SQLQUERRY}"
    else
      (( notFoundInSQL++ ))
    fi
    (( i++ ))

    dpctrl[0]=${i}
    dpctrl[3]=`printf "${printFormBar}" "Updating active jobs" ${i} ${liveJBsCount}`
    display_progres
  done

  if [ $VERBOSE -eq 1 ];then
    echo
    if [ $notFoundInSQL -gt 0 ]; then
      printf "${printForm}" "Active jobs not registered in SQL" $notFoundInSQL
    fi
  fi
fi


# List SQL active records
#${SQL} ${SQLDB} \
#  "SELECT JOBDIR FROM JOBS WHERE STATUS LIKE 'started';"  > $sqlLog

# Remove present job directories from the SQL list log
#dpctrl[1]=${srcJBsCount}
#i=0; while [ $i -lt ${srcJBsCount} ]; do
#  sJB_JD=`echo ${srcJBs[$i]} | sed 's/^SLID[0-9]*_//'`
#  eval "sed -i '/${sJB_JD}/d' ${sqlLog}"
#  (( i++ ))
#  dpctrl[0]=${i}
#  dpctrl[3]=`printf "${printFormBar}" "Looking for ghosts in DB" ${i} ${srcJBsCount}`
#  display_progres
#done
#
#if [ $VERBOSE -eq 1 ]; then
#  echo
#fi

# Ghost missing job directories in SQL records
#ghsJBs=(`cat ${sqlLog}`)
#ghsJBsCount=${#ghsJBs[@]}
#
#if [ $ghsJBsCount -ne 0 ]; then
#  if [ $VERBOSE -eq 1 ]; then
#    printf "${printForm}" "Ghosts in SQL found" $ghsJBsCount
#  fi
#  dpctrl[1]=${ghsJBsCount}
#  i=0; while [ $i -lt $ghsJBsCount ]; do
#    ghsJB=${ghsJBs[$i]}
#    # Update SQL record
##    ${SQL} ${SQLDB} \
##      "UPDATE ${SQLTABLE} SET STATUS='ghost' WHERE JOBDIR LIKE '${ghsJB}';"
#    (( i++ ))
#
#    dpctrl[0]=${i}
#    dpctrl[3]=`printf "${printFormBar}" "Marking ghosts in DB" ${i} ${ghsJBsCount}`
#    display_progres
#  done
#
#  if [ $VERBOSE -eq 1 ];then
#    echo
#  fi
#fi

# Display progres histogram
SQLprogresHistogram

# Remove logs
rm $scrLog $deadLog $liveLog #$sqlLog

exit 0
