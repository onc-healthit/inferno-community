# frozen_string_literal: true

module Inferno
  module IpsProfileDefinitions
    class IpsPractitionerroleuvipsSequenceDefinition
      PROFILE_URL = 'http://hl7.org/fhir/uv/ips/StructureDefinition/PractitionerRole-uv-ips'
      MUST_SUPPORTS = {
        extensions: [],
        slices: [],
        elements: [
          {
            path: 'practitioner'
          },
          {
            path: 'organization'
          }
        ]
      }.freeze
      SEARCH_PARAMETERS = [].freeze
    end
  end
end
