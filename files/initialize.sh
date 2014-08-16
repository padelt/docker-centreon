#!/bin/bash
# Copies an initial set of configuration files
if [ ! -f /usr/local/nagios/etc/ ]
then
	yes n | cp -i /root/nagios/nagios.cfg /usr/local/nagios/etc/nagios.cfg
	yes n | cp -i /root/nagios/nagios/sample-config/cgi.cfg /usr/local/nagios/etc/
	yes n | cp -i /root/nagios/nagios/sample-config/resource.cfg /usr/local/nagios/etc/
	cp -r /root/nagios/nagios/sample-config/template-object /usr/local/nagios/etc/objects
fi
chown -R nagios:nagios /usr/local/nagios/etc/
chmod -R g+w /usr/local/nagios/etc/
chmod -R 664 /usr/local/nagios/etc/objects/
chmod 775 /usr/local/nagios/etc/objects/

# This file needs to be applied manually to seed the empty database on the first run.
cp /root/nagios/ndoutils-*/db/mysql.sql /usr/local/nagios/etc/
