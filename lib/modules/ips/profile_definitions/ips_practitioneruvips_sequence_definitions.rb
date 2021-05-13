# frozen_string_literal: true

module Inferno
  module IpsProfileDefinitions
    class IpsPractitioneruvipsSequenceDefinition
      PROFILE_URL = 'http://hl7.org/fhir/uv/ips/StructureDefinition/Practitioner-uv-ips'
      MUST_SUPPORTS = {
        extensions: [],
        slices: [],
        elements: [
          {
            path: 'Practitioner'
          },
          {
            path: 'name'
          },
          {
            path: 'name.family'
          },
          {
            path: 'name.given'
          },
          {
            path: 'telecom'
          },
          {
            path: 'address'
          }
        ]
      }.freeze
      SEARCH_PARAMETERS = [].freeze
    end
  end
end
