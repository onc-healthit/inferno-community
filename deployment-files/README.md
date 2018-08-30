Deployment Files
================

Heere are some handy files for deploying this application on a production server.

* start_unicirn.sh - A bash script that starts Inferno using unicorn.

* unicorn.rb - A unicorn configuration file.

* nginix.conf - This file replaces the default  `/etc/nginx/nginx.conf` file.  
It instructs nginix to proxy the content to unicorn.
