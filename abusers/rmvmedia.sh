#!/bin/bash

source /home/sample/scripts/dataset.sh

input=$1

function check_input() {
	username=$(cat /etc/trueuserowners | awk '{print $1}' | sed 's/://' | awk -v user=$input '{if ($1==user) print $1}')

	if [[ $input == "$username" ]]; then
		rmv_media
	else
		echo "Username not found"
	fi
}

function rmv_media() {
	fspath=($(find $svrlogs/abusers/filesharing -type f -name "$username-fs*" -exec ls -lat {} + | head -1 | awk '{print $NF}'))

	if [ ! -z $fspath ]; then
		filesharing=$(cat $fspath | awk '{$1=$2=$3=""; print}' | grep -v total$ | sed 's/^[[:space:]]*//')

		if [[ ! -z $filesharing ]]; then
			while IFS= read -r line; do
				if [[ -f "$line" ]]; then
					rm -f "$line"

					echo "Removed - $line" >>$svrlogs/abusers/remove/$username-rmvfs_$time.txt
				else
					echo "Unavailable - $line" >>$svrlogs/abusers/remove/$username-rmvfs_$time.txt
				fi

			done <<<"$filesharing"
		fi
	else
		echo "File list not found"
	fi
}

check_input
