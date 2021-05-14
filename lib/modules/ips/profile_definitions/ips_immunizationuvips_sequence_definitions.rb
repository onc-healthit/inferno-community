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
            path: 'vaccineCode.coding',
            discriminator: {
              type: 'binding',
              path: '',
              valueset: 'http://hl7.org/fhir/uv/ips/ValueSet/vaccines-gps-uv-ips'
            }
          },
          {
            name: 'Immunization.vaccineCode.coding:atcClass',
            path: 'vaccineCode.coding',
            discriminator: {
              type: 'binding',
              path: '',
              valueset: 'http://hl7.org/fhir/uv/ips/ValueSet/whoatc-uv-ips'
            }
          },
          {
            name: 'Immunization.vaccineCode.coding:absentOrUnknownImmunization',
            path: 'vaccineCode.coding',
            discriminator: {
              type: 'binding',
              path: '',
              valueset: 'http://hl7.org/fhir/uv/ips/ValueSet/absent-or-unknown-immunizations-uv-ips'
            }
          },
          {
            name: 'Immunization.protocolApplied.targetDisease:targetDiseaseGPSCode',
            path: 'protocolApplied.targetDisease',
            discriminator: {
              type: 'binding',
              path: '',
              valueset: 'http://hl7.org/fhir/uv/ips/ValueSet/targetDiseases-gps-uv-ips'
            }
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
            path: 'occurrence'
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
