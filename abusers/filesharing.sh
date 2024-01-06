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
			file_sharing
		fi
	done
}

function file_sharing() {
	abuserfs=$(find /home/$username -type f -size +$((1 * 1024 * 1024))c \( -name "*.mp4" -o -name "*.mkv" -o -name "*.webm" -o -name "*.avi" -o -name "*.mov" -o -name "*.ogv" -o -name "*.m4v" -o -name "*.wmv" -o -name "*.flv" -o -name "*.3gp" -o -name "*.mpeg" -o -name "*.mpg" -o -name "*.divx" -o -name "*.mp3" -o -name "*.wav" -o -name "*.aac" -o -name "*.flac" -o -name "*.ogg" -o -name "*.wma" -o -name "*.m4a" -o -name "*.pdf" -o -name "*.doc" -o -name "*.docx" -o -name "*.xls" -o -name "*.xlsx" -o -name "*.ppt" -o -name "*.pptx" -o -name "*.exe" -o -name "*.app" -o -name "*.apk" -o -name "*.deb" -o -name "*.iso" -o -name "*.torrent" -o -name "*.rar" \) ! \( -path "*/cache" -o -path "*/.cpanel/*" -o -path "*/.trash/*" -o -path "*/logs/*" -o -path "*/ssl/*" -o -path "*/tmp/*" \) -exec du -ch --time {} + | sort -rh)

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

	echo "$abuserfs" >>$svrlogs/abusers/filesharing/$username-fs_$time.txt

	fcount=$(cat $svrlogs/abusers/filesharing/$username-fs_$time.txt | grep -v total$ | wc -l)

	capacity=$(cat $svrlogs/abusers/filesharing/$username-fs_$time.txt | grep total$ | awk '{print $1}')

	ext=$(cat $svrlogs/abusers/filesharing/$username-fs_$time.txt | grep -v total$ | awk -F"." '{print $NF}' | sort | uniq -c | sort -nr | awk '{printf $1" - "$2", "}')

	extension=${ext:0:${#ext}-2}

	filedir=$(cat $svrlogs/abusers/filesharing/$username-fs_$time.txt | grep -v total$ | awk '{$1=$2=$3=""; print}' | awk -F'/' '{print $4}' | sort | uniq -c | sort -nr)

	printf "%-12s - %5s - %6s out of %6s M - %-70s\n" "$username" "$fcount" "$capacity" "$usedspace" "$package" >>$temp/filesharing_$time.txt
	printf "EXTENSION: $extension\n" >>$temp/filesharing_$time.txt
	printf "FILEDIR: \n$filedir\n\n" >>$temp/filesharing_$time.txt
}

function file_sharing_sort() {
	if [ -r $temp/filesharing_$time.txt ] && [ -s $temp/filesharing_$time.txt ]; then
		cat $temp/filesharing_$time.txt >>$svrlogs/abusers/filesharing/filesharing_$time.txt
	fi
}

function send_mail() {
	if [ -r $svrlogs/abusers/filesharing/filesharing_$time.txt ] && [ -s $svrlogs/abusers/filesharing/filesharing_$time.txt ]; then
		echo "SUBJECT: File Sharing - $(hostname) - $(date +"%F")" >>$svrlogs/mail/fsmail_$time.txt
		echo "FROM: File Sharing <root@$(hostname)>" >>$svrlogs/mail/fsmail_$time.txt
		echo "" >>$svrlogs/mail/fsmail_$time.txt
		cat $svrlogs/abusers/filesharing/filesharing_$time.txt >>$svrlogs/mail/fsmail_$time.txt
		sendmail "$emailmo,$emailmg" <$svrlogs/mail/fsmail_$time.txt
	fi
}

check_users

file_sharing

file_sharing_sort

send_mail
