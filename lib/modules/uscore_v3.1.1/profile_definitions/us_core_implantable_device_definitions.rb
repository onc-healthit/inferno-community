# frozen_string_literal: true

module Inferno
  module USCoreProfileDefinitions
    class USCore311ImplantableDeviceSequenceDefinitions
      MUST_SUPPORTS = {
        extensions: [],
        slices: [],
        elements: [
          {
            path: 'udiCarrier'
          },
          {
            path: 'udiCarrier.deviceIdentifier'
          },
          {
            path: 'udiCarrier.carrierAIDC'
          },
          {
            path: 'udiCarrier.carrierHRF'
          },
          {
            path: 'distinctIdentifier'
          },
          {
            path: 'manufactureDate'
          },
          {
            path: 'expirationDate'
          },
          {
            path: 'lotNumber'
          },
          {
            path: 'serialNumber'
          },
          {
            path: 'type'
          },
          {
            path: 'patient'
          }
        ]
      }.freeze

      DELAYED_REFERENCES = [].freeze
    end
  end
end
