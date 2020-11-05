#!/bin/sh

RACK_ENV=test bundle exec rake db:create db:migrate test
