# frozen_string_literal: true

require 'byebug'

module Inferno
  # FHIRModelsValidator extends BaseValidator to use the validation in fhir_models.
  # It passes the validation off to the correct model version.
  class FHIRModelsValidator < BaseValidator
    def initialize; end

    def validate(resource, fhir_version, profile_url = nil)
      validator_klass = if profile_url
                          Inferno::ValidationUtil.definitions[profile_url]
                        else
                          fhir_version::Definitions.resource_definition(resource.resourceType)
                        end
      errors = validator_klass.validate_resource(resource)
      warnings = validator_klass.warnings

      {
        fatals: [],
        errors: errors,
        warnings: warnings,
        informations: []
      }
    end
  end
end
