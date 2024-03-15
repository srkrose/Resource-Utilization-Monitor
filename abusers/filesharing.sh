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
	abuserfs=$(find /home/$username -type f \( -name "*.png" -o -name "*.PNG" -o -name "*.jpg" -o -name "*.JPG" -o -name "*.jpeg" -o -name "*.bmp" -o -name "*.gif" -o -name "*.tif" -o -name "*.tiff" -o -name "*.mp4" -o -name "*.mkv" -o -name "*.webm" -o -name "*.avi" -o -name "*.mov" -o -name "*.ogv" -o -name "*.m4v" -o -name "*.wmv" -o -name "*.flv" -o -name "*.3gp" -o -name "*.mpeg" -o -name "*.mpg" -o -name "*.divx" -o -name "*.mp3" -o -name "*.wav" -o -name "*.aac" -o -name "*.flac" -o -name "*.ogg" -o -name "*.wma" -o -name "*.m4a" -o -name "*.pdf" -o -name "*.doc" -o -name "*.docx" -o -name "*.xlsx" -o -name "*.ppt" -o -name "*.pptx" -o -name "*.app" -o -name "*.apk" -o -name "*.deb" -o -name "*.iso" -o -name "*.torrent" -o -name "*.rar" \) ! \( -path "*/cache*" -o -path "*/plugin*" -o -path "*/theme*" -o -path "*/.cpanel/*" -o -path "*/.trash/*" -o -path "*/logs/*" -o -path "*/ssl/*" -o -path "*/tmp/*" -o -path "*/wp-content/*" -o -path "*/lib/*" -o -path "*/src/*" -o -path "*/dist/*" -o -path "*/app/*" -o -path "*assets*" -o -path "*/vendor*" -o -path "*/icons/*" -o -path "*/favicon/*" -o -path "*/resources/*" -o -path "*/libraries/*" -o -path "*/dolibarrdata/*" -o -path "*/css/*" -o -path "*/bootstrap/*" \) -exec du -h --time {} + | awk -F. '{print $NF ": " $0}' | sort)

	if [[ ! -z $abuserfs ]]; then
		extlist=$(echo "$abuserfs" | awk -F":" '{print $1}' | sort | uniq -c | sort -nr)

		while IFS= read -r line; do
			extcount=$(echo "$line" | awk '{print $1}')
			exttype=$(echo "$line" | awk '{print $2}')

			data=$(echo "$abuserfs" | awk -v exttype="$exttype" -F":" '{if($1==exttype) print}')

			if [[ $extcount -gt 100 && $exttype != "png" && $exttype != "PNG" && $exttype != "jpg" && $exttype != "JPG" && $exttype != "jpeg" && $exttype != "bmp" && $exttype != "gif" && $exttype != "tif" && $exttype != "tiff" ]]; then
				echo "$data" >>$temp/$username-fs_$time.txt

			elif [[ $extcount -gt 5000 ]]; then
				if [[ $exttype == "png" || $exttype == "PNG" || $exttype == "jpg" || $exttype == "JPG" || $exttype == "jpeg" || $exttype == "bmp" || $exttype == "gif" || $exttype == "tif" || $exttype == "tiff" ]]; then
					size_check

					if [ -r $temp/$username-$exttype-temp_$time.txt ] && [ -s $temp/$username-$exttype-temp_$time.txt ]; then
						lcount=$(cat $temp/$username-$exttype-temp_$time.txt | wc -l)

						if [[ $lcount -gt 5000 ]]; then
							cat $temp/$username-$exttype-temp_$time.txt >>$temp/$username-fs_$time.txt
						fi
					fi
				fi

			else
				if [[ $exttype != "png" && $exttype != "PNG" && $exttype != "jpg" && $exttype != "JPG" && $exttype != "jpeg" && $exttype != "bmp" && $exttype != "gif" && $exttype != "tif" && $exttype != "tiff" ]]; then
					size_check

					if [ -r $temp/$username-$exttype-temp_$time.txt ] && [ -s $temp/$username-$exttype-temp_$time.txt ]; then
						lcount=$(cat $temp/$username-$exttype-temp_$time.txt | wc -l)

						if [[ $lcount -gt 20 ]]; then
							echo "$data" >>$temp/$username-fs_$time.txt
						fi
					fi
				fi
			fi

		done <<<"$extlist"

		print_data
	fi
}

function size_check() {
	while IFS= read -r dline; do
		size=$(echo "$dline" | awk '{print $2}')
		stype=${size: -1}

		if [[ "$stype" == "G" ]]; then
			echo "$dline" >>$temp/$username-fs_$time.txt

		elif [[ "$stype" == "M" ]]; then
			nsize=${size:0:${#size}-1}

			if [[ $nsize == *[.]* ]]; then
				val=${nsize%.*}
			else
				val=$nsize
			fi

			if [[ $val -gt 1 ]]; then
				echo "$dline" >>$temp/$username-$exttype-temp_$time.txt
			fi
		fi

	done <<<"$data"
}

function print_data() {
	if [ -r $temp/$username-fs_$time.txt ] && [ -s $temp/$username-fs_$time.txt ]; then
		package=$(whmapi1 accountsummary user=$username | grep -i "plan:" | awk -F':' '{print $2}')

		fcount=$(cat $temp/$username-fs_$time.txt | wc -l)

		cat $temp/$username-fs_$time.txt >>$svrlogs/abusers/filesharing/$username-fs_$time.txt

		ext=$(cat $svrlogs/abusers/filesharing/$username-fs_$time.txt | awk -F":" '{print $1}' | sort | uniq -c | sort -nr | awk '{printf $1" - "$2", "}')

		extension=${ext:0:${#ext}-2}

		filedir=$(cat $svrlogs/abusers/filesharing/$username-fs_$time.txt | awk '{$1=$2=$3=""; print}' | awk -F'/' '{print $4}' | sort | uniq -c | sort -nr)

		printf "%-12s - %5s - %6s M - %-70s\n" "$username" "$fcount" "$usedspace" "$package" >>$temp/filesharing_$time.txt
		printf "EXTENSION: $extension\n" >>$temp/filesharing_$time.txt
		printf "FILEDIR: \n$filedir\n\n" >>$temp/filesharing_$time.txt
	fi
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

file_sharing_sort

send_mail
