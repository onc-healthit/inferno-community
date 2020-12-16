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
          system: 'http://hl7.org/fhir/ValueSet/medicationrequest-status',
          path: 'status'
        },
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/medicationrequest-intent',
          path: 'intent'
        },
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/request-priority',
          path: 'priority'
        },
        {
          type: 'CodeableConcept',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/us/core/ValueSet/us-core-medication-codes',
          path: 'medication'
        }
      ].freeze
    end
  end
end
