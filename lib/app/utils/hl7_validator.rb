# frozen_string_literal: true

require 'json'

module Inferno
  # A validator that calls out to the HL7 validator API
  class HL7Validator
    @validator_url = nil

    def initialize(validator_url)
      raise ArgumentError, 'Validator URL is unset' if validator_url.blank?

      @validator_url = validator_url
    end

    def validate(resource, fhir_models_klass, profile_url = nil)
      if resource.is_a? String
        profile_url ||= fhir_models_klass::Definitions.resource_definition(JSON.parse(resource)['resourceType']).url
        validate_json_against_profile(resource, fhir_models_klass, profile_url)
      else
        profile_url ||= fhir_models_klass::Definitions.resource_definition(resource.resourceType).url

        Inferno.logger.info("Validating #{resource.resourceType} resource with id #{resource.id}")
        Inferno.logger.info("POST #{@validator_url}/validate?profile=#{profile_url}")

        validate_json_against_profile(resource.to_json, fhir_models_klass, profile_url)
      end
    end

    private

    def validate_json_against_profile(resource, fhir_models_klass, profile)
      result = RestClient.post "#{@validator_url}/validate", resource, params: { profile: profile }
      outcome = fhir_models_klass.from_contents(result.body)
      fatals = issues_by_severity(outcome.issue, 'fatal')
      errors = issues_by_severity(outcome.issue, 'error')
      warnings = issues_by_severity(outcome.issue, 'warning')
      information = issues_by_severity(outcome.issue, 'information')
      {
        errors: fatals.concat(errors).reject(&:empty?),
        warnings: warnings,
        information: information
      }
    end

    def issues_by_severity(issues, severity)
      issues.select { |i| i.severity == severity }
        .map { |iss| "#{issue_location(iss)}: #{iss&.details&.text}" }
    end

    def issue_location(issue)
      if issue.respond_to?(:expression)
        issue&.expression&.join(', ')
      else
        issue&.location&.join(', ')
      end
    end
  end
end
