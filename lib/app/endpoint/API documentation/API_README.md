# Inferno's JSON API

## Overview
A RESTful JSON API was created for Inferno to allow for automated testing and an option for a new front end. 

### Sections

* Overview
* FHIR API
* RESTful API
* Documentation
* Testing
* Other Notes

## FHIR API
The first prototype API created was FHIR conformant, and its conformance was tested using Crucible. By conforming to the FHIR standard, the API concepts differed from Inferno’s usual user interface because of the different mappings. Inferno’s sequences were chosen to be represented by the FHIR resource TestScript, and Inferno’s test results were represented by the FHIR resource TestReport. This caused the FHIR API to not work well with Inferno, so this design was left and a new one was created. 

Files:
* `fhir.rb`: Request endpoints
* `fhir_definitions.rb`: Builds JSONs for API
* `fhir_api_test`: Unit tests

Documentation: 
* [FHIR API Summary.docx](https://github.com/onc-healthit/inferno/files/3482177/FHIR.API.Summary.docx)
* [FHIR API Requests.docx](https://github.com/onc-healthit/inferno/files/3482178/FHIR.API.Requests.docx)
* [Inferno FHIR API.postman_collection.json.zip](https://github.com/onc-healthit/inferno/files/3482659/Inferno.FHIR.API.postman_collection.json.zip)

The FHIR API can probably be discarded and then these files will no longer be needed. 

## RESTful API
The API’s mappings were designed be as close to Inferno concepts as possible in order to allow Inferno to be fully functional as an API. To my knowledge, except for the restrictions mentioned, the API has all of Inferno's capabilities. 

Files: 
* `api.rb`: Request endpoints
* `api_helper.rb`: Helper functions for requests that get information from Inferno
* `api_json.rb`: Builds JSONs for API
* `api_test.rb`:  Unit tests

### Restrictions
* Some requests require some unnecessary information in order to keep a consistent request structure but are not actually needed to perform the request in Inferno
  * ex. Sequences are always accessed by group and then by the sequence name, even though finding the group name is unnecessary, only makes it easier to search through Inferno
  * ex. When a result is accessed through its instance using its ID, Inferno only needs the ID to retrieve the result

### Next Steps
1. Separate the web application user interface from the functionality of the executing tests endpoints
    * Inferno's endpoints for running tests return ERB pages, which we want to remove for API use
    * Test groups/test sets do not exist in the API because they can't use the usual endpoints
      * Sequences are run individually, group is faked run as a test group (test groups are manually named, see comments in code for details)
      * Faking it works except for problem #2 below, so that's why executing tests needs to change
1. OAuth tests can't be executed
    * ex. Standalone Patient Launch, EHR Launch
    * API can't currently handle "waiting" and redirecting back to Inferno 
    * Tests return error or fail statuses 
    * Can't use the current executing endpoints because of problem #1, they need to be separated from the front end
    * Need to design some sort of way to give a status back to the client for the redirect tests to tell them what to do next, and then how to pick it back up in Inferno
1. Flush out streaming with NDJSON
    * Currently, a group or a sequence can be executed either with or without streaming
    * The streaming generally works (see section on testing), but needs to be tested in more depth
      * ex. The stream can close without warning if the requests take too long from the FHIR server, so now the API just stops instead of returning an error message or reopening the stream
    * These endpoints will have to be rewritten anyway in the final version once problems #1 and #2 are fixed. 

## Documentation
There is documentation written for the RESTful API in the `API Documentation` folder. The code is also commented with some more specific details than the topics covered in this document. 

Files: 
* `api.yaml`: Documentation in the OpenAPI format
* `API_README.md`: Explains the current state of the API

## Testing

### Testing with Postman
[Inferno API.postman_collection.json.zip](https://github.com/onc-healthit/inferno/files/3482666/Inferno.API.postman_collection.json.zip)

### Inferno Unit Tests
* Unit tests were written for the RESTful API in `api_test.rb`
* Currently the unit tests have about 80% code coverage because some testing is not allowed the way the unit tests are configured
  * HTTP requests are not allowed in the testing mode, and Inferno contains only one test (Manual App Registration) that does not perform HTTP requests
* All unit tests are written, but some tests are commented out, see file comments for more details
  * ex. Executing a group, executing with streaming, and getting requests information from a result are not included in the unit tests

### Sample Front End
* A example front end was written in JavaScript and HTML to test the API and demonstrate that it has the same capabilities as Inferno's current front end (minus the restrictions mentioned above)
* Front end is not meant to be pretty or reusable in the future, just a proof of concept and example
  * Functionality and concepts should be the same as Inferno
  * It uses almost all of the requests in the API
* The API sample front end can be accessed at [http://localhost:4567/landing](http://localhost:4567/landing)
  * This front end was put into the landing endpoint ERB because it was empty and already linked to Inferno's headers, a real new front end should be located in a new HTML file
* Known bugs that never got finished 
  * Sometimes the page is loaded incorrectly, and needs a hard refresh (or two) to reset
  * The "loading" modal that shows up while the tests are running doesn't automatically hide like it's supposed to on the OAuth tests
  * The HTML uses sequence names as IDs but sequence names aren't unique, their ID should also include the group name to distinguish because now those duplicates are not updated properly 
* Files: 
  * `api.js`: JavaScript for API
  * `landing.erb`: HTML for page using API
  * `can-ndjson-stream.js`: Module used for streaming in `api.js`
    * [Canjs NDJSON Stream Documentation](https://canjs.com/doc/can-ndjson-stream.html)
    * [NDJSON Stream Github](https://github.com/canjs/can-ndjson-stream)

Front End Preview: 
<img width="300" alt="Screen Shot 2019-08-08 at 10 12 00 AM" src="https://user-images.githubusercontent.com/47094547/62710464-5955c580-b9c5-11e9-97d8-b16cf201c833.png"> <img width="300" alt="Screen Shot 2019-08-08 at 10 12 13 AM" src="https://user-images.githubusercontent.com/47094547/62710477-5c50b600-b9c5-11e9-9c0f-d014a003bb19.png">

## Other Notes
Other files that were edited: 
* `.rubocop_todo.yml`: Updated to pass rubocop tests for length issues
* `endpoint.rb`: Added references to the FHIR and regular API files
* `sequence_base.rb`: Saves the results during the start function to make sure that all the counts are updated and saved in the database (ex. count of tests passed) after a sequence is run
* `.codeclimate.yml`: Updated to ignore imported JS files, but not the ones we wrote