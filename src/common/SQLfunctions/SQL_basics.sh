#!/bin/bash

# Test hostname before SQL access
SQLtestHostname(){
  if [ ${useSQL} -eq 1 ] && [[ `uname -n` = "eagle.man.poznan.pl" ]]; then
    useSQL=0
    echo " ${_RED}Cannot use SQL funcionality at the head node${_RST}"
    printf " run:\n\tsrun -pstandard --pty /bin/bash\n"
    if [ ${SQLavailStrictMode} -eq 0 ]; then
      printf " Continue in non-SQL mode [Y/n]? "; read userResp
      if [[ "${userResp}" = "n" ]] || [[ "${userResp}" = "N" ]]; then
        exit 0
      fi
      continueWithoutSQL=1
    else 
      exit 0
    fi
  fi
}

# Test if the DB exist
SQLDBpresent(){
  dbName=${SQLDB##/*/}
  if [ ${useSQL} -eq 1 ]; then
    if [ ! -f ${SQLDB} ]; then
      useSQL=0
      if [ $VERBOSE -eq 1 ]; then
        printf " ${_RED}Selected DB (%s) not found.\n ${_YEL}Swithing to non-SQL mode${_RST}\n"\
          ${dbName}
      fi
    else
      if [ $VERBOSE -eq 1 ]; then
        printf " Running with SQL enabled. Using %s\n" "${_YEL}${_BLD}${dbName}${_RST}"
      fi
    fi
  fi
}

SQLconnect(){
  SQLQUERRY="$1"
  WD_LIMIT_COUNT=60
  if [ ${useSQL} -ne 0 ] && [ ${#SQLQUERRY} -gt 0 ]; then
    sqlActionStatus=5
    sqlWatchDog=0
    while [ ${sqlActionStatus} -ne 0 ] && [ $sqlWatchDog -lt $WD_LIMIT_COUNT ]; do
      ${SQL} ${SQLDB} "${SQLQUERRY}"
      sqlActionStatus=$?
      if [ $sqlActionStatus -ne 0 ]; then
        (( sqlWatchDog++ ))
        sleep $(expr ${RANDOM:1:1} + 1)
        echo " SQL connection timeout. Waiting ${sqlWatchDog}/${WD_LIMIT_COUNT}" >> ${log:-/dev/null}
      fi
    done
  fi
}

SQLprogresHistogram(){
  hData=(\
    `${SQL} ${SQLDB} "SELECT COUNT(ID) FROM ${SQLTABLE} WHERE (PROGRES >0.0  AND PROGRES <=0.05);"` \
    `${SQL} ${SQLDB} "SELECT COUNT(ID) FROM ${SQLTABLE} WHERE (PROGRES >0.05 AND PROGRES <=0.10);"` \
    `${SQL} ${SQLDB} "SELECT COUNT(ID) FROM ${SQLTABLE} WHERE (PROGRES >0.1  AND PROGRES <=0.15);"` \
    `${SQL} ${SQLDB} "SELECT COUNT(ID) FROM ${SQLTABLE} WHERE (PROGRES >0.15 AND PROGRES <=0.20);"` \
    `${SQL} ${SQLDB} "SELECT COUNT(ID) FROM ${SQLTABLE} WHERE (PROGRES >0.2  AND PROGRES <=0.25);"` \
    `${SQL} ${SQLDB} "SELECT COUNT(ID) FROM ${SQLTABLE} WHERE (PROGRES >0.25 AND PROGRES <=0.30);"` \
    `${SQL} ${SQLDB} "SELECT COUNT(ID) FROM ${SQLTABLE} WHERE (PROGRES >0.3  AND PROGRES <=0.35);"` \
    `${SQL} ${SQLDB} "SELECT COUNT(ID) FROM ${SQLTABLE} WHERE (PROGRES >0.35 AND PROGRES <=0.40);"` \
    `${SQL} ${SQLDB} "SELECT COUNT(ID) FROM ${SQLTABLE} WHERE (PROGRES >0.4  AND PROGRES <=0.45);"` \
    `${SQL} ${SQLDB} "SELECT COUNT(ID) FROM ${SQLTABLE} WHERE (PROGRES >0.45 AND PROGRES <=0.50);"` \
    `${SQL} ${SQLDB} "SELECT COUNT(ID) FROM ${SQLTABLE} WHERE (PROGRES >0.5  AND PROGRES <=0.55);"` \
    `${SQL} ${SQLDB} "SELECT COUNT(ID) FROM ${SQLTABLE} WHERE (PROGRES >0.55 AND PROGRES <=0.60);"` \
    `${SQL} ${SQLDB} "SELECT COUNT(ID) FROM ${SQLTABLE} WHERE (PROGRES >0.6  AND PROGRES <=0.65);"` \
    `${SQL} ${SQLDB} "SELECT COUNT(ID) FROM ${SQLTABLE} WHERE (PROGRES >0.65 AND PROGRES <=0.70);"` \
    `${SQL} ${SQLDB} "SELECT COUNT(ID) FROM ${SQLTABLE} WHERE (PROGRES >0.7  AND PROGRES <=0.75);"` \
    `${SQL} ${SQLDB} "SELECT COUNT(ID) FROM ${SQLTABLE} WHERE (PROGRES >0.75 AND PROGRES <=0.80);"` \
    `${SQL} ${SQLDB} "SELECT COUNT(ID) FROM ${SQLTABLE} WHERE (PROGRES >0.8  AND PROGRES <=0.85);"` \
    `${SQL} ${SQLDB} "SELECT COUNT(ID) FROM ${SQLTABLE} WHERE (PROGRES >0.85 AND PROGRES <=0.90);"` \
    `${SQL} ${SQLDB} "SELECT COUNT(ID) FROM ${SQLTABLE} WHERE (PROGRES >0.9  AND PROGRES <=0.95);"` \
    `${SQL} ${SQLDB} "SELECT COUNT(ID) FROM ${SQLTABLE} WHERE (PROGRES >0.95 AND PROGRES < 1.00);"` )

  bins=${#hData[@]}
  binSize=`echo "scale=0; 100.0/${bins}" |bc`
  total=0
  i=0; while [ $i -lt ${bins} ]; do
    total=$(expr $total + ${hData[$i]})
    (( i++ ))
  done
  echo " MIN       N    MAX    Histogram"
  i=0; while [ $i -lt ${bins} ]; do
    hBar=`$FPB ${hData[$i]} $total 40`
    printf " %3d%% < %${#total}d <= %3d%% | %s\n" \
      $(expr 0 + ${i} \* ${binSize}) \
      ${hData[$i]} \
      $(expr ${binSize} + ${i} \* ${binSize})\
      "${hBar}"
  (( i++ ))
  done
}
