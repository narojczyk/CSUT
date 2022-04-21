#!/bin/bash

iam=`echo $(basename $BASH_SOURCE)| sed 's/\.sh//'`


# printf "making eps/pdf files (latex)\t["

# echo marker to login file
echo $iam >> $logFile

# check for latex files
unset texFiles
texFiles=( `ls -1 *tex` )
texFilesQty=${#texFiles[@]}

j=0
while [ $j -lt $texFilesQty ]; do
  fname=${texFiles[$j]%.tex}
  echo "### $j ${texFiles[$j]} ###" >> $logFile

  if [ -f ${fname}-inc.eps ]; then
    echo " ### LATEX $j" >> $logFile
    latex -halt-on-error ${texFiles[$j]} 1>> $logFile 2>> $logFile
    if [ -f ${fname}.dvi ]; then
      echo " ### DVIPS $j" >> $logFile
      dvips ${fname}.dvi 1>> $logFile 2>> $logFile
      rm ${fname}.dvi ${fname}.aux ${fname}.log
    
      echo " ### PS2EPS $j" >> $logFile
      ps2eps -f -B -l ${fname}.ps 1>> $logFile 2>> $logFile
      rm ${fname}.ps ${fname}-inc.eps ${fname}.tex;
    fi
  fi
  
  (( j++ ))
  
  progress_bar=`$FPB $j $texFilesQty $pbLength`
  progress_msg=`printf "$msgItemFormat" "converting formats (1/3) latex -> eps" "$progress_bar"`
  echo -ne "$progress_msg"\\r
done

epsFiles=( `ls -1 *eps | grep -e "merged" -e "Sij"` )
epsFilesQty=${#epsFiles[@]}

j=0
while [ $j -lt $epsFilesQty ]
do
  fname=${epsFiles[$j]}
  if [ -f $fname ]; then
    echo " ### EPSTOPDF $j" >> $logFile
    epstopdf --gsopt=-dCompatibilityLevel=1.5 --quiet $fname 1>> $logFile 2>> $logFile 
  fi
  
  (( j++ ))
  
  progress_bar=`$FPB $j $epsFilesQty $pbLength`
  progress_msg=`printf "$msgItemFormat" "converting formats (2/3) eps -> pdf" "$progress_bar"`
  echo -ne "$progress_msg"\\r
done

unset epsFiles
epsFiles=(`ls -1 *hi[ij][0-9]*.eps *_V[0-9]*.eps *_RAAA*.eps`)
epsFilesQty=${#epsFiles[@]}

j=0
while [ $j -lt ${epsFilesQty} ]; do
  input_eps=${epsFiles[$j]}
#   input_pdf=`echo $input_eps | sed 's/eps/pdf/'`
  output_png=${input_eps/.eps/.png} #`echo $input_eps | sed 's/eps/png/'`
  if [ ! -f $output_png ]; then
    convert -colorspace sRGB -density 600 $input_eps -resize 800 $output_png
    mogrify -background white -flatten $output_png
  fi

  rm $input_eps

  (( j++ ))

  progress_bar=`$FPB $j ${epsFilesQty} $pbLength`
  progress_msg=`printf "$msgItemFormat" "converting formats (3/3) eps -> png)" "$progress_bar"`
  echo -ne "$progress_msg"\\r
done
echo

# Clean any remaining eps
rm *eps 2>> $logFile