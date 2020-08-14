# frozen_string_literal: true

module Inferno
  module USCore310ProfileDefinitions
    class USCore310PediatricWeightForHeightSequenceDefinitions
      MUST_SUPPORTS = {
        extensions: [],
        slices: [
          {
            name: 'Observation.category:VSCat',
            path: 'category',
            discriminator: {
              type: 'value',
              values: [
                {
                  path: 'coding.code',
                  value: 'vital-signs'
                },
                {
                  path: 'coding.system',
                  value: 'http://terminology.hl7.org/CodeSystem/observation-category'
                }
              ]
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
            path: 'category.coding'
          },
          {
            path: 'category.coding.system',
            fixed_value: 'http://terminology.hl7.org/CodeSystem/observation-category'
          },
          {
            path: 'category.coding.code',
            fixed_value: 'vital-signs'
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
            path: 'value.value'
          },
          {
            path: 'value.unit'
          },
          {
            path: 'value.system',
            fixed_value: 'http://unitsofmeasure.org'
          },
          {
            path: 'value.code',
            fixed_value: '%'
          }
        ]
      }.freeze

      DELAYED_REFERENCES = [].freeze
    end
  end
end
