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
            path: 'section.entry',
            discriminator: {
              type: 'profile',
              path: '',
              profile: [
                'http://hl7.org/fhir/uv/ips/StructureDefinition/MedicationStatement-uv-ips'
              ]
            }
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
            path: 'section.entry',
            discriminator: {
              type: 'profile',
              path: '',
              profile: [
                'http://hl7.org/fhir/uv/ips/StructureDefinition/AllergyIntolerance-uv-ips'
              ]
            }
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
            path: 'section.entry',
            discriminator: {
              type: 'profile',
              path: '',
              profile: [
                'http://hl7.org/fhir/uv/ips/StructureDefinition/Condition-uv-ips'
              ]
            }
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
            path: 'section.entry',
            discriminator: {
              type: 'profile',
              path: '',
              profile: [
                'http://hl7.org/fhir/uv/ips/StructureDefinition/Procedure-uv-ips'
              ]
            }
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
            path: 'section.entry',
            discriminator: {
              type: 'profile',
              path: '',
              profile: [
                'http://hl7.org/fhir/uv/ips/StructureDefinition/Immunization-uv-ips'
              ]
            }
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
            path: 'section.entry',
            discriminator: {
              type: 'profile',
              path: '',
              profile: [
                'http://hl7.org/fhir/uv/ips/StructureDefinition/DeviceUseStatement-uv-ips'
              ]
            }
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
            path: 'section.entry',
            discriminator: {
              type: 'profile',
              path: '',
              profile: [
                'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-results-laboratory-uv-ips',
                'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-results-pathology-uv-ips',
                'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-results-radiology-uv-ips',
                'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-results-uv-ips'
              ]
            }
          },
          {
            name: 'Composition.section:sectionResults.entry:results-diagnosticReport',
            path: 'section.entry',
            discriminator: {
              type: 'profile',
              path: '',
              profile: [
                'http://hl7.org/fhir/uv/ips/StructureDefinition/DiagnosticReport-uv-ips'
              ]
            }
          },
          {
            name: 'Composition.section:sectionVitalSigns',
            path: 'section',
            discriminator: {
              type: 'patternCodeableConcept',
              path: 'code',
              code: '8716-3',
              system: 'http://loinc.org'
            }
          },
          {
            name: 'Composition.section:sectionVitalSigns.entry:vitalSign',
            path: 'section.entry',
            discriminator: {
              type: 'profile',
              path: '',
              profile: [
                'http://hl7.org/fhir/StructureDefinition/vitalsigns'
              ]
            }
          },
          {
            name: 'Composition.section:sectionPastIllnessHx',
            path: 'section',
            discriminator: {
              type: 'patternCodeableConcept',
              path: 'code',
              code: '11348-0',
              system: 'http://loinc.org'
            }
          },
          {
            name: 'Composition.section:sectionPastIllnessHx.entry:pastProblem',
            path: 'section.entry',
            discriminator: {
              type: 'profile',
              path: '',
              profile: [
                'http://hl7.org/fhir/uv/ips/StructureDefinition/Condition-uv-ips'
              ]
            }
          },
          {
            name: 'Composition.section:sectionFunctionalStatus',
            path: 'section',
            discriminator: {
              type: 'patternCodeableConcept',
              path: 'code',
              code: '47420-5',
              system: 'http://loinc.org'
            }
          },
          {
            name: 'Composition.section:sectionFunctionalStatus.entry:disability',
            path: 'section.entry',
            discriminator: {
              type: 'profile',
              path: '',
              profile: [
                'http://hl7.org/fhir/uv/ips/StructureDefinition/Condition-uv-ips'
              ]
            }
          },
          {
            name: 'Composition.section:sectionFunctionalStatus.entry:functionalAssessment',
            path: 'section.entry',
            discriminator: {
              type: 'profile',
              path: '',
              profile: [
                'http://hl7.org/fhir/StructureDefinition/ClinicalImpression'
              ]
            }
          },
          {
            name: 'Composition.section:sectionPlanOfCare',
            path: 'section',
            discriminator: {
              type: 'patternCodeableConcept',
              path: 'code',
              code: '18776-5',
              system: 'http://loinc.org'
            }
          },
          {
            name: 'Composition.section:sectionSocialHistory',
            path: 'section',
            discriminator: {
              type: 'patternCodeableConcept',
              path: 'code',
              code: '29762-2',
              system: 'http://loinc.org'
            }
          },
          {
            name: 'Composition.section:sectionSocialHistory.entry:smokingTobaccoUse',
            path: 'section.entry',
            discriminator: {
              type: 'profile',
              path: '',
              profile: [
                'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-tobaccouse-uv-ips'
              ]
            }
          },
          {
            name: 'Composition.section:sectionSocialHistory.entry:alcoholUse',
            path: 'section.entry',
            discriminator: {
              type: 'profile',
              path: '',
              profile: [
                'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-alcoholuse-uv-ips'
              ]
            }
          },
          {
            name: 'Composition.section:sectionPregnancyHx',
            path: 'section',
            discriminator: {
              type: 'patternCodeableConcept',
              path: 'code',
              code: '10162-6',
              system: 'http://loinc.org'
            }
          },
          {
            name: 'Composition.section:sectionPregnancyHx.entry:pregnancyStatus',
            path: 'section.entry',
            discriminator: {
              type: 'profile',
              path: '',
              profile: [
                'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-pregnancy-status-uv-ips'
              ]
            }
          },
          {
            name: 'Composition.section:sectionPregnancyHx.entry:pregnancyOutcomeSummary',
            path: 'section.entry',
            discriminator: {
              type: 'profile',
              path: '',
              profile: [
                'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-pregnancy-outcome-uv-ips'
              ]
            }
          },
          {
            name: 'Composition.section:sectionAdvanceDirectives',
            path: 'section',
            discriminator: {
              type: 'patternCodeableConcept',
              path: 'code',
              code: '42348-3',
              system: 'http://loinc.org'
            }
          },
          {
            name: 'Composition.section:sectionAdvanceDirectives.entry:advanceDirectivesConsent',
            path: 'section.entry',
            discriminator: {
              type: 'profile',
              path: '',
              profile: [
                'http://hl7.org/fhir/StructureDefinition/Consent'
              ]
            }
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
            path: 'custodian'
          },
          {
            path: 'relatesTo'
          },
          {
            path: 'relatesTo.code'
          },
          {
            path: 'relatesTo.target'
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
            path: 'section.code.coding.code',
            fixed_value: '10160-0'
          },
          {
            path: 'section.code.coding.code',
            fixed_value: '48765-2'
          },
          {
            path: 'section.code.coding.code',
            fixed_value: '11450-4'
          },
          {
            path: 'section.code.coding.code',
            fixed_value: '47519-4'
          },
          {
            path: 'section.code.coding.code',
            fixed_value: '11369-6'
          },
          {
            path: 'section.code.coding.code',
            fixed_value: '46264-8'
          },
          {
            path: 'section.code.coding.code',
            fixed_value: '30954-2'
          },
          {
            path: 'section.code.coding.code',
            fixed_value: '8716-3'
          },
          {
            path: 'section.code.coding.code',
            fixed_value: '11348-0'
          },
          {
            path: 'section.code.coding.code',
            fixed_value: '47420-5'
          },
          {
            path: 'section.code.coding.code',
            fixed_value: '18776-5'
          },
          {
            path: 'section.code.coding.code',
            fixed_value: '29762-2'
          },
          {
            path: 'section.code.coding.code',
            fixed_value: '10162-6'
          },
          {
            path: 'section.title'
          },
          {
            path: 'section.code.coding.code',
            fixed_value: '42348-3'
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
