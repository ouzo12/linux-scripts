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



