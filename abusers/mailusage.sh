#!/bin/bash

source /home/sample/scripts/dataset.sh

function mail_usage() {
	list=$(find $svrlogs/serverwatch -type f -name "diskusage*" -exec ls -lat {} + | grep "$(date +"%F")" | head -1 | awk '{print $NF}')

	users=($(cat $list | awk '{print $1}'))
	usage=($(cat $list | awk '{print $3}'))

	count=${#users[@]}

	for ((i = 0; i < count; i++)); do
		username=${users[i]}
		usedspace=${usage[i]}

		if [ $usedspace -gt 10240 ]; then
			mail=$(du -sm /home/$username/mail | awk '{print $1}')

			if [ $mail -gt 10240 ]; then
				package=$(whmapi1 accountsummary user=$username | grep -i "plan:" | awk -F':' '{print $2}')

				if [[ "$package" == *Unmetered* || "$package" == "WordPress Hosting - G1 - SD - L1" ]]; then

					status=$(whmapi1 accountsummary user=$username | grep -i "outgoing_mail_suspended:" | awk '{print $2}' | sed -e 's/^[[:space:]]*//')

					if [ "$status" -eq 0 ]; then
						printf "%-12s - %6s M - %-12s - %-70s\n" "$username" "$mail" "Active" "$package" >>$temp/mailusage_$time.txt
					else
						printf "%-12s - %6s M - %-12s - %-70s\n" "$username" "$mail" "Suspended" "$package" >>$temp/mailusage_$time.txt
					fi
				fi
			fi
		fi
	done
}

function mail_usage_sort() {
	if [ -r $temp/mailusage_$time.txt ] && [ -s $temp/mailusage_$time.txt ]; then
		cat $temp/mailusage_$time.txt | sort -nrk3 >>$svrlogs/abusers/mailusage/mailusage_$time.txt
	fi
}

mail_usage

mail_usage_sort
