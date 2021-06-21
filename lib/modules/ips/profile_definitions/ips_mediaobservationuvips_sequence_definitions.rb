# frozen_string_literal: true

module Inferno
  module IpsProfileDefinitions
    class IpsMediaobservationuvipsSequenceDefinition
      PROFILE_URL = 'http://hl7.org/fhir/uv/ips/StructureDefinition/Media-observation-uv-ips'
      MUST_SUPPORTS = {
        extensions: [],
        slices: [],
        elements: [
          {
            path: 'Media'
          },
          {
            path: 'status',
            fixed_value: 'completed'
          },
          {
            path: 'type'
          },
          {
            path: 'subject'
          },
          {
            path: 'subject.reference'
          },
          {
            path: 'operator'
          },
          {
            path: 'device'
          },
          {
            path: 'content'
          }
        ]
      }.freeze
      SEARCH_PARAMETERS = [].freeze
    end
  end
end
