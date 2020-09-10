# frozen_string_literal: true

module Inferno
  module USCore310ProfileDefinitions
    class USCore310AllergyintoleranceSequenceDefinitions
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
            path: 'code'
          },
          {
            path: 'patient'
          }
        ]
      }.freeze

      DELAYED_REFERENCES = [].freeze
    end
  end
end
