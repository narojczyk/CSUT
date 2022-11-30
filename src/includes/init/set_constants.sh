#!/bin/bash

# Output message definitions
msg[0]="$(tput bold)$(tput setaf 2)OK$(tput sgr0)"
msg[1]="$(tput bold)$(tput setaf 2)done$(tput sgr0)"
msg[2]="$(tput bold)$(tput setaf 2)found$(tput sgr0)"
msg[3]="$(tput bold)$(tput setaf 2)submitting jobs$(tput sgr0)"
msg[4]="$(tput bold)$(tput setaf 3)match$(tput sgr0)"
msg[10]="$(tput bold)$(tput setaf 1)ERR$(tput sgr0)"
msg[11]="$(tput bold)$(tput setaf 1)failed$(tput sgr0)"
msg[12]="$(tput bold)$(tput setaf 1)missing$(tput sgr0)"
msg[13]="$(tput bold)$(tput setaf 1)terminated$(tput sgr0)"
msg[14]="$(tput bold)$(tput setaf 1)no match$(tput sgr0)"
msg[15]="$(tput bold)$(tput setaf 1)overwritten$(tput sgr0)"

G_ok=${msg[0]}
G_done=${msg[1]}
G_found=${msg[2]}

R_err=${msg[10]}
R_failed=${msg[11]}

# Constant settings
today=`eval date +%F`
dateTime=`date +"%F_%H-%M-%S"`

STARTDIR=$PWD

# SQL constants
SQL="/usr/bin/sqlite3"
DBNAME="jobRegister.db"
SQLTABLE="JOBS"
DBFOLDER="${HOME}/main/work/DB"
SQLDB="${DBFOLDER}/${DBNAME}"


