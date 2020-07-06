# frozen_string_literal: true

module Inferno
  module Generator
    module ProfileValidationTest
      def create_profile_validation_test(sequence)
        test_key = :validate_resources
        search_test = {
          tests_that: "The #{sequence[:resource]} resource returned from the first Read test is valid according to the profile #{sequence[:profile]}.",
          key: test_key,
          index: sequence[:tests].length + 1,
          description: %()
        }
        search_test[:test_code] = %(
          skip 'No resource found from Read test' unless @resource_found.present?

          test_resource_against_profile('#{sequence[:resource]}', @raw_resource_found, '#{sequence[:profile]}')
        )
        sequence[:tests] << search_test
      end
    end
  end
end
