#!/bin/bash
maillog=/var/log/mail.log
cat $maillog | /usr/bin/postgreyreport --nosingle_line --check_sender=mx,a --show_tries --separate_by_subnet=":===============================================================================================\n"
