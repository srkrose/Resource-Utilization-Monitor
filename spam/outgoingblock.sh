#!/bin/bash

source /home/sample/scripts/dataset.sh

function spam_list() {
	cat /etc/outgoing_mail_suspended_users >>$temp/outgoingblock_$time.txt
}

function check_list() {
	if [ -r $temp/outgoingblock_$time.txt ] && [ -s $temp/outgoingblock_$time.txt ]; then
		blocklist=($(cat $temp/outgoingblock_$time.txt))

		if [ ! -z $blocklist ]; then
			cat $temp/outgoingblock_$time.txt >>$svrlogs/spam/mailblock/outgoingblock_$time.txt
		fi
	fi
}

function check_new() {
	if [ -r $svrlogs/spam/mailblock/outgoingblock_$time.txt ] && [ -s $svrlogs/spam/mailblock/outgoingblock_$time.txt ]; then
		tlist=($(find $svrlogs/spam/mailblock -type f -name "outgoingblock*" -exec ls -lat {} + | grep "$(date +"%F")" | head -1 | awk '{print $NF}'))
		ylist=($(find $svrlogs/spam/mailblock -type f -name "outgoingblock*" -exec ls -lat {} + | grep "$(date -d 'yesterday' +"%F")" | head -1 | awk '{print $NF}'))

		tcount=$(cat $tlist | wc -l)

		echo "Total: $tcount" >>$svrlogs/serverwatch/outgoingblock_$time.txt
		echo "" >>$svrlogs/serverwatch/outgoingblock_$time.txt

		if [[ ! -z "$ylist" ]]; then
			newusers=$(grep -Fxv -f $ylist $tlist)

			if [[ ! -z "$newusers" ]]; then
				ncount=$(echo "$newusers" | wc -l)

				echo "New Entries: $newcount" >>$svrlogs/serverwatch/outgoingblock_$time.txt
				echo "" >>$svrlogs/serverwatch/outgoingblock_$time.txt

				while IFS= read -r nuser; do
					status=$(whmapi1 accountsummary user=$nuser | grep -w "suspended:" | awk '{print $NF}')

					if [ $status -ne 0 ]; then
						echo "$nuser - account suspended" >>$svrlogs/serverwatch/outgoingblock_$time.txt
					else
						echo "$nuser - mail suspended" >>$svrlogs/serverwatch/outgoingblock_$time.txt
					fi
				done <<<"$newusers"

			fi

		fi
	fi
}

spam_list

check_list

check_new
