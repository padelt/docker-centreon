# Dockerized Centreon 2.5.2

This is NOT well-tested. It works on two different installations but the result you see evolved
while getting it to this stage..

Please report any problems!

## Preparing the host

The configuration files and state data are stored on directories outside the container.
We will mount external directories for all state that should not vanish when the container is regenerated:

 * /docker-store/centreon/nagios-etc
 * /docker-store/centreon/nagios-var
 * /docker-store/centreon/centreon-etc
 * /docker-store/centreon/centreon-var

You may place these folders somewhere else, just make sure you update the corresponding paths below.

## Building the image

First step you do with this repo (if you cloned it) is to

	docker build -t centreon .

it. Note that dot at the end referencing the current directory. Once that is done you have an image that you can run and that is tagged `centeron` for easier reference below.

## Running the container

Now that's the easy part, as long as you remember to connect the right volumes:

	docker run -i -t -p 8100:80 --name centreon \
	  -v /docker-store/centreon/nagios-etc:/usr/local/nagios/etc \
	  -v /docker-store/centreon/nagios-var:/usr/local/nagios/var \
	  -v /docker-store/centreon/centreon-var:/var/lib/centreon \
	  -v /docker-store/centreon/centreon-etc:/etc/centreon \
	  -v /etc/localtime:/etc/localtime:ro \
	  --privileged=true \
	  centreon /bin/bash

The 8100 is the host TCP port under which the Apache Webserver inside the container will be available on the outside. Change as desired.

The `/bin/bash` drops you in a shell in exactly the situation where the container
normally would execute `/start.sh`. If you omit `/bin/bash`, exactly that will be done
(as specified as the CMD statement in `Dockerfile`). While running the container with `bash`, try `/start.sh &` to start the "normal" stuff and still be able to look inside
the container for logfiles etc.

The need to run the container as a privileged container stems from the need to increase the `kernel.msgmnb` parameter.

The Centreon daemon `centcore` will not start and end up in a supervisord-FATAL state. That is expected, as the following setup will need to create the configuration files first. Nevertheless, the web interface works already.

## Setting up Centreon

Once the container is running, you can reach Centreon under

	http://host-server.example.com:8100/centreon/

Centreon will start the setup process. It is very opinionated and even requires you to hand over
your MySQL root user password. Here are some hints for what values are needed:

* Monitoring Engine: nagios
* Nagios directory: /usr/local/nagios
* Nagiostats binary: /usr/local/nagios/bin/nagiostats
* Nagios image directory: /usr/local/nagios/share/images
* Embedded Perl initialisation file: /usr/local/nagios/share/p1.pl
* Broker Module: ndoutils
* Ndomod binary (ndomod.o): /usr/local/nagios/bin/ndomod.o

You may end up in an unescapable loop of Centreon trying to apply upgrades.
It seems that it does not remove the install directory. If that happens, restart the container. `/start.sh` should now take care of that.

Centreon contains defaults that end up in the generated Nagios configuration.
Those defaults need to be changed. Log into the web frontend as `admin` and go to:

	Configuration -> Monitoring Engines -> `main.cfg` (left nav bar) -> `Nagios CFG 1`

Then change these values:

Files tab:

* Status file: /usr/local/nagios/var/status.log
* Log file: /usr/local/nagios/var/nagios.log
* Temp File: /usr/local/nagios/var/nagios.tmp
* Lock File: /usr/local/nagios/var/nagios.lock

Log Options tab:

* Log Archive Path: /usr/local/nagios/var/archives/
* State Retention File: /usr/local/nagios/var/retention.dat

Now click Save and generate the Nagios configuration files:

* `Configuration` -> `Monitoring Engine` -> Generate
* Click `Export` to see if any errors pop up. If not:
* Activate checkbox `Move Export Files`
* Activate checkbox `Restart Monitoring Engine` (Method: Restart)
* Click `Export`

Then stop and restart the container to give `centcore` a chance to start.

## Fixing MySQL permissions

Centreon sets itself up with MySQL access rights from the IP address that the installation is
running from. Inside a container, that IP very likely changes on restart, so it needs to be
fixed.

Look for the centreon enty in table `mysql.user` that is limited to `172.17.xx.yy` and
change the host column to read `172.17.%`. `%` obviously works too.
Do the same thing in the `mysql.db` database.

Don't forget to `FLUSH PRIVILEGES;` before retrying.

## Troubleshooting

### NODUtils

It logs to syslog. If you see the following message, you need to increate the kernel parameter `kernel.msgmnb`:

	ndo2db: Warning: Retrying message send. This can occur because you have too few messages
	allowed or too few total bytes allowed in message queues.
	You are currently using 64 of 2002 messages and 65536 of 65536 bytes in the queue.
	See README for kernel tuning options.

Increasing the value on the host seemed like a reasonable thing, like so:

	sysctl -w kernel.msgmnb=655360

65536 was too small in my case. Adding a zero did the trick and may be way too high.
This only works when running the container with `--privileged=true` *and*
running `sysctl -w` as above from *inside* the container.
Running it on the outside yields 16384 inside the container, no matter what you do.
Doesn't make sense? Yeah, doesn't. Sorry.

### Centreon not showing any services or hosts under 'Monitoring'

Check for errors from ndo2db in syslog. See above.

## TODO

* Cron-Jobs are not handled yet (see `/root/nagios/centreon-2.5.2/tmpl/install/*.cron`)

## Contributors

* Philipp Adelt <info@philipp.adelt.net>
* Brian Christner <brian.christner@gmail.com>
