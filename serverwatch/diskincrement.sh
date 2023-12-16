#!/bin/bash

source /home/sample/scripts/dataset.sh

function disk_increment() {
	tlist=($(find $svrlogs/serverwatch -type f -name "diskusage*" -exec ls -lat {} + | grep "$(date +"%F")" | head -1 | awk '{print $NF}'))
	ylist=($(find $svrlogs/serverwatch -type f -name "diskusage*" -exec ls -lat {} + | grep "$(date -d 'yesterday' +"%F")" | head -1 | awk '{print $NF}'))

	tusers=($(cat $tlist | awk '{print $1}'))
	tusage=($(cat $tlist | awk '{print $3}'))
	yusers=($(cat $ylist | awk '{print $1}'))
	yusage=($(cat $ylist | awk '{print $3}'))

	tcount=${#tusers[@]}
	ycount=${#yusers[@]}

	for ((i = 0; i < tcount; i++)); do
		for ((j = 0; j < ycount; j++)); do
			if [[ "${tusers[i]}" == "${yusers[j]}" ]]; then
				username=${tusers[i]}
				cur=${tusage[i]}
				prev=${yusage[j]}

				if [[ $cur -gt $prev ]]; then
					increment=$(echo "{tusage[i]}" | awk -v tu=${tusage[i]} -v yu=${yusage[j]} 'BEGIN {foo=tu-yu ; printf "%d",foo}')

					if [ $increment -gt 1000 ]; then
						printf "%-12s - %6s M\n" "$username" "$increment" >>$temp/diskincrement_$time.txt
					fi
				fi
			fi
		done
	done
}

function disk_increment_sort() {
	if [ -r $temp/diskincrement_$time.txt ] && [ -s $temp/diskincrement_$time.txt ]; then
		cat $temp/diskincrement_$time.txt | sort -nrk3 >>$svrlogs/serverwatch/diskincrement_$time.txt
	fi
}

disk_increment

disk_increment_sort
