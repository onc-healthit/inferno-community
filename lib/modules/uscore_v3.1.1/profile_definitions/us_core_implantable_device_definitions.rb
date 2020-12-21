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

      BINDINGS = [
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/udi-entry-type',
          path: 'udiCarrier.entryType'
        },
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/device-status',
          path: 'status'
        },
        {
          type: 'CodeableConcept',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/ValueSet/device-status-reason',
          path: 'statusReason'
        },
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/device-nametype',
          path: 'deviceName.type'
        },
        {
          type: 'CodeableConcept',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/ValueSet/device-kind',
          path: 'type'
        }
      ].freeze
    end
  end
end
