#!/bin/bash
##########################################
#
# Start crucuble_smarrt_app with unicorn.
#
##########################################
echo "Starting the crucible_smart_app with unicorn."
echo "Add rvm to path"
[[ -s "/home/ubuntu/.profile" ]] && source "/home/ubuntu/.profile" # Load the default .profile

[[ -s "/home/ubuntu/.rvm/scripts/rvm" ]] && source "/home/ubuntu/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

APP_NAME="crucible_smart_app"
APP_ROOT=/var/www/$APP_NAME
UNICORN_CONFIG=$APP_ROOT/deployment-files/unicorn.rb
echo "Unicorn config file is " $UNICORN_CONFIG
cd $APP_ROOT || exit 1
echo "Fetch latest form Github"
git pull origin master
echo "bundle install"
bundle install
echo "Start unicorn"
unicorn -c  $UNICORN_CONFIG -D