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

while getopts sv argv
do
    case "${argv}" in
        s) useSQL=1 ;;
        v) VERBOSE=0 ;;
    esac
done

# Display greetings
source ${CSUT_CORE_INC}/header.sh \
  "${_BLD}${_PRP}Inspect directory with simulations and erase old jobs${_RST}"

# Surce module-level resource paths
source ${CORE}/init/set_module_resource_paths.sh

# get names of system-wide env. variables
env_dirs=( JOBSTARTER DBFOLDER )

# Verify that environment variables are set correctly
source ${CSUT_CORE_INC}/settings/check_environment_vars.sh\
  ${env_dirs[@]} ${script_dirs[@]} FPB

# Surce module-level utility variables
source ${INITIALS}/set_module_constants.sh

# When enabled, test if SQL database is availiable
SQLtestHostname

# Test if DB is present
SQLDBpresent

# Set initial control array for printing progress bar (see IOfunctions)
dpctrl=( 0 0 66 ' ' )

# Off we go
cd ${JOBSTARTER}

# Get the list of directories
if [ ${useSQL} -eq 1 ]; then
  jobSelArchive=(\
    `${SQL} ${SQLDB} "SELECT JOBDIR FROM JOBS WHERE (STATUS LIKE 'claimed' AND JOBDIR LIKE '%_001' );" | sed 's/^/del_/' |\
     sort -u` )
  jobSelDelete=(\
    `${SQL} ${SQLDB} "SELECT JOBDIR FROM JOBS WHERE (STATUS LIKE 'claimed' AND JOBDIR NOT LIKE '%_001' );" | sed 's/^/del_/' |\
     sort -u` )
else
  jobSelArchive=(`ls -1d del_20??-${mask}*_001 2> /dev/null`)
  jobSelDelete=(`ls -1d del_20??-${mask}*_[0-9][0-9][0-9] 2>/dev/null | grep -v "_001$"`)
fi
jobSelArchiveN=${#jobSelArchive[@]}
jobSelDeleteN=${#jobSelDelete[@]}

printW=$(( ${#jobSelArchiveN} > ${#jobSelDeleteN} ? ${#jobSelArchiveN} : ${#jobSelDeleteN} ))
printFormBar=" [ %${printW}d/%${printW}d ]"

printf " Found:\n"
printf " %${printW}d jobs to archive\n" $jobSelArchiveN
printf " %${printW}d jobs to delete\n" $jobSelDeleteN

printf "\n Archiving selected jobs for re-use\n"
dpctrl[1]=${jobSelArchiveN}
i=0; while [ $i -lt ${jobSelArchiveN} ]; do
  JB=${jobSelArchive[$i]}
  dpctrl[0]=$(expr ${i} + 1)
  dpctrl[3]=`printf "${printFormBar}" ${dpctrl[0]} ${dpctrl[1]}`
  display_progres

  # Remove the entry from database
  if [ ${useSQL} -ne 0 ]; then
    sqlRemoveStatus=5
    sqlWatchDog=0
    while [ ${sqlRemoveStatus} -ne 0 ] && [ $sqlWatchDog -lt $WD_LIMIT_SEC ]; do
      ${SQL} ${SQLDB} "DELETE FROM JOBS WHERE JOBDIR LIKE '${JB#del_}';"
      sqlRemoveStatus=$?
      if [ $sqlRemoveStatus -ne 0 ]; then
        (( sqlWatchDog++ ))
        sleep 1
      fi
    done
  fi

  if [ -d ${JB} ]; then
    # Clean directory before archiving0
    rm ${JB}/JOB_* ${JB}/2*.[bt][zg][z2] ${JB}/*.chkp* ${JB}/*.part* ${JB}/*.msnap* 2>/dev/null
    # Archive job
    tar cjf ${JB}.bz2 ${JB}
    # Remove job directory
    rm -rf ${JB} 2>/dev/null
    # move the archive an appropriate location
    YY=`echo ${JB} | sed 's/del_//' | sed 's/-.*$//'`
    if [ -d _finished_${YY} ]; then
      mv ${JB}.bz2 _finished_${YY}/
    fi
  fi

  (( i++ ))
done

printf "\n Removing obsolete jobs\n"
dpctrl[1]=${jobSelDeleteN}
i=0; while [ $i -lt ${jobSelDeleteN} ]; do
  JB=${jobSelDelete[$i]}
  dpctrl[0]=$(expr ${i} + 1)
  dpctrl[3]=`printf "${printFormBar}" ${dpctrl[0]} ${dpctrl[1]}`
  display_progres

  # Remove the entry from database
  if [ ${useSQL} -ne 0 ]; then
    sqlRemoveStatus=5
    sqlWatchDog=0
    while [ ${sqlRemoveStatus} -ne 0 ] && [ $sqlWatchDog -lt $WD_LIMIT_SEC ]; do
      ${SQL} ${SQLDB} "DELETE FROM JOBS WHERE JOBDIR LIKE '${JB#del_}';"
      sqlRemoveStatus=$?
      if [ $sqlRemoveStatus -ne 0 ]; then
        (( sqlWatchDog++ ))
        sleep 1
      fi
    done
  fi

  if [ -d ${JB} ]; then
    rm -rf ${JB} 2>/dev/null
  fi

  (( i++ ))
done

echo
exit 0
