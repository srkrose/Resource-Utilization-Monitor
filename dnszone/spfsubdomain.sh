#!/bin/bash

source /home/sample/scripts/dataset.sh

function user_list() {
	cat /etc/trueuserowners | awk '{print $1}' | sed 's/://' >>$temp/userlist_$time.txt
}

function spf_sub() {
	while IFS= read -r line || [[ -n "$line" ]]; do
		username=$line
		domains=$(uapi --user=$username DomainInfo list_domains | sed -n '/main_domain:/,/errors:/p' | grep -v "parked_domains:\|sub_domains:\|errors:" | sed '2d' | awk '{print $NF}')
		maindomain=$(echo "$domains" | head -1)
		subdoms=$(echo "$domains" | sed '1d')

		if [[ ! -z $subdoms && $maindomain != $subdoms ]]; then
			while IFS= read -r line; do
				subdomain=$line
				domip=$(whmapi1 dumpzone domain=$maindomain | grep -v "cname: " | grep -B 2 "name: webmail.$subdomain." | grep "address:" | awk '{print $NF}')
				spf="v=spf1 +a +mx +ip4:$domip +include:eig.spf.a.cloudfilter.net ~all"
				zonesub=$(whmapi1 dumpzone domain=$maindomain | grep -B 2 "txtdata: v=spf1" | grep -A 2 "name: $subdomain." | grep "txtdata:" | sed 's/txtdata://' | sed -e 's/^[[:space:]]*//')

				spf_rec

			done <<<"$subdoms"
		fi

	done <"$temp/userlist_$time.txt"
}

function spf_rec() {

	if [[ ! -z $domip ]]; then
		if [[ "$zonesub" != "$spf" ]]; then
			if [[ "$domip" != "$svrip" ]]; then
				iplist=$(ip a | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | cut -d"/" -f1)

				filter=$(echo "$iplist" | grep "$domip")

				if [[ ! -z $filter ]]; then
					default="v=spf1 +a +mx +ip4:$domip ~all"

					spfrec="v%3Dspf1%20%2Ba%20%2Bmx%20%2Bip4%3A$domip%20%2Binclude%3Aeig.spf.a.cloudfilter.net%20~all"

					spf_update
				fi
			else
				default="v=spf1 +a +mx +ip4:$svrip ~all"

				spfrec="v%3Dspf1%20%2Ba%20%2Bmx%20%2Bip4%3A$svrip%20%2Binclude%3Aeig.spf.a.cloudfilter.net%20~all"

				spf_update
			fi
		fi
	fi
}

function spf_update() {
	if [[ "$zonesub" == "$default" ]]; then
		result=$(whmapi1 install_spf_records domain=$subdomain record=$spfrec | grep -i "result:" | awk '{print $2}')
		#result=0

		print_data
	else
		result=0

		print_data
	fi
}

function print_data() {
	if [ "$result" -eq 1 ]; then
		printf "%-25s %-22s %-50s %-50s %-20s\n" "USER: $username" "IP: $domip" "SUB: $subdomain" "MAIN: $maindomain" "UPDATED: Yes" >>$svrlogs/dnszone/subdomspf_$time.txt
		printf "SPF: $zonesub\n\n" >>$svrlogs/dnszone/subdomspf_$time.txt
		#else
		#printf "%-25s %-22s %-50s %-50s %-20s\n" "USER: $username" "IP: $domip" "SUB: $subdomain" "MAIN: $maindomain" "UPDATED: No" >> $svrlogs/dnszone/subdomspf_$time.txt
		#printf "SPF: $zonesub\n\n" >> $svrlogs/dnszone/subdomspf_$time.txt
	fi
}

user_list

spf_sub
