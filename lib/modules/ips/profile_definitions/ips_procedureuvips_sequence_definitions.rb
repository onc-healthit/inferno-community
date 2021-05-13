# frozen_string_literal: true

module Inferno
  module IpsProfileDefinitions
    class IpsProcedureuvipsSequenceDefinition
      PROFILE_URL = 'http://hl7.org/fhir/uv/ips/StructureDefinition/Procedure-uv-ips'
      MUST_SUPPORTS = {
        extensions: [
          {
            id: 'Procedure.performed[x].extension:data-absent-reason',
            url: 'http://hl7.org/fhir/StructureDefinition/data-absent-reason'
          }
        ],
        slices: [
          {
            name: 'Procedure.code:absentOrUnknownProcedure',
            path: 'code'
          }
        ],
        elements: [
          {
            path: 'Procedure'
          },
          {
            path: 'status'
          },
          {
            path: 'code'
          },
          {
            path: 'subject'
          },
          {
            path: 'subject.reference'
          },
          {
            path: 'performed[x]'
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
