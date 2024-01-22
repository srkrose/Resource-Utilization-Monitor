#!/bin/bash

source /home/sample/scripts/dataset.sh

input=$1

function check_input() {
	username=$(cat /etc/trueuserowners | awk '{print $1}' | sed 's/://' | awk -v user=$input '{if ($1==user) print $1}')

	if [[ $input == "$username" ]]; then
		mk_dir

		mv_backup
	else
		echo "Username not found"
	fi
}

function mk_dir() {
	filepath="/home/$username/Abuse"

	if [[ ! -d "$filepath" ]]; then
		mkdir $filepath

		chown $username: $filepath
	fi
}

function mv_backup() {
	bkpath=($(find $svrlogs/abusers/backupusage -type f -name "$username-bk*" -exec ls -lat {} + | head -1 | awk '{print $NF}'))

	if [ ! -z $bkpath ]; then
		backupusage=$(cat $bkpath | awk '{$1=$2=$3=""; print}' | grep -v total$ | sed 's/^[[:space:]]*//')

		if [[ ! -z $backupusage ]]; then
			while IFS= read -r line; do
				if [[ -f "$line" ]]; then
					mv "$line" $filepath

					echo "Moved - $line" >>$svrlogs/abusers/move/$username-mvbk_$time.txt
				else
					echo "Unavailable - $line" >>$svrlogs/abusers/move/$username-mvbk_$time.txt
				fi
				
			done <<<"$backupusage"
		fi
	else
		echo "Backup list not found"
	fi
}

check_input
