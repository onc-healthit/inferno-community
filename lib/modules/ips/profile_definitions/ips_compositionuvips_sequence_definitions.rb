# frozen_string_literal: true

module Inferno
  module IpsProfileDefinitions
    class IpsCompositionuvipsSequenceDefinition
      PROFILE_URL = 'http://hl7.org/fhir/uv/ips/StructureDefinition/Composition-uv-ips'
      MUST_SUPPORTS = {
        extensions: [],
        slices: [
          {
            name: 'Composition.event:careProvisioningEvent',
            path: 'event',
            discriminator: {
              type: 'patternCodeableConcept',
              path: 'code',
              code: 'PCPR',
              system: 'http://terminology.hl7.org/CodeSystem/v3-ActClass'
            }
          },
          {
            name: 'Composition.section:sectionMedications',
            path: 'section',
            discriminator: {
              type: 'patternCodeableConcept',
              path: 'code',
              code: '10160-0',
              system: 'http://loinc.org'
            }
          },
          {
            name: 'Composition.section:sectionMedications.entry:medicationStatement',
            path: 'section.entry'
          },
          {
            name: 'Composition.section:sectionAllergies',
            path: 'section',
            discriminator: {
              type: 'patternCodeableConcept',
              path: 'code',
              code: '48765-2',
              system: 'http://loinc.org'
            }
          },
          {
            name: 'Composition.section:sectionAllergies.entry:allergyOrIntolerance',
            path: 'section.entry'
          },
          {
            name: 'Composition.section:sectionProblems',
            path: 'section',
            discriminator: {
              type: 'patternCodeableConcept',
              path: 'code',
              code: '11450-4',
              system: 'http://loinc.org'
            }
          },
          {
            name: 'Composition.section:sectionProblems.entry:problem',
            path: 'section.entry'
          },
          {
            name: 'Composition.section:sectionProceduresHx',
            path: 'section',
            discriminator: {
              type: 'patternCodeableConcept',
              path: 'code',
              code: '47519-4',
              system: 'http://loinc.org'
            }
          },
          {
            name: 'Composition.section:sectionProceduresHx.entry:procedure',
            path: 'section.entry'
          },
          {
            name: 'Composition.section:sectionImmunizations',
            path: 'section',
            discriminator: {
              type: 'patternCodeableConcept',
              path: 'code',
              code: '11369-6',
              system: 'http://loinc.org'
            }
          },
          {
            name: 'Composition.section:sectionImmunizations.entry:immunization',
            path: 'section.entry'
          },
          {
            name: 'Composition.section:sectionMedicalDevices',
            path: 'section',
            discriminator: {
              type: 'patternCodeableConcept',
              path: 'code',
              code: '46264-8',
              system: 'http://loinc.org'
            }
          },
          {
            name: 'Composition.section:sectionMedicalDevices.entry:deviceStatement',
            path: 'section.entry'
          },
          {
            name: 'Composition.section:sectionResults',
            path: 'section',
            discriminator: {
              type: 'patternCodeableConcept',
              path: 'code',
              code: '30954-2',
              system: 'http://loinc.org'
            }
          },
          {
            name: 'Composition.section:sectionResults.entry:results-observation',
            path: 'section.entry'
          },
          {
            name: 'Composition.section:sectionResults.entry:results-diagnosticReport',
            path: 'section.entry'
          },
          {
            name: 'Composition.section:sectionVitalSigns.entry:vitalSign',
            path: 'section.entry'
          },
          {
            name: 'Composition.section:sectionPastIllnessHx.entry:pastProblem',
            path: 'section.entry'
          },
          {
            name: 'Composition.section:sectionFunctionalStatus.entry:disability',
            path: 'section.entry'
          },
          {
            name: 'Composition.section:sectionFunctionalStatus.entry:functionalAssessment',
            path: 'section.entry'
          },
          {
            name: 'Composition.section:sectionSocialHistory.entry:smokingTobaccoUse',
            path: 'section.entry'
          },
          {
            name: 'Composition.section:sectionSocialHistory.entry:alcoholUse',
            path: 'section.entry'
          },
          {
            name: 'Composition.section:sectionPregnancyHx.entry:pregnancyStatus',
            path: 'section.entry'
          },
          {
            name: 'Composition.section:sectionPregnancyHx.entry:pregnancyOutcomeSummary',
            path: 'section.entry'
          },
          {
            name: 'Composition.section:sectionAdvanceDirectives.entry:advanceDirectivesConsent',
            path: 'section.entry'
          }
        ],
        elements: [
          {
            path: 'Composition'
          },
          {
            path: 'text'
          },
          {
            path: 'status'
          },
          {
            path: 'type.coding.code',
            fixed_value: '60591-5'
          },
          {
            path: 'subject'
          },
          {
            path: 'subject.reference'
          },
          {
            path: 'date'
          },
          {
            path: 'author'
          },
          {
            path: 'title'
          },
          {
            path: 'attester'
          },
          {
            path: 'attester.mode'
          },
          {
            path: 'attester.time'
          },
          {
            path: 'attester.party'
          },
          {
            path: 'event'
          },
          {
            path: 'event.code.coding.code',
            fixed_value: 'PCPR'
          },
          {
            path: 'event.period'
          },
          {
            path: 'section'
          },
          {
            path: 'section.title'
          },
          {
            path: 'section.code'
          },
          {
            path: 'section.text'
          },
          {
            path: 'section.entry'
          }
        ]
      }.freeze
      SEARCH_PARAMETERS = [].freeze
    end
  end
end
