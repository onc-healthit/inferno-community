# frozen_string_literal: true

module Inferno
  module IpsProfileDefinitions
    class IpsDeviceuvipsSequenceDefinition
      PROFILE_URL = 'http://hl7.org/fhir/uv/ips/StructureDefinition/Device-uv-ips'
      MUST_SUPPORTS = {
        extensions: [],
        slices: [
          {
            name: 'Device.type.coding:absentOrUnknownDevice',
            path: 'type.coding'
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
            path: 'type.coding'
          },
          {
            path: 'type.text'
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
