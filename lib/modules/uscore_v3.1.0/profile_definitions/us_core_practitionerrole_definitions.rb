# frozen_string_literal: true

module Inferno
  module USCore310ProfileDefinitions
    class USCore310PractitionerroleSequenceDefinitions
      MUST_SUPPORTS = {
        extensions: [

        ],
        slices: [

        ],
        elements: [
          {
            path: 'practitioner'
          },
          {
            path: 'organization'
          },
          {
            path: 'code'
          },
          {
            path: 'specialty'
          },
          {
            path: 'location'
          },
          {
            path: 'telecom'
          },
          {
            path: 'telecom.system'
          },
          {
            path: 'telecom.value'
          },
          {
            path: 'endpoint'
          }
        ]
      }.freeze

      DELAYED_REFERENCES = [
        {
          path: 'practitioner',
          resources: [
            'Practitioner'
          ]
        },
        {
          path: 'organization',
          resources: [
            'Organization'
          ]
        }
      ].freeze

      BINDINGS = [
        {
          type: 'CodeableConcept',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/us/core/ValueSet/us-core-provider-role',
          path: 'code'
        },
        {
          type: 'CodeableConcept',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/us/core/ValueSet/us-core-provider-specialty',
          path: 'specialty'
        },
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/contact-point-system',
          path: 'telecom.system'
        },
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/contact-point-use',
          path: 'telecom.use'
        },
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/days-of-week',
          path: 'availableTime.daysOfWeek'
        }
      ].freeze
    end
  end
end
