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

