# frozen_string_literal: true

module Inferno
  module IpsProfileDefinitions
    class IpsDiagnosticreportuvipsSequenceDefinition
      PROFILE_URL = 'http://hl7.org/fhir/uv/ips/StructureDefinition/DiagnosticReport-uv-ips'
      MUST_SUPPORTS = {
        extensions: [
          {
            id: 'DiagnosticReport.effective[x].extension',
            url: 'http://hl7.org/fhir/StructureDefinition/data-absent-reason'
          }
        ],
        slices: [
          {
            name: 'DiagnosticReport.result:observation-results',
            path: 'result'
          }
        ],
        elements: [
          {
            path: 'DiagnosticReport'
          },
          {
            path: 'status',
            fixed_value: 'final'
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
            path: 'subject.reference'
          },
          {
            path: 'effective'
          },
          {
            path: 'performer'
          },
          {
            path: 'result'
          }
        ]
      }.freeze
      SEARCH_PARAMETERS = [].freeze
    end
  end
end
