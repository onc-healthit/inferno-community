# frozen_string_literal: true

module Inferno
  module IpsProfileDefinitions
    class IpsConditionuvipsSequenceDefinition
      PROFILE_URL = 'http://hl7.org/fhir/uv/ips/StructureDefinition/Condition-uv-ips'
      MUST_SUPPORTS = {
        extensions: [],
        slices: [
          {
            name: 'Condition.code.coding:problemGPSCode',
            path: 'code.coding',
            discriminator: {
              type: 'binding',
              path: '',
              valueset: 'http://hl7.org/fhir/uv/ips/ValueSet/core-problem-finding-situation-event-gps-uv-ips'
            }
          },
          {
            name: 'Condition.code.coding:absentOrUnknownProblem',
            path: 'code.coding',
            discriminator: {
              type: 'binding',
              path: '',
              valueset: 'http://hl7.org/fhir/uv/ips/ValueSet/absent-or-unknown-problems-uv-ips'
            }
          },
          {
            name: 'Condition.onset[x]:onsetDateTime',
            path: 'onset',
            discriminator: {
              type: 'type',
              code: 'DateTime'
            }
          },
          {
            name: 'Condition.abatement[x]:abatementDateTime',
            path: 'abatement',
            discriminator: {
              type: 'type',
              code: 'DateTime'
            }
          }
        ],
        elements: [
          {
            path: 'Condition'
          },
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
            path: 'severity'
          },
          {
            path: 'code'
          },
          {
            path: 'code.coding'
          },
          {
            path: 'code.text'
          },
          {
            path: 'bodySite'
          },
          {
            path: 'subject'
          },
          {
            path: 'subject.reference'
          },
          {
            path: 'onset'
          },
          {
            path: 'abatement'
          },
          {
            path: 'asserter'
          }
        ]
      }.freeze
      SEARCH_PARAMETERS = [].freeze
    end
  end
end
