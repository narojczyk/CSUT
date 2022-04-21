#!/bin/bash

# Check if the required env. variables are set

error_msg(){
  lvl=${2:-"ERR"}
  printf " [%s] Variable %s is not set or the directory does not exist.\n"\
    $lvl $1; }

error_msg_access_perm(){
  lvl=${3:-"ERR"}
  printf " [%s] No %s permissions granted on %s\n" $lvl $1 $2; }



# Array with environment variables names, to hold paths to their respective
# directories (passed as an array of arguments)
argv=( "$@" )
argc=${#argv[@]}

echo "checking $argc variables"

for (( i=0; i<argc; i++ ));
do
  var=${argv[$i]}
  # parse the contents of 'var' with indirect parameter expansion
  # https://stackoverflow.com/questions/1921279/how-to-get-a-variable-value-if-variable-name-is-stored-as-string
  env_var=${!var}
  if [ -z ${env_var:+x} ] || [ ! -d ${env_var} ]; then
    error_msg $var
    exit 1;
  elif [ -d ${env_var} ] && [ ! -r ${env_var} ]; then
    error_msg_access_perm "read" $var
    exit 1;
  # Test write premissions only for mandatory scratch directories
  elif [ -d ${env_var} ] && [[ $var == *"SCRATCH"* ]] && [ ! -w ${env_var} ]; then
    error_msg_access_perm "write" $var
    exit 1;
  elif [ -d ${env_var} ] && [ ! -x ${env_var} ]; then
    error_msg_access_perm "execute" $var
    exit 1;
  fi
done
