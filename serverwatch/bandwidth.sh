#!/bin/bash

source /home/sample/scripts/dataset.sh

function user_list() {
	cat /etc/trueuserowners | awk '{print $1}' | sed 's/://' >>$temp/userlist_$time.txt
}

function bandwidth_calc() {
	bwtotal=0

	while IFS= read -r line || [[ -n "$line" ]]; do
		bwuser=$(whmapi1 uapi_cpanel cpanel.function='get_stats' display=bandwidthusage cpanel.module='StatsBar' cpanel.user=$line | grep -i " count:" | awk '{print $2}')

		if [[ $bwuser == *"GB"* ]]; then
			bwcut=$(echo "$bwuser" | sed 's/GB//')
			bwgb=$(echo "$bwcut" | awk '{foo=$1 ; printf "%0.2f",foo}')
			echo -e "$bwgb G\t$line" >>$temp/bandwidth_$time.txt
			bwbytes=$(echo "$bwcut" | awk '{foo=$1*1024*1024*1024 ; printf "%d",foo}')
			bwtotal=$((bwtotal + bwbytes))

		elif [[ $bwuser == *"MB"* ]]; then
			bwcut=$(echo "$bwuser" | sed 's/MB//')
			bwmb=$(echo "$bwcut" | awk '{foo=$1 ; printf "%0.2f",foo}')
			echo -e "$bwmb M\t$line" >>$temp/bandwidth_$time.txt
			bwbytes=$(echo "$bwcut" | awk '{foo=$1*1024*1024 ; printf "%d",foo}')
			bwtotal=$((bwtotal + bwbytes))

		elif [[ $bwuser == *"KB"* ]]; then
			bwcut=$(echo "$bwuser" | sed 's/KB//')
			bwmb=$(echo "$bwcut" | awk '{foo=$1/1024 ; printf "%0.2f",foo}')
			echo -e "$bwmb M\t$line" >>$temp/bandwidth_$time.txt
			bwbytes=$(echo "$bwcut" | awk '{foo=$1*1024 ; printf "%d",foo}')
			bwtotal=$((bwtotal + bwbytes))

		elif [[ $bwuser == *"bytes"* ]]; then
			bwcut=$(echo "$bwuser" | sed 's/bytes//')
			bwmb=$(echo "$bwcut" | awk '{foo=$1/1024/1024 ; printf "%0.2f",foo}')
			echo -e "$bwmb M\t$line" >>$temp/bandwidth_$time.txt
			bwbytes=$(echo "$bwcut" | awk '{foo=$1 ; printf "%d",foo}')
			bwtotal=$((bwtotal + bwbytes))
		fi

	done <"$temp/userlist_$time.txt"

	if [ $bwtotal -ge 1073741824 ]; then
		bwtotalgb=$(echo "$bwtotal" | awk '{foo=$1/1024/1024/1024 ; printf "%0.2f",foo}')
		echo -e "$bwtotalgb G\tTotal" >>$temp/bandwidth_$time.txt
	else
		bwtotalmb=$(echo "$bwtotal" | awk '{foo=$1/1024/1024 ; printf "%0.2f",foo}')
		echo -e "$bwtotalmb M\tTotal" >>$temp/bandwidth_$time.txt
	fi
}

function bandwidth_sort() {
	if [ -r $temp/bandwidth_$time.txt ] && [ -s $temp/bandwidth_$time.txt ]; then
		cat $temp/bandwidth_$time.txt | grep "G" | sort -nr >>$svrlogs/serverwatch/bandwidth_$time.txt
		cat $temp/bandwidth_$time.txt | grep "M" | sort -nr >>$svrlogs/serverwatch/bandwidth_$time.txt
	fi
}

user_list

bandwidth_calc

bandwidth_sort
