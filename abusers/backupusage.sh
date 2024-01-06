#!/bin/bash

source /home/sample/scripts/dataset.sh

function check_users() {
	list=$(find $svrlogs/serverwatch -type f -name "diskusage*" -exec ls -lat {} + | grep "$(date +"%F")" | head -1 | awk '{print $NF}')

	users=($(cat $list | awk '{print $1}'))
	usage=($(cat $list | awk '{print $3}'))

	count=${#users[@]}

	for ((i = 0; i < count; i++)); do
		username=${users[i]}
		usedspace=${usage[i]}

		if [ $usedspace -gt 1024 ]; then
			backup_usage
		fi
	done
}

function backup_usage() {
	abuserfs=$(find /home/$username -type f -size +$((1 * 1024 * 1024))c -mtime +7 \( -name "*.zip" -o -name "*.tar.gz" -o -name "*.gz" -o -name "*.tar" -o -name "*.rar" -o -name "*.7z" -o -name "*.wpress" -o -name "*.tar.bz2" -o -name "*.bz2" -o -name "*.xz" -o -name "*.daf" \) ! \( -path "*/cache" -o -path "*/.cpanel/*" -o -path "*/.trash/*" -o -path "*/logs/*" -o -path "*/ssl/*" -o -path "*/tmp/*" \) -exec du -ch --time {} + | sort -rh)

	if [[ ! -z $abuserfs ]]; then
		lines=$(echo "$abuserfs" | grep -v total$ | wc -l)

		head=$(echo "$abuserfs" | grep -v total$ | head -1 | awk '{print $1}')

		type=${head: -1}

		if [[ $type == "G" ]]; then
			print_data

		elif [[ $type == "M" ]]; then
			max=${head:0:${#head}-1}

			if [[ $max == *[.]* ]]; then
				val=${max%.*}
			else
				val=$max
			fi

			if [[ $val -gt 512 || $lines -gt 50 ]]; then
				print_data
			fi
		fi
	fi
}

function print_data() {
	package=$(whmapi1 accountsummary user=$username | grep -i "plan:" | awk -F':' '{print $2}')

	echo "$abuserfs" >>$svrlogs/abusers/backupusage/$username-bk_$time.txt

	fcount=$(cat $svrlogs/abusers/backupusage/$username-bk_$time.txt | grep -v total$ | wc -l)

	capacity=$(cat $svrlogs/abusers/backupusage/$username-bk_$time.txt | grep total$ | awk '{print $1}')

	ext=$(cat $svrlogs/abusers/backupusage/$username-bk_$time.txt | grep -v total$ | awk -F"." '{print $NF}' | sort | uniq -c | sort -nr | awk '{printf $1" - "$2", "}')

	extension=${ext:0:${#ext}-2}

	filedir=$(cat $svrlogs/abusers/backupusage/$username-bk_$time.txt | grep -v total$ | awk '{$1=$2=$3=""; print}' | awk -F'/' '{print $4}' | sort | uniq -c | sort -nr)

	printf "%-12s - %5s - %6s out of %6s M - %-70s\n" "$username" "$fcount" "$capacity" "$usedspace" "$package" >>$temp/backupusage_$time.txt
	printf "EXTENSION: $extension\n" >>$temp/backupusage_$time.txt
	printf "FILEDIR: \n$filedir\n\n" >>$temp/backupusage_$time.txt
}

function backup_usage_sort() {
	if [ -r $temp/backupusage_$time.txt ] && [ -s $temp/backupusage_$time.txt ]; then
		cat $temp/backupusage_$time.txt >>$svrlogs/abusers/backupusage/backupusage_$time.txt
	fi
}

function send_mail() {
	if [ -r $svrlogs/abusers/backupusage/backupusage_$time.txt ] && [ -s $svrlogs/abusers/backupusage/backupusage_$time.txt ]; then
		echo "SUBJECT: Backup Usage - $(hostname) - $(date +"%F")" >>$svrlogs/mail/bumail_$time.txt
		echo "FROM: Backup Usage <root@$(hostname)>" >>$svrlogs/mail/bumail_$time.txt
		echo "" >>$svrlogs/mail/bumail_$time.txt
		cat $svrlogs/abusers/backupusage/backupusage_$time.txt >>$svrlogs/mail/bumail_$time.txt
		sendmail "$emailmo,$emailmg" <$svrlogs/mail/bumail_$time.txt
	fi
}

check_users

backup_usage

backup_usage_sort

send_mail
