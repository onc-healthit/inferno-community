# frozen_string_literal: true

require_relative 'base_validator'
require_relative 'fhir_models_validator'
require_relative 'grahame_validator'

module Inferno
  class App
    module ResourceValidatorFactory
      def self.new_validator(selected_validator, external_validator_url)
        case selected_validator
        when 'internal'
          Inferno::FHIRModelsValidator.new
        when 'external'
          Inferno::GrahameValidator.new(external_validator_url)
        end
      end
    end
  end
end
