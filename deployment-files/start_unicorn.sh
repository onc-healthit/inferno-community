#!/bin/bash
##########################################
#
# Start crucuble_smarrt_app with unicorn.
#
##########################################
echo "Starting the crucible_smart_app with unicorn."
APP_NAME="crucible_smart_app"
APP_ROOT=/var/www/$APP_NAME
UNICORN_CONFIG=$APP_ROOT/deployment-files/unicorn.rb
echo "Unicorn config file is " $UNICORN_CONFIG
cd $APP_ROOT || exit 1
git pull origin master
bundle install
unicorn -c  $UNICORN_CONFIG -D
