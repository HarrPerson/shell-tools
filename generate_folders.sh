#!/bin/bash

OUTPATH=$1
RUNCOUNTER=$2
echo $RUNCOUNTER

for (( i=1; i<=$RUNCOUNTER; i++ ))
do
   rnd=$(( $RANDOM % 1000000 + 1 ))
   echo "${i}: ${rnd}"
   mkdir "${OUTPATH}/rnd_dir_${rnd}"
done


exit 0
