Deployment Configuration
========================

This document decribes how to install the software on various platforms.

Ubuntu 16.04 LTS
================

This section describes how to setup the tool using Apache2 using Passenger.


    sudo apt-get update
    sudo apt-get install apache2 git ruby-bundler ruby-dev
    sudo apt-get install sqlite3 libsqlite3-dev
    sudo apt-get install build-essential patch zlib1g-dev liblzma-dev
    git clone https://github.com/fhir-crucible/crucible_smart_app.git
    cd  crucible_smart_app
    bundle install

Next We will install Passenger

    sudo apt-get install -y dirmngr gnupg
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
    sudo apt-get install -y apt-transport-https ca-certificates
    sudo sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger xenial main > /etc/apt/sources.list.d/passenger.list'
    sudo apt-get update
    sudo apt-get install -y libapache2-mod-passenger
    sudo a2enmod passenger
    sudo apache2ctl restart
    
Verify the Passenger Install:

    sudo /usr/bin/passenger-config validate-install
    sudo /usr/sbin/passenger-memory-stats

Modify the Apache configuration file.

    sudo nano /etc/apache2/sites-available/000-default.conf

You can use any text editor you like.  Update the `DocumentRoot` 
and `Directory` sections like seen below. Make sure the path you set
matches your actual path.  If you plan to host this non locally,
then update the `Servername` to match that of your DNS setting.

    <VirtualHost *:80>
	# The ServerName directive sets the request scheme, hostname and port that
	# the server uses to identify itself. This is used when creating
	# redirection URLs. In the context of virtual hosts, the ServerName
	# specifies what hostname must appear in the request's Host: header to
	# match this virtual host. For the default virtual host (this file) this
	# value is not decisive as it is used as a last resort host regardless.
	# However, you must set it for any further virtual host explicitly.
	ServerName localhost

	ServerAdmin webmaster@localhost
	DocumentRoot /home/parallels/crucible_smart_app/public


    <Directory /home/parallels/crucible_smart_app/public >
        Require all granted
        Allow from all
        Options -MultiViews
    </Directory>

	# Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
	# error, crit, alert, emerg.
	# It is also possible to configure the loglevel for particular
	# modules, e.g.
	#LogLevel info ssl:warn

	ErrorLog ${APACHE_LOG_DIR}/error.log
	CustomLog ${APACHE_LOG_DIR}/access.log combined

	# For most configuration files from conf-available/, which are
	# enabled or disabled at a global level, it is possible to
	# include a line for only one particular virtual host. For example the
	# following line enables the CGI configuration for this host only
	# after it has been globally disabled with "a2disconf".
	#Include conf-available/serve-cgi-bin.conf
    </VirtualHost>


Now all that is left to do is to restart Apache2.


    sudo apache2ctl restart

Now point a browser to `http://localhost`

That's it!


Docker Configuration
====================
