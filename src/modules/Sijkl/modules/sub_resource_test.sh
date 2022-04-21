#!/bin/bash

#TODO: check all scripts in a loop if the exist and redeable
# check Datarepo
# check cwd for write premissions
printf "\n %-60s " "Final setting and resources check"

if [ ! -d $DATAREPO ] || [ ! -r $DATAREPO ]; then
  printf " [ %s ]\n" ${R_failed}
  printf "  [%s] Cannot access %s\n" $R_err $DATAREPO
  printf "  [%s] DATAREPO not found or no read permissions\n" $R_err
  exit 1
fi

printf " [ %s ]\n" ${G_ok}



return 0
