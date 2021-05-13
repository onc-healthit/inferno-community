# frozen_string_literal: true

module Inferno
  module IpsProfileDefinitions
    class IpsObservationpregnancyedduvipsSequenceDefinition
      PROFILE_URL = 'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-pregnancy-edd-uv-ips'
      MUST_SUPPORTS = {
        extensions: [
          {
            id: 'Observation.effective[x].extension',
            url: 'http://hl7.org/fhir/StructureDefinition/data-absent-reason'
          }
        ],
        slices: [
          {
            name: 'Observation.value[x]:valueDateTime',
            path: 'value[x]',
            discriminator: {
              type: 'type',
              code: 'DateTime'
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
            path: 'effective[x]'
          }
        ]
      }.freeze
      SEARCH_PARAMETERS = [].freeze
    end
  end
end
