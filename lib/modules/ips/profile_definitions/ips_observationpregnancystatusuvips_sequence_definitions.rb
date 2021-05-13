# frozen_string_literal: true

module Inferno
  module IpsProfileDefinitions
    class IpsObservationpregnancystatusuvipsSequenceDefinition
      PROFILE_URL = 'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-pregnancy-status-uv-ips'
      MUST_SUPPORTS = {
        extensions: [
          {
            id: 'Observation.effective[x].extension',
            url: 'http://hl7.org/fhir/StructureDefinition/data-absent-reason'
          }
        ],
        slices: [
          {
            name: 'Observation.value[x]:valueCodeableConcept',
            path: 'value[x]',
            discriminator: {
              type: 'type',
              code: 'CodeableConcept'
            }
          }
        ],
        elements: [
          {
            path: 'Observation'
          },
          {
            path: 'code.coding.code',
            fixed_value: '82810-3'
          },
          {
            path: 'subject'
          },
          {
            path: 'subject.reference'
          },
          {
            path: 'effective[x]'
          },
          {
            path: 'hasMember'
          },
          {
            path: 'hasMember.reference'
          }
        ]
      }.freeze
      SEARCH_PARAMETERS = [].freeze
    end
  end
end
