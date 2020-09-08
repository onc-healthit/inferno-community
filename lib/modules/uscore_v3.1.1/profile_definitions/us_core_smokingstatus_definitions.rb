# frozen_string_literal: true

module Inferno
  module USCoreProfileDefinitions
    class USCore311SmokingstatusSequenceDefinitions
      MUST_SUPPORTS = {
        extensions: [],
        slices: [
          {
            name: 'Observation.value[x]:valueCodeableConcept',
            path: 'value',
            discriminator: {
              type: 'type',
              code: 'CodeableConcept'
            }
          }
        ],
        elements: [
          {
            path: 'status'
          },
          {
            path: 'code'
          },
          {
            path: 'subject'
          },
          {
            path: 'issued'
          }
        ]
      }.freeze

      DELAYED_REFERENCES = [].freeze
    end
  end
end
