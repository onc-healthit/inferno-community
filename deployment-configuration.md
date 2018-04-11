Deployment Configuration
========================

This document describes how to install the software on various platforms.

Run on Amazon Web Services EC2 using an Amazon Machine Image (AMI)
------------------------------------------------------------------

An AWS account is required to use AMI version. If you wish to run it locally, you can use Docker, or a number of other configuration options described below.

The latest AMI ID is `ami-b8e539c7`.

After your instance is loaded, the application will be accessible on port 80 (the standard port for HTTP).
Use the following link to jump start your deployment:


https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#LaunchInstanceWizard:ami=ami-b8e539c7


A `t2.micro` sized instance should be sufficient  for sites expecting a low amount of traffic.

It is important to open port `80` for HTTP  and port `22` for SSH if you need to gain shell access to the server.  Instead of clicking the
"Review and Launch" button, click next button until you get to the Security Groups option. Ensure 80 is accessible from anywhere and 22 is
available from an IP range from which you will connect. Below is an example:

![Security Groups Configuration]https://raw.githubusercontent.com/fhir-crucible/crucible_smart_app/master/deployment-files/security-groups.png "Security Groups Configuration")

After this step is done, launch the instance.  Obtain your instance's IP or host name from the AWS console. Point a web browser to the instance using the IP address or host name.


Ubuntu 16.04 With Nginx and Unicorn Installation (Preferred Method)
-------------------------------------------------------------------

This section details how to configure the crucible_smart_app using Nginx 
and Unicorn on Ubuntu 16.

1. Remove Apache2 if already installed.


    `
    sudo apache2ctl stop
    sudo apt-get remove apache2
    `


2. Setup the crucible_smart_app.

TLS connection testing requires Ruby 2.5 or greater. To check to see what version of ruby is installed, type in the following command:

    `
    ruby --version
    `

If you are not running version Ruby 2.5, you can install it using Ruby Version Manager (rvm) by issuing the following commands.

    `
    sudo apt-get install libgdbm-dev libncurses5-dev automake libtool bison libffi-dev
    gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
    curl -sSL https://get.rvm.io | bash -s stable
    source ~/.rvm/scripts/rvm
    rvm install 2.5.1
    rvm use 2.5.1 --default
    ruby -v
    gem install bundle
    `


Now, issue the following commands to setup the crucible smart app.

     `
     sudo apt-get update
     sudo apt-get install git ruby-bundler ruby-dev
     sudo apt-get install sqlite3 libsqlite3-dev
     sudo apt-get install build-essential patch zlib1g-dev liblzma-dev
     git clone https://github.com/fhir-crucible/crucible_smart_app.git
     cd  crucible_smart_app
     bundle install
     `


3. Install Nginx

Install NGINX with apt-get

    `
    sudo apt-get install nginx
    `

4. Install Unicorn

Install unicorn with gem

    `
    sudo gem install unicorn
    `

5. Create some directories Unicorn will need. 

From within the `crucible_smart_app`, execute the following commands.

    `
    mkdir tmp
    mkdir tmp/sockets
    mkdir tmp/pids
    mkdir log
    `


7. Start Unicorn

Start running Unicorn as a daemon procedss with the following command:

    `
    unicorn -c deployment-files/unicorn.rb -E development -D
    `

You can now test this is working by pointing your browser
 to http://localhost:4567

Note: If you need to stop Unicorn use the following command.

    `
    cat tmp/pids/unicorn.pid | xargs kill -QUIT
    `

8. Configure Nginix to proxy to Unicorn

Delete the contents of `/etc/nginx/nginx.conf` and replace with the content
found in deployment-files/nginx.conf.
(Please note to change all paths to `crucilbe_smart_app`, to your actual path.)

9. Restart Nginx

Execute the following command to restart Nginx to pick up the new configuration.

    `
    sudo service nginx restart
    `


You can test this is working by pointing your browser to http://localhost.


11. Ensure unicorn starts on boot with Supervisor (Optional)

Install supervisor.

    `
    sudo apt-get install supervisor
    `

Create the file `/etc/supervisor/conf.d/unicorn.conf` with 
the content of the file `deployment-files/unicorn.conf`.
This calls the bash script `deployment-files/start_unicorn.sh`.


Now tell supervisor about the new item.

    `
    sudo supervisorctl reread
    sudo supervisorctl update
    `

To start unicorn with Supervisor use the following command.

    `
    sudo supervisorctl start unicorn
    `


12. Set Hostname (Optional)

If you plan to run the service on a remote server (not locally), then replace the 
value of `server_name` in `/etc/nginx/nginx.conf` with your actual hostname and 
restart Nginx.





Ubuntu 16.04 With Apache2 and Passenger Installation
----------------------------------------------------

This section describes how to setup the tool using Apache2 using Passenger.

    `  
    sudo apt-get update
    sudo apt-get install apache2 git ruby-bundler ruby-dev
    sudo apt-get install sqlite3 libsqlite3-dev
    sudo apt-get install build-essential patch zlib1g-dev liblzma-dev
    git clone https://github.com/fhir-crucible/crucible_smart_app.git
    cd  crucible_smart_app
    bundle install
    `

Next We will install Passenger

    `
    sudo apt-get install -y dirmngr gnupg
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
    sudo apt-get install -y apt-transport-https ca-certificates
    sudo sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger xenial main > /etc/apt/sources.list.d/passenger.list'
    sudo apt-get update
    sudo apt-get install -y libapache2-mod-passenger
    sudo a2enmod passenger
    sudo apache2ctl restart
    `

Verify the Passenger Install:

    `
    sudo /usr/bin/passenger-config validate-install
    sudo /usr/sbin/passenger-memory-stats
    `

Modify the Apache configuration file.

    `
    sudo nano /etc/apache2/sites-available/000-default.conf
    `

You can use any text editor you like.  Update the `DocumentRoot` 
and `Directory` sections like seen below. Make sure the path you set
matches your actual path.  If you plan to host this non locally,
then update the `Servername` to match that of your DNS setting.

     `
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
     `

Now all that is left to do is to restart Apache2.

    `
    sudo apache2ctl restart
    `

Now point a browser to `http://localhost` to test.

That's it!



Local Windows Configuration
---------------------------

Use Docker to run the application on Windows.


Docker Configuration
--------------------

1. Install Docker for Windows.
2. Download the crucuble_smart_app to your local computer on a directory of your choice.
3. Open a terminal Window and navigate to the crucuble_smart_app folder.
4. Run the command `docker-compose up` to configure and run the container.
5. Navigate to http://localhost:8080 to find the running application.

Note: If you run into issues in the above instructions, you _may_ need to `docker-compose up -- build` to rebuild the containers.