# frozen_string_literal: true

module Inferno
  module IpsProfileDefinitions
    class IpsObservationresultsuvipsSequenceDefinition
      PROFILE_URL = 'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-results-uv-ips'
      MUST_SUPPORTS = {
        extensions: [
          {
            id: 'Observation.effective[x].extension',
            url: 'http://hl7.org/fhir/StructureDefinition/data-absent-reason'
          }
        ],
        slices: [],
        elements: [
          {
            path: 'Observation'
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
            path: 'effective[x]'
          },
          {
            path: 'performer'
          },
          {
            path: 'value[x]'
          },
          {
            path: 'hasMember'
          },
          {
            path: 'component'
          }
        ]
      }.freeze
      SEARCH_PARAMETERS = [].freeze
    end
  end
end
