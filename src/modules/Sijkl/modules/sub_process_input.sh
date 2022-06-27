#!/bin/bash

iam=`echo $(basename $BASH_SOURCE)| sed 's/\.sh//'`

# Set the names of config files 
binconfig="${binary}.ini"

# Set the file pattern for input (use current file names, excepf of '*_full.csv' files)
input_pattern=`ls [^2]*s*[^l].csv | head -n 1 | sed 's/s[0-9]\{4\}/s%04d/'`

# Get simulation parameters from first dat file or ini file
primary_info=0
csm=`printf "%04d" 1`
datfile=`ls *s${csm}.dat 2>> $logFile`
if [ -f $datfile ] ; then
  primary_info=1
  echo "firstDatFile=${datfile}" >> $cacheInfo
fi

# Check all the ini files and find the one for the simulation program
iniFilesTab=(`ls -1 *ini`); 
iniFilesTabN=${#iniFilesTab[@]}
j=0
while [ $j -lt $iniFilesTabN ]; do
  testingIniFile=${iniFilesTab[$j]}
  # Look for phrase speciffic for configuration of the simulation program
  buffer=`cat ${testingIniFile} | grep "Equilibration"`
  if [ ${#buffer} -gt 0 ]; then
    inifile=${testingIniFile}
    echo "inifile=${testingIniFile}" >> $cacheInfo
    break;
  fi
  (( j++ ))
done

if [ $primary_info -eq 1 ]; then
  # Get data lines per file
  Nlines=`cat ${datfile} | grep "MC " | grep -e "steps" -e "cycles"| grep -v "block" | sed -e 's/^.*\ \ //' -e 's/00$//'`
  # Get number of data 'lines' to reject from file
  Rlines=`cat ${datfile} | grep "EQ " | grep -e "steps" -e "cycles" | sed -e 's/^.*\ \ //' -e 's/00$//'`
  # Get pressure value for the system
  pressure=`cat ${datfile} | grep "# Pressure " | sed 's/^.*\ \ //'`
else
  # Try to get the same from ini file
  Nlines=`cat ${inifile} | grep "Monte Carlo" | sed -e 's/^.*:\ //' -e 's/00$//'`
  Rlines=`cat ${inifile} | grep "Equilibration" | sed -e 's/^.*:\ //' -e 's/00$//'`
  pressure=`cat ${inifile} | grep "^p\*"  | sed 's/^.*:\ //'`
fi

if [ ! $pressure ] || [ ! $Nlines ] || [ ! $Rlines ]; then
  printf " [%s] %s: One or more key variables for %s are undetermined.\n" \ 
    $iam $R_err $binconfig
fi

# Check the number of last input file
lastBinID=`cat $cacheInfo | grep lastBinInput |\
  sed 's/^.*_s0*//' | sed 's/\..*//'`

# Prepare config 
template_conf=`./$binary -t`
template_conf=${template_conf##*\ }

cat $template_conf |\
  eval "sed -e '1s/#.*$/$input_pattern/'" |\
  sed '2s/INT/1/' |\
  eval "sed '3s/INT/$lastBinID/'" |\
  eval "sed '4s/INT/$Nlines/'" |\
  eval "sed '5s/INT/$Rlines/'" |\
  eval "sed '6s/DOUBLE/1e0/'" |\
  eval "sed '7s/DOUBLE/$pressure/'" > $binconfig
rm $template_conf

# Prepare output files
bin_stdout="${res_base_name}.csv"
bin_stderr="${res_base_name}.out"

return 0
