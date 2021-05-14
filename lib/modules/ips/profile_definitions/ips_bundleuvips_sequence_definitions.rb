# frozen_string_literal: true

module Inferno
  module IpsProfileDefinitions
    class IpsBundleuvipsSequenceDefinition
      PROFILE_URL = 'http://hl7.org/fhir/uv/ips/StructureDefinition/Bundle-uv-ips'
      MUST_SUPPORTS = {
        extensions: [],
        slices: [
          {
            name: 'Bundle.entry:composition',
            path: 'entry',
            discriminator: {
              type: 'profile',
              path: 'resource',
              profile: [
                'http://hl7.org/fhir/uv/ips/StructureDefinition/Composition-uv-ips'
              ]
            }
          }
        ],
        elements: [
          {
            path: 'Bundle'
          },
          {
            path: 'identifier'
          },
          {
            path: 'timestamp'
          },
          {
            path: 'entry'
          },
          {
            path: 'entry.fullUrl'
          },
          {
            path: 'entry.resource'
          }
        ]
      }.freeze
      SEARCH_PARAMETERS = [].freeze
    end
  end
end
