# frozen_string_literal: true

require 'json'

module Inferno
  class ValidationUtil
    def self.get_resource(json, version)
      if version == :dstu2
        FHIR::DSTU2.from_contents(json)
      else
        FHIR.from_contents(json)
      end
    end

    # Cache the Argonaut IG definitions
    validation_packs = File.join('resources', '*', '*.json')

    DEFINITIONS = {}
    RESOURCES = { dstu2: {}, stu3: {}, r4: {} }
    VALUESETS = {}

    VERSION_MAP = { '1.0.2' => :dstu2, '3.0.1' => :stu3, '4.0.0' => :r4 }.freeze

    Dir.glob(validation_packs).each do |definition|
      json = File.read(definition)
      version = VERSION_MAP[JSON.parse(json)['fhirVersion']]
      resource = get_resource(json, version)
      DEFINITIONS[resource.url] = resource
      if resource.resourceType == 'StructureDefinition'
        profiled_type = resource.snapshot.element.first.path # will this always be the first?
        RESOURCES[version][profiled_type] ||= []
        RESOURCES[version][profiled_type] << resource
      elsif resource.resourceType == 'ValueSet'
        VALUESETS[resource.url] = resource
      end
    end

    ARGONAUT_URIS = {
      smoking_status: 'http://fhir.org/guides/argonaut/StructureDefinition/argo-smokingstatus',
      observation_results: 'http://fhir.org/guides/argonaut/StructureDefinition/argo-observationresults',
      vital_signs: 'http://fhir.org/guides/argonaut/StructureDefinition/argo-vitalsigns',
      care_team: 'http://fhir.org/guides/argonaut/StructureDefinition/argo-careteam',
      care_plan: 'http://fhir.org/guides/argonaut/StructureDefinition/argo-careplan'
    }.freeze

    BLUEBUTTON_URIS = {
      carrier: 'https://bluebutton.cms.gov/assets/ig/StructureDefinition-bluebutton-carrier-claim',
      dme: 'https://bluebutton.cms.gov/assets/ig/StructureDefinition-bluebutton-dme-claim',
      hha: 'https://bluebutton.cms.gov/assets/ig/StructureDefinition-bluebutton-hha-claim',
      hospice: 'https://bluebutton.cms.gov/assets/ig/StructureDefinition-bluebutton-hospice-claim',
      inpatient: 'https://bluebutton.cms.gov/assets/ig/StructureDefinition-bluebutton-inpatient-claim',
      outpatient: 'https://bluebutton.cms.gov/assets/ig/StructureDefinition-bluebutton-outpatient-claim',
      pde: 'https://bluebutton.cms.gov/assets/ig/StructureDefinition-bluebutton-pde-claim',
      snf: 'https://bluebutton.cms.gov/assets/ig/StructureDefinition-bluebutton-snf-claim'
    }.freeze

    US_CORE_R4_URIS = {
      smoking_status: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-smokingstatus',
      diagnostic_report_lab: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-lab',
      diagnostic_report_note: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-note',
      lab_results: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-observation-lab',
      pediatric_bmi_age: 'http://hl7.org/fhir/us/core/StructureDefinition/pediatric-bmi-for-age',
      pediatric_weight_height: 'http://hl7.org/fhir/us/core/StructureDefinition/pediatric-weight-for-height',
      pulse_oximetry: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-pulse-oximetry'
    }.freeze

    def self.guess_profile(resource, version)
      # if the profile is given, we don't need to guess
      if resource&.meta&.profile&.present?
        resource.meta.profile.each do |uri|
          return DEFINITIONS[uri] if DEFINITIONS[uri]
        end
      end

      if version == :dstu2
        guess_dstu2_profile(resource)
      elsif version == :stu3
        guess_stu3_profile(resource)
      elsif version == :r4
        guess_r4_profile(resource)
      end
    end

    def self.guess_dstu2_profile(resource)
      return if resource.blank?

      candidates = RESOURCES[:dstu2][resource.resourceType]
      return if candidates.blank?

      # Special cases where there are multiple profiles per Resource type
      if resource.resourceType == 'Observation'
        if resource&.code&.coding&.any? { |coding| coding&.code == '72166-2' }
          return DEFINITIONS[ARGONAUT_URIS[:smoking_status]]
        elsif resource&.category&.coding&.any? { |coding| coding&.code == 'laboratory' }
          return DEFINITIONS[ARGONAUT_URIS[:observation_results]]
        elsif resource&.category&.coding&.any? { |coding| coding&.code == 'vital-signs' }
          return DEFINITIONS[ARGONAUT_URIS[:vital_signs]]
        end
      elsif resource.resourceType == 'CarePlan'
        if resource&.category&.any? { |category| category&.coding&.any? { |coding| coding&.code == 'careteam' } }
          return DEFINITIONS[ARGONAUT_URIS[:care_team]]
        else
          return DEFINITIONS[ARGONAUT_URIS[:care_plan]]
        end
      end

      # Otherwise, guess the first profile that matches on resource type
      candidates.first
    end

    def self.guess_stu3_profile(resource)
      return if resource.blank?

      candidates = RESOURCES[:stu3][resource.resourceType]
      return if candidates.blank?

      # Special cases where there are multiple profiles per Resource type
      if resource.resourceType == 'ExplanationOfBenefit'
        if resource&.type&.coding&.any? { |coding| coding.code == 'CARRIER' }
          return DEFINITIONS[BLUEBUTTON_URIS[:carrier]]
        elsif resource&.type&.coding&.any? { |coding| coding.code == 'DME' }
          return DEFINITIONS[BLUEBUTTON_URIS[:dme]]
        elsif resource&.type&.coding&.any? { |coding| coding.code == 'HHA' }
          return DEFINITIONS[BLUEBUTTON_URIS[:hha]]
        elsif resource&.type&.coding&.any? { |coding| coding.code == 'HOSPICE' }
          return DEFINITIONS[BLUEBUTTON_URIS[:hospice]]
        elsif resource&.type&.coding&.any? { |coding| coding.code == 'INPATIENT' }
          return DEFINITIONS[BLUEBUTTON_URIS[:inpatient]]
        elsif resource&.type&.coding&.any? { |coding| coding.code == 'OUTPATIENT' }
          return DEFINITIONS[BLUEBUTTON_URIS[:outpatient]]
        elsif resource&.type&.coding&.any? { |coding| coding.code == 'PDE' }
          return DEFINITIONS[BLUEBUTTON_URIS[:pde]]
        elsif resource&.type&.coding&.any? { |coding| coding.code == 'SNF' }
          return DEFINITIONS[BLUEBUTTON_URIS[:snf]]
        end
      end

      # Otherwise, guess the first profile that matches on resource type
      candidates.first
    end

    def self.guess_r4_profile(resource)
      return if resource.blank?

      candidates = RESOURCES[:r4][resource.resourceType]
      return if candidates.blank?

      if resource.resourceType == 'Observation'
        return DEFINITIONS[US_CORE_R4_URIS[:smoking_status]] if resource&.code&.coding&.any? { |coding| coding&.code == '72166-2' }

        return DEFINITIONS[US_CORE_R4_URIS[:lab_results]] if resource&.category&.first&.coding&.any? { |coding| coding&.code == 'laboratory' }

        return DEFINITIONS[US_CORE_R4_URIS[:pediatric_bmi_age]] if resource&.code&.coding&.any? { |coding| coding&.code == '59576-9' }

        return DEFINITIONS[US_CORE_R4_URIS[:pediatric_weight_height]] if resource&.code&.coding&.any? { |coding| coding&.code == '77606-2' }

        return DEFINITIONS[US_CORE_R4_URIS[:pulse_oximetry]] if resource&.code&.coding&.any? { |coding| coding&.code == '59408-5' }
      elsif resource.resourceType == 'DiagnosticReport'
        return DEFINITIONS[US_CORE_R4_URIS[:diagnostic_report_lab]] if resource&.category&.first&.coding&.any? { |coding| coding&.code == 'LAB' }

        return DEFINITIONS[US_CORE_R4_URIS[:diagnostic_report_note]]
      end

      candidates.first
    end
  end
end
