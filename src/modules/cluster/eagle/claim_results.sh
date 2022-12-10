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

# Script variables
header="${_BLD}${_PRP}Inspect directory with simulations and claim results${_RST}"
useSQL=0
mask="*"

# Surce module-level utility variables
source ${CORE}/init/set_module_constants.sh

# Display greetings 
source ${CORE}/init/credits.sh "${header}"

# define script-wide env. variables
source ${CORE}/init/declare_environment_vars.sh

# get names of system-wide env. variables
env_dirs=( SCRATCH JOBSTARTER SIMDATA DBFOLDER CODES )

# Verify that environment variables are set correctly
source ${CSUT_CORE_INC}/settings/check_environment_vars.sh\
  ${env_dirs[@]} ${script_dirs[@]} FPB

while getopts svm: argv
do
    case "${argv}" in
        s) useSQL=1 ;;
        v) VERBOSE=1 ;;
        m) mask=${OPTARG} ;;
    esac
done

# When enabled, test if SQL database is availiable
if [ ${useSQL} -eq 1 ] && [ ! -f ${SQLDB} ]; then
  useSQL=0
elif [ ${useSQL} -eq 1 ] && [ -f ${SQLDB} ]; then
  printf " Running with SQL enabled. Using %s\n" ${SQLDB##/*/}
fi

# Off we go
cd ${JOBSTARTER}

# Extract all the different dates
if [ ${useSQL} -eq 1 ]; then
  sets=(`${SQL} ${SQLDB} "SELECT JOBDIR FROM JOBS WHERE STATUS LIKE 'finished';" |\
    sed 's/_.*_\([0-9][0-9][0-9][0-9]\)_[0-9][0-9]-[0-9][0-9]-[0-9][0-9]_.*/_\1/' | sort -u`)
  fin_count=`${SQL} ${SQLDB} "SELECT COUNT(ID) FROM JOBS WHERE STATUS LIKE 'finished';"`
  fail_count=`${SQL} ${SQLDB} "SELECT COUNT(ID) FROM JOBS WHERE STATUS LIKE 'failed';"`
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


 # subsets=(`ls -1d ${CS}* | grep -v "\." | sed 's/^.*_\([0-9][0-9]-[0-9][0-9]-[0-9][0-9]\)_.*/\1/' |sort -u`)
# Present job sets to inspect or bail out if nothing to do
if [ $fin_count -gt 0 ]; then
  echo -e "\n List of job sets to inspect:"
  j=0
  while [ $j -lt $setsN ]; do
    s=`echo ${sets[$j]} | cut -d '_' -f 1` # Date signature
    n=`echo ${sets[$j]} | cut -d '_' -f 2` # N-particles signature
    if [ $useSQL -eq 1 ]; then
      jobsInSet=`${SQL} ${SQLDB} "SELECT COUNT(ID) FROM JOBS WHERE JOBDIR LIKE '${s}%_${n}_%';"`
setFinCount=`${SQL} ${SQLDB} "SELECT COUNT(ID) FROM JOBS WHERE (STATUS LIKE 'finished' AND JOBDIR LIKE '${s}%_${n}_%');"`
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

i=$setIDstart;    # Loop over selected sets
while [ $i -le $setIDend ]; do

  s=`echo ${sets[$i]} | cut -d '_' -f 1` # Date signature
  n=`echo ${sets[$i]} | cut -d '_' -f 2` # N-particles signature

  printf "\n Current job set: [ %${#setsN}d ] %s %s\n" $i ${s} ${n}
  echo -ne " Preparing the list of jobs ... "\\r

  if [ $useSQL -eq 1 ]; then
    jobSel=(\
    `${SQL} ${SQLDB} "SELECT JOBDIR FROM JOBS WHERE (STATUS LIKE 'finished' AND JOBDIR LIKE '${s}%_${n}_%');"`)
  else
    jobSel=(`find ./${s}*_${n}_* -iname "JOB*finished.txt" |\
      sed 's;/JOB.*;;' | sed 's;^\./;;' |  sort`);
  fi
  jobSelN=${#jobSel[@]}
  printf " %-60s\n" "Selected ${jobSelN} jobs"
  
  # Skip the rest of thie loop iteration if smoehow no jobs are found
  if [ ${jobSelN} -eq 0 ]; then
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
  timeLog=$DEST/job_execution_times.csv
  stepLog=$DEST/job_mc_steps.csv
  if [ -f ${timeLog} ]; then 
    rm ${timeLog}
  fi
  if [ -f ${stepLog} ]; then
    rm ${stepLog}
  fi

  # Loop over job directories and copy results to the repository
  cpyCount=0
  cpyFailCount=0
  j=0; while [ $j -lt ${jobSelN} ]; do
    # Select job directory
    JB=${jobSel[$j]}
    # Establish archive name
    resArchive=`ls -1 ${JB}/${s}_*_${n}_*[tb][gz][[z2] 2>/dev/null | sed 's;^.*/;;'`
    # Prepare progress bar
    let jj=j+1
    progress_bar=`$FPB ${jj} ${jobSelN} 48`
    progress_msg=`printf " [ %${#jobSelN}d/${jobSelN} ] CPY %${#jobSelN}d FAIL %d %s"\
      $j $cpyCount $cpyFailCount "${progress_bar}"`
    if [ -f ${JB}/${resArchive} ]; then
      # Copy data archive to destination repository
      # syntax: Copy <file name> <source path> <target path>
      source ${CORE}/utils/copy_and_verify_archive.sh ${resArchive} ${JB} ${DEST}
      echo -ne "${progress_msg}"\\r

      # Statistics: get execution time
      mm=`cat ${JB}/JOB_exec_time.txt | sed 's/^real\t//' | sed 's/m.*$//'`
      ss=`cat ${JB}/JOB_exec_time.txt | sed 's/^real.*m//'| sed 's/\..*$//'`
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
      sqlUpdateStatus=5
      sqlWatchDog=0
        while [ ${sqlUpdateStatus} -ne 0 ] && [ $sqlWatchDog -lt $WD_LIMIT_SEC ]; do
          ${SQL} ${SQLDB} \
            "UPDATE ${SQLTABLE} SET STATUS='claimed' WHERE JOBDIR LIKE '${JB}';"
          sqlUpdateStatus=$?
          if [ $sqlUpdateStatus -ne 0 ]; then 
            (( sqlWatchDog++ ))
            sleep 1
          fi
        done
      fi

      (( cpyCount++ ))
    else
      printf " ${_RED}[%s]${_RST} %s %s\n" ${SNAME} ${R_err} "${JB} missing archive"
      (( cpyFailCount++ ))
    fi
    (( j++ ))
  done
  
  # Calculate and display averages for this set of jobs
  if [ $cpyCount -gt 0 ]; then
    source ${CORE}/utils/calculate_average_exectime.sh
  fi

  (( i++ ))
done

exit 0

