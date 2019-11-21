# frozen_string_literal: true

module Inferno
  module Generator
    class USCoreUnitTestGenerator
      def tests
        @tests ||= Hash.new { |hash, key| hash[key] = [] }
      end

      def generate(sequence, path, module_name)
        template = ERB.new(File.read(File.join(__dir__, 'templates', 'unit_tests', 'unit_test.rb.erb')))
        class_name = sequence[:class_name]
        return if tests[class_name].blank?

        unit_tests = template.result_with_hash(
          class_name: class_name,
          tests: tests[class_name],
          resource_type: sequence[:resource],
          module_name: module_name
        )

        test_path = File.join(path, 'test')
        FileUtils.mkdir_p(test_path) unless File.directory?(test_path)

        file_name = File.join(test_path, "#{sequence[:name].downcase}_test.rb")
        File.write(file_name, unit_tests)
      end

      def generate_search_test(test_key:, resource_type:, search_params:, class_name:, is_first_search:, sequence_name:)
        template = ERB.new(File.read(File.join(__dir__, 'templates', 'unit_tests', 'search_unit_test.rb.erb')))

        resource_var_name = resource_type.underscore

        if is_first_search
          test = template.result_with_hash(
            test_key: test_key,
            resource_type: resource_type,
            resource_var_name: resource_var_name,
            search_params: search_params,
            search_param_string: search_params_to_string(search_params),
            sequence_name: sequence_name
          )
          tests[class_name] << test
        end
      end

      def generate_authorization_test(test_key:, resource_type:, search_params:, class_name:, sequence_name:)
        template = ERB.new(File.read(File.join(__dir__, 'templates', 'unit_tests', 'authorization_unit_test.rb.erb')))
        test = template.result_with_hash(
          test_key: test_key,
          resource_type: resource_type,
          search_param_string: search_params_to_string(search_params),
          dynamic_search_params: dynamic_search_params(search_params),
          sequence_name: sequence_name
        )
        tests[class_name] << test
      end

      def generate_resource_read_test(test_key:, resource_type:, class_name:, interaction_test: false)
        template = ERB.new(File.read(File.join(__dir__, 'templates', 'unit_tests', 'resource_read_unit_test.rb.erb')))
        resource_var_name = resource_type.underscore

        test = template.result_with_hash(
          test_key: test_key,
          resource_type: resource_type,
          resource_var_name: resource_var_name,
          interaction_test: interaction_test,
          no_resources_found_message: no_resources_found_message(interaction_test, resource_type),
          wrong_resource_type: resource_type == 'Patient' ? 'Observation' : 'Patient'
        )
        tests[class_name] << test
      end

      def no_resources_found_message(interaction_test, resource_type)
        if interaction_test
          "No #{resource_type} resources could be found for this patient. Please use patients with more information."
        else
          "No #{resource_type} references found from the prior searches"
        end
      end

      def search_params_to_string(search_params)
        search_params.map do |param, value|
          if dynamic_search_param? value
            dynamic_search_param_string(param, value)
          elsif value.start_with? '@'
            "'#{param}': #{value}"
          else
            "'#{param}': '#{value}'"
          end
        end.join(",\n")
      end

      def dynamic_search_param_string(param, value)
        param_info = dynamic_search_param(value)
        path = param_info[:resource_path]
        variable_name = param_info[:variable_name]
        "'#{param}': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(#{variable_name}, '#{path}'))"
      end

      def dynamic_search_param?(param_value)
        param_value.start_with? 'get_value_for_search_param'
      end

      def dynamic_search_params(search_params)
        search_params
          .select { |_param, value| dynamic_search_param?(value) }
          .transform_values { |value| dynamic_search_param(value) }
      end

      # From a string like:
      #   get_value_for_search_param(resolve_element_from_path(@careplan_ary, 'category'))
      # this method extracts the variable name '@careplan_ary' and the path 'category'
      def dynamic_search_param(param_value)
        match = param_value.match(/(@\w+).*'([\w\.]+)'/)
        {
          variable_name: match[1],
          resource_path: match[2]
        }
      end
    end
  end
end
