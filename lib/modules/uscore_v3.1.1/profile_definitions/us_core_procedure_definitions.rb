# frozen_string_literal: true

module Inferno
  module USCoreProfileDefinitions
    class USCore311ProcedureSequenceDefinitions
      MUST_SUPPORTS = {
        extensions: [],
        slices: [],
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
            path: 'performed'
          }
        ]
      }.freeze

      DELAYED_REFERENCES = [].freeze
    end
  end
end
