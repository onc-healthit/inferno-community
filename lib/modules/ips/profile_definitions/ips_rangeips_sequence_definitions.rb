# frozen_string_literal: true

module Inferno
  module IpsProfileDefinitions
    class IpsRangeipsSequenceDefinition
      PROFILE_URL = 'http://hl7.org/fhir/uv/ips/StructureDefinition/Range-uv-ips'
      MUST_SUPPORTS = {
        extensions: [],
        slices: [],
        elements: [
          {
            path: 'Range'
          },
          {
            path: 'low'
          },
          {
            path: 'high'
          }
        ]
      }.freeze
      SEARCH_PARAMETERS = [].freeze
    end
  end
end
