# frozen_string_literal: true

module Inferno
  module USCore311ProfileDefinitions
    class USCore311LocationSequenceDefinitions
      MUST_SUPPORTS = {
        extensions: [],
        slices: [],
        elements: [
          {
            path: 'status'
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
            path: 'managingOrganization'
          }
        ]
      }.freeze

      DELAYED_REFERENCES = [
        {
          path: 'managingOrganization',
          resources: [
            'Organization'
          ]
        }
      ].freeze
    end
  end
end
