#!/bin/bash

# local temp file name (thread-safe)
sub_local_tmp=".inspect_datarepo_${RANDOM}.tmp"

printf "\n %-60s\n" "Inspecting repository with simulation data"

# Look inside $DATAREPO
printf "\n * location: %s\n" ${DATAREPO/*${USER}/"~"}

# Get the list of dated sub-repositories (Tdsr)
unset Tdsr
Tdsr=(`ls -1d $DATAREPO/20* | eval "sed 's/\/home.*\///'"`)
TdsrN=${#Tdsr[@]}

i=0
if [[ ! $((TdsrN-showLastN)) -lt 0 ]]; then 
  i=$((TdsrN-showLastN))
  printf "   (last %d data folders)\n" $showLastN
fi

w=`echo ${#TdsetN}` # set the according format width for archive id on the list
while [ $i -lt $TdsrN ]; do
  printf "    [%${w}d] %-7s\n" $i ${Tdsr[$i]}
  (( i++ ))
done
let default_subrep_id=TdsrN-1
printf "   enter sub-repository index [%d]: " $default_subrep_id ; read subrep_id
if [ ! $subrep_id ]; then
  subrep_id=$default_subrep_id
else
  # Sanity check of the selection
  test_index_in_range 0 $subrep_id $TdsrN
fi

# Get the selected subrepository
subrepository=${Tdsr[$subrep_id]}

unset Tdsr

# Look inside selected sub-repository
printf "\n * listing data in %s: \n" $subrepository

# Generate a sorted list of data sets
#  disregard job numbers and check for different pressure exponents
Tpexp=(`ls $DATAREPO/$subrepository/20* |\
  sed -e 's/^\/.*\///' -e 's/_[0-9][0-9][0-9]\..*$//' | sort -u |\
   sed 's/^20.*e\([+-][0-9]\)/\1/' | sort -ur`)

#  based on the pressure exponents list archives and write to a temp file
i=0
echo > $sub_local_tmp
while [ $i -lt ${#Tpexp[@]} ]; do
  ls -1 $DATAREPO/$subrepository/20*_sd[0-9]*e${Tpexp[$i]}* |\
     sed -e 's/^\/.*\///' -e 's/_[0-9][0-9][0-9]\..*$//' |\
      sort -u >> $sub_local_tmp
  (( i++ ))
done
#  cat the sorted entries from the temp file as consecutive inputs for procssing
Tdset=(`cat $sub_local_tmp`)   
TdsetN=${#Tdset[@]}
w=`echo ${#TdsetN}` # set the according format width for archive id on the list

#  clean temp file
rm $sub_local_tmp

# Display data sets found
i=0
while [ $i -lt $TdsetN ]; do
  printf " [%${w}d] %s (%d)\n" \
    $i ${Tdset[$i]} `ls -1 $DATAREPO/$subrepository/${Tdset[$i]}* | wc -l` |\
    sed 's/3DNpT_.*_fcc/\ \.\.\.\ /'
  (( i++ ))
done

printf "   enter start index for data [0]: " ;  read dset_sta_id
dset_sta_id=${dset_sta_id:=0}
# Sanity check of the selection
test_index_in_range 0 $dset_sta_id $TdsetN

printf "   enter end index for data [%d]: " $dset_sta_id;  read dset_end_id
dset_end_id=${dset_end_id:=${dset_sta_id}}
# Sanity check of the selection
test_index_in_range $dset_sta_id $dset_end_id $TdsetN

return 0
