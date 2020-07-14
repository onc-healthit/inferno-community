# frozen_string_literal: true

module Inferno
  module Generator
    module ReadTest
      def create_update_test(sequence, interaction)
        test_key = :resource_update
        create_test = {
          tests_that: "Server updates #{sequence[:resource]} resource with the #{sequence[:resource]} update interaction",
          key: test_key,
          index: sequence[:tests].length + 1,
          link: 'http://hl7.org/fhir/us/mcode/index.html',
          description: "A server #{interaction[:expectation]} support the #{sequence[:resource]} update interaction.",
          optional: interaction[:expectation] != 'SHALL'
        }
        create_test[:test_code] = %(
            #{sequence[:resource].downcase}_example = File.read(File.expand_path('./resources/mcode/mcode-#{sequence[:resource].downcase}-example.json'))
            resource = FHIR.from_contents(#{sequence[:resource].downcase}_example)
            @resource_updated_response = validate_update_reply(resource, FHIR::#{sequence[:resource]})
          )
        sequence[:tests] << create_test
      end
    end
  end
end
