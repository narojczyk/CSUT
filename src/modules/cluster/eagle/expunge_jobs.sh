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
source ${CSUT_CORE_INC}/colours.sh
source ${CSUT_CORE_INC}/settings/set_constants.sh

# Script variables
header="${_BOLD}${_PURP}Inspect directory with simulations and erase old jobs${_RESET}"
useSQL=0
sqlAware=1
# mask="*"

# Surce module-level utility variables
source ${CORE}/init/set_module_constants.sh

# Display greetings
source ${CORE}/init/credits.sh "${header}"

# define script-wide env. variables
source ${CORE}/init/declare_environment_vars.sh

# get names of system-wide env. variables
env_dirs=( JOBSTARTER DBFOLDER )

# Verify that environment variables are set correctly
source ${CSUT_CORE_INC}/settings/check_environment_vars.sh\
  ${env_dirs[@]} ${script_dirs[@]} FPB

# while getopts svm: argv
while getopts sv argv
do
    case "${argv}" in
        s) useSQL=1 ;;
        v) VERBOSE=1 ;;
#         m) mask=${OPTARG} ;;
    esac
done

# When enabled, test if SQL database is availiable
if [ ${useSQL} -eq 1 ] || [ ${sqlAware} -eq 1 ]; then
  if [[ `uname -n` = "eagle.man.poznan.pl" ]]; then
    useSQL=0
    sqlAware=0
    echo " ${_RED}Cannot use SQL funcionality at the head node${_RESET}"
    printf " run:\n\tsrun -pstandard --pty /bin/bash\n"
    printf " or continue in non-SQL mode"; read trash
  fi
fi
if [ ${useSQL} -eq 1 ] && [ ! -f ${SQLDB} ]; then
  useSQL=0
  sqlAware=0
elif [ ${useSQL} -eq 0 ] && [ ! -f ${SQLDB} ]; then
  sqlAware=0
elif [ ${useSQL} -eq 1 ] && [ -f ${SQLDB} ]; then
  printf " Running with SQL enabled. Using %s\n" ${SQLDB##/*/}
fi

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
  jobSelArchive=(`ls -1d del_20??-${mask}*_001`)
  jobSelDelete=(`ls -1d del_20??-${mask}*_[0-9][0-9][0-9] | grep -v "_001$"`)
fi
jobSelArchiveN=${#jobSelArchive[@]}
jobSelDeleteN=${#jobSelDelete[@]}
printW=${#jobSelDeleteN}

printf " Found:\n"
printf " %${printW}d jobs to archive\n" $jobSelArchiveN
printf " %${printW}d jobs to delete\n" $jobSelDeleteN

printf "\n Archiving selected jobs for re-use\n"
i=0; while [ $i -lt ${jobSelArchiveN} ]; do
  JB=${jobSelArchive[$i]}
  # Prepare progress bar
  let ii=i+1
  progress_bar=`$FPB ${ii} ${jobSelArchiveN} 60`
  progress_msg=`printf " [ %${printW}d/%${printW}d ] %s"\
    ${ii} ${jobSelArchiveN} "${progress_bar}"`
  # Display progress bar
  echo -ne "${progress_msg}"\\r

  # Remove the entry from database
  if [ ${useSQL} -ne 0 ] || [ ${sqlAware} -ne 0 ]; then
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
    # Clean directory before archiving
    rm ${JB}/JOB_* ${JB}/2*.[bt][zg][z2]
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
i=0; while [ $i -lt ${jobSelDeleteN} ]; do
  JB=${jobSelDelete[$i]}
  # Prepare progress bar
  let ii=i+1
  progress_bar=`$FPB ${ii} ${jobSelDeleteN} 60`
  progress_msg=`printf " [ %${printW}d/%${printW}d ] %s"\
    ${ii} ${jobSelDeleteN} "${progress_bar}"`
  # Display progress bar
  echo -ne "${progress_msg}"\\r

  # Remove the entry from database
  if [ ${useSQL} -ne 0 ] || [ ${sqlAware} -ne 0 ]; then
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
