# frozen_string_literal: true

module Inferno
  module IpsProfileDefinitions
    class IpsObservationresultspathologyuvipsSequenceDefinition
      PROFILE_URL = 'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-results-pathology-uv-ips'
      MUST_SUPPORTS = {
        extensions: [
          {
            id: 'Observation.effective[x].extension',
            url: 'http://hl7.org/fhir/StructureDefinition/data-absent-reason'
          }
        ],
        slices: [
          {
            name: 'Observation.category:laboratory',
            path: 'category',
            discriminator: {
              type: 'patternCodeableConcept',
              path: '',
              code: 'laboratory',
              system: 'http://terminology.hl7.org/CodeSystem/observation-category'
            }
          },
          {
            name: 'Observation.value[x]:valueString',
            path: 'value[x]',
            discriminator: {
              type: 'type',
              code: 'String'
            }
          },
          {
            name: 'Observation.value[x]:valueRange',
            path: 'value[x]',
            discriminator: {
              type: 'type',
              code: 'Range'
            }
          },
          {
            name: 'Observation.value[x]:valueRatio',
            path: 'value[x]',
            discriminator: {
              type: 'type',
              code: 'Ratio'
            }
          },
          {
            name: 'Observation.value[x]:valueTime',
            path: 'value[x]',
            discriminator: {
              type: 'type',
              code: 'Time'
            }
          },
          {
            name: 'Observation.value[x]:valueDateTime',
            path: 'value[x]',
            discriminator: {
              type: 'type',
              code: 'DateTime'
            }
          },
          {
            name: 'Observation.value[x]:valuePeriod',
            path: 'value[x]',
            discriminator: {
              type: 'type',
              code: 'Period'
            }
          },
          {
            name: 'Observation.value[x]:valueQuantity',
            path: 'value[x]',
            discriminator: {
              type: 'type',
              code: 'Quantity'
            }
          },
          {
            name: 'Observation.value[x]:valueCodeableConcept',
            path: 'value[x]',
            discriminator: {
              type: 'type',
              code: 'CodeableConcept'
            }
          }
        ],
        elements: [
          {
            path: 'Observation'
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
            path: 'effective[x]'
          },
          {
            path: 'performer'
          },
          {
            path: 'value[x]'
          },
          {
            path: 'specimen'
          },
          {
            path: 'hasMember'
          },
          {
            path: 'hasMember.reference'
          },
          {
            path: 'component'
          }
        ]
      }.freeze
      SEARCH_PARAMETERS = [].freeze
    end
  end
end
