#!/bin/bash
BASE=/usr/local/nagios
mkdir -p $BASE/var/spool/checkresults
mkdir -p $BASE/var/archives/
mkdir -p $BASE/var/log/
mkdir -p $BASE/var/rw
mkdir -p /var/lib/centreon/metrics/
mkdir -p /var/lib/centreon/status/
mkdir -p /var/lib/centreon/nagios-perf/
mkdir -p /var/lib/centreon/centplugins/
chown -R nagios:nagios $BASE/etc $BASE/var
chown -R centreon:centreon /var/lib/centreon/ /etc/centreon
chmod -R 775 $BASE/etc $BASE/var /var/lib/centreon /etc/centreon

# Perfdata is hardcoded in process-perfdata...
mkdir -p /var/log/nagios/
chown -R nagios:nagios /var/log/nagios
chmod -R g+w /var/log/nagios

yes n | cp -i /root/centreon-etc/inst* /etc/centreon/ 2> /dev/null

# Stop Centreon stumbling over its own feet...
if [ -f /etc/centreon/conf.pm ]
then
        # Configuration was completed, so try to move the install directory out of the way.
        if [ -d /usr/local/centreon/www/install ]
        then
                mv /usr/local/centreon/www/install /usr/local/centreon/www-install.deactivated
        fi
fi

sysctl -w kernel.msgmnb=655360 # without that, ndo2db will fail to work and no services or hosts will show up in Centreon, Monitoring tab

supervisord -n -c /etc/supervisord.conf -e debug
