# frozen_string_literal: true

module Inferno
  module IpsProfileDefinitions
    class IpsObservationalcoholuseuvipsSequenceDefinition
      PROFILE_URL = 'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-alcoholuse-uv-ips'
      MUST_SUPPORTS = {
        extensions: [
          {
            id: 'Observation.effective[x].extension',
            url: 'http://hl7.org/fhir/StructureDefinition/data-absent-reason'
          }
        ],
        slices: [
          {
            name: 'Observation.value[x]:valueQuantity',
            path: 'value',
            discriminator: {
              type: 'type',
              code: 'Quantity'
            }
          }
        ],
        elements: [
          {
            path: 'Observation'
          },
          {
            path: 'status'
          },
          {
            path: 'code.coding.code',
            fixed_value: '74013-4'
          },
          {
            path: 'subject'
          },
          {
            path: 'subject.reference'
          },
          {
            path: 'effective'
          }
        ]
      }.freeze
      SEARCH_PARAMETERS = [].freeze
    end
  end
end
