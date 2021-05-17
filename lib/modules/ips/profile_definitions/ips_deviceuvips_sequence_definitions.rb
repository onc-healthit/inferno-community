# frozen_string_literal: true

module Inferno
  module IpsProfileDefinitions
    class IpsDeviceuvipsSequenceDefinition
      PROFILE_URL = 'http://hl7.org/fhir/uv/ips/StructureDefinition/Device-uv-ips'
      MUST_SUPPORTS = {
        extensions: [],
        slices: [
          {
            name: 'Device.type:absentOrUnknownDevice',
            path: 'type'
          }
        ],
        elements: [
          {
            path: 'Device'
          },
          {
            path: 'type'
          },
          {
            path: 'patient'
          },
          {
            path: 'patient.reference'
          }
        ]
      }.freeze
      SEARCH_PARAMETERS = [].freeze
    end
  end
end
