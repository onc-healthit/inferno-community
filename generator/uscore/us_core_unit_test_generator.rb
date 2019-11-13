# frozen_string_literal: true

module Inferno
  module Generator
    class USCoreUnitTestGenerator
      def tests
        @tests ||= Hash.new { |hash, key| hash[key] = [] }
      end

      def generate(sequence, path)
        template = ERB.new(File.read(File.join(__dir__, 'templates', 'unit_tests', 'unit_test.rb.erb')))
        class_name = sequence[:class_name]
        unit_tests = template.result_with_hash(
          class_name: class_name,
          tests: tests[class_name]
        )

        test_path = File.join(path, 'test')
        FileUtils.mkdir_p(test_path) unless File.directory?(test_path)

        file_name = File.join(test_path, "#{sequence[:name].downcase}_test.rb")
        File.write(file_name, unit_tests)
      end

      def generate_authorization_test(key:, resource_type:, search_params:, class_name:)
        template = ERB.new(File.read(File.join(__dir__, 'templates', 'unit_tests', 'authorization_unit_test.rb.erb')))
        test = template.result_with_hash(
          key: key,
          resource_type: resource_type,
          search_param_string: search_params_to_string(search_params)
        )
        tests[class_name] << test
      end

      def search_params_to_string(search_params)
        search_params.map do |param, value|
          if value.start_with? 'get_value_for_search_param'
            path = value.match(/'(\w+)'/)[1]
            variable_name = value.match(/(@\w+)/)[1]
            "'#{param}': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(#{variable_name}, '#{path}'))"
          elsif value.start_with? '@'
            "'#{param}': #{value}"
          else
            "'#{param}': '#{value}'"
          end
        end.join(",\n")
      end
    end
  end
end
