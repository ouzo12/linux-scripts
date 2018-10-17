#!/bin/bash

#seperate ip with <SPACE> leave $1 if you want an argument
##singleip="$1 8.8.7.7 7.7.6.6"
singleip="$1"

#please dont use googledns or any other public dns they might not show valid results
dnsserver="74.82.42.42"

#color output (1=on / 0=off)
color=0

#got a microsoft snds account?
snds_enable=1

#snds api key - the ps you chech must be in your snds ip accesslist
sndskey="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
sndskey="9236a252-c640-126a-c427-20c390e4aa5b"

#snds tmp files
sndsfile=/tmp/snds.txt
iplist=/tmp/myiplist.txt

#rbl lister der skal checkes. ny liste pr linie.
rbl="
bl.spamcop.net
cbl.abuseat.org
free.v4bl.org
"
ERT="bl.spamcannibal.org
ddnsbl.internetdefensesystems.com
dnsbl.invaluement.com
black.uribl.com
grey.uribl.com
dnsbl.ahbl.org
ircbl.ahbl.org
b.barracudacentral.org
dnsbl.sorbs.net
http.dnsbl.sorbs.net
dul.dnsbl.sorbs.net
misc.dnsbl.sorbs.net
smtp.dnsbl.sorbs.net
socks.dnsbl.sorbs.net
spam.dnsbl.sorbs.net
web.dnsbl.sorbs.net
zombie.dnsbl.sorbs.net
dnsbl-1.uceprotect.net
dnsbl-2.uceprotect.net
dnsbl-3.uceprotect.net
pbl.spamhaus.org
sbl.spamhaus.org
xbl.spamhaus.org
zen.spamhaus.org
psbl.surriel.com
ubl.unsubscore.com
dnsbl.njabl.org
combined.njabl.org
rbl.spamlab.com
dyna.spamrats.com
noptr.spamrats.com
spam.spamrats.com
cbl.anti-spam.org.cn
cdl.anti-spam.org.cn
dnsbl.inps.de
drone.abuse.ch
httpbl.abuse.ch
dul.ru
korea.services.net
short.rbl.jp
virus.rbl.jp
spamrbl.imp.ch
wormrbl.imp.ch
virbl.bit.nl
rbl.suresupport.com
dsn.rfc-ignorant.org
ips.backscatterer.org
spamguard.leadmon.net
opm.tornevall.org
netblock.pedantic.org
multi.surbl.org
ix.dnsbl.manitu.net
tor.dan.me.uk
rbl.efnetrbl.org
relays.mail-abuse.org
blackholes.mail-abuse.org
rbl-plus.mail-abuse.org
dnsbl.dronebl.org
access.redhawk.org
db.wpbl.info
rbl.interserver.net
query.senderbase.org
bogons.cymru.com
spamsources.fabel.dk
bad.psky.me
reputation-ip.rbl.scrolloutf1.com
"

# do not edit
if [ "$2" = "-color" ]; then
	color=1
fi

 if [ "$color" = "1" ]; then
	myclean="\e[32mCLEAN\e[0m"
	myblisted="\e[31mBLACKLISTED\e[0m"
	myok="\e[32mOK\e[0m"
	myneutral="\e[32mNEUTRAL\e[0m"
	mygood="\e[32mGOOD\e[0m"
	mypoor="\e[31mPOOR\e[0m"
 else
	myclean="CLEAN"
	myblisted="BLACKLISTED"
    myok="OK"
    myneutral="NEUTRAL"
    mygood="GOOD"
    mypoor="POOR"
fi



if [ "$singleip" = "" ]; then
    echo "Usage: $0 <ip>"
	echo ""
	echo "example"
	echo "$0 \"1.2.3.4 8.8.8.8\""
	echo "force color"
	echo "$0 \"88.77.66.55\" -color"
    exit 2
fi

echo "RBL check uses $dnsserver for checks"

for i in $singleip; do
  black_count=0
  clean_count=0
  reverseip=`echo -n ${i}. | tac -s'.'`
  nameit=`/usr/bin/host $i| awk {'print $5'} | sed s/.$//`

if [ "$nameit" = "3(NXDOMAIN" ]; then
	if [ "$color" = "1" ]; then
	  echo -e "\e[31mMissing PTR/RDNS for $i\e[0m"
	 else
	  echo -e "Missing PTR/RDNS for $i"
	fi
else
    if [ "$color" = "1" ]; then
	  echo -e "\e[32mPTR/RDNS for $i is $nameit\e[0m"

     else
	  echo -e "PTR/RDNS for $i is $nameit"
    fi
fi

 for hosts in $rbl; do
	livetest=`/usr/bin/host $reverseip$hosts. $dnsserver | tail -1`
	test=`echo $livetest | grep -v "not found"`
	counter=`echo $test | wc -c`
	checkit=`echo $livetest |grep "has address" | wc -c `
	if [ $checkit -gt 1 ]; then
	  echo -e "$i is $myblisted at $hosts"
	  black_count=`expr $black_count + 1`
	 else
	  echo -e "$i is $myclean at $hosts"
	  clean_count=`expr $clean_count + 1`
	fi
 done
	echo "Microsoft related: "
	sb_neutral="0.5"
	sb_poor="-1.0"
	senderbasetest=`dig -t txt +short $reverseip\rf.senderbase.org`
	senderbase=`echo $senderbasetest| sed 's/"//g'`
	if [ "$senderbasetest" = "" ]; then
     echo -e "$i is $myok at rf.sederbase.org - No result found"
	 else
	 if [ `echo "$senderbase > $sb_neutral" | bc -l` = 1 ]; then
      echo -e "$i is $mygood ($senderbase) at rf.sederbase.org"
     elif [ `echo "$senderbase > $sb_poor" | bc -l` = 1 ]; then
        echo -e "$i is $myneutral ($senderbase) at rf.sederbase.org"
     else
        echo -e "$i is $mypoor ($senderbase) at rf.sederbase.org"
     fi
	fi

	ses_neutral="69"
	ses_poor="60"
	senderscoretest=`dig -t a +short $reverseip\score.senderscore.com`
	senderscore=`echo ${senderscoretest##*.}`

	if [ "$senderscoretest" = "" ]; then
	 echo -e "$i is $myok at score.senderscore.com - No result found"
	 else
     if [ `echo "$senderscore > $ses_neutral" | bc -l` = 1 ]; then
         echo -e "$i is $mygood ($senderscore) at score.senderscore.com"
     elif [ `echo "$senderscore > $ses_poor" | bc -l` = 1 ]; then
         echo -e "$i is $myneutral ($senderscore) at score.senderscore.com"
     else
         echo -e "$i is $mypoor ($senderscore) at score.senderscore.com - Info: https://www.senderscore.org/lookup.php?lookup=$1"
     fi
	fi

d2ip() {
 IFS=" " read -r a b c d  <<< $(echo  "obase=256 ; $1" |bc | sed 's/ 0/ /g')
 echo ${a#0}.${b#0}.${c#0}.${d#0}
}

ip2d() {
 IFS=.
 set -- $*
 echo $(( ($1*256**3) + ($2*256**2) + ($3*256) + ($4) ))
}

if [ "$sndskey" = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" ]; then
    if [ "$color" = "1" ]; then
	  echo -e "\e[31mSNDS enabled but NOT configured\e[0m"
     else
	  echo "SNDS enabled but NOT configured"
    fi
  else

if [ ! -f $sndsfile ]; then
 touch -d "200 hours ago" $sndsfile
fi

if [ ! -f $iplist ]; then
 touch -d "200 hours ago" $iplist
fi

if test "`find $sndsfile -mmin +720`"; then
  wget -q "https://postmaster.live.com/snds/ipStatus.aspx?key=$sndskey" -O $sndsfile
fi

if test "`find $iplist -mmin +720`"; then
 if [ -s $sndsfile ]; then
  rm -f $iplist
 fi
 myip=`cat $sndsfile | sed 's/,/ /g' | awk {' print $1"-"$2 '}`

 for MYIP in $myip; do
  ips=`echo ${MYIP%-*}`
  ipe=`echo ${MYIP#*-}`
  dec1=`ip2d $ips`
  dec2=`ip2d $ipe`

   for ilo in `eval echo {$dec1..$dec2}`; do
    d2ip $ilo >>$iplist
   done
 done
fi

counter=0
ipcount=""
 myfinder=`grep $i $iplist`
 myfinder2=`grep "$i$" $iplist | wc -l`
  if [ ! "$myfinder2" = "0" ]; then
   ((counter++))
   ipcount="$ipcount $H"
  fi

if [ $counter -gt 0 ]; then
    echo -e "$ipcount $myblisted Listed at Microsoft SNDS"
     else
    echo -e "$i is $myok and not listed at Microsoft SNDS (ip might not be in your snds list)"
fi

fi

echo -e "Sum: blacklisted $black_count, clean $clean_count of `echo $rbl |wc -w` rbl lists"

done

exit


for H in $myhostip; do
 myfinder=`grep $H $iplist`
 myfinder2=`grep "$H$" $iplist | wc -l`
  if [ ! "$myfinder2" = "0" ]; then
   ((counter++))
   ipcount="$ipcount $H"
  fi
done

if [ $counter -gt 0 ]; then
	echo "$ipcount Listed at Microsoft SNDS"
	exit 2
	 else
	echo "OK - Server ip - ($myhostip) are not listed at Microsoft SNDS"
	exit 0
fi
else
	echo "wrong paramters"
	exit 2
