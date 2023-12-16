#!/bin/bash

source /home/sample/scripts/dataset.sh

function ip_list() {
	ip a | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | cut -d"/" -f1 >>$temp/iplist_$time.txt
}

function blacklist_check() {
	while IFS= read -r ip || [[ -n "$ip" ]]; do
		revip=$(echo $ip | sed -ne "s~^\([0-9]\{1,3\}\)\.\([0-9]\{1,3\}\)\.\([0-9]\{1,3\}\)\.\([0-9]\{1,3\}\)$~\4.\3.\2.\1~p")

		while IFS= read -r bl || [[ -n "$bl" ]]; do
			listed="$(dig +short -t a $revip.$bl.)"

			if [[ ! -z $listed ]]; then
				printf "%-18s %-50s\n" "$ip" "$bl" >>$temp/ipblacklist_$time.txt
			fi

		done <"$scripts/serverwatch/blacklists.txt"

	done <"$temp/iplist_$time.txt"
}

function ip_blacklist() {
	if [ -r $temp/ipblacklist_$time.txt ] && [ -s $temp/ipblacklist_$time.txt ]; then
		ipblacklist=$(cat $temp/ipblacklist_$time.txt)
		cipcount=$(echo "$ipblacklist" | wc -l)

		sips=($(cat $scripts/svrips.txt | grep "$hostname" | awk -F':' '{print $NF}'))
		scount=${#sips[@]}

		printf "SHARED IP: \n\n" >>$svrlogs/serverwatch/ipblacklist_$time.txt

		for ((i = 0; i < scount; i++)); do
			data=$(cat $temp/ipblacklist_$time.txt | grep ${sips[i]} | awk '{print $NF}')

			if [[ ! -z "$data" ]]; then
				echo "${sips[i]}: " >>$svrlogs/serverwatch/ipblacklist_$time.txt
				echo "$data" >>$svrlogs/serverwatch/ipblacklist_$time.txt
				echo "" >>$svrlogs/serverwatch/ipblacklist_$time.txt
			fi

			ipblacklist=$(echo "$ipblacklist" | grep -v ${sips[i]})
		done

		nipcount=$(echo "$ipblacklist" | wc -l)

		if [ $cipcount -eq $nipcount ]; then
			printf "Not blacklisted\n\n" >>$svrlogs/serverwatch/ipblacklist_$time.txt
		fi

		if [[ ! -z "$ipblacklist" ]]; then
			uips=($(echo "$ipblacklist" | awk '{print $1}' | sort | uniq))
			ucount=${#uips[@]}

			printf "DEDICATED IP: \n\n" >>$svrlogs/serverwatch/ipblacklist_$time.txt

			for ((i = 0; i < ucount; i++)); do
				data=$(echo "$ipblacklist" | grep ${uips[i]} | awk '{print $NF}')

				echo "${uips[i]}: " >>$svrlogs/serverwatch/ipblacklist_$time.txt
				echo "$data" >>$svrlogs/serverwatch/ipblacklist_$time.txt
				echo "" >>$svrlogs/serverwatch/ipblacklist_$time.txt
			done
		fi
	fi
}

ip_list

blacklist_check

ip_blacklist
