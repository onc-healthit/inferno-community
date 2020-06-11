# frozen_string_literal: true

module Inferno
  module USCore310ProfileDefinitions
    class USCore310AllergyintoleranceSequenceDefinitions
      MUST_SUPPORTS = {
        extensions: [],
        slices: [],
        elements: [
          {
            path: 'clinicalStatus'
          },
          {
            path: 'verificationStatus'
          },
          {
            path: 'code'
          },
          {
            path: 'patient'
          }
        ]
      }.freeze

      DELAYED_REFERENCES = [].freeze

      BINDINGS = [
        {
          type: 'CodeableConcept',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/allergyintolerance-clinical',
          path: 'clinicalStatus'
        },
        {
          type: 'CodeableConcept',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/allergyintolerance-verification',
          path: 'verificationStatus'
        },
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/allergy-intolerance-type',
          path: 'type'
        },
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/allergy-intolerance-category',
          path: 'category'
        },
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/allergy-intolerance-criticality',
          path: 'criticality'
        },
        {
          type: 'CodeableConcept',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/us/core/ValueSet/us-core-allergy-substance',
          path: 'code'
        },
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/reaction-event-severity',
          path: 'reaction.severity'
        }
      ].freeze
    end
  end
end
