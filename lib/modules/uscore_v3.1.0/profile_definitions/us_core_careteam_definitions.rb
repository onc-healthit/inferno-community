# frozen_string_literal: true

module Inferno
  module USCore310ProfileDefinitions
    class USCore310CareteamSequenceDefinitions
      MUST_SUPPORTS = {
        extensions: [],
        slices: [],
        elements: [
          {
            path: 'status'
          },
          {
            path: 'subject'
          },
          {
            path: 'participant'
          },
          {
            path: 'participant.role'
          },
          {
            path: 'participant.member'
          }
        ]
      }.freeze

      DELAYED_REFERENCES = [
        {
          path: 'participant.member',
          resources: [
            'Practitioner',
            'Organization'
          ]
        }
      ].freeze
    end
  end
end
