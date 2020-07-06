# frozen_string_literal: true

module Inferno
  module Generator
    module ReadTest
      def create_create_test(sequence, interaction)
        test_key = :resource_create
        create_test = {
          tests_that: "Server creates #{sequence[:resource]} resource with the #{sequence[:resource]} create interaction",
          key: test_key,
          index: sequence[:tests].length + 1,
          link: 'http://hl7.org/fhir/us/mcode/index.html',
          description: "A server #{interaction[:expectation]} support the #{sequence[:resource]} create interaction.",
          optional: interaction[:expectation] != 'SHALL'
        }
        create_test[:test_code] = %(
            #{sequence[:resource].downcase}_example = File.read(File.expand_path('./resources/saner/saner-#{sequence[:resource].downcase}-example.json'))
            resource = FHIR.from_contents(#{sequence[:resource].downcase}_example)
            @resource_created_response = validate_create_reply(resource, FHIR::#{sequence[:resource]})
          )
        sequence[:tests] << create_test
      end
    end
  end
end
