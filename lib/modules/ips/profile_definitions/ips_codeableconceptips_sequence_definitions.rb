# frozen_string_literal: true

module Inferno
  module IpsProfileDefinitions
    class IpsCodeableconceptipsSequenceDefinition
      PROFILE_URL = 'http://hl7.org/fhir/uv/ips/StructureDefinition/CodeableConcept-uv-ips'
      MUST_SUPPORTS = {
        extensions: [],
        slices: [],
        elements: [
          {
            path: 'CodeableConcept'
          },
          {
            path: 'coding'
          },
          {
            path: 'text'
          }
        ]
      }.freeze
      SEARCH_PARAMETERS = [].freeze
    end
  end
end
