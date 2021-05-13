# frozen_string_literal: true

module Inferno
  module IpsProfileDefinitions
    class IpsImmunizationuvipsSequenceDefinition
      PROFILE_URL = 'http://hl7.org/fhir/uv/ips/StructureDefinition/Immunization-uv-ips'
      MUST_SUPPORTS = {
        extensions: [
          {
            id: 'Immunization.occurrence[x].extension:data-absent-reason',
            url: 'http://hl7.org/fhir/StructureDefinition/data-absent-reason'
          }
        ],
        slices: [
          {
            name: 'Immunization.vaccineCode.coding:vaccineGPSCode',
            path: 'vaccineCode.coding'
          },
          {
            name: 'Immunization.vaccineCode.coding:atcClass',
            path: 'vaccineCode.coding'
          },
          {
            name: 'Immunization.vaccineCode.coding:absentOrUnknownImmunization',
            path: 'vaccineCode.coding'
          },
          {
            name: 'Immunization.protocolApplied.targetDisease:targetDiseaseGPSCode',
            path: 'protocolApplied.targetDisease'
          }
        ],
        elements: [
          {
            path: 'Immunization'
          },
          {
            path: 'status'
          },
          {
            path: 'vaccineCode'
          },
          {
            path: 'vaccineCode.coding'
          },
          {
            path: 'vaccineCode.text'
          },
          {
            path: 'patient'
          },
          {
            path: 'patient.reference'
          },
          {
            path: 'occurrence[x]'
          },
          {
            path: 'site'
          },
          {
            path: 'route'
          },
          {
            path: 'performer'
          },
          {
            path: 'performer.actor'
          }
        ]
      }.freeze
      SEARCH_PARAMETERS = [].freeze
    end
  end
end
