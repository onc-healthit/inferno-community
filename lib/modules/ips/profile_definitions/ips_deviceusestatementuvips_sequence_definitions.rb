# frozen_string_literal: true

module Inferno
  module IpsProfileDefinitions
    class IpsDeviceusestatementuvipsSequenceDefinition
      PROFILE_URL = 'http://hl7.org/fhir/uv/ips/StructureDefinition/DeviceUseStatement-uv-ips'
      MUST_SUPPORTS = {
        extensions: [
          {
            id: 'DeviceUseStatement.timing[x].extension:data-absent-reason',
            url: 'http://hl7.org/fhir/StructureDefinition/data-absent-reason'
          }
        ],
        slices: [],
        elements: [
          {
            path: 'DeviceUseStatement'
          },
          {
            path: 'subject'
          },
          {
            path: 'subject.reference'
          },
          {
            path: 'timing[x]'
          },
          {
            path: 'source'
          },
          {
            path: 'device'
          },
          {
            path: 'bodySite'
          }
        ]
      }.freeze
      SEARCH_PARAMETERS = [].freeze
    end
  end
end
