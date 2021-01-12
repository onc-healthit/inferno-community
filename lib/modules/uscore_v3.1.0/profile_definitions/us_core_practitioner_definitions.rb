# frozen_string_literal: true

module Inferno
  module USCore310ProfileDefinitions
    class USCore310PractitionerSequenceDefinitions
      MUST_SUPPORTS = {
        extensions: [],
        slices: [
          {
            name: 'Practitioner.identifier:NPI',
            path: 'identifier',
            discriminator: {
              type: 'patternIdentifier',
              path: '',
              system: 'http://hl7.org/fhir/sid/us-npi'
            }
          }
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
          }
        ]
      }.freeze

      DELAYED_REFERENCES = [].freeze

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
          system: 'http://hl7.org/fhir/ValueSet/administrative-gender',
          path: 'gender'
        }
      ].freeze
    end
  end
end
