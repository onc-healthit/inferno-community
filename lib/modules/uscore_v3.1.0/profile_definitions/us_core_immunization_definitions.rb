# frozen_string_literal: true

module Inferno
  module USCore310ProfileDefinitions
    class USCore310ImmunizationSequenceDefinitions
      MUST_SUPPORTS = {
        extensions: [],
        slices: [],
        elements: [
          {
            path: 'status'
          },
          {
            path: 'statusReason'
          },
          {
            path: 'vaccineCode'
          },
          {
            path: 'patient'
          },
          {
            path: 'occurrence'
          },
          {
            path: 'primarySource'
          }
        ]
      }.freeze

      DELAYED_REFERENCES = [].freeze
    end
  end
end
