# frozen_string_literal: true

module Inferno
  module USCore310ProfileDefinitions
    class USCore310ProvenanceSequenceDefinitions
      MUST_SUPPORTS = {
        extensions: [],
        slices: [
          {
            name: 'Provenance.agent:ProvenanceAuthor',
            path: 'agent',
            discriminator: {
              type: 'patternCodeableConcept',
              path: 'type',
              code: 'author',
              system: 'http://terminology.hl7.org/CodeSystem/provenance-participant-type'
            }
          },
          {
            name: 'Provenance.agent:ProvenanceTransmitter',
            path: 'agent',
            discriminator: {
              type: 'patternCodeableConcept',
              path: 'type',
              code: 'transmitter',
              system: 'http://hl7.org/fhir/us/core/CodeSystem/us-core-provenance-participant-type'
            }
          }
        ],
        elements: [
          {
            path: 'target'
          },
          {
            path: 'recorded'
          },
          {
            path: 'agent'
          },
          {
            path: 'agent.type'
          },
          {
            path: 'agent.who'
          },
          {
            path: 'agent.onBehalfOf'
          },
          {
            path: 'agent.type.coding.code',
            fixed_value: 'author'
          },
          {
            path: 'agent.type.coding.code',
            fixed_value: 'transmitter'
          }
        ]
      }.freeze

      DELAYED_REFERENCES = [
        {
          path: 'agent.who',
          resources: [
            'Practitioner',
            'Organization'
          ]
        },
        {
          path: 'agent.onBehalfOf',
          resources: [
            'Organization'
          ]
        }
      ].freeze

      BINDINGS = [
        {
          type: 'CodeableConcept',
          strength: 'extensible',
          system: 'http://terminology.hl7.org/ValueSet/v3-PurposeOfUse',
          path: 'reason'
        },
        {
          type: 'CodeableConcept',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/ValueSet/provenance-activity-type',
          path: 'activity'
        },
        {
          type: 'CodeableConcept',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/us/core/ValueSet/us-core-provenance-participant-type',
          path: 'agent.type'
        },
        {
          type: 'CodeableConcept',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/ValueSet/provenance-agent-type',
          path: 'agent.type'
        },
        {
          type: 'CodeableConcept',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/ValueSet/provenance-agent-type',
          path: 'agent.type'
        },
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/provenance-entity-role',
          path: 'entity.role'
        }
      ].freeze
    end
  end
end
