# Summary
Inferno is a tool that tests a server's compliance to hl7 specifications. This repo is forked from the original repo located: 
https://github.com/onc-healthit/inferno

This repo has been modified to build the docker image, run the containers, rest the test suite and then output the results into script.log file in the root of this entire repo


## Run the test suite (currently only configured for dev environment)

```
// obtain clientId, clientSecret and accessToken information from the command below
1upapi --stage dev -l devuser --app SANDBOX token -u USCDI
```

```
// run the entire suite using the information obtained above
./start.sh <CLIENT_ID> <CLIENT_SECRET> <ACCESS_TOKEN>
```

You must have a valid clientid, clientsecret and accesstoken when running the above command. 

## How it works
When the bash script runs, it will call make-script.js. This .js file will create a json file specifying the endpoint, setting the clientId, clientSecret, accesToken as well as specifying all of the tests that we want to run. make-script.js is currently only configured for our dev environment with a specific patient (Abigail with patientId=abde0edecb6a) that is loaded under the USCDI user. NOTE: This script is currently only configured for our dev environment