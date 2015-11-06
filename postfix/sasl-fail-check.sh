#!/bin/bash

abuselog=/var/log/bruteforce-mail-abuse.log
maillog=/var/log/mail.log
sender_mail="operations@example.tld"
date=$(date)
servername="myserver.example.tld"
myip="8.7.6.5"

#Do NOT edit below unless you know what you are doing :)

mail=`cat $maillog | grep auth-work | awk {' print $7 '} | sed 's/,/ /g' | sed 's/)/ /g' | awk {' print $2 '} | sort -n |uniq -c | awk {' print $1"-"$2 '}`

for IP in $mail; do
 number=`echo $IP | sed 's/-/ /g' | awk {' print $1 '}`
 ip=`echo $IP | sed 's/-/ /g' | awk {' print $2 '}`
  if [ ! "$1" == "--email" ]; then
   echo "$ip did $number attemps"
  else
  if [ $number -gt 10 ]; then
   rev_ip=$(echo $ip | awk 'BEGIN{FS=".";ORS="."} {for (i = NF; i > 0; i--){print $i}}')
    if dns_reply=$(host -t TXT ${rev_ip}abuse-contacts.abusix.org); then
      abuse_mail=$(echo $dns_reply | grep -Eio '\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b' | paste -sd ",")
    fi
   echo "$date - $ip tried $number times. send to $abuse_mail" >> $abuselog
   example=`grep "auth-work" $maillog | grep $ip | awk -v srvname=$servername {' print $1" "$2" "$3" "srvname" mail: "$6" "$7" wrong password "$10" "$11" "$12" "$13" "$14 '} | tail -n 10`
if [ $abuse_mail ]; then
sendmail -t -i -f $sender_mail $abuse_mail << EOF
Subject: Automatic bruteforce abuse report for IP address $ip
From: $sender_mail
To: $abuse_mail

This is an email abuse report about the IP address $ip generated at $date
You get this email because you are listed as the official abuse contact for this IP address.

The following ip tried to bruteforce our mailservice at $myip - $number times today, here is the last 10 attempts:

$example

EOF
fi
  else
  echo "$date - $ip tried $number times - no alert send" >> $abuselog
fi
fi
done
