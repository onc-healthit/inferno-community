# frozen_string_literal: true

module Inferno
  module USCoreProfileDefinitions
    class USCore311DiagnosticreportLabSequenceDefinitions
      MUST_SUPPORTS = {
        extensions: [],
        slices: [
          {
            name: 'DiagnosticReport.category:LaboratorySlice',
            path: 'category',
            discriminator: {
              type: 'patternCodeableConcept',
              path: '',
              code: 'LAB',
              system: 'http://terminology.hl7.org/CodeSystem/v2-0074'
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
            path: 'code'
          },
          {
            path: 'subject'
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
            path: 'result'
          }
        ]
      }.freeze

      DELAYED_REFERENCES = [
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
