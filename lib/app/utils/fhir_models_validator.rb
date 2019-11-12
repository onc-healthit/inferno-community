# frozen_string_literal: true

module Inferno
  # FHIRModelsValidator extends BaseValidator to use the validation in fhir_models.
  # It passes the validation off to the correct model version.
  class FHIRModelsValidator < BaseValidator
    def validate(resource, profile_url)
      run_validation(resource, profile_url, get_model_klass)
    end

    private

    def run_validation(resource, profile_url, model_klass)
      begin
        parsed_resource = model_klass.from_contents(resource)
      rescue StandardError => e
        raise ArgumentError, e.message
      end
      raise ArgumentError, 'No resource provided' unless parsed_resource

      if profile_url
        validator_klass = FHIRValidator::ValidationUtil.definitions[profile_url]
      else
        validator_klass = model_klass::Definitions.resource_definition(parsed_resource.resourceType)
      end
      @errors = validator_klass.validate_resource(parsed_resource)
      @warnings = validator_klass.warnings
    end

    def get_model_klass
      # case @version
      #   when 'dstu2'
      #     FHIR::DSTU2
      #   when 'stu3'
      #     FHIR::STU3
      #   when 'r4'
      #     FHIR
      #   end
      FHIR
    end
  end
end
