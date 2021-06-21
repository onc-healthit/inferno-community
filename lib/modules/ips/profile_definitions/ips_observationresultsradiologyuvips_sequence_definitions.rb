# frozen_string_literal: true

module Inferno
  module IpsProfileDefinitions
    class IpsObservationresultsradiologyuvipsSequenceDefinition
      PROFILE_URL = 'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-results-radiology-uv-ips'
      MUST_SUPPORTS = {
        extensions: [
          {
            id: 'Observation.effective[x].extension',
            url: 'http://hl7.org/fhir/StructureDefinition/data-absent-reason'
          }
        ],
        slices: [
          {
            name: 'Observation.category:radiology',
            path: 'category',
            discriminator: {
              type: 'patternCodeableConcept',
              path: '',
              code: 'imaging',
              system: 'http://terminology.hl7.org/CodeSystem/observation-category'
            }
          },
          {
            name: 'Observation.value[x]:valueString',
            path: 'value',
            discriminator: {
              type: 'type',
              code: 'String'
            }
          },
          {
            name: 'Observation.component:observationText',
            path: 'component',
            discriminator: {
              type: 'type',
              code: 'String'
            }
          },
          {
            name: 'Observation.component:observationCode',
            path: 'component',
            discriminator: {
              type: 'type',
              code: 'CodeableConcept'
            }
          },
          {
            name: 'Observation.component:numericQuantityMeasurement',
            path: 'component',
            discriminator: {
              type: 'type',
              code: 'Quantity'
            }
          },
          {
            name: 'Observation.component:numericRangeMeasurement',
            path: 'component',
            discriminator: {
              type: 'type',
              code: 'Range'
            }
          },
          {
            name: 'Observation.component:numericRatioMeasurement',
            path: 'component',
            discriminator: {
              type: 'type',
              code: 'Ratio'
            }
          },
          {
            name: 'Observation.component:numericSampledDataMeasurement',
            path: 'component',
            discriminator: {
              type: 'type',
              code: 'SampledData'
            }
          }
        ],
        elements: [
          {
            path: 'Observation'
          },
          {
            path: 'partOf'
          },
          {
            path: 'status',
            fixed_value: 'final'
          },
          {
            path: 'category'
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
            path: 'effective'
          },
          {
            path: 'performer'
          },
          {
            path: 'value'
          },
          {
            path: 'bodySite'
          },
          {
            path: 'device'
          },
          {
            path: 'hasMember'
          },
          {
            path: 'hasMember.reference'
          },
          {
            path: 'component'
          },
          {
            path: 'component.code'
          },
          {
            path: 'component.value'
          }
        ]
      }.freeze
      SEARCH_PARAMETERS = [].freeze
    end
  end
end
