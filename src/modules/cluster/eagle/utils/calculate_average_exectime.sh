#!/bin/bash
iam=`echo $(basename $BASH_SOURCE)| sed 's/\.sh//'`

binavg="${CODES}/tools/average"
if [ ! -f ${binavg} ]; then
  printf "[%s] %s Missing %s\n" ${iam} ${R_err} ${binavg}
  return 0
fi

printf "\n\n Calculating an average execution time per job\n"
cd $DEST;
ln -s ${binavg} 2>/dev/null
avmcs=`./average ${stepLog##/*/}`
avtime=`./average ${timeLog##/*/}`
echo "Average calculation time: ${avtime} min."      > $averageJobStatsLog
echo "Average MC steps: ${avmcs}"                   >> $averageJobStatsLog
echo "Samples taken: `cat ${stepFileName} | wc -l`" >> $averageJobStatsLog
cat $averageJobStatsLog | sed 's/^/\t/'

# Return to job directory for the next set
cd ${JOBSTARTER}

# Clean  temporary files
rm ${DEST}/average $stepLog $timelog

