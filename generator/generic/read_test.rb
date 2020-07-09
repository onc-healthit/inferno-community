# frozen_string_literal: true

module Inferno
  module Generator
    module ReadTest
      def create_read_test(sequence)
        test_key = :resource_read
        read_test = {
          tests_that: "Server returns correct #{sequence[:resource_type]} resource from the #{sequence[:resource_type]} read interaction",
          key: test_key,
          link: '',
          description: "This test will attempt to Reference to #{sequence[:resource]} can be resolved and read."
        }
        read_test[:test_code] = %(
            resource_id = @instance.#{sequence[:resource_type].downcase}_id
            @resource_found = validate_read_reply(FHIR::#{sequence[:resource_type]}.new(id: resource_id), FHIR::#{sequence[:resource_type]})
        )
        sequence[:tests] << read_test
      end
    end
  end
end
