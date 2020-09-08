# frozen_string_literal: true

module Inferno
  module USCore310ProfileDefinitions
    class USCore311ObservationLabSequenceDefinitions
      MUST_SUPPORTS = {
        extensions: [],
        slices: [
          {
            name: 'Observation.category:Laboratory',
            path: 'category',
            discriminator: {
              type: 'patternCodeableConcept',
              path: '',
              code: 'laboratory',
              system: 'http://terminology.hl7.org/CodeSystem/observation-category'
            }
          }
        ],
        elements: [
          {
            path: 'status'
          },
          {
            path: 'category'
          },
          {
            path: 'code'
          },
          {
            path: 'subject'
          },
          {
            path: 'effective'
          },
          {
            path: 'value'
          },
          {
            path: 'dataAbsentReason'
          }
        ]
      }.freeze

      DELAYED_REFERENCES = [].freeze
    end
  end
end
