# frozen_string_literal: true

module Inferno
  module USCore310ProfileDefinitions
    class USCore311PractitionerroleSequenceDefinitions
      MUST_SUPPORTS = {
        extensions: [],
        slices: [],
        elements: [
          {
            path: 'practitioner'
          },
          {
            path: 'organization'
          },
          {
            path: 'code'
          },
          {
            path: 'specialty'
          },
          {
            path: 'location'
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
            path: 'endpoint'
          }
        ]
      }.freeze

      DELAYED_REFERENCES = [
        {
          path: 'practitioner',
          resources: [
            'Practitioner'
          ]
        },
        {
          path: 'organization',
          resources: [
            'Organization'
          ]
        }
      ].freeze
    end
  end
end
