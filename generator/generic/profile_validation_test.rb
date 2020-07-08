# frozen_string_literal: true

module Inferno
    module Generator
      module ProfileValidationTest
        def create_profile_validation_test(sequence)
          test_key = :resource_validate_profile
          profiel_validation_test = {
            tests_that: "Server returns #{sequence[:resource_type]} resource that matches the #{sequence[:title]} profile",
            key: test_key,
            link: '',
            description: "This test will validate that the #{sequence[:resource_type]} resource returned from the server matches the #{sequence[:title]} profile."
          }
          profiel_validation_test[:test_code] = %(
              skip 'No resource found from Read test' unless @resource_found.present?
              test_resource_against_profile('#{sequence[:resource_type]}', @resource_found, '#{sequence[:url]}')
          )
          sequence[:tests] << profiel_validation_test
        end
      end
    end
  end