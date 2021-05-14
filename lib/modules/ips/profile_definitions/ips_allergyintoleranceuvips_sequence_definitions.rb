# frozen_string_literal: true

module Inferno
  module IpsProfileDefinitions
    class IpsAllergyintoleranceuvipsSequenceDefinition
      PROFILE_URL = 'http://hl7.org/fhir/uv/ips/StructureDefinition/AllergyIntolerance-uv-ips'
      MUST_SUPPORTS = {
        extensions: [
          {
            id: 'AllergyIntolerance.extension:abatement-datetime',
            url: 'http://hl7.org/fhir/uv/ips/StructureDefinition/abatement-dateTime-uv-ips'
          }
        ],
        slices: [
          {
            name: 'AllergyIntolerance.code.coding:allergyIntoleranceGPSCode',
            path: 'code.coding'
          },
          {
            name: 'AllergyIntolerance.code.coding:absentOrUnknownAllergyIntolerance',
            path: 'code.coding'
          },
          {
            name: 'AllergyIntolerance.onset[x]:onsetDateTime',
            path: 'onset',
            discriminator: {
              type: 'type',
              code: 'DateTime'
            }
          },
          {
            name: 'AllergyIntolerance.reaction.manifestation:allergyIntoleranceReactionManifestationGPSCode',
            path: 'reaction.manifestation'
          }
        ],
        elements: [
          {
            path: 'AllergyIntolerance'
          },
          {
            path: 'clinicalStatus'
          },
          {
            path: 'verificationStatus'
          },
          {
            path: 'type'
          },
          {
            path: 'criticality'
          },
          {
            path: 'code'
          },
          {
            path: 'code.coding'
          },
          {
            path: 'code.text'
          },
          {
            path: 'patient'
          },
          {
            path: 'patient.reference'
          },
          {
            path: 'asserter'
          },
          {
            path: 'reaction'
          },
          {
            path: 'reaction.manifestation'
          },
          {
            path: 'reaction.onset'
          },
          {
            path: 'reaction.severity'
          }
        ]
      }.freeze
      SEARCH_PARAMETERS = [].freeze
    end
  end
end
