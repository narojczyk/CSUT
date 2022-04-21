#!/bin/bash

iam=`echo $(basename $BASH_SOURCE)| sed 's/\.sh//'`

#############
    echo;
    echo " [ $iam ]"
    echo " this mode needs updating to new data format"
    exit 0
############

# Set the names of config files 
binconfig="${binary}_merged.ini"

# Set the file name for merged input
merged_sim_data=`ls n*.dat | head -n 1 | sed 's/s.*dat$/_merged_01.csv/'`

# Merge input for all structures
printf "  merging input\n"
j=0
while [ $j -lt $data_setN ]; do
  let jj=j+1
  # Get current-structure-marker to select respective simulation files
  csm=`printf "%04d" $jj`
  infofile=`ls n*s${csm}.dat`
  
  # Get number of data 'lines' to reject from file
  Rlines=`cat ${infofile} | grep "EQ steps" | sed -e 's/^.*\ \ //' -e 's/00$//'`            
  
  if [ $j -eq 0 ]; then
    cat n*s${csm}.csv > $merged_sim_data
  else
    cat n*s${csm}.csv | eval "sed '1,${Rlines}d'" >> $merged_sim_data
  fi
  
  (( j++ ))
done
# Get data lines per file
#    Nlines=`cat ${infofile} |\
#      grep "MC steps" | sed 's/^.*\ \ //' | sed 's/00$//'`    
Nlines=`cat $merged_sim_data |wc -l`

# Get pressure value for the system
pressure=`cat ${infofile} | grep "# p\* " | sed 's/^.*\ \ //'`

# Prepare config 
template_conf=`./$binary -t | sed 's/^.*://'`

cat $template_conf |\
  eval "sed -e '1s/#.*$/$merged_sim_data/' -e '1s/_01/_%02d/'" |\
  sed '2,3s/INT/1/' |\
  eval "sed '4s/INT/$Nlines/'" |\
  eval "sed '5s/INT/$Rlines/'" |\
  eval "sed '6s/DOUBLE/1e0/'" |\
  eval "sed '7s/DOUBLE/$pressure/'" > $binconfig
rm $template_conf

# Prepare output files
bin_stdout="${res_base_name}_merged.csv"
bin_stderr="${res_base_name}_merged.out"

return 0
