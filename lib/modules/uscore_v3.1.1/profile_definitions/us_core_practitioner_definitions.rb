# frozen_string_literal: true

module Inferno
  module USCore310ProfileDefinitions
    class USCore311PractitionerSequenceDefinitions
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
    end
  end
end
