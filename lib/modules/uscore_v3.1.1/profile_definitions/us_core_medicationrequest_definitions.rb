# frozen_string_literal: true

module Inferno
  module USCoreProfileDefinitions
    class USCore311MedicationrequestSequenceDefinitions
      MUST_SUPPORTS = {
        extensions: [],
        slices: [],
        elements: [
          {
            path: 'status'
          },
          {
            path: 'intent'
          },
          {
            path: 'reported'
          },
          {
            path: 'medication'
          },
          {
            path: 'subject'
          },
          {
            path: 'encounter'
          },
          {
            path: 'authoredOn'
          },
          {
            path: 'requester'
          },
          {
            path: 'dosageInstruction'
          },
          {
            path: 'dosageInstruction.text'
          }
        ]
      }.freeze

      DELAYED_REFERENCES = [
        {
          path: 'requester',
          resources: [
            'Practitioner',
            'Organization'
          ]
        }
      ].freeze
    end
  end
end
