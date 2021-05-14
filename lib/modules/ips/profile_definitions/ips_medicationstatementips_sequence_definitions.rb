# frozen_string_literal: true

module Inferno
  module IpsProfileDefinitions
    class IpsMedicationstatementipsSequenceDefinition
      PROFILE_URL = 'http://hl7.org/fhir/uv/ips/StructureDefinition/MedicationStatement-uv-ips'
      MUST_SUPPORTS = {
        extensions: [
          {
            id: 'MedicationStatement.effective[x].extension',
            url: 'http://hl7.org/fhir/StructureDefinition/data-absent-reason'
          }
        ],
        slices: [
          {
            name: 'MedicationStatement.medication[x]:medicationReference',
            path: 'medication',
            discriminator: {
              type: 'type',
              code: 'Reference'
            }
          },
          {
            name: 'MedicationStatement.medication[x]:medicationCodeableConcept',
            path: 'medication',
            discriminator: {
              type: 'type',
              code: 'CodeableConcept'
            }
          }
        ],
        elements: [
          {
            path: 'MedicationStatement'
          },
          {
            path: 'status'
          },
          {
            path: 'medication'
          },
          {
            path: 'subject'
          },
          {
            path: 'subject.reference'
          },
          {
            path: 'effective'
          },
          {
            path: 'informationSource'
          },
          {
            path: 'dosage'
          },
          {
            path: 'dosage.text'
          },
          {
            path: 'dosage.timing'
          },
          {
            path: 'dosage.route'
          }
        ]
      }.freeze
      SEARCH_PARAMETERS = [].freeze
    end
  end
end
