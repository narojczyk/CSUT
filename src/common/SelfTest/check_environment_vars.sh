#!/bin/bash

# Check if the required env. variables are set

error_msg(){
  lvl=${2:-"ERR"}
  printf " [%s] Variable %s is not set or the directory does not exist.\n"\
    $lvl $1; }

# Array with environment variables names, to hold paths to their respective
# directories
env_dirs=( SCRATCH0 CODESDIR SCRIPTDIR SIMDATA SIMPLOTS SIMRESULTS SIMREPORTS )

env_qty=${#env_dirs[@]}
for (( i=0; i<env_qty; i++ ));
do
  var=${env_dirs[$i]}
  # parse the contents of 'var' with indirect parameter expansion
  # https://stackoverflow.com/questions/1921279/how-to-get-a-variable-value-if-variable-name-is-stored-as-string
  env_var=${!var}
  if [ -z ${env_var+x} ] || [ ! -d ${env_var} ]; then
    error_msg $var
    exit 1;
  fi
done

# Check if the optional env. variables are set and act accordingly
# if they are not set.

if [ -z ${SCRATCH1+x} ] || [ ! -d ${SCRATCH1} ]; then
  error_msg "SCRATCH1" "WRN"
  # default to primary scratch if the secondary does not exist
  export SCRATCH1="${SCRATCH0}"
fi
