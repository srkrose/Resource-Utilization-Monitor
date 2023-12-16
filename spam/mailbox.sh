#!/bin/bash

source /home/sample/scripts/dataset.sh

function user_list() {
	cat /etc/trueuserowners | awk '{print $1}' | sed 's/://' >>$temp/userlist_$time.txt
}

function list_mailbox() {
	while IFS= read -r line || [[ -n "$line" ]]; do
		username=$line
		mailboxes=$(whmapi1 list_pops_for user=$username | awk '/pops:/{f=1;next} /metadata:/{f=0} f' | awk '{print $NF}')

		if [[ ! -z $mailboxes ]]; then
			domains=$(echo "$mailboxes" | awk -F'@' '{print $NF}' | sort | uniq)

			while IFS= read -r domain; do
				data=$(echo "$mailboxes" | grep -w "$domain")

				while IFS= read -r mailbox; do
					header

					printf "%-20s %-30s %-70s\n" "$username" "$domain" "$mailbox" >>$svrlogs/spam/mailbox/mailbox_$time.txt

				done <<<"$data"

			done <<<"$domains"

		fi

	done <"$temp/userlist_$time.txt"
}

function header() {
	if [ ! -f $svrlogs/spam/mailbox/mailbox_$time.txt ]; then
		printf "%-20s %-30s %-70s\n" "USER" "DOMAIN" "MAILBOX" >>$svrlogs/spam/mailbox/mailbox_$time.txt
	fi
}

function check_new() {
	if [ -r $svrlogs/spam/mailbox/mailbox_$time.txt ] && [ -s $svrlogs/spam/mailbox/mailbox_$time.txt ]; then
		tlist=($(find $svrlogs/spam/mailbox -type f -name "mailbox*" -exec ls -lat {} + | grep "$(date +"%F")" | head -1 | awk '{print $NF}'))
		ylist=($(find $svrlogs/spam/mailbox -type f -name "mailbox*" -exec ls -lat {} + | grep "$(date -d 'yesterday' +"%F")" | head -1 | awk '{print $NF}'))

		tcount=$(cat $tlist | tail -n +2 | wc -l)

		echo "Total: $tcount" >>$svrlogs/serverwatch/mailbox_$time.txt
		echo "" >>$svrlogs/serverwatch/mailbox_$time.txt

		if [[ ! -z "$ylist" ]]; then
			newmailbox=$(grep -Fxv -f $ylist $tlist)

			if [[ ! -z "$newmailbox" ]]; then
				ncount=$(echo "$newmailbox" | wc -l)

				echo "New Entries: $ncount" >>$svrlogs/serverwatch/mailbox_$time.txt
				echo "" >>$svrlogs/serverwatch/mailbox_$time.txt
				echo "$newmailbox" >>$svrlogs/serverwatch/mailbox_$time.txt
			fi
		fi
	fi
}

user_list

list_mailbox

check_new
