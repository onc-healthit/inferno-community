# frozen_string_literal: true

module Inferno
  module USCore311ProfileDefinitions
    class USCore311CareplanSequenceDefinitions
      MUST_SUPPORTS = {
        extensions: [

        ],
        slices: [
          {
            name: 'CarePlan.category:AssessPlan',
            path: 'category',
            discriminator: {
              type: 'patternCodeableConcept',
              path: '',
              code: 'assess-plan',
              system: 'http://hl7.org/fhir/us/core/CodeSystem/careplan-category'
            }
          }
        ],
        elements: [
          {
            path: 'text'
          },
          {
            path: 'text.status'
          },
          {
            path: 'status'
          },
          {
            path: 'intent'
          },
          {
            path: 'category'
          },
          {
            path: 'subject'
          }
        ]
      }.freeze

      DELAYED_REFERENCES = [

      ].freeze

      BINDINGS = [
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/us/core/ValueSet/us-core-narrative-status',
          path: 'text.status'
        },
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/request-status',
          path: 'status'
        },
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/care-plan-intent',
          path: 'intent'
        },
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/care-plan-activity-kind',
          path: 'activity.detail.kind'
        },
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/care-plan-activity-status',
          path: 'activity.detail.status'
        }
      ].freeze
    end
  end
end
