# frozen_string_literal: true

module Inferno
  module IpsProfileDefinitions
    class IpsMedicationipsSequenceDefinition
      PROFILE_URL = 'http://hl7.org/fhir/uv/ips/StructureDefinition/Medication-uv-ips'
      MUST_SUPPORTS = {
        extensions: [],
        slices: [
          {
            name: 'Medication.code.coding:atcClass',
            path: 'code.coding'
          },
          {
            name: 'Medication.code.coding:snomed',
            path: 'code.coding'
          },
          {
            name: 'Medication.ingredient.item[x]:itemCodeableConcept',
            path: 'ingredient.item[x]',
            discriminator: {
              type: 'type',
              code: 'CodeableConcept'
            }
          }
        ],
        elements: [
          {
            path: 'Medication'
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
            path: 'form'
          },
          {
            path: 'ingredient'
          },
          {
            path: 'ingredient.item[x].coding'
          },
          {
            path: 'ingredient.item[x].text'
          },
          {
            path: 'ingredient.strength'
          }
        ]
      }.freeze
      SEARCH_PARAMETERS = [].freeze
    end
  end
end
