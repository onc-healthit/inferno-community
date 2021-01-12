# frozen_string_literal: true

module Inferno
  module USCore311ProfileDefinitions
    class USCore311DocumentreferenceSequenceDefinitions
      MUST_SUPPORTS = {
        extensions: [],
        slices: [],
        elements: [
          {
            path: 'identifier'
          },
          {
            path: 'status'
          },
          {
            path: 'type'
          },
          {
            path: 'category'
          },
          {
            path: 'subject'
          },
          {
            path: 'date'
          },
          {
            path: 'author'
          },
          {
            path: 'custodian'
          },
          {
            path: 'content'
          },
          {
            path: 'content.attachment'
          },
          {
            path: 'content.attachment.contentType'
          },
          {
            path: 'content.attachment.data'
          },
          {
            path: 'content.attachment.url'
          },
          {
            path: 'content.format'
          },
          {
            path: 'context'
          },
          {
            path: 'context.encounter'
          },
          {
            path: 'context.period'
          }
        ]
      }.freeze

      DELAYED_REFERENCES = [
        {
          path: 'author',
          resources: [
            'Practitioner',
            'Organization'
          ]
        },
        {
          path: 'custodian',
          resources: [
            'Organization'
          ]
        },
        {
          path: 'context.encounter',
          resources: [
            'Encounter'
          ]
        }
      ].freeze

      BINDINGS = [
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/document-reference-status',
          path: 'status'
        },
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/composition-status',
          path: 'docStatus'
        },
        {
          type: 'CodeableConcept',
          strength: 'required',
          system: 'http://hl7.org/fhir/us/core/ValueSet/us-core-documentreference-type',
          path: 'type'
        },
        {
          type: 'CodeableConcept',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/us/core/ValueSet/us-core-documentreference-category',
          path: 'category'
        },
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/document-relationship-type',
          path: 'relatesTo.code'
        },
        {
          type: 'CodeableConcept',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/ValueSet/security-labels',
          path: 'securityLabel'
        },
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/mimetypes',
          path: 'content.attachment.contentType'
        },
        {
          type: 'Coding',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/ValueSet/formatcodes',
          path: 'content.format'
        }
      ].freeze
    end
  end
end
