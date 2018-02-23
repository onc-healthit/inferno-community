# Crucible SMART on FHIR Test App

This application creates test clients that exercise the range of requirements of a [SMART on FHIR]
(http://smarthealthit.org/smart-on-fhir/) server. These clients have tests for the [SMART App Launch Framework]
(http://www.hl7.org/fhir/smart-app-launch/), [Argonaut](http://hl7.org/fhir/DSTU2/argonaut/argonaut.html)
Implementation Guides, and [FHIR DSTU2](http://hl7.org/fhir/DSTU2/index.html).

## System Requirements

* [Ruby 2.2+](https://www.ruby-lang.org/en/)
* [Ruby Bundler](http://bundler.io/)
* [SQLite](https://www.sqlite.org/)

## Local Installation

The *Crucible SMART on FHIR Test App* can installed and run locally on your machine.  Install the dependencies 
listed above and enter the following in a terminal prompt:

```sh
# MacOS or Linux
git clone https://github.com/fhir-crucible/crucible_smart_app.git
bundle install
bundle exec ruby app.rb
```

*Crucible SMART on FHIR Test App* can then be accessed at http://localhost:4567 in a web browser.

## Remote Deployment

The *Crucible SMART on FHIR Test App* can also be remotely deployed onto a server to test many different
instances of the FHIR Servers.

* [Deployment Instructions](deployment-configuration.md)

## Unit Tests

The *Crucible SMART on FHIR Test App* contains a robust set of self-tests to ensure that the 
test clients conform to the specification and performs as intended.  To run these tests, execute the following
command:

```sh
bundle exec rake
```

## Basic Usage Instructions

Open the application in the browser (http://localhost:3456 by default for local installations).  Provide the DSTU2
FHIR endpoint to be tested in the prompt and click the `Begin` button.

The application is organized into a series of test sequences, each which perform a set of actions against a FHIR
server and related security services.  These actions contain tests to ensure that the server is responding to client requests
as expected.  They also may collect information about the server for use in later sequences, such a list of FHIR Resources
supported by the FHIR server.  Some sequences also perform actions that may be required for later tests, such as 
authorizing the client to access protected resources in accordance with SMART on FHIR.

Several test sequences will be displayed on screen. The user will be given the option to begin or skip these test sequences, and the results of running these tests will be displayed after a sequence runs. Certain later test sequences can only be run after information is collected from earlier sequences, or after skipping an earlier test sequence and manually providing the application with this information.

### Example

For the purpose of example, testing of the DSTU2 FHIR server of the
[SMART Sandbox](http://docs.smarthealthit.org/sandbox/) will be described.

1) Create an account at https://sandbox.smarthealthit.org/smartdstu2

2) Open the *Crucible SMART on FHIR Test App*, and enter the SMART DSTU2 FHIR endpoint https://sb-fhir-dstu2.smarthealthit.org/api/smartdstu2/data into the prompt on the front page.  Click `Begin`.  A new testing instance
is created that saves results of tests and associated client state.

3) To start testing, run the `Conformance Statement Sequence` , which queries the FHIR server for capabilities supported
by the FHIR server and related authorization services.  This sequence will gather information about the server, as well as check to make sure all responses from the server conform to the appropriate specifications.  Tests are results are listed below the sequence.  Specifics about why tests failed, or what requests were made during the excution of the test, can be accessed by clicking on the test.

4) The Dynamic Registration Sequence can be run by entering the correct registration URL, client name, and scopes necessary. Default values will already be provided. If this sequence is skipped, the user is required to manually enter their client ID. In the case of the SMART Sandbox, this client ID will be provided upon registering an application. The launch URL and redirect URL necessary to register an app will be provided upon trying to skip dynamic registration.

5) After registering the application with the server, the user can run the Standalone Launch Sequence and/or the EHR Launch Sequence. The Standalone Launch Sequence can be initiated from the application and the user will be redirected back to the application after the necessary steps are followed. The EHR Launch Sequence will require the user to launch the application from the EHR, which, for the SMART Sandbox, can be done from within the registered app details. Note: Because of the nature of the SMART Sandbox, it is not possible to run the EHR Launch Sequence against it if the app was dynamically registered.

6) After at least one successful launch, the remaining test sequences can be run. Any sequence can be rerun after completion.

## License

Copyright 2018 The MITRE Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
```
http://www.apache.org/licenses/LICENSE-2.0
```
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
