# frozen_string_literal: true

module Inferno
  module IpsProfileDefinitions
    class IpsCodingipsSequenceDefinition
      PROFILE_URL = 'http://hl7.org/fhir/uv/ips/StructureDefinition/Coding-uv-ips'
      MUST_SUPPORTS = {
        extensions: [
          {
            id: 'Coding.display.extension:translation',
            url: 'http://hl7.org/fhir/StructureDefinition/translation'
          }
        ],
        slices: [],
        elements: [
          {
            path: 'Coding'
          },
          {
            path: 'system'
          },
          {
            path: 'version'
          },
          {
            path: 'code'
          },
          {
            path: 'display'
          }
        ]
      }.freeze
      SEARCH_PARAMETERS = [].freeze
    end
  end
end
