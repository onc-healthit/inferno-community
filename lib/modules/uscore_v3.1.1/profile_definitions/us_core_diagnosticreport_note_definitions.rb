# frozen_string_literal: true

module Inferno
  module USCoreProfileDefinitions
    class USCore311DiagnosticreportNoteSequenceDefinitions
      MUST_SUPPORTS = {
        extensions: [],
        slices: [],
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
            path: 'encounter'
          },
          {
            path: 'effective'
          },
          {
            path: 'issued'
          },
          {
            path: 'performer'
          },
          {
            path: 'presentedForm'
          }
        ]
      }.freeze

      DELAYED_REFERENCES = [
        {
          path: 'encounter',
          resources: [
            'Encounter'
          ]
        },
        {
          path: 'performer',
          resources: [
            'Practitioner',
            'Organization'
          ]
        }
      ].freeze
    end
  end
end
