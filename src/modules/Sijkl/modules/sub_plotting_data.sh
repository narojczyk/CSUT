#!/bin/bash

iam=`echo $(basename $BASH_SOURCE)| sed 's/\.sh//'`
localTmpFile="${iam}.tmp"
localResultsCatTmp="${iam}_bininput_cat.tmp"
localPlotVariables="${iam}_var_cache.tmp"
localMergedStructureInput="merged_structure_input.csv"

if [ -f ./$cacheInfo ]; then
  inifile=`cat ./$cacheInfo | grep inifile= | tail -n 1 | sed 's/^.*=//'`
else
  printf " [%s] %s: Missing simulation *.ini filename.\n" $iam $R_err
  exit 1 
fi

if [ ! -f ./$inifile ]; then
  printf " [%s] %s: Missing simulation %s file.\n" $iam $R_err $inifile
  exit 1
fi

firstDatFile=`cat ./$cacheInfo | grep firstDatFile | tail -n 1 | sed 's/^.*=//'`
lastFullInput=`cat ./$cacheInfo | grep lastFullInput | tail -n 1 | sed 's/^.*=//'`
lastBinInput=`cat ./$cacheInfo | grep lastBinInput | tail -n 1 | sed 's/^.*=//'`

j=1
while [ $j -le $dat_filesN ]; do
  csm=`printf "%04d" $j`
  datfile=${firstDatFile/s[0-9][0-9][0-9][0-9]/s${csm}}

  if [ -f $datfile ]; then
    # Get data lines per file
    Nlines=`cat ${datfile} | grep "MC" |grep -e "cycles"| grep -v "block"  | sed -e 's/^.*\ \ //' -e 's/00$//'`
    # Get number of data 'lines' to reject from file
    Rlines=`cat ${datfile} | grep "EQ " | grep -e "cycles" | sed -e 's/^.*\ \ //' -e 's/00$//'`
  else
    Nlines=`cat ${inifile} | grep "Monte Carlo" | sed -e 's/^.*:\ //' -e 's/00$//'`
    Rlines=`cat ${inifile} | grep "Equilibration" | sed -e 's/^.*:\ //' -e 's/00$//'`
  fi

  let ValidLines=Nlines-Rlines
  let ExtractLines=ValidLines/1000

  # Extract only 1000 lines of data for every full data file
  csm_input=${lastFullInput/s[0-9][0-9][0-9][0-9]/s${csm}}
  csm_output=${csm_input/"full"/"gplt_part"}
  cat $csm_input | eval sed '1,${Rlines}d' > $localTmpFile
  eval "awk 'NR == 1 || NR % $ExtractLines == 0' $localTmpFile  > $csm_output"
  sed -i '1d' $csm_output
  
  progress_bar=`$FPB $j $dat_filesN $pbLength`
  progress_msg=`printf "$msgItemFormat" \
    "preparing gnuplot input data (x$ExtractLines)" "$progress_bar"`
  echo -ne "$progress_msg"\\r

  (( j++ ))
done
echo

cat -n *gplt_part*csv > $localMergedStructureInput
rm $localTmpFile

# Analyse gnuplot input data and set key plotting variables
printf "$msgItemFormat" "analysing gnuplot input" ""

# Concatenate all the volume and box matrix data for all structures
j=0
while [ $j -lt $dat_filesN ]; do
  cfm=${svalues[$j]}
  binInput=${lastBinInput/s[0-9][0-9][0-9][0-9]/s${cfm}}
  cat $binInput > $localResultsCatTmp
  (( j++ ))
done

# Find extreems and remove the temporary file
if [ ! -e ./$inspectForExtreemes ]; then
  cp -s ${UTILS}/$inspectForExtreemes ./$inspectForExtreemes
fi
python ./$inspectForExtreemes $localResultsCatTmp > $localPlotVariables
source $localPlotVariables

rm $localResultsCatTmp $localPlotVariables $inspectForExtreemes

echo $G_done  # done analysing gnuplot input

# Preparing gnuplot scripts"
pl1_title=`echo ${bin_stdout}|\
  sed -e 's/_3DNpT_[HKIY][SXPU]_[SD][PI][HM]_/\ /' -e 's/\.csv//' -e 's/_/\ /g'`

#Get power factor for the Sij multiplier
scexp=`cat $bin_stdout_av |\
  grep AVG | sed 's/\ \ */;/g' | sed 's/^;//' |\
  cut -d ';' -f 5 | sed 's/^.*e-//' | sed 's/^0//'`

# Prepare gnuplot script for S_ij
cat ${GPLT}/plot_S_template.gplt |\
  eval "sed -e 's/@PL1_NAME@/${bin_stdout}/' -e 's/\.csv/_Sij\.tex/'" |\
  eval "sed 's/@PL1_TITLE@/${pl1_title}/'" |\
  eval "sed 's/@DATA_FILE@/${bin_stdout}/'"|\
  eval "sed 's/@SCEXP@/${scexp}/'"|\
  sed  's/@PL1_XLABEL@/structure\ no\./' |\
  sed  's/@PL1_YLABEL@/\$10^XXXAAA\\cdot\ S_\{ij\}\$/' |\
  eval "sed 's/XXXAAA/$scexp/'" |\
  eval "sed 's/@XRANGE@/${last_s}*3.0\/2.0/'" > plot_S.gplt

# Prepare gnuplot script for h_ij
j=0
while [ $j -lt $dat_filesN ]; do
  # Get current-file-marker to select respective simulation files
  cfm=${svalues[$j]}
  cfmnos=`echo $cfm | sed 's/^s//'`

  # Set file name for selected partial data
  gnupltdata=${lastBinInput/s[0-9][0-9][0-9][0-9]/s${cfm}}
  gnupltdataFull=${lastFullInput/s[0-9][0-9][0-9][0-9]/s${csm}}
  datfile=${firstDatFile/s[0-9][0-9][0-9][0-9]/s${csm}}

  # Get data lines per file  (2 spaces after 'cycles' are IMPORTANT!)
  if [ -f $datfile ]; then
    max_range=`cat ${datfile} |\
      grep -e "MC\ cycles\ \ " -e "MC\ cycles#" -e "MC\ steps\ \ " |\
      sed -e 's/^.*\ \ //'`
    avgVol=`cat $datfile | grep "<V>" | grep "last" | grep -v cp | sed 's/^.*\ //'`
  else
    max_range=`cat ${inifile} | grep "Monte Carlo" | sed -e 's/^.*:\ //'`
      avgVol=0 # TODO REMOVE THIS
  fi

  # Title of the plots
  pl2_title=`echo "$pl1_title $cfm"`

  gnuplotscript=`printf "plot_h%s.gplt" $cfmnos`
  cat ${GPLT}/plot_h_template.gplt |\
    eval "sed -e 's/@PL1_NAME@/${bin_stdout}/' -e 's/\.csv/_hii${cfm}\.tex/'" |\
    eval "sed 's/@DATA_FILE@/${gnupltdata}/'"     |\
    eval "sed 's/@YRANGE_MIN@/${HYmin}/'"         |\
    eval "sed 's/@YRANGE@/${HYmax}/'"       > $gnuplotscript

  gnuplotscript=`printf "plot_V%s.gplt" $cfmnos`
  cat ${GPLT}/plot_V_template.gplt |\
    eval "sed -e 's/@PL1_NAME@/${bin_stdout}/' -e 's/\.csv/_V${cfm}\.tex/'" |\
    eval "sed 's/@DATA_FILE@/${gnupltdata}/'"     |\
    eval "sed 's/@AVGVOL@/${avgVol}/'"            |\
    eval "sed 's/@YRANGE_MIN@/${VolYmin}/'"       |\
    eval "sed 's/@YRANGE@/${VolYmax}/'"     > $gnuplotscript

  gnuplotscript=`printf "plot_RAAA%s.gplt" $cfmnos`
  cat ${GPLT}/plot_RAAA_template.gplt |\
    eval "sed -e 's/@PL1_NAME@/${bin_stdout}/' -e 's/\.csv/_RAAA${cfm}\.tex/'"|\
    eval "sed 's/@DATA_FILE@/${gnupltdataFull}/'" > $gnuplotscript

  eval "sed -i 's/@PL1_TITLE@/${pl2_title}/'      *${cfmnos}.gplt"      
  eval "sed -i 's/@XRANGE_MIN@/${gpltMinimalX}/'  *${cfmnos}.gplt"  
  eval "sed -i 's/@XRANGE@/${max_range}/'         *${cfmnos}.gplt"         

  (( j++ ))
done

# prepare the merged version of the above
gnupltdata="$localMergedStructureInput"

max_range=`cat $gnupltdata |wc -l`
cat ${GPLT}/plot_hii_long_template.gplt   |\
  eval "sed -e 's/@PL1_NAME@/${bin_stdout}/' -e 's/\.csv/_hii_merged\.tex/'"  |\
  eval "sed 's/@INDEX@/ii/'"              > plot_hii_merged.gplt

cat ${GPLT}/plot_hij_long_template.gplt   |\
  eval "sed -e 's/@PL1_NAME@/${bin_stdout}/' -e 's/\.csv/_hij_merged\.tex/'"  |\
  eval "sed 's/@INDEX@/ij/'"              > plot_hij_merged.gplt

# Common updates to *merged gnuplot scripts
eval "sed -i 's/@DATA_FILE@/${gnupltdata}/' *merged.gplt"
eval "sed -i 's/@PL1_TITLE@/${pl1_title}/'  *merged.gplt"
eval "sed -i 's/@XRANGE_MIN@/0/'            *merged.gplt"
eval "sed -i 's/@XRANGE@/${max_range}/'     *merged.gplt"

# Common updates to all gnuplot scripts
eval "sed -i 's~@PATH@~${GPLT}~' *.gplt" 

# Run gnuplot
plots=(`ls -1 *gplt`)
Nplots=${#plots[@]}

j=0
while [ $j -lt ${Nplots} ]; do
  gnuplot ${plots[$j]}

  (( j++ ))

  progress_bar=`$FPB $j ${Nplots} $pbLength`
  progress_msg=`printf "$msgItemFormat" "gnuplotting ${Nplots} files" "$progress_bar"`
  echo -ne "$progress_msg"\\r
done
echo

return 0
