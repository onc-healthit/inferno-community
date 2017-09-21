NOTE: This Crucible SMART App has been deprecated. All of its functionality has been moved into the main Rails application for Crucible.

# Crucible SMART App
Crucible SMART App is a [SMART-on-FHIR App](http://smarthealthit.org/smart-on-fhir/) that executes a series of tests against an HL7&reg; FHIR&reg; Server.

These tests focus on [FHIR DSTU2](http://hl7.org/fhir/DSTU2/index.html) and in particular the [DAF Implementation Guide](http://hl7.org/fhir/DSTU2/daf/daf.html) and [Argonauts](http://hl7.org/fhir/DSTU2/argonaut/argonaut.html) Use-Cases.

## Setup
```
git clone https://github.com/fhir-crucible/crucible_smart_app.git
bundle install
bundle exec ruby app.rb
```

### Configuring Client ID and Scopes (required)
OAuth2 client IDs and scopes for different FHIR servers can be stored in the
`config.yml` file, so the deployed app can be used with multiple FHIR server
implementations.

Each entry under `client_id` and `scopes` should be a unique substring within
the FHIR server URL (for example, `cerner` or `epic`), with the value being the
associated client ID to use or OAuth2 scopes to request.

### Configuring Terminology (optional)
The app can optionally use terminology data. To configure the
terminology data, follow these [instructions](https://github.com/fhir-crucible/fhir_scorecard#optional-terminology-support).

### Deploying to AWS Elastic Beanstalk (optional)
Install the AWS Elastic Beanstalk Command Line Interface.
For example, on Mac OS X:
```
brew install awsebcli
```
Build and deploy the app:
```
bundle install
eb init
eb create crucible-smart-app-dev --sample
eb deploy
```

### Launching the App
- Using Cerner Millenium
  1. Create an account on [code.cerner.com](https://code.cerner.com)
  - Register a "New App"
    - Launch URI: `[deployed endpoint]/launch`
    - Redirect URI: `[deployed endpoint]/app`
    - App Type: `Provider`
    - FHIR Spec: `dstu2_patient`
    - Authorized: `Yes`
    - Scopes: _select all the Patient Scopes_
  - Select your App under "My Apps"
  - Follow the directions and "Begin Testing"
- Using Epic
  1. Create an account on [open.epic.com](https://open.epic.com).
  - Navigate to the [Launchpad](https://open.epic.com/Launchpad/Oauth2Sso).
  - Enter the details:
    - Launch URL: `[deployed endpoint]/launch`
    - Redirect URL: `[deployed endpoint]/app`
  - Click "Launch App"

Errors encountered during launch are probably associated with improper
configuration of the client ID and scopes.

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
