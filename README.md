# Inferno

This application creates test clients that exercise the range of requirements of a
[SMART on FHIR](http://smarthealthit.org/smart-on-fhir/) server. These clients have tests for the
[SMART App Launch Framework](http://www.hl7.org/fhir/smart-app-launch/), [Argonaut](http://hl7.org/fhir/DSTU2/argonaut/argonaut.html)
Implementation Guides, and [FHIR DSTU2](http://hl7.org/fhir/DSTU2/index.html).

## System Requirements

* [Ruby 2.5+](https://www.ruby-lang.org/en/)
* [Ruby Bundler](http://bundler.io/)
* [SQLite](https://www.sqlite.org/)

## Installation and Running

### Local Installation

The *Inferno SMART on FHIR Test App* can installed and run locally on your machine.  Install the dependencies
listed above and enter the following in a terminal prompt:

```sh
# MacOS or Linux
git clone https://github.com/siteadmin/inferno
cd inferno
bundle install
bundle exec ruby app.rb
```

*Inferno SMART on FHIR Test App* can then be accessed at http://localhost:4567 in a web browser.

### Docker Installation

Docker is the recommended installation method for Windows devices and can also be used on Linux and MacOS hosts.

1. Install Docker for the host platform as well as the docker-compose tool (which may be included in the distribution, as is the case for Windows and MacOS).
2. Download the `inferno` project to your local computer on a directory of your choice.
3. Open a terminal in the directory where the project was downloaded (above).
4. Run the command `docker-compose up` to start the server. This will automatically build the Docker image with the correct ruby version and launch both the ruby server (using unicorn) and an NGINX server to front it all.
5. Navigate to http://localhost:8080 to find the running application.

If the docker image gets out of sync with the underlying system, such as when new dependencies are added to the application, you need to run `docker-compose up -- build` to rebuild the containers.

### Remote Deployment

The *Inferno SMART on FHIR Test App* can also be deployed onto a server to test many different
instances of the FHIR Servers by multiple users.  Test results are kept private at a unique, unguessable URI that can
be saved for future reference or shared.

Deployment on a remote server can be done by using a modified form of the Docker containers provided (see above) or by direct installation on the remote host.

Please see the file [deployment-configuration.md](https://github.com/siteadmin/inferno/blob/master/deployment-configuration.md) for details.

## Unit Tests

The *Inferno SMART on FHIR Test App* contains a robust set of self-tests to ensure that the
test clients conform to the specification and performs as intended.  To run these tests, execute the following
command:

```sh
bundle exec rake
```

## Basic Usage Instructions

Open the application in the browser (http://localhost:4567 by default for local installations).  Provide the DSTU2
FHIR endpoint to be tested in the prompt and click the `Begin` button.

The application is organized into a series of test sequences, each which perform a set of actions against a FHIR
server and related security services.  These actions contain tests to ensure that the server is responding to client requests
as expected.  They also may collect information about the server for use in later sequences, such a list of FHIR Resources
supported by the FHIR server.  Some sequences also perform actions that may be required for later tests, such as
authorizing the client to access protected resources in accordance with SMART on FHIR.

Several test sequences will be displayed on screen. The user will be given the option to begin or skip these test sequences, and the results of running these tests will be displayed after a sequence runs. Certain later test sequences can only be run after information is collected from earlier sequences, or after skipping an earlier test sequence and manually providing the application with this information.

### Example

For the purpose of example, testing of the DSTU2 FHIR server of the SMART Sandbox will be described.

1) Create an account at https://sandbox.hspconsortium.org/#/start

2) Create a new DSTU 2 Sandbox. 

3) Open the Inferno SMART on FHIR Test App, and enter the SMART DSTU2 FHIR endpoint, which can be found under Settings, into the prompt on the front page. Click Begin. A new testing instance is created that saves results of tests and associated client state.

4) To start testing, run the `Conformance Statement Sequence` , which queries the FHIR server for capabilities supported
by the FHIR server and related authorization services.  This sequence will gather information about the server, as well as check to make sure all responses from the server conform to the appropriate specifications.  Tests are results are listed below the sequence.  Specifics about why tests failed, or what requests were made during the excution of the test, can be accessed by clicking on the test.

5) The `Dynamic Registration Sequence` can be run by entering the correct registration URL, client name, and scopes necessary. Default values will already be provided. If this sequence is skipped, the user is required to manually enter their client ID. In the case of the SMART Sandbox, this client ID will be provided upon registering an application. The launch URL and redirect URL necessary to register an app will be provided upon trying to skip dynamic registration.

6) After registering the application with the server, the user can run the `Standalone Launch Sequence` and/or the `EHR Launch Sequence`. The `Standalone Launch Sequence` can be initiated from the application and the user will be redirected back to the application after the necessary steps are followed. The `EHR Launch Sequence` will require the user to launch the application from the EHR, which, for the SMART Sandbox, can be done from within the registered app details. Note: Because of the nature of the SMART Sandbox, it is not possible to run the EHR Launch Sequence against it if the app was dynamically registered.

7) After at least one successful launch, the remaining test sequences can be run. Any sequence can be rerun after completion.

## Inspecting and Exporting Tests

Tests are written to be easily understood, even by those who aren't familiar with Ruby.  They can be
viewed directly [in this repository](https://github.com/siteadmin/inferno/tree/master/lib/sequences).

Tests contain metadata that provide additional details and traceability to standards.  The active tests and related metadata
can be exported into CSV format and saved to a file named `testlist.csv` iwith the following command:

```sh
bundle exec rake tests_to_csv
```

Arguments can be provided to the task in order to export a specific set of tests or to specify the output file.

The currently supported groups of tests are `all`, `active` or `inactive`.  For example:

```sh
bundle exec rake tests_to_csv[all,all_tests.csv]
```
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
