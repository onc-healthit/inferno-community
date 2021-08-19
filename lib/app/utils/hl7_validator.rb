# frozen_string_literal: true

require_relative 'walk'

module Inferno
  # A validator that calls out to the HL7 validator API
  class HL7Validator
    ISSUE_DETAILS_FILTER = [
      %r{^Sub-extension url 'introspect' is not defined by the Extension http://fhir-registry\.smarthealthit\.org/StructureDefinition/oauth-uris$},
      %r{^Sub-extension url 'revoke' is not defined by the Extension http://fhir-registry\.smarthealthit\.org/StructureDefinition/oauth-uris$},
      /^URL value .* does not resolve$/,
      /^vs-1: if Observation\.effective\[x\] is dateTime and has a value then that value shall be precise to the day/, # Invalid invariant in FHIR v4.0.1
      /^us-core-1: Datetime must be at least to day/ # Invalid invariant in US Core v3.1.1
    ].freeze
    @validator_url = nil

    def initialize(validator_url)
      raise ArgumentError, 'Validator URL is unset' if validator_url.blank?

      @validator_url = validator_url
    end

    def validate(resource, fhir_models_klass, profile_url = nil)
      profile_url ||= fhir_models_klass::Definitions.resource_definition(resource.resourceType).url

      Inferno.logger.info("Validating #{resource.resourceType} resource with id #{resource.id}")
      Inferno.logger.info("POST #{@validator_url}/validate?profile=#{profile_url}")

      result = RestClient.post "#{@validator_url}/validate", resource.source_contents, params: { profile: profile_url }
      outcome = fhir_models_klass.from_contents(result.body)

      result = issues_by_severity(outcome.issue)

      id_errors = validate_resource_id(resource)

      result[:errors].concat(id_errors)

      result
    end

    # FHIR validator does not valid Resource.id /^[A-Za-z0-9\-\.]{1,64}$/
    # So Inferno has to check Resource.id against this regex.
    # This should be removed after FHIR validator fix
    def validate_resource_id(resource)
      errors = []

      walk_resource(resource) do |value, meta, path|
        next unless meta['type'] == 'id'
        next unless value.present?

        errors << "#{resource.resourceType}.#{path}: FHIR id value shall match Regex /^[A-Za-z0-9\-\.]{1,64}$/" unless value.match?(/^[A-Za-z0-9\-\.]{1,64}$/)
      end

      errors
    end

    # @return [String] the version of the validator currently being used or nil
    #   if unable to reach the /version endpoint
    def version
      Inferno.logger.info('Fetching validator version')
      Inferno.logger.info("GET #{@validator_url}/version")

      result = RestClient.get "#{@validator_url}/version"
      result.body
    rescue StandardError
      Inferno.logger.error('Unable to reach the /version validator endpoint. Please ensure that the validator is up to date.')
      nil
    end

    private

    def issues_by_severity(issues)
      errors = []
      warnings = []
      information = []

      issues.each do |iss|
        if iss.severity == 'information' || ISSUE_DETAILS_FILTER.any? { |filter| filter.match?(iss&.details&.text) }
          information << issue_message(iss)
        elsif iss.severity == 'warning'
          warnings << issue_message(iss)
        else
          errors << issue_message(iss)
        end
      end

      {
        errors: errors,
        warnings: warnings,
        information: information
      }
    end

    def issue_message(issue)
      location = if issue.respond_to?(:expression)
                   issue&.expression&.join(', ')
                 else
                   issue&.location&.join(', ')
                 end

      "#{location}: #{issue&.details&.text}"
    end
  end
end
