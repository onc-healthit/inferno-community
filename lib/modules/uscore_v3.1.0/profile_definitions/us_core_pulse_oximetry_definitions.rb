# frozen_string_literal: true

module Inferno
  module USCore310ProfileDefinitions
    class USCore310PulseOximetrySequenceDefinitions
      MUST_SUPPORTS = {
        extensions: [],
        slices: [
          {
            name: 'Observation.category:VSCat',
            path: 'category',
            discriminator: {
              type: 'value',
              values: [
                {
                  path: 'coding.code',
                  value: 'vital-signs'
                },
                {
                  path: 'coding.system',
                  value: 'http://terminology.hl7.org/CodeSystem/observation-category'
                }
              ]
            }
          },
          {
            name: 'Observation.code.coding:PulseOx',
            path: 'code.coding',
            discriminator: {
              type: 'value',
              values: [
                {
                  path: 'code',
                  value: '59408-5'
                },
                {
                  path: 'system',
                  value: 'http://loinc.org'
                }
              ]
            }
          },
          {
            name: 'Observation.value[x]:valueQuantity',
            path: 'value',
            discriminator: {
              type: 'type',
              code: 'Quantity'
            }
          },
          {
            name: 'Observation.component:FlowRate',
            path: 'component',
            discriminator: {
              type: 'patternCodeableConcept',
              path: 'code',
              code: '3151-8',
              system: 'http://loinc.org'
            }
          },
          {
            name: 'Observation.component:Concentration',
            path: 'component',
            discriminator: {
              type: 'patternCodeableConcept',
              path: 'code',
              code: '3150-0',
              system: 'http://loinc.org'
            }
          }
        ],
        elements: [
          {
            path: 'status'
          },
          {
            path: 'category'
          },
          {
            path: 'category.coding'
          },
          {
            path: 'category.coding.system',
            fixed_value: 'http://terminology.hl7.org/CodeSystem/observation-category'
          },
          {
            path: 'category.coding.code',
            fixed_value: 'vital-signs'
          },
          {
            path: 'code'
          },
          {
            path: 'code.coding'
          },
          {
            path: 'code.coding.system',
            fixed_value: 'http://loinc.org'
          },
          {
            path: 'code.coding.code',
            fixed_value: '59408-5'
          },
          {
            path: 'subject'
          },
          {
            path: 'effective'
          },
          {
            path: 'value'
          },
          {
            path: 'value.value'
          },
          {
            path: 'value.unit'
          },
          {
            path: 'value.system',
            fixed_value: 'http://unitsofmeasure.org'
          },
          {
            path: 'value.code',
            fixed_value: '%'
          },
          {
            path: 'dataAbsentReason'
          },
          {
            path: 'component'
          },
          {
            path: 'component.code'
          },
          {
            path: 'component.code.coding.code',
            fixed_value: '3151-8'
          },
          {
            path: 'component.value.system',
            fixed_value: 'http://unitsofmeasure.org'
          },
          {
            path: 'component.value.code',
            fixed_value: 'l/min'
          },
          {
            path: 'component.code.coding.code',
            fixed_value: '3150-0'
          },
          {
            path: 'component.value'
          },
          {
            path: 'component.value.value'
          },
          {
            path: 'component.value.unit'
          },
          {
            path: 'component.value.system',
            fixed_value: 'http://unitsofmeasure.org'
          },
          {
            path: 'component.value.code',
            fixed_value: '%'
          },
          {
            path: 'component.dataAbsentReason'
          }
        ]
      }.freeze

      DELAYED_REFERENCES = [].freeze

      BINDINGS = [
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/observation-status',
          path: 'status'
        },
        {
          type: 'CodeableConcept',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/ValueSet/observation-vitalsignresult',
          path: 'code'
        },
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/quantity-comparator',
          path: 'value.comparator'
        },
        {
          type: 'CodeableConcept',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/ValueSet/data-absent-reason',
          path: 'dataAbsentReason'
        },
        {
          type: 'CodeableConcept',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/ValueSet/observation-interpretation',
          path: 'interpretation'
        },
        {
          type: 'CodeableConcept',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/ValueSet/observation-vitalsignresult',
          path: 'component.code'
        },
        {
          type: 'CodeableConcept',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/ValueSet/data-absent-reason',
          path: 'component.dataAbsentReason'
        },
        {
          type: 'CodeableConcept',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/ValueSet/observation-interpretation',
          path: 'component.interpretation'
        },
        {
          type: 'CodeableConcept',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/ValueSet/observation-vitalsignresult',
          path: 'component.code'
        },
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/quantity-comparator',
          path: 'component.value.comparator'
        },
        {
          type: 'CodeableConcept',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/ValueSet/data-absent-reason',
          path: 'component.dataAbsentReason'
        },
        {
          type: 'CodeableConcept',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/ValueSet/observation-interpretation',
          path: 'component.interpretation'
        },
        {
          type: 'CodeableConcept',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/ValueSet/observation-vitalsignresult',
          path: 'component.code'
        },
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/quantity-comparator',
          path: 'component.value.comparator'
        },
        {
          type: 'CodeableConcept',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/ValueSet/data-absent-reason',
          path: 'component.dataAbsentReason'
        },
        {
          type: 'CodeableConcept',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/ValueSet/observation-interpretation',
          path: 'component.interpretation'
        }
      ].freeze
    end
  end
end
