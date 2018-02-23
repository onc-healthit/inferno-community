# Crucible SMART on FHIR Test App

This application creates test clients that exercise the range of requirements of a [SMART on FHIR](http://smarthealthit.org/smart-on-fhir/) server. These tests focus on the [SMART App Launch Framework](http://www.hl7.org/fhir/smart-app-launch/), [Argonaut](http://hl7.org/fhir/DSTU2/argonaut/argonaut.html) Implementation Guides, and [FHIR DSTU2](http://hl7.org/fhir/DSTU2/index.html).

## Setup

To run the Crucible SMART on FHIR Test App locally on your machine, follow the steps below.
```
git clone https://github.com/fhir-crucible/crucible_smart_app.git
bundle install
bundle exec ruby app.rb
```
By default, the application will be listening on localhost:4567.

## Usage

Enter the endpoint of the DSTU2 FHIR server to test into the application.

Several test sequences will be displayed on screen. The user will be given the option to begin or skip these test sequences, and the results of running these tests will be displayed after a sequence runs. Certain later test sequences can only be run after information is collected from earlier sequences, or after skipping an earlier test sequence and manually providing the application with this information.

### Example

For the purpose of example, testing of the DSTU2 FHIR server of the [SMART Sandbox](https://sandbox.smarthealthit.org/smartdstu2) will be described.

Beginning the Conformance Statement Sequence will provide the application with the OAuth endpoints necessary to run the Dynamic Registration Sequence.

The Dynamic Registration Sequence can be run by entering the correct registration URL, client name, and scopes necessary. Default values will already be provided. If this sequence is skipped, the user is required to manually enter their client ID. In the case of the SMART Sandbox, this client ID will be provided upon registering an application. The launch URL and redirect URL necessary to register an app will be provided upon trying to skip dynamic registration.

After registering the application with the server, the user can run the Standalone Launch Sequence and/or the EHR Launch Sequence. The Standalone Launch Sequence can be initiated from the application and the user will be redirected back to the application after the necessary steps are followed. The EHR Launch Sequence will require the user to launch the application from the EHR, which, for the SMART Sandbox, can be done from within the registered app details. Note: Because of the nature of the SMART Sandbox, it is not possible to run the EHR Launch Sequence against it if the app was dynamically registered.

After at least one successful launch, the remaining test sequences can be run. Any sequence can be rerun after completion.

## License

Copyright 2017 The MITRE Corporation

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
