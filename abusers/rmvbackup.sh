#!/bin/bash

source /home/sample/scripts/dataset.sh

input=$1

function check_input() {
	username=$(cat /etc/trueuserowners | awk '{print $1}' | sed 's/://' | awk -v user=$input '{if ($1==user) print $1}')

	if [[ $input == "$username" ]]; then
		rmv_backup
	else
		echo "Username not found"
	fi
}

function rmv_backup() {
	bkpath=($(find $svrlogs/abusers/backupusage -type f -name "$username-bk*" -exec ls -lat {} + | head -1 | awk '{print $NF}'))

	if [ ! -z $bkpath ]; then
		backupusage=$(cat $bkpath | awk '{$1=$2=$3=""; print}' | grep -v total$ | sed 's/^[[:space:]]*//')

		if [[ ! -z $backupusage ]]; then
			while IFS= read -r line; do
				rm -f "$line"

				echo "Removed - $line" >>$svrlogs/abusers/remove/$username-rmvbk_$time.txt
			done <<<"$backupusage"
		fi
	else
		echo "Backup list not found"
	fi
}

check_input
