# frozen_string_literal: true

module Inferno
  module IpsProfileDefinitions
    class IpsSpecimenuvipsSequenceDefinition
      PROFILE_URL = 'http://hl7.org/fhir/uv/ips/StructureDefinition/Specimen-uv-ips'
      MUST_SUPPORTS = {
        extensions: [],
        slices: [],
        elements: [
          {
            path: 'Specimen'
          },
          {
            path: 'type'
          },
          {
            path: 'subject'
          },
          {
            path: 'subject.reference'
          },
          {
            path: 'collection'
          },
          {
            path: 'collection.method'
          },
          {
            path: 'collection.bodySite'
          },
          {
            path: 'collection.fastingStatus[x]'
          }
        ]
      }.freeze
      SEARCH_PARAMETERS = [].freeze
    end
  end
end
