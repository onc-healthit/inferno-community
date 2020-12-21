# frozen_string_literal: true

module Inferno
  module USCore311ProfileDefinitions
    class USCore311ProvenanceSequenceDefinitions
      MUST_SUPPORTS = {
        extensions: [

        ],
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
    end
  end
end
