# frozen_string_literal: true

module Inferno
  module USCore311ProfileDefinitions
    class USCore311MedicationrequestSequenceDefinitions
      MUST_SUPPORTS = {
        extensions: [],
        slices: [],
        elements: [
          {
            path: 'status'
          },
          {
            path: 'intent'
          },
          {
            path: 'reported'
          },
          {
            path: 'medication'
          },
          {
            path: 'subject'
          },
          {
            path: 'encounter'
          },
          {
            path: 'authoredOn'
          },
          {
            path: 'requester'
          },
          {
            path: 'dosageInstruction'
          },
          {
            path: 'dosageInstruction.text'
          }
        ]
      }.freeze

      DELAYED_REFERENCES = [
        {
          path: 'requester',
          resources: [
            'Practitioner',
            'Organization'
          ]
        }
      ].freeze

      BINDINGS = [
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/location-status',
          path: 'status'
        },
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/location-mode',
          path: 'mode'
        },
        {
          type: 'CodeableConcept',
          strength: 'extensible',
          system: 'http://terminology.hl7.org/ValueSet/v3-ServiceDeliveryLocationRoleType',
          path: 'type'
        },
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/address-use',
          path: 'address.use'
        },
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/address-type',
          path: 'address.type'
        },
        {
          type: 'string',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/us/core/ValueSet/us-core-usps-state',
          path: 'address.state'
        },
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/days-of-week',
          path: 'hoursOfOperation.daysOfWeek'
        }
      ].freeze
    end
  end
end
