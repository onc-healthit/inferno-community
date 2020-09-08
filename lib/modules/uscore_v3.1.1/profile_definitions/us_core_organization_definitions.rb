# frozen_string_literal: true

module Inferno
  module USCoreProfileDefinitions
    class USCore311OrganizationSequenceDefinitions
      MUST_SUPPORTS = {
        extensions: [],
        slices: [
          {
            name: 'Organization.identifier:NPI',
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
            path: 'active'
          },
          {
            path: 'name'
          },
          {
            path: 'telecom'
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
            path: 'address.country'
          }
        ]
      }.freeze

      DELAYED_REFERENCES = [].freeze
    end
  end
end
