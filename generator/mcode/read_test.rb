# frozen_string_literal: true

module Inferno
  module Generator
    module ReadTest
      def create_read_test(sequence)
        test_key = :resource_read
        read_test = {
          tests_that: "Server returns correct #{sequence[:resource]} resource from the #{sequence[:resource]} read interaction",
          key: test_key,
          index: sequence[:tests].length + 1,
          link: 'http://hl7.org/fhir/us/mcode/index.html',
          description: "Tests whether the #{sequence[:resource]} with the provided id can be resolved and read."
        }
        read_test[:test_code] = %(
            resource_id = @instance.#{sequence[:name].downcase}_id
            read_response = validate_read_reply(FHIR::#{sequence[:resource]}.new(id: resource_id), FHIR::#{sequence[:resource]})
            @resource_found = read_response.resource
            @raw_resource_found = read_response.response[:body]
        )
        sequence[:tests] << read_test
      end
    end
  end
end
