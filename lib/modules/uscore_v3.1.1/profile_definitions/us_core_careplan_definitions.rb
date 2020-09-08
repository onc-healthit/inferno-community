# frozen_string_literal: true

module Inferno
  module USCore310ProfileDefinitions
    class USCore311CareplanSequenceDefinitions
      MUST_SUPPORTS = {
        extensions: [],
        slices: [
          {
            name: 'CarePlan.category:AssessPlan',
            path: 'category',
            discriminator: {
              type: 'patternCodeableConcept',
              path: '',
              code: 'assess-plan',
              system: 'http://hl7.org/fhir/us/core/CodeSystem/careplan-category'
            }
          }
        ],
        elements: [
          {
            path: 'text'
          },
          {
            path: 'text.status'
          },
          {
            path: 'status'
          },
          {
            path: 'intent'
          },
          {
            path: 'category'
          },
          {
            path: 'subject'
          }
        ]
      }.freeze

      DELAYED_REFERENCES = [].freeze
    end
  end
end
