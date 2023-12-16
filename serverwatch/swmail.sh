#!/bin/bash

source /home/sample/scripts/dataset.sh

function send_mail() {
	serverwatch=($(find $svrlogs/serverwatch -type f -name "serverwatch*" -exec ls -lat {} + | grep "$(date +"%F")" | head -1 | awk '{print $NF}'))

	if [ ! -z $serverwatch ]; then
		echo "SUBJECT: Server Watch - $(hostname) - $(date +"%F")" >>$svrlogs/mail/swmail_$time.txt
		echo "FROM: Server Watch <root@$(hostname)>" >>$svrlogs/mail/swmail_$time.txt
		echo "" >>$svrlogs/mail/swmail_$time.txt
		echo "$(cat $serverwatch)" >>$svrlogs/mail/swmail_$time.txt
		sendmail "$emaillo,$emaillg" <$svrlogs/mail/swmail_$time.txt
	else
		echo "$(date +"%F %T") No content to send" >>$svrlogs/logs/serverwatchlogs_$logtime.txt
	fi
}

send_mail
