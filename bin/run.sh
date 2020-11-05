#!/bin/sh

bundle exec rake db:create db:migrate
bundle exec rackup -o 0.0.0.0
