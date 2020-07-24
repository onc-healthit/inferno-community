# frozen_string_literal: true

module Inferno
  module Generator
    module InteractionTest
      def create_interaction_test(sequence, interaction)
        return if interaction[:code] == 'read'

        test_key = :"#{interaction[:code]}_interaction"
        interaction_test = {
          tests_that: "Server returns correct #{sequence[:resource]} resource from #{sequence[:resource]} #{interaction[:code]} interaction",
          key: test_key,
          index: sequence[:tests].length + 1,
          link: 'http://hl7.org/fhir/us/mcode/index.html',
          description: "A server #{interaction[:expectation]} support the #{sequence[:resource]} #{interaction[:code]} interaction.",
          optional: interaction[:expectation] != 'SHALL'
        }

        sequence[:tests] << interaction_test
      end
    end
  end
end
