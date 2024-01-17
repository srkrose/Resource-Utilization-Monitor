#!/bin/bash

source /home/sample/scripts/dataset.sh

function php_version() {
	whmapi1 php_get_vhost_versions | grep "version:\|vhost:" | grep -v "version: 1" | awk '{print $NF}' | sed 's/"//g' | paste -d' ' - - >>$temp/phpversions_$time.txt

	whmapi1 php_get_vhosts_by_version version=inherit | grep " - " | awk '{ print $NF }' | sed 's/"//g' | sort >>$temp/phpinherit_$time.txt
}

function rmv_inherit() {
	if [ -r $temp/phpinherit_$time.txt ] && [ -s $temp/phpinherit_$time.txt ]; then
		while IFS= read -r domain || [[ -n "$domain" ]]; do
			phpversion=$(cat $temp/phpversions_$time.txt | awk -v domain=$domain '{if($2==domain) print $1}')

			result=$(whmapi1 php_set_vhost_versions version=$phpversion vhost=$domain | grep -i "result:" | awk '{print $2}')

			if [ "$result" -eq 1 ]; then
				printf "%-16s %-50s %-16s\n" "PHP: $phpversion" "DOMAIN: $domain" "MODIFIED: Yes" >>$temp/phpinheritmod_$time.txt
			else
				printf "%-16s %-50s %-16s\n" "PHP: $phpversion" "DOMAIN: $domain" "MODIFIED: No" >>$temp/phpinheritmod_$time.txt
			fi

		done <"$temp/phpinherit_$time.txt"
	fi
}

function php_version_sort() {
	if [ -r $temp/phpinheritmod_$time.txt ] && [ -s $temp/phpinheritmod_$time.txt ]; then
		cat $temp/phpinheritmod_$time.txt | sort >>$svrlogs/serverwatch/phpinheritmod_$time.txt
	fi
}

php_version

rmv_inherit

php_version_sort
