#!/bin/bash

iam=`echo $(basename $BASH_SOURCE)| sed 's/\.sh//'`

if [ ! $3 ]; then
  printf " %s [%s] missing mandatory arguments\n" ${R_err} $iam
  exit 1
else
  fln=$1
  src=$2
  tgt=$3
fi

# Check sha1 for the source file
sha1_src=`sha1sum ${src}/${fln} | sed 's/\ \ .*//'`

# If the file is present on the destination, check it's SHA1
# and ask whether to overwrite
if [ -f ${tgt}/${fln} ]; then
  sha1_tgt=`sha1sum ${tgt}/${fln} | sed 's/\ \ .*//'`
  printf " %s\n Archive present in the repository, " ${fln}
  if [ "${sha1_src}" = "${sha1_tgt}" ]; then
    echo "SHA1 ${msg[4]}."
    return 0
  else
    printf "${msg[14]} of SHA1."
    if [ "$overwrite_all_targets" = "no" ]; then
      printf " Overwite target [(y)es/No/(a)ll]: "; read overwrite
      if [ "$overwrite" = "y" ] || [ "$overwrite" = "yes" ]; then
        overwrite_target="yes"
      elif [ "$overwrite" = "a" ] || [ "$overwrite" = "all" ]; then
        overwrite_target="yes"
        overwrite_all_targets="yes"
      else
        overwrite_target="no"
      fi
    fi

    if [ "$overwrite_all_targets" = "yes" ] || [ "$overwrite_target" = "yes" ]; then
      cp  ${src}/${fln} ${tgt}
    fi
  fi
else
  cp ${src}/${fln} ${tgt}
fi

# Verify copy operation
sha1_tgt=`sha1sum ${tgt}/${fln} | sed 's/\ \ .*//'`
if [ $VERBOSE -ne 0 ]; then
  printf " %s " ${fln} >> $log
fi
if [ "${sha1_src}" = "${sha1_tgt}" ]; then
  sha1sum ${src}/${fln} | sed 's;/.*/;;' >> ${tgt}/checksum.sha1
  if [ $VERBOSE -ne 0 ]; then
    printf "OK\n" >> $log
  fi
else
  printf "FAILED\n" >> $log
  printf "[%s] %s Copy failed. Archive's SHA1 checksum do not match.\n" ${iam} ${R_err}
  exit 1
fi

