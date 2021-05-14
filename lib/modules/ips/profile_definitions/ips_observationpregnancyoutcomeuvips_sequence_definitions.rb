# frozen_string_literal: true

module Inferno
  module IpsProfileDefinitions
    class IpsObservationpregnancyoutcomeuvipsSequenceDefinition
      PROFILE_URL = 'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-pregnancy-outcome-uv-ips'
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
          }
        ]
      }.freeze
      SEARCH_PARAMETERS = [].freeze
    end
  end
end
