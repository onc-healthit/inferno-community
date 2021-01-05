'use strict';

const fs = require('fs');

const {
  ONEUPHEALTH_FHIR_SERVER_URL
} = process.env;

const clientId = process.argv[2];
const clientSecret = process.argv[3];
const accessToken = process.argv[4]

const write = {
  "server": ONEUPHEALTH_FHIR_SERVER_URL || "https://api.1uphealthdev.com/r4",
  "module": "uscore_v3.1.0",
  "arguments": {
    "initiate_login_uri": "http://localhost:3000/launch",
    "redirect_uris": "http://localhost:3000/redirect",
    "confidential_client": "yes",
    "client_id": `${clientId}`,
    "client_secret": `${clientSecret}`,
    "token": `${accessToken}`,
    "patient_ids": "abde0edecb6a",
    "device_codes": ""
  },
  "sequences": [
    {
      "sequence": "ManualRegistrationSequence"
    },
    {
      "sequence": "UsCoreR4CapabilityStatementSequence"
    },
    {
      "sequence": "USCore310PatientSequence"
    },
    {
      "sequence": "USCore310AllergyintoleranceSequence"
    },
    {
      "sequence": "USCore310CareplanSequence"
    },
    {
      "sequence": "USCore310CareteamSequence"
    },
    {
      "sequence": "USCore310ConditionSequence"
    },
    // {
    //   "sequence": "USCore310ImplantableDeviceSequence"
    // },
    {
      "sequence": "USCore310DiagnosticreportNoteSequence"
    },
    {
      "sequence": "USCore310DiagnosticreportLabSequence"
    },
    {
      "sequence": "USCore310DocumentreferenceSequence"
    },
    {
      "sequence": "USCore310GoalSequence"
    },
    {
      "sequence": "USCore310ImmunizationSequence"
    },
    {
      "sequence": "USCore310MedicationrequestSequence"
    },
    {
      "sequence": "USCore310SmokingstatusSequence"
    },
    {
      "sequence": "USCore310PediatricWeightForHeightSequence"
    },
    {
      "sequence": "USCore310ObservationLabSequence"
    },
    {
      "sequence": "USCore310PediatricBmiForAgeSequence"
    },
    {
      "sequence": "USCore310PulseOximetrySequence"
    },
    {
      "sequence": "USCore310BodyheightSequence"
    },
    {
      "sequence": "USCore310BodytempSequence"
    },
    {
      "sequence": "USCore310BpSequence"
    },
    {
      "sequence": "USCore310BodyweightSequence"
    },
    {
      "sequence": "USCore310HeadcircumSequence"
    },
    {
      "sequence": "USCore310HeartrateSequence"
    },
    {
      "sequence": "USCore310ResprateSequence"
    },
    {
      "sequence": "USCore310ProcedureSequence"
    },
    {
      "sequence": "USCoreR4ClinicalNotesSequence"
    },
    {
      "sequence": "USCore310EncounterSequence"
    },
    {
      "sequence": "USCore310OrganizationSequence"
    },
    {
      "sequence": "USCore310PractitionerSequence"
    },
    {
      "sequence": "USCore310ProvenanceSequence"
    },
    {
      "sequence": "USCoreR4DataAbsentReasonSequence"
    }
  ]
}
let data = JSON.stringify(write);
fs.writeFileSync('script.json', data);