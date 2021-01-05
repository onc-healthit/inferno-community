#!/bin/zsh --rcs

clientId=$1
clientSecret=$2
accessToken=$3

echo "You have input the following: client_id=$1 client_secret=$2 access_token=$3" &&

node make-script.js $1 $2 $3

cd ../
docker-compose build &&
docker-compose up --detach

sleep 10

docker exec -it inferno_ruby_server_1 /bin/bash -c "bundle exec rake inferno:execute_batch[bin/script.json] | tee bin/script.log" &&
docker cp inferno_ruby_server_1:./var/www/inferno/bin/script.log . &&

passed=$(grep -o "✓ pass" script.log | wc -l)
failed=$(grep -o "X fail" script.log | wc -l)
skipped=$(grep -o "* skip" script.log | wc -l)

echo "************************************************************\n"
echo "Individual Test Results:"
echo "\e[32m$passed \e[39mpassed, \e[0;31m$failed \e[39mfailed, \e[33m$skipped \e[39mskipped/errored\n"
echo "************************************************************\n"

exit;
