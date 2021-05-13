# frozen_string_literal: true

module Inferno
  module IpsProfileDefinitions
    class IpsRatioipsSequenceDefinition
      PROFILE_URL = 'http://hl7.org/fhir/uv/ips/StructureDefinition/Ratio-uv-ips'
      MUST_SUPPORTS = {
        extensions: [],
        slices: [],
        elements: [
          {
            path: 'Ratio'
          },
          {
            path: 'numerator'
          },
          {
            path: 'denominator'
          }
        ]
      }.freeze
      SEARCH_PARAMETERS = [].freeze
    end
  end
end
