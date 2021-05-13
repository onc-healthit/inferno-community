# frozen_string_literal: true

module Inferno
  module IpsProfileDefinitions
    class IpsSimplequantityipsSequenceDefinition
      PROFILE_URL = 'http://hl7.org/fhir/uv/ips/StructureDefinition/SimpleQuantity-uv-ips'
      MUST_SUPPORTS = {
        extensions: [],
        slices: [],
        elements: [
          {
            path: 'Quantity'
          },
          {
            path: 'system',
            fixed_value: 'http://unitsofmeasure.org'
          },
          {
            path: 'code'
          }
        ]
      }.freeze
      SEARCH_PARAMETERS = [].freeze
    end
  end
end
