#!/bin/bash

source /home/sample/scripts/dataset.sh

function ip_list() {
	ip a | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | cut -d"/" -f1 >>$temp/ipaddress_$time.txt
}

function check_ptr() {
	while IFS= read -r line || [[ -n "$line" ]]; do
		ptr=$(dig -x $line +short)

		if [ ! -z $ptr ]; then
			printf "%-18s %-50s\n" "$line" "$ptr" >>$temp/ipptr_$time.txt
		else
			printf "%-18s %-50s\n" "$line" "no_ptr_record" >>$temp/ipptr_$time.txt
		fi

	done <"$temp/ipaddress_$time.txt"
}

function check_data() {
	if [ -r $temp/ipptr_$time.txt ] && [ -s $temp/ipptr_$time.txt ]; then
		ipptr=$(cat $temp/ipptr_$time.txt)

		sips=($(cat $scripts/svrips.txt | grep "$hostname" | awk -F':' '{print $NF}'))
		scount=${#sips[@]}

		printf "SHARED IP: \n\n" >>$svrlogs/serverwatch/ipptr_$time.txt

		for ((i = 0; i < scount; i++)); do
			data=$(cat $temp/ipptr_$time.txt | grep ${sips[i]})

			echo "$data" >>$svrlogs/serverwatch/ipptr_$time.txt

			ipptr=$(echo "$ipptr" | grep -v ${sips[i]})
		done

		echo "" >>$svrlogs/serverwatch/ipptr_$time.txt

		if [[ ! -z "$ipptr" ]]; then
			uips=($(echo "$ipptr" | awk '{print $1}' | sort | uniq))
			ucount=${#uips[@]}

			printf "DEDICATED IP: \n\n" >>$svrlogs/serverwatch/ipptr_$time.txt

			for ((i = 0; i < ucount; i++)); do
				data=$(echo "$ipptr" | grep ${uips[i]})

				echo "$data" >>$svrlogs/serverwatch/ipptr_$time.txt
			done
		fi
	fi
}

function check_diff() {
	tlist=($(find $svrlogs/serverwatch -type f -name "ipptr*" -exec ls -lat {} + | grep "$(date +"%F")" | head -1 | awk '{print $NF}'))
	ylist=($(find $svrlogs/serverwatch -type f -name "ipptr*" -exec ls -lat {} + | grep "$(date -d 'yesterday' +"%F")" | head -1 | awk '{print $NF}'))

	if [[ ! -z $ylist ]]; then
		tip=($(cat $tlist | grep -v "SERVER IP:\|USER IP:\|Today:\|Yesterday:" | awk '{print $1}'))
		tptr=($(cat $tlist | grep -v "SERVER IP:\|USER IP:\|Today:\|Yesterday:" | awk '{print $2}'))
		yip=($(cat $ylist | grep -v "SERVER IP:\|USER IP:\|Today:\|Yesterday:" | awk '{print $1}'))
		yptr=($(cat $ylist | grep -v "SERVER IP:\|USER IP:\|Today:\|Yesterday:" | awk '{print $2}'))

		tcount=${#tip[@]}
		ycount=${#yip[@]}

		for ((i = 0; i < tcount; i++)); do
			for ((j = 0; j < ycount; j++)); do
				if [[ "${tip[i]}" == "${yip[j]}" ]]; then
					if [[ "${tptr[i]}" != "${yptr[j]}" ]]; then
						echo "Today: ${tip[i]} - ${tptr[i]}" >>$temp/ipptrdiff_$time.txt
						echo "Yesterday: ${yip[j]} - ${yptr[j]}" >>$temp/ipptrdiff_$time.txt
					fi
				fi
			done
		done
	fi
}

function diff_data() {
	if [ -r $temp/ipptrdiff_$time.txt ] && [ -s $temp/ipptrdiff_$time.txt ]; then
		echo "" >>$svrlogs/serverwatch/ipptr_$time.txt
		data=$(cat $temp/ipptrdiff_$time.txt)
		echo "$data" >>$svrlogs/serverwatch/ipptr_$time.txt
	fi
}

ip_list

check_ptr

check_data

check_diff

diff_data
