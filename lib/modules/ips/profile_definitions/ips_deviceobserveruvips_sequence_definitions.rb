# frozen_string_literal: true

module Inferno
  module IpsProfileDefinitions
    class IpsDeviceobserveruvipsSequenceDefinition
      PROFILE_URL = 'http://hl7.org/fhir/uv/ips/StructureDefinition/Device-observer-uv-ips'
      MUST_SUPPORTS = {
        extensions: [],
        slices: [],
        elements: [
          {
            path: 'Device'
          },
          {
            path: 'identifier'
          },
          {
            path: 'manufacturer'
          },
          {
            path: 'modelNumber'
          }
        ]
      }.freeze
      SEARCH_PARAMETERS = [].freeze
    end
  end
end
