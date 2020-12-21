# frozen_string_literal: true

module Inferno
  module USCore311ProfileDefinitions
    class USCore311PatientSequenceDefinitions
      MUST_SUPPORTS = {
        extensions: [
          {
            id: 'Patient.extension:race',
            url: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-race'
          },
          {
            id: 'Patient.extension:ethnicity',
            url: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity'
          },
          {
            id: 'Patient.extension:birthsex',
            url: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex'
          }
        ],
        slices: [

        ],
        elements: [
          {
            path: 'identifier'
          },
          {
            path: 'identifier.system'
          },
          {
            path: 'identifier.value'
          },
          {
            path: 'name'
          },
          {
            path: 'name.family'
          },
          {
            path: 'name.given'
          },
          {
            path: 'telecom'
          },
          {
            path: 'telecom.system'
          },
          {
            path: 'telecom.value'
          },
          {
            path: 'telecom.use'
          },
          {
            path: 'gender'
          },
          {
            path: 'birthDate'
          },
          {
            path: 'address'
          },
          {
            path: 'address.line'
          },
          {
            path: 'address.city'
          },
          {
            path: 'address.state'
          },
          {
            path: 'address.postalCode'
          },
          {
            path: 'address.period'
          },
          {
            path: 'communication'
          },
          {
            path: 'communication.language'
          }
        ]
      }.freeze

      DELAYED_REFERENCES = [

      ].freeze

      BINDINGS = [
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/identifier-use',
          path: 'identifier.use'
        },
        {
          type: 'CodeableConcept',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/ValueSet/identifier-type',
          path: 'identifier.type'
        },
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/name-use',
          path: 'name.use'
        },
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/contact-point-system',
          path: 'telecom.system'
        },
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/contact-point-use',
          path: 'telecom.use'
        },
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/administrative-gender',
          path: 'gender'
        },
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/address-use',
          path: 'address.use'
        },
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/address-type',
          path: 'address.type'
        },
        {
          type: 'string',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/us/core/ValueSet/us-core-usps-state',
          path: 'address.state'
        },
        {
          type: 'CodeableConcept',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/ValueSet/marital-status',
          path: 'maritalStatus'
        },
        {
          type: 'CodeableConcept',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/ValueSet/patient-contactrelationship',
          path: 'contact.relationship'
        },
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/administrative-gender',
          path: 'contact.gender'
        },
        {
          type: 'CodeableConcept',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/us/core/ValueSet/simple-language',
          path: 'communication.language'
        },
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/link-type',
          path: 'link.type'
        },
        {
          type: 'Coding',
          strength: 'required',
          system: 'http://hl7.org/fhir/us/core/ValueSet/omb-race-category',
          path: 'value',
          extensions: [
            'http://hl7.org/fhir/us/core/StructureDefinition/us-core-race',
            'ombCategory'
          ]
        },
        {
          type: 'Coding',
          strength: 'required',
          system: 'http://hl7.org/fhir/us/core/ValueSet/detailed-race',
          path: 'value',
          extensions: [
            'http://hl7.org/fhir/us/core/StructureDefinition/us-core-race',
            'detailed'
          ]
        },
        {
          type: 'Coding',
          strength: 'required',
          system: 'http://hl7.org/fhir/us/core/ValueSet/omb-ethnicity-category',
          path: 'value',
          extensions: [
            'http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity',
            'ombCategory'
          ]
        },
        {
          type: 'Coding',
          strength: 'required',
          system: 'http://hl7.org/fhir/us/core/ValueSet/detailed-ethnicity',
          path: 'value',
          extensions: [
            'http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity',
            'detailed'
          ]
        },
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/us/core/ValueSet/birthsex',
          path: 'value',
          extensions: [
            'http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex'
          ]
        }
      ].freeze
    end
  end
end
