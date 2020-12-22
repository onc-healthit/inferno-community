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
        slices: [],
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

      DELAYED_REFERENCES = [].freeze
    end
  end
end
