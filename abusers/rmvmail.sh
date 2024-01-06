#!/bin/bash

source /home/sample/scripts/dataset.sh

input=$1
dcount=$2

num='^[0-9]+$'

function check_input() {
    username=$(cat /etc/trueuserowners | awk '{print $1}' | sed 's/://' | awk -v user=$input '{if ($1==user) print $1}')

    if [[ $input == "$username" ]]; then

        if [[ $dcount =~ $num ]]; then
            rmv_mail
        else
            echo "Invalid number"
        fi
    else
        echo "Username not found"
    fi
}

function rmv_mail() {
    total=$(find /home/$username/mail -type f -name "*,S=*,W=*" -mtime +$dcount | wc -l)

    if [ $total -gt 0 ]; then
        find /home/$username/mail -type f -name "*,S=*,W=*" -mtime +$dcount -exec ls -lhat {} + >>$svrlogs/abusers/remove/$username-rmvml_$time.txt

        find /home/$username/mail -type f -name "*,S=*,W=*" -mtime +$dcount -delete

        echo "$total emails found and removed"

        find /home/$username/mail/ -type f -name maildirsize | while read line; do mv -v $line{,.bak}; done

        /usr/local/cpanel/scripts/generate_maildirsize --confirm $username

        mv -v /home/$username/.cpanel/email_accounts.json{,-bak}

        find /home/$username/mail -type f -name "*.bak" -delete

        rm -f /home/$username/.cpanel/email_accounts.json-bak
    else
        echo "No emails older than $dcount days found"
    fi
}

check_input
