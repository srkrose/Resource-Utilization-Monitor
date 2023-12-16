#!/bin/bash

source /home/sample/scripts/dataset.sh

function user_list() {
	cat /etc/trueuserowners | awk '{print $1}' | sed 's/://' >>$temp/userlist_$time.txt
}

function disk_usage() {
	while IFS= read -r line || [[ -n "$line" ]]; do
		username=$line
		usage=$(whmapi1 accountsummary user=$username | grep -i "diskused:" | awk '{print $2}' | sed 's/M//')

		printf "%-12s - %7s M\n" "$username" "$usage" >>$temp/diskusage_$time.txt

	done <"$temp/userlist_$time.txt"
}

function disk_usage_sort() {
	if [ -r $temp/diskusage_$time.txt ] && [ -s $temp/diskusage_$time.txt ]; then
		cat $temp/diskusage_$time.txt | sort -nrk3 >>$svrlogs/serverwatch/diskusage_$time.txt
	fi
}

user_list

disk_usage

disk_usage_sort
