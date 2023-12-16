#!/bin/bash

source /home/sample/scripts/dataset.sh

function user_list() {
	cat /etc/trueuserowners | awk '{print $1}' | sed 's/://' >>$temp/userlist_$time.txt
}

function daily_process() {
	/usr/local/cpanel/bin/dcpumonview | grep -iv "Top" | sed -e 's#<[^>]*># #g' | awk '{print $3,"\t"$1}' | sort -nr >>$temp/dailyprocess_$time.txt
}

function process_calc() {
	cores=$(lscpu | grep -i "^CPU(s):" | awk '{print $2}')

	userlist=($(cat $temp/userlist_$time.txt))
	processlist=($(cat $temp/dailyprocess_$time.txt | awk '{print $1}'))
	prouserlist=($(cat $temp/dailyprocess_$time.txt | awk '{print $2}'))

	usercount=${#userlist[@]}
	processcount=${#processlist[@]}
	prousercount=${#prouserlist[@]}

	for ((i = 0; i < prousercount; i++)); do
		for ((j = 0; j < usercount; j++)); do
			if [[ "${prouserlist[i]}" == "${userlist[j]}" ]]; then
				username=${prouserlist[i]}
				process=$(echo "${processlist[i]}" | awk -v proc=${processlist[i]} -v cores=$cores 'BEGIN {foo=proc/cores ; printf "%0.2f",foo}')

				printf "%-12s - %7s\n" "$username" "$process%" >>$svrlogs/serverwatch/dailyprocess_$time.txt
			fi
		done
	done
}

user_list

daily_process

process_calc
