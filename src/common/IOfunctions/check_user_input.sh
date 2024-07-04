#!/bin/bash

test_index_in_range(){
    if [ ! $3 ]; then   
        printf " [%s] %s: Bad call, to few parameters" ${FUNCNAME[0]} $R_err
        exit 1
    fi

    range_min=$1
    idx=$2
    range_max=$3

    if [ $idx -lt $range_min ] || [ $idx -ge $range_max ]; then
      printf " [%s] %s: index (%d) out of range\n" ${FUNCNAME[0]} $R_err $idx
      exit 1
    fi
}