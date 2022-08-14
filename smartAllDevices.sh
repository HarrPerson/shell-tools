#!/bin/bash

GREP_PATTERN_ERROR="Seek_Error_Rate\|UDMA_CRC_Error_Count\|Multi_Zone_Error_Rate\|Raw_Read_Error_Rate"

case "$1" in
        statusall)
                for dir in /dev/disk/by-uuid/*
                do
                        echo "Smart for ${dir}"
                        smartctl -H ${dir}
                        smartctl -a ${dir}
			echo "================================="
                done
        ;;
        status)
		for dir in /dev/disk/by-uuid/*
		do
    			echo "Smart for ${dir}"
    			smartctl -H ${dir}
    			smartctl -a ${dir} | grep ${GREP_PATTERN_ERROR}
			echo "================================="
		done
	;;
	longtest)
		for dir in /dev/disk/by-uuid/*
		do
			echo "Enable Smart Long Test for ${dir}"
			smartctl --test=long ${dir}
			echo "================================="
		done
	;;
	*)
	echo "Usage: $0 {statusall|status|longtest)"
esac

exit 0
