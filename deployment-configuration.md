Deployment Configuration
========================

This document decribes how to install the software on various platforms.



Ubuntu 16.04 With Nginx and Unicorn Installation (Preferred Method)
===================================================================

This section details how to configure the crucible_smart_app using Nginx 
and Unicorn on Ubuntu 16.

1. Remove Apache2 if already installed. 

    sudo apache2ctl stop
    sudo apt-get remove apache2

2. Setup the crucible_smart_app

    sudo apt-get update
    sudo apt-get install git ruby-bundler ruby-dev
    sudo apt-get install sqlite3 libsqlite3-dev
    sudo apt-get install build-essential patch zlib1g-dev liblzma-dev
    git clone https://github.com/fhir-crucible/crucible_smart_app.git
    cd  crucible_smart_app
    bundle install


3. Install Nginx

    sudo apt-get install nginx

4. Install Unicorn

    sudo gem install unicorn

5. Create some directories Unicorn will need. 

From within the `crucible_smart_app`, execute the following commands.

    mkdir tmp
    mkdir tmp/sockets
    mkdir tmp/pids
    mkdir log

6. Create a Unicorn config file.

Using your favorite text editor, create the file `unicorn.rb`  in the `crucible_smart_app` directory with the following content:


    # set path to app that will be used to configure unicorn,
    # note the trailing slash in this example
    @dir = "/var/www/crucible_smart_app/"

    worker_processes 2
    working_directory @dir

    timeout 30

    # Specify path to socket unicorn listens to,
    # we will use this in our nginx.conf later
    listen "#{@dir}tmp/sockets/unicorn.sock", :backlog => 64

    # Set process id path
    pid "#{@dir}tmp/pids/unicorn.pid"

    # Set log file paths
    stderr_path "#{@dir}log/unicorn.stderr.log"
    stdout_path "#{@dir}log/unicorn.stdout.log"

Be sure and replace the value of `@dir` with your actual path to `crucible_smart_app`.

7. Start Unicorn

Start running Unicorn as a daemon procedss with the following command:

    unicorn -c unicorn.rb -E development -D

You can now test this is working by pointing your browser
 to http://localhost:4567

Note: If you need to stop Unicorn use the following command.

    cat tmp/pids/unicorn.pid | xargs kill -Q

8. Configure Nginix to proxy to Unicorn

Delete the contents of `/etc/nginx/nginx.conf` and replace with the following content.
(Please note to change all paths to `crucilbe_smart_app`, to your actual path.)

	# this sets the user nginx will run as,
	#and the number of worker processes
	user nobody nogroup;
	worker_processes  1;
	#user www-data;
	#worker_processes auto;

	# setup where nginx will log errors to
	# and where the nginx process id resides
	error_log  /var/log/nginx/error.log;
	pid        /var/run/nginx.pid;

	events {
	  worker_connections  1024;
	  # set to on if you have more than 1 worker_processes
	  accept_mutex off;
	}

	http {
	  include       /etc/nginx/mime.types;

	  default_type application/octet-stream;
	  access_log /tmp/nginx.access.log combined;

	  # use the kernel sendfile
	  sendfile        on;
	  # prepend http headers before sendfile()
	  tcp_nopush     on;

	  keepalive_timeout  5;
	  tcp_nodelay        on;

	  gzip  on;
	  gzip_vary on;
	  gzip_min_length 500;

	  gzip_disable "MSIE [1-6]\.(?!.*SV1)";
	  gzip_types text/plain text/xml text/css
	     text/comma-separated-values
	     text/javascript application/x-javascript
	     application/atom+xml image/x-icon;

	  # use the socket we configured in our unicorn.rb
	  upstream unicorn_server {
	    server unix:/var/www/crucible_smart_app/tmp/sockets/unicorn.sock
		fail_timeout=0;
	  }

	  # configure the virtual host
	  server {
	    # replace with your domain name
	    server_name myhost;
	    # replace this with your static Sinatra app files, root + public
	    root /var/www/crucible_smart_app/public;
	    # port to listen for requests on
	    listen 80;
	    # maximum accepted body size of client request
	    client_max_body_size 4G;
	    # the server will close connections after this time
	    keepalive_timeout 5;

	    location / {
	      try_files $uri @app;
	    }

	    location @app {
	      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
	      proxy_set_header Host $http_host;
	      proxy_redirect off;
	      # pass to the upstream unicorn server mentioned above
	      proxy_pass http://localhost:4567;
	    }
	  }
	}

9. Restart Nginx

Execute the following command to restart Nginx to pick up the new configuration.


    sudo service nginx restart


You can test this is working by pointing your browser to http://localhost.

10. Set Hostname (Optional)

If you plan to run the service on a remote server (not locally), then replace the 
value of `server_name` in `/etc/nginx/nginx.conf` with your actual hostname and 
restart Nginx.



Ubuntu 16.04 With Apache2 and Passenger Installation
====================================================

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

Now point a browser to `http://localhost` to test.

That's it!



Local Windows Configuration
===========================


Docker Configuration
====================

