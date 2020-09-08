# frozen_string_literal: true

module Inferno
  module USCoreProfileDefinitions
    class USCore311AllergyintoleranceSequenceDefinitions
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
          },
          {
            path: 'reaction'
          },
          {
            path: 'reaction.manifestation'
          }
        ]
      }.freeze

      DELAYED_REFERENCES = [].freeze
    end
  end
end
