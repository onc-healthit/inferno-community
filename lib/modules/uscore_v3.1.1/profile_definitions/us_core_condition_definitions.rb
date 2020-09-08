# frozen_string_literal: true

module Inferno
  module USCore310ProfileDefinitions
    class USCore311ConditionSequenceDefinitions
      MUST_SUPPORTS = {
        extensions: [],
        slices: [],
        elements: [
          {
            path: 'clinicalStatus'
          },
          {
            path: 'verificationStatus'
          },
          {
            path: 'category'
          },
          {
            path: 'code'
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
