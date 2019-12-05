# frozen_string_literal: true

module Inferno
  # A validator that calls out to the HL7 validator API
  class HL7Validator
    @validator_url = nil

    def initialize(validator_url)
      @validator_url = validator_url
    end

    def validate(resource, fhir_models_klass, profile = nil)
      profile ||= fhir_models_klass::Definitions.resource_definition(resource.resourceType).url
      result = RestClient.post "#{@validator_url}/validate", resource.to_json, params: { profile: profile }
      outcome = fhir_models_klass.from_contents(result.body)
      fatals = issues_by_severity(outcome.issue, 'fatal')
      errors = issues_by_severity(outcome.issue, 'error')
      warnings = issues_by_severity(outcome.issue, 'warning')
      informations = issues_by_severity(outcome.issue, 'information')
      {
        fatals: fatals,
        errors: errors,
        warnings: warnings,
        informations: informations
      }
    end

    private

    def issues_by_severity(issues, severity)
      issues.select { |i| i.severity == severity }
        .map { |iss| "#{iss&.expression&.join(', ')}: #{iss&.details&.text}" }
    end
  end
end
