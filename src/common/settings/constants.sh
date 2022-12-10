#!/bin/bash

# Colour definitions
_RED=$(tput setaf 1)
_GRE=$(tput setaf 2)
_YEL=$(tput setaf 3)
_BLE=$(tput setaf 4)
_PRP=$(tput setaf 5)

_BLD=$(tput bold)

_RST=$(tput sgr0)


# Output message definitions
 msg[0]="${_BLD}${_GRE}OK${_RST}"
 msg[1]="${_BLD}${_GRE}done${_RST}"
 msg[2]="${_BLD}${_GRE}found${_RST}"
 msg[3]="${_BLD}${_GRE}submitting jobs${_RST}"
 msg[4]="${_BLD}${_YEL}match${_RST}"
msg[10]="${_BLD}${_RED}ERR${_RST}"
msg[11]="${_BLD}${_RED}failed${_RST}"
msg[12]="${_BLD}${_RED}missing${_RST}"
msg[13]="${_BLD}${_RED}terminated${_RST}"
msg[14]="${_BLD}${_RED}no match${_RST}"
msg[15]="${_BLD}${_RED}overwritten${_RST}"

G_ok=${msg[0]}
G_done=${msg[1]}
G_found=${msg[2]}

R_err=${msg[10]}
R_failed=${msg[11]}

# Constant settings
today=`eval date +%F`
dateTime=`date +"%F_%H-%M-%S"`

STARTDIR=$PWD

# Defaults
VERBOSE=1

# SQL constants
SQL="/usr/bin/sqlite3"
DBNAME="jobRegister.db"
#DBNAME="jobRegister_test.db"
SQLTABLE="JOBS"
DBFOLDER="${HOME}/main/work/DB"
SQLDB="${DBFOLDER}/${DBNAME}"
WD_LIMIT_SEC=60

# FPB settings
FPB=${CSUT_CORE_INC}/utils/fancypb

