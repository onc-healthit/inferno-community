<img src="https://raw.githubusercontent.com/onc-healthit/inferno/master/public/images/inferno_logo.png" width="300px" />

[![Build Status](https://travis-ci.org/onc-healthit/inferno.svg?branch=master)](https://travis-ci.org/onc-healthit/inferno)

Inferno is an open source tool that tests whether patients can access their health data through a standard interface.
It makes HTTP(S) requests to test your server's conformance to authentication, authorization, and FHIR content standards and reports the results back to you.

This application creates test clients that exercise the range of requirements of a [SMART on FHIR](http://smarthealthit.org/smart-on-fhir/) server. These clients have tests for the [SMART App Launch Framework](http://www.hl7.org/fhir/smart-app-launch/), [Argonaut](http://hl7.org/fhir/DSTU2/argonaut/argonaut.html) Implementation Guides, and [FHIR DSTU2](http://hl7.org/fhir/DSTU2/index.html).

## Using Inferno

If you are new to FHIR or SMART-on-FHIR, you may want to review the [Inferno Quick Start Guide](https://github.com/onc-healthit/inferno/wiki/Quick-Start-Guide).

## Installation and Deployment

### Docker Installation

Docker is the recommended installation method for Windows devices and can also be used on Linux and MacOS hosts.

1. Install [Docker](https://www.docker.com/) for the host platform as well as the [docker-compose](https://docs.docker.com/compose/install/) tool (which may be included in the distribution, as is the case for Windows and MacOS).
2. Download the [latest release of the `inferno` project](https://github.com/onc-healthit/inferno/releases) to your local computer on a directory of your choice.
3. Open a terminal in the directory where the project was downloaded (above).
4. Run the command `docker-compose up` to start the server. This will automatically build the Docker image and launch both the ruby server (using unicorn) and an NGINX web server.
5. Navigate to http://localhost:4567 to find the running application.

If the docker image gets out of sync with the underlying system, such as when new dependencies are added to the application, you need to run `docker-compose up --build` to rebuild the containers.

Check out the [Troubleshooting Documentation](https://github.com/onc-healthit/inferno/wiki/Troubleshooting) for help.

### Native Installation

Inferno can installed and run locally on your machine.  Install the following dependencies first:

* [Ruby 2.5+](https://www.ruby-lang.org/en/)
* [Ruby Bundler](http://bundler.io/)
* [SQLite](https://www.sqlite.org/)

And run the following commands from the terminal:

```sh
# MacOS or Linux
git clone https://github.com/onc-healthit/inferno
cd inferno
bundle install
bundle exec rake db:create db:schema:load
bundle exec rackup
```

Inferno can then be accessed at http://localhost:4567 in a web browser.

If you would like to use a different port it can be specified when calling `rackup`.  For example, the following command would host Inferno on port 3000:

```sh
rackup -p 3000
```

### Remote Deployment

Inferno can also be deployed onto a server to test many different instances of the FHIR Servers by multiple users.  Test results are kept private at a unique, unguessable URI that can be saved for future reference or shared.

Deployment on a remote server can be done by using a modified form of the Docker containers provided (see above) or by direct installation on the remote host.

Please see the file [deployment-configuration.md](https://github.com/onc-healthit/inferno/blob/master/deployment-configuration.md) for details.

#### Upgrading Inferno

If an Inferno update makes changes to the database schema, migrations will have
to be run when updating. Run migrations with:

```sh
bundle exec rake db:migrate
```

The above will migrate the development database. To migrate a production or test
database, use:

```sh
RACK_ENV=production bundle exec rake db:migrate
RACK_ENV=test bundle exec rake db:migrate
```

If you are using the provided inferno docker image, migrations will be run
automatically.

### Reference Implementation

While it is recommended that users install Inferno locally, a reference implementation of Inferno is hosted at https://inferno.healthit.gov

Users that would like to try out Inferno before installing locally can use that reference implementation, but should be forewarned that the database will be periodically refreshed and there is no guarantee that previous test runs will be available in perpetuity.

## Supported Browsers

Inferno has been tested on the latest versions of Chrome, Firefox, Safari, and Edge.  Internet Explorer is not supported at this time.

## Unit Tests

Inferno contains a robust set of self-tests to ensure that the test clients conform to the specification and performs as intended.  To run these tests, execute the following command:

```sh
RACK_ENV=test bundle exec rake db:create db:schema:load
bundle exec rake test
```

## Inspecting and Exporting Tests

Tests are written to be easily understood, even by those who aren't familiar with Ruby.  They can be
viewed directly [in this repository](https://github.com/onc-healthit/inferno/tree/master/lib/app/modules).

Tests contain metadata that provide additional details and traceability to standards.  The active tests and related metadata can be exported into CSV format and saved to a file named `testlist.csv` with the following command:

```sh
bundle exec rake inferno:tests_to_csv
```

Arguments can be provided to the task in order to export a specific set of tests or to specify the output file.

```sh
bundle exec rake inferno:tests_to_csv[onc,all_tests.csv]
```

To just choose the module and use the default groups and filename:

```sh
bundle exec rake inferno:tests_to_csv[onc]

```

## Running Tests from the Command Line
Inferno provides two methods of running tests via the command line: by directly providing the sequences or running automated scripts

_Note: This feature is still in development and we are looking for feedback on features and improvements in ways it can be used_

### Running Tests Directly

Testing sequences can be run from the command line via a rake task which takes the sequence (or sequences) to be run and server url as arguments:
```sh
bundle exec rake inferno:execute[https://my-server.org/data,onc,ArgonautConformance]
```

### Running Automated Command Line Interface Scripts
For more complicated testing where passing arguments is unwieldy, Inferno provides the ability to use a script containing parameters to drive test execution.
The provided `example_script.json` shows an example of this script and how it can be used.  The `execute_batch` task runs the script:

```sh
bundle exec rake inferno:execute_batch[script.json]
```

Inferno also provides a  `generate_script` rake task which prompts the user for a series of inputs which are then used to generate a script.
The user is expected to provide a url for the FHIR Server to be tested and the module name from which sequences will be pulled.
```sh
bundle exec rake inferno:generate_script[https://my-server.org/data,onc]
```

### Caveats
* For `DynamicRegistration` users must provide instructions similar to that provided in `example_script.json` to automate the webdriver.
* The `confidential_client` field is a boolean and must be provided as `true` or `false`

## Using with Continuous Integration Systems
Instructions and examples are available in the [Continuous Integration Section of the Wiki](https://github.com/onc-healthit/inferno/wiki/Using-with-Continuous-Integration-Systems).

## Contact Us
The Inferno development team can be reached by email at inferno@groups.mitre.org.  Inferno also has a dedicated [HL7 FHIR chat channel](https://chat.fhir.org/#narrow/stream/153-inferno).

## License

Copyright 2019 The MITRE Corporation

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
```
http://www.apache.org/licenses/LICENSE-2.0
```
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
