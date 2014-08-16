#!/bin/sh
/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg
supervisorctl -c /etc/supervisord.conf restart nagios
