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
            path: 'type',
            discriminator: {
              type: 'binding',
              path: '',
              valueset: 'http://hl7.org/fhir/uv/ips/ValueSet/absent-or-unknown-devices-uv-ips'
            }
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
