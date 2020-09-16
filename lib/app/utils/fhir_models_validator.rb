# frozen_string_literal: true

module Inferno
  # FHIRModelsValidator extends BaseValidator to use the validation in fhir_models.
  # It passes the validation off to the correct model version.
  class FHIRModelsValidator
    def validate(resource, _fhir_models_klass, profile_url = nil)
      if profile_url
        validator_klass = Inferno::ValidationUtil.definitions[profile_url]
        errors = validator_klass.validate_resource(resource)
        warnings = validator_klass.warnings
      else
        errors = resource.validate.collect { |k, v| "#{k}: #{v}" }
        warnings = []
      end

      {
        errors: errors.reject(&:empty?),
        warnings: warnings.reject(&:empty?),
        # This key is included for compatibility with the HL7 Validator class
        information: []
      }
    end
  end
end
