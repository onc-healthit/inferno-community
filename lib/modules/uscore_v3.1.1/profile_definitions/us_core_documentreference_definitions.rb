# frozen_string_literal: true

module Inferno
  module USCoreProfileDefinitions
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
    end
  end
end
