#postfix scripts

##sasl-fail-check.sh

edit dovecot.conf

	pico /etc/dovecot/dovecot.conf

insert

	auth_verbose = yes
	auth_verbose_passwords = sha1

restart dovecot

	service dovecot restart

edit crontab

	pico /etc/crontab

insert

	#sends abuse mails of bruteforce ip owners
	58    23       *       *       *       root    /root/linux-scripts/postfix/sasl-fail-check.sh --email > /dev/null 2>&1

without --email it will only show at status of ips trying to bruteforce

##postgrey-report.sh

just a quick postgrey report script
NOTE: postgrey must be installed and used by postfix

##requeue.sh

Just re-queue all mails in postfix queue.

##delete-deferred.sh

Delete all mails in deferred queue

##delete-from-mailq.pl

Delete specific mails from domain or email in queue

##mailqueue-count.sh

Count how many mails in queue
