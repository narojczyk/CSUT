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

# Script variables
mask="*"

while getopts svm: argv
do
    case "${argv}" in
        s) useSQL=1 ;;
        v) VERBOSE=0 ;;
        m) mask=${OPTARG} ;;
    esac
done

# Display greetings
source ${CSUT_CORE_INC}/header.sh \
  "${_BLD}${_PRP}Inspect directory with simulations and claim results${_RST}"

# define module-level resource paths
source ${CORE}/init/set_module_resource_paths.sh

# get names of system-wide env. variables
env_dirs=( SCRATCH JOBSTARTER SIMDATA DBFOLDER CODES )

# Verify that environment variables are set correctly
source ${CSUT_CORE_INC}/settings/check_environment_vars.sh\
  ${env_dirs[@]} ${script_dirs[@]} FPB

# Surce module-level utility variables
source ${INITIALS}/set_module_constants.sh

# When enabled, test if SQL database is availiable
SQLtestHostname

# Test if DB is present
SQLDBpresent

# Off we go
cd ${JOBSTARTER}

log="${JOBSTARTER}/${logFileName}"
if [ ${VERBOSE} -eq 1 ]; then
  echo " Log to file: ${_YEL}${_BLD}${logFileName}${_RST} on JOBSTARTER"
fi

# Extract all the different dates
if [ ${useSQL} -eq 1 ]; then
  SQLQUERRY="SELECT JOBDIR FROM ${SQLTABLE} WHERE STATUS LIKE 'finished';"
  sets=(`SQLconnect "${SQLQUERRY}" |\
    sed 's/_.*_\([0-9][0-9][0-9][0-9]\)_[0-9][0-9]-[0-9][0-9]-[0-9][0-9]_.*/_\1/' | sort -u`)
  SQLQUERRY="SELECT COUNT(ID) FROM ${SQLTABLE} WHERE STATUS LIKE 'finished';"
  fin_count=`SQLconnect "${SQLQUERRY}"`
  SQLQUERRY="SELECT COUNT(ID) FROM ${SQLTABLE} WHERE STATUS LIKE 'failed';"
  fail_count=`SQLconnect "${SQLQUERRY}"`
else
  sets=(`ls -1d 20??-${mask}* | grep -v "\." |\
    sed 's/\(20..-..-..\)_.*_\([0-9][0-9][0-9][0-9]\)_[0-9][0-9]-[0-9][0-9]-[0-9][0-9]_.*/\1_\2/' |\
    sort -u`)
  fin_count=`find ./20??-${mask}* -iname "JOB*finished.txt" |wc -l`;
  fail_count=`find ./20??-${mask}* -iname "JOB*failed.txt" |wc -l`;
fi
setsN=${#sets[@]}

echo " Found:"
echo " $setsN set(s) of jobs"
if [ $fail_count -ne 0 ]; then
  echo " $fail_count marked as failed" #TODO: kolorem
fi
echo " $fin_count marked as completed"

# Present job sets to inspect or bail out if nothing to do
if [ $fin_count -gt 0 ]; then
  echo -e "\n List of job sets to inspect:"
  j=0
  while [ $j -lt $setsN ]; do
    s=`echo ${sets[$j]} | cut -d '_' -f 1` # Date signature
    n=`echo ${sets[$j]} | cut -d '_' -f 2` # N-particles signature
    if [ $useSQL -eq 1 ]; then
      SQLQUERRY="SELECT COUNT(ID) FROM ${SQLTABLE} WHERE JOBDIR LIKE '${s}%_${n}_%';"
      jobsInSet=`SQLconnect "${SQLQUERRY}"`
      SQLQUERRY="SELECT COUNT(ID) FROM ${SQLTABLE} WHERE (STATUS LIKE 'finished' AND JOBDIR LIKE '${s}%_${n}_%');"
      setFinCount=`SQLconnect "${SQLQUERRY}"`
    else
      jobsInSet=`ls -1d ${s}*_${n}_* | wc -l`
      setFinCount=`ls -1d ${s}*_${n}_*/*finished* 2>/dev/null | wc -l`
    fi
    prcfin=`echo "scale=1; ${setFinCount}*100/${jobsInSet}" |bc`
    printf "\t[ %${#setsN}d ] %s N= %s (%5d/%5d jobs %5s%% )\n" $j ${s} ${n} $setFinCount $jobsInSet $prcfin
    (( j++ ))
  done
  printf " Select job set to inspect for results [all]: " ;  read setID
  if [ ! $setID ]; then
    setIDstart=0
    setIDend=$setsN; (( setIDend-- ))
  elif [ $setID -lt 0 ] || [ $setID -ge $setsN ]; then
    printf " %s [%s] index out of range\n" ${R_err} $SNAME
    exit 1
  else
    setIDstart=$setID
    setIDend=$setID
  fi
else
  echo -e "\n Nothing to do at the moment"
  exit 0
fi

# Set initial control array for printing progress bar (see IOfunctions)
dpctrl=( 0 0 76 ' ' )


i=$setIDstart;    # Loop over selected sets
while [ $i -le $setIDend ]; do

  s=`echo ${sets[$i]} | cut -d '_' -f 1` # Date signature
  n=`echo ${sets[$i]} | cut -d '_' -f 2` # N-particles signature

  printf "\n Current job set: [ %${#setsN}d ] %s %s\n" $i ${s} ${n}
  echo -ne " Preparing the list of jobs ... "\\r

  if [ $useSQL -eq 1 ]; then
    SQLQUERRY="SELECT JOBDIR FROM ${SQLTABLE} WHERE (STATUS LIKE 'finished' AND JOBDIR LIKE '${s}%_${n}_%');"
    jobSel=( `SQLconnect "${SQLQUERRY}"` )
  else
    jobSel=(`find ./${s}*_${n}_* -iname "JOB*finished.txt" |\
      sed 's;/JOB.*;;' | sed 's;^\./;;' |  sort`);
  fi
  jobSelN=${#jobSel[@]}
  printf " %-60s\n" "Selected ${jobSelN} jobs"

  printFormBar=" [ %${#jobSelN}d/${jobSelN} ] CPY %${#jobSelN}d FAIL %d"
  
  # Skip the rest of thie loop iteration if smoehow no jobs are found
  if [ ${jobSelN} -eq 0 ]; then
    (( i++ ))
    continue
  fi

  # Based on the first job name, select the main repository
  if [[ ${jobSel[0]} == *"_3DNpT_HS_SPH_"* ]]; then
    REPOSITORY="sph3d_NpT_HS"
  elif [[ ${jobSel[0]} == *"_3DNpT_HS_DIM_"* ]]; then
    REPOSITORY="dim3d_NpT_HS"
  else
    REPOSITORY=""
  fi

  # Find or create directory for the simulation results
  SUBREPO=`ls -1d ${SIMDATA}/${REPOSITORY}/${s}*_${n}_*  2>/dev/null | sed 's;^.*/;;'`
  if [ ${#SUBREPO} -eq 0 ]; then
    repoDefSuffix="${n}_auto"
    printf " Missing repository for ${s}*${n} data\n Hint: "
    printf "%s\n" ${jobSel[0]#${s}_}
    printf " Enter suffix for repository ${s}_ [${repoDefSuffix}]: "; read repoSuffix
    if [ ${#repoSuffix} -eq 0 ]; then
      repoSuffix=${repoDefSuffix}
    fi
    SUBREPO="${s}_${repoSuffix}"
    mkdir ${SIMDATA}/${REPOSITORY}/${SUBREPO}
  fi
  DEST="${SIMDATA}/${REPOSITORY}/${SUBREPO}"
  printf " Store simulation data in: \$SIMDATA/%s\n" "${REPOSITORY}/${SUBREPO}"
  
  # Remove old logs
  timeLog=$DEST/${timeFileName}
  stepLog=$DEST/${stepFileName}
  if [ -f ${timeLog} ]; then 
    rm ${timeLog}
  fi
  if [ -f ${stepLog} ]; then
    rm ${stepLog}
  fi

  # Loop over job directories and copy results to the repository
  cpyCount=0
  cpyFailCount=0
  dpctrl[1]=${jobSelN}
  j=0; while [ $j -lt ${jobSelN} ]; do
    # Select job directory
    JB=${jobSel[$j]}
    # Establish archive name
    resArchive=`ls -1 ${JB}/${s}_*_${n}_*[tb][gz][[z2] 2>/dev/null | sed 's;^.*/;;'`
    if [ -f ${JB}/${resArchive} ]; then
      # Copy data archive to destination repository
      # syntax: Copy <file name> <source path> <target path>
      source ${UTILS}/copy_and_verify_archive.sh ${resArchive} ${JB} ${DEST}

      # Statistics: get execution time
      mm=`cat ${JB}/${JBexecTime} | sed 's/^real\t//' | sed 's/m.*$//'`
      ss=`cat ${JB}/${JBexecTime} | sed 's/^real.*m//'| sed 's/\..*$//'`
      echo -n "$mm" >> ${timeLog}
      echo "scale=3; ${ss}.09/60.0" |bc >> ${timeLog}

      # Statistics: get simulation length
      mcs=`cat ${JB}/*.ini | grep "Monte Carlo steps"  | sed 's/^.*:\ //'`
      st0=`cat ${JB}/*.ini | grep "Start at structure" | sed 's/^.*:\ //'`
      st1=`cat ${JB}/*.ini | grep "End at structure"   | sed 's/^.*:\ //'`
      (( st1++ ))
      let stn=st1-st0
      mcs_total=`echo "$stn * $mcs" | bc`
      echo "$mcs_total" >> ${stepLog}

      # Mark job directory for removal
      mv ${JB} del_${JB}
      
      ### Log into SQL if enabled
      if [ $useSQL -eq 1 ]; then
        SQLQUERRY="UPDATE ${SQLTABLE} SET STATUS='claimed' WHERE JOBDIR LIKE '${JB}';"
        SQLconnect "${SQLQUERRY}"
      fi

      (( cpyCount++ ))
    else
      printf " ${_RED}[%s]${_RST} %s %s\n" ${SNAME} ${R_err} "${JB} missing archive"
      (( cpyFailCount++ ))
    fi
    (( j++ ))
    dpctrl[0]=${j}
    dpctrl[3]=`printf "${printFormBar}" $j $cpyCount $cpyFailCount`
    display_progres
  done
  
  # Calculate and display averages for this set of jobs
  if [ $cpyCount -gt 0 ]; then
    source ${UTILS}/calculate_average_exectime.sh
  fi

  (( i++ ))
done

exit 0

