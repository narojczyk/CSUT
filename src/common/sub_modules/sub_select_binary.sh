#!/bin/bash

thisUnitBaseName=`echo $(basename $BASH_SOURCE)| sed 's/\.sh//'`

if [ ! -f $BINARYDIR/$defaultBinary ]; then
  Tbin=(`ls -ltd $BINARYDIR/$defaultBinaryMarker 2>> $logFile |\
    grep ^-[-r][-w][x] | sed 's/^.*\///'`)
  TbinN=${#Tbin[@]}

  # Exit with error if no matching binaries found
  if [ $TbinN -eq 0 ]; then
    printf " [%s] %s No binaries found matching search: %s\n" \
      $thisUnitBaseName $R_err $defaultBinaryMarker
    exit 1
  fi
  
  # Auto select binary if only one is found
  if [ $TbinN -eq 1 ]; then
    comment=`printf "Using binary (%s) autoselected based on %s mask" \
      ${Tbin[$bin_id]} $defaultBinaryMarker`
    printf "\n %-60s \n" "$comment"
    bin_id=0
  fi

  # Display selection when multiple binaries are found
  if [ $TbinN -gt 1 ]; then
    # If multiple binaries found show list and wait for selection
    printf "\n %-60s \n" "Select binary for calculations"
    printf "   binaries found in %s\n" $BINARYDIR
    
    i=0
    while [ $i -lt $TbinN ]; do
      bin_info=`ls -l $BINARYDIR/${Tbin[$i]} | sed 's/\/.*$//' | \
                eval "sed 's/^.*${USER}\ *[0-9]*//'"`
      printf "\t[%d] (%s) %-18s\n" $i "$bin_info" ${Tbin[$i]}
      (( i++ ))
    done

    printf "   select index for binary [0]: " ;  read bin_id
    bin_id=${bin_id:=0}
    # Sanity check of the selection
    test_index_in_range 0 $bin_id $TbinN
    
    printf "\n %-60s \n" "Using binary: ${Tbin[$bin_id]}"
  fi

  binary=${Tbin[$bin_id]}
  
else
  printf "\n %-60s \n" "Using default binary ($defaultBinary)"
  binary=$defaultBinary
fi

return 0
