# frozen_string_literal: true

module Inferno
  module USCore311ProfileDefinitions
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

      BINDINGS = [
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/diagnostic-report-status',
          path: 'status'
        },
        {
          type: 'CodeableConcept',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/us/core/ValueSet/us-core-diagnosticreport-category',
          path: 'category'
        },
        {
          type: 'CodeableConcept',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/us/core/ValueSet/us-core-diagnosticreport-report-and-note-codes',
          path: 'code'
        }
      ].freeze
    end
  end
end
