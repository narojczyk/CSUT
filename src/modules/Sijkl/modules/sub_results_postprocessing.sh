#!/bin/bash

# Split stdout to separate averages
bin_stdout_av=`echo $bin_stdout | sed 's/\.csv/_av\.csv/'`
cat $bin_stdout | grep -e "#no" -e AVG > $bin_stdout_av
sed -i '/AVG/d' $bin_stdout

# File names written by ${binary}
SNPTout1="mc3D_HS_output_SijHij.csv"
SNPTout2="mc3D_HS_output_Bij.csv"
SNPTout1AVG="mc3D_HS_output_av_SijHij.csv"
SNPTout2AVG="mc3D_HS_output_av_Bij.csv"

# File names to store the results in (based on $res_base_name)
SNPTexport1=`echo $bin_stdout | sed 's/\.csv/_SijHij\.csv/'`
SNPTexport2=`echo $bin_stdout | sed 's/\.csv/_Bij\.csv/'`
SNPTexport1AVG=`echo $bin_stdout | sed 's/\.csv/_SijHij_avg\.csv/'`
SNPTexport2AVG=`echo $bin_stdout | sed 's/\.csv/_Bij_avg\.csv/'`

# Rename files
mv $SNPTout1 $SNPTexport1
mv $SNPTout2 $SNPTexport2
mv $SNPTout1AVG $SNPTexport1AVG
mv $SNPTout2AVG $SNPTexport2AVG