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
      profile_url ||= fhir_models_klass::Definitions.resource_definition(resource.resourceType).url

      Inferno.logger.info("Validating #{resource.resourceType} resource with id #{resource.id}")
      Inferno.logger.info("POST #{@validator_url}/validate?profile=#{profile_url}")

      result = RestClient.post "#{@validator_url}/validate", resource.to_json, params: { profile: profile_url }
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

    # @param [String] id the NPM package ID of the IG to be loaded into the validator
    # @return [Array<String>] a list of profiles belonging to the loaded IG
    def load_ig_by_id(id)
      Inferno.logger.info("Loading IG with id #{id} from packages.fhir.org")
      Inferno.logger.info("PUT #{@validator_url}/igs/#{id}")

      result = RestClient.put "#{@validator_url}/igs/#{id}", {}
      JSON.parse(result.body)
    end

    # @param [String] package_tgz the package.tgz contents of the IG to be loaded into the validator
    # @return [Array<String>] a list of profiles belonging to the loaded IG
    def load_ig_by_tgz(package_tgz)
      Inferno.logger.info('Loading custom IG from a package.tgz')
      Inferno.logger.info("POST #{@validator_url}/igs")

      result = RestClient.post "#{@validator_url}/igs", package_tgz, content_encoding: 'gzip'
      JSON.parse(result.body)
    end

    private

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
