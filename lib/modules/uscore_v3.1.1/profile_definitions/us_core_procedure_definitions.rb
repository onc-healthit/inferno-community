# frozen_string_literal: true

module Inferno
  module USCore311ProfileDefinitions
    class USCore311ProcedureSequenceDefinitions
      MUST_SUPPORTS = {
        extensions: [

        ],
        slices: [

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
            path: 'performed'
          }
        ]
      }.freeze

      DELAYED_REFERENCES = [

      ].freeze
    end
  end
end
