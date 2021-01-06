# Inferno
Inferno is a tool that tests a server's compliance to hl7 specifications. This repo is forked from the original repo located: 
https://github.com/onc-healthit/inferno

This repo has been modified to build the docker image, run the containers, rest the test suite and then output the results into script.log file in the root of this entire repo


## Run the test suite
```
./start.sh <CLIENT_ID> <CLIENT_SECRET> <ACCESS_TOKEN>

```

You must have a valid clientid, clientsecret and accesstoken when running the above command