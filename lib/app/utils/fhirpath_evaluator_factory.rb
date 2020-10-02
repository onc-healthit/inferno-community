# frozen_string_literal: true

require_relative 'fhirpath_evaluator'
require_relative 'basic_fhirpath_evaluator'

module Inferno
  class App
    module FHIRPathEvaluatorFactory
      def self.new_evaluator(selected_evaluator, external_evaluator_url)
        return Inferno::BasicFHIRPathEvaluator.new if ENV['RACK_ENV'] == 'test'

        case selected_evaluator
        when 'internal'
          Inferno::BasicFHIRPathEvaluator.new
        when 'external'
          Inferno::FHIRPathEvaluator.new(external_evaluator_url)
        end
      end
    end
  end
end
