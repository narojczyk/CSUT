#!/bin/bash

# local temp file name (thread-safe)
sub_local_tmp=".inspect_datarepo_${RANDOM}.tmp"

printf "\n %-60s\n" "Inspecting repository with Sij data"

# Look inside $DATAREPO
printf "\n * location: %s\n" ${DATAREPO/*${USER}/"~"}

# Get the list of dated sub-repositories (Tdsr)
unset Tdsr
Tdsr=(`ls -1dtr $DATAREPO/20* | grep -v _NuS | eval "sed 's/\/home.*\///'"`)
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
Tpexp=(`ls $DATAREPO/$subrepository/20*_SijHij_avg.csv |\
  sed -e 's/^\/.*\///' -e 's/_sd[0-9].*$//' | sed 's/^20.*_p//' | sort -u`)

#  based on the pressure exponents list archives and write to a temp file
i=0
echo > $sub_local_tmp
while [ $i -lt ${#Tpexp[@]} ]; do
  ls -1 $DATAREPO/$subrepository/20*_p${Tpexp[$i]}*_SijHij_avg.csv |\
     sed -e 's/^\/.*\///' -e 's/_sd[0-9].*$//' | sort -u >> $sub_local_tmp
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
  printf " [%${w}d] %s (%d)\n" $i ${Tdset[$i]} \
    `ls -1 $DATAREPO/$subrepository/${Tdset[$i]}*_SijHij_avg.csv | wc -l` |\
    sed 's/3DNpT_.*_fcc/\ \.\.\.\ /'
  (( i++ ))
done

printf "   enter start index for data [0]: " ;  read dset_sta_id
dset_sta_id=${dset_sta_id:=0}
# Sanity check of the selection
test_index_in_range 0 $dset_sta_id $TdsetN

printf "   enter end index for data [%d]: " $((TdsetN-1));  read dset_end_id
dset_end_id=${dset_end_id:=$((TdsetN-1))}
# Sanity check of the selection
test_index_in_range $dset_sta_id $dset_end_id $TdsetN

if [ $dset_sta_id -eq $dset_end_id ]; then
  # display possible _sd values for the selected data set
  isel=$dset_sta_id
  uniqueSD=(`ls -1 $DATAREPO/$subrepository/${Tdset[$isel]}*csv |\
    sed 's/^.*_sd//' | sed 's/[_\.].*//' | sort -u`)

  printf "\n   possible SD-values for\n   %s\n\n" ${Tdset[$isel]}
  printf "\t%-10s %-10s %-10s %-10s %-10s\n" "${uniqueSD[@]}"

  printf "\n   enter space separated list of sd values to select them\n"
  printf "   start with '-' to specify the excluded list of sd values\n"
  printf "   all will be selected by default [all]: "
  read -a SD_selection_string

  # select all by default
  selectedSDtab=(`echo ${uniqueSD[@]}`)
echo ${selectedSDtab[@]}
  # check if the first sign is a '-'
  SDselectionMode="${SD_selection_string:0:1}"
  if [ "$SDselectionMode" == "-" ]; then
    SD_selection_string=${SD_selection_string:1}

    # associacion table for values to remove
    declare -A filterOut
    for x in "${SD_selection_string[@]}"; do filterOut["$x"]=1; done

    # clear selection by default
    selectedSDtab=()

    # prepare the list of selected SD values
    for x in "${uniqueSD[@]}"; do
      if [[ -z ${filterOut["$x"]} ]]; then
        selectedSDtab+=("$x")
      fi
    done
  else
    echo ${#SD_selection_string[@]}
    if [ ${#SD_selection_string[@]} -gt 0 ]; then
    # otherwise the default selection of all SD values has been made
      # use user imput directly as the selected list of elements
      selectedSDtab=(${SD_selection_string[@]})
    else
      selectedSDtab=(${uniqueSD[@]})
    fi
  fi
  echo "   Selected SD values for processing:"
  printf "\t%-10s %-10s %-10s %-10s %-10s\n" ${selectedSDtab[@]}
fi


return 0
