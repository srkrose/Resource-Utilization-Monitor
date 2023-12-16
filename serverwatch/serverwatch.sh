#!/bin/bash

source /home/sample/scripts/dataset.sh

function check_directory() {
	sh $scripts/directory.sh
}

printf "Server Watch - $(date +"%F %T")\n" >>$svrlogs/serverwatch/serverwatch_$time.txt
printf "\n************************************************************\n" >>$svrlogs/serverwatch/serverwatch_$time.txt

function disk_free() {
	printf "\n# *** Disk Free ***\n\n" >>$svrlogs/serverwatch/serverwatch_$time.txt

	diskfree=$(echo "$(df -Th | egrep "vda1|sda1" | awk '{print $(NF-1)}')")

	echo "$diskfree" >>$svrlogs/serverwatch/serverwatch_$time.txt

	printf "\n************************************************************\n" >>$svrlogs/serverwatch/serverwatch_$time.txt
}

function file_count() {
	printf "\n# *** File Count (/home) ***\n\n" >>$svrlogs/serverwatch/serverwatch_$time.txt

	filecount=($(find $svrlogs/filecount -type f -name "homedir*" -exec ls -lat {} + | grep "$(date +"%F")" | head -1 | awk '{print $NF}'))

	if [[ ! -z $filecount ]]; then
		fcount=$(cat $filecount | grep "FILE COUNT" | awk '{print $NF}')
		diff=$(cat $filecount | grep "DIFFERENCE:" | awk '{print $2,$NF}')

		echo "$fcount" >>$svrlogs/serverwatch/serverwatch_$time.txt
		echo "$diff" >>$svrlogs/serverwatch/serverwatch_$time.txt
	else
		printf "File count not found\n" >>$svrlogs/serverwatch/serverwatch_$time.txt
	fi

	printf "\n************************************************************\n" >>$svrlogs/serverwatch/serverwatch_$time.txt
}

function uptime_check() {
	printf "\n# *** Uptime ***\n\n" >>$svrlogs/serverwatch/serverwatch_$time.txt

	utfull=$(uptime | grep "day")

	if [[ ! -z $utfull ]]; then
		uptime=$(echo "$(uptime | awk '{print $3,$4}' | sed 's/,//')")
	else
		uptime=$(echo "$(uptime | awk '{print $3}' | sed 's/,//')")
	fi

	echo "$uptime" >>$svrlogs/serverwatch/serverwatch_$time.txt

	printf "\n************************************************************\n" >>$svrlogs/serverwatch/serverwatch_$time.txt
}

function daily_process() {
	printf "\n# *** Daily Process ***\n\n" >>$svrlogs/serverwatch/serverwatch_$time.txt

	sh $scripts/serverwatch/dailyprocess.sh

	dailyprocess=($(find $svrlogs/serverwatch -type f -name "dailyprocess*" -exec ls -lat {} + | grep "$(date +"%F_%H:")" | head -1 | awk '{print $NF}'))

	if [[ ! -z $dailyprocess ]]; then
		echo "$(head -3 $dailyprocess)" >>$svrlogs/serverwatch/serverwatch_$time.txt
	else
		printf "Not available\n" >>$svrlogs/serverwatch/serverwatch_$time.txt
	fi

	printf "\n************************************************************\n" >>$svrlogs/serverwatch/serverwatch_$time.txt
}

function ip_blacklist() {
	printf "\n# *** IP Blacklist ***\n\n" >>$svrlogs/serverwatch/serverwatch_$time.txt

	sh $scripts/serverwatch/ipcheck.sh

	ipblacklist=($(find $svrlogs/serverwatch -type f -name "ipblacklist*" -exec ls -lat {} + | grep "$(date +"%F_%H:")" | head -1 | awk '{print $NF}'))

	if [[ ! -z $ipblacklist ]]; then
		echo "$(cat $ipblacklist)" >>$svrlogs/serverwatch/serverwatch_$time.txt
	else
		printf "Not blacklisted\n" >>$svrlogs/serverwatch/serverwatch_$time.txt
	fi

	printf "\n************************************************************\n" >>$svrlogs/serverwatch/serverwatch_$time.txt
}

function bandwidth_usage() {
	printf "\n# *** Bandwidth Usage ***\n\n" >>$svrlogs/serverwatch/serverwatch_$time.txt

	sh $scripts/serverwatch/bandwidth.sh

	bandwidthusage=($(find $svrlogs/serverwatch -type f -name "bandwidth*" -exec ls -lat {} + | grep "$(date +"%F_%H:")" | head -1 | awk '{print $NF}'))

	if [[ ! -z $bandwidthusage ]]; then
		bandwidth=$(cat $bandwidthusage | grep "Total" | sed 's/Total//')

		echo "$bandwidth" >>$svrlogs/serverwatch/serverwatch_$time.txt
	else
		printf "Not available\n" >>$svrlogs/serverwatch/serverwatch_$time.txt
	fi

	printf "\n************************************************************\n" >>$svrlogs/serverwatch/serverwatch_$time.txt
}

function disk_usage() {
	printf "\n# *** Disk Usage ***\n\n" >>$svrlogs/serverwatch/serverwatch_$time.txt

	sh $scripts/serverwatch/diskusage.sh

	diskusage=($(find $svrlogs/serverwatch -type f -name "diskusage*" -exec ls -lat {} + | grep "$(date +"%F_%H:")" | head -1 | awk '{print $NF}'))

	if [[ ! -z $diskusage ]]; then
		echo "$(head -5 $diskusage | sed 's/M//')" >>$svrlogs/serverwatch/serverwatch_$time.txt
	else
		printf "Not available\n" >>$svrlogs/serverwatch/serverwatch_$time.txt
	fi

	printf "\n************************************************************\n" >>$svrlogs/serverwatch/serverwatch_$time.txt
}

function disk_increment() {
	printf "\n# *** Disk Usage Increment ***\n\n" >>$svrlogs/serverwatch/serverwatch_$time.txt

	sh $scripts/serverwatch/diskincrement.sh

	diskincrement=($(find $svrlogs/serverwatch -type f -name "diskincrement*" -exec ls -lat {} + | grep "$(date +"%F_%H:")" | head -1 | awk '{print $NF}'))

	if [[ ! -z $diskincrement ]]; then
		echo "$(cat $diskincrement)" >>$svrlogs/serverwatch/serverwatch_$time.txt
	else
		printf "No high disk usage increment\n" >>$svrlogs/serverwatch/serverwatch_$time.txt
	fi

	printf "\n************************************************************\n" >>$svrlogs/serverwatch/serverwatch_$time.txt
}

function abusers_usage() {
	printf "\n# *** Mail Usage ***\n\n" >>$svrlogs/serverwatch/serverwatch_$time.txt

	sh $scripts/abusers/mailusage.sh

	mailusage=($(find $svrlogs/abusers/mailusage -type f -name "mailusage*" -exec ls -lat {} + | grep "$(date +"%F_%H:")" | head -1 | awk '{print $NF}'))

	if [[ ! -z $mailusage ]]; then
		echo "$(cat $mailusage | grep -v "Email Hosting")" >>$svrlogs/serverwatch/serverwatch_$time.txt
	else
		printf "No high mail usage\n" >>$svrlogs/serverwatch/serverwatch_$time.txt
	fi

	printf "\n************************************************************\n" >>$svrlogs/serverwatch/serverwatch_$time.txt
}

function mail_block() {
	printf "\n# *** Outgoing Mail Blocked ***\n\n" >>$svrlogs/serverwatch/serverwatch_$time.txt

	sh $scripts/spam/outgoingblock.sh

	mailblock=($(find $svrlogs/serverwatch -type f -name "outgoingblock*" -exec ls -lat {} + | grep "$(date +"%F_%H:")" | head -1 | awk '{print $NF}'))

	if [[ ! -z $mailblock ]]; then
		echo "$(cat $mailblock)" >>$svrlogs/serverwatch/serverwatch_$time.txt
	else
		printf "No new mail block entries\n" >>$svrlogs/serverwatch/serverwatch_$time.txt
	fi

	printf "\n************************************************************\n" >>$svrlogs/serverwatch/serverwatch_$time.txt
}

function ip_ptr() {
	printf "\n# *** IP PTR Records ***\n\n" >>$svrlogs/serverwatch/serverwatch_$time.txt

	sh $scripts/serverwatch/ptrcheck.sh

	ipptr=($(find $svrlogs/serverwatch -type f -name "ipptr*" -exec ls -lat {} + | grep "$(date +"%F_%H:")" | head -1 | awk '{print $NF}'))

	if [[ ! -z $ipptr ]]; then
		echo "$(cat $ipptr)" >>$svrlogs/serverwatch/serverwatch_$time.txt
	else
		printf "No PTR record found\n" >>$svrlogs/serverwatch/serverwatch_$time.txt
	fi

	printf "\n************************************************************\n" >>$svrlogs/serverwatch/serverwatch_$time.txt
}

function spf_subdomain() {
	printf "\n# *** SPF Check - Subdomain ***\n\n" >>$svrlogs/serverwatch/serverwatch_$time.txt

	sh $scripts/dnszone/spfsubdomain.sh

	spfsubdomain=($(find $svrlogs/dnszone -type f -name "subdomspf*" -exec ls -lat {} + | grep "$(date +"%F_%H:")" | head -1 | awk '{print $NF}'))

	if [[ ! -z $spfsubdomain ]]; then
		echo "$(cat $spfsubdomain)" >>$svrlogs/serverwatch/serverwatch_$time.txt
	else
		printf "No SPF updates\n" >>$svrlogs/serverwatch/serverwatch_$time.txt
	fi

	printf "\n************************************************************\n" >>$svrlogs/serverwatch/serverwatch_$time.txt
}

function check_mailbox() {
	printf "\n# *** Mailbox Check ***\n\n" >>$svrlogs/serverwatch/serverwatch_$time.txt

	sh $scripts/spam/mailbox.sh

	mailbox=($(find $svrlogs/serverwatch -type f -name "mailbox*" -exec ls -lat {} + | grep "$(date +"%F_%H:")" | head -1 | awk '{print $NF}'))

	if [[ ! -z $mailbox ]]; then
		echo "$(cat $mailbox)" >>$svrlogs/serverwatch/serverwatch_$time.txt
	else
		printf "No new mailbox entries\n" >>$svrlogs/serverwatch/serverwatch_$time.txt
	fi

	printf "\n************************************************************\n" >>$svrlogs/serverwatch/serverwatch_$time.txt
}

function send_mail() {
	sh $scripts/serverwatch/swmail.sh
}

check_directory

disk_free

file_count

ip_blacklist

daily_process

bandwidth_usage

disk_usage

ip_ptr

disk_increment

abusers_usage

check_mailbox

mail_block

uptime_check

spf_subdomain

send_mail
