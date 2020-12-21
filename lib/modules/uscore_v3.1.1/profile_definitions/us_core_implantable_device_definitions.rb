# frozen_string_literal: true

module Inferno
  module USCore311ProfileDefinitions
    class USCore311ImplantableDeviceSequenceDefinitions
      MUST_SUPPORTS = {
        extensions: [

        ],
        slices: [

        ],
        elements: [
          {
            path: 'udiCarrier'
          },
          {
            path: 'udiCarrier.deviceIdentifier'
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

      DELAYED_REFERENCES = [

      ].freeze
    end
  end
end
