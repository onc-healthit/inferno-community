# frozen_string_literal: true

require_relative '../test_metadata'

module Inferno
  module Generator
    module SearchTest
      def create_search_tests(metadata)
        metadata.searches.each do |search|
          search_test = TestMetadata.new(
            title: "Server returns expected results from #{metadata.resource_type} search by #{search[:parameters].join('+')}",
            key: :"search_by_#{search[:parameters].map(&:underscore).join('_')}",
            description: "This test will verify that #{metadata.resource_type} resources can be searched from the server.",
            optional: search[:expectation] != 'SHALL'
          )

          search_parameter_assignments = search[:parameters].map do |parameter|
            param_metadata = metadata.search_parameter_metadata.find { |parameter_metadata| parameter_metadata.code == parameter }
            path = param_metadata.expression
            path = path.gsub(/\.where\(.*\)/, '') # TODO: remove once FHIRPath resolve() function is handled

            "#{search_param_value_name(parameter)} = find_search_parameter_value_from_resource(@resource_found, '#{path}')"
          end
          search_test.code = %(
            skip 'No resource found from Read test' unless @resource_found.present?
            #{search_parameter_assignments.join("\n")}
            search_parameters = {
              #{search[:parameters].map { |parameter| "'#{parameter}': #{search_param_value_name(parameter)}" }.join(",\n")}
            }

            reply = get_resource_by_params(versioned_resource_class('#{metadata.resource_type}'), search_parameters)
            validate_search_reply(versioned_resource_class('#{metadata.resource_type}'), reply, search_parameters)
          )
          metadata.add_test(search_test)
        end
      end

      def search_param_value_name(parameter)
        parameter.gsub!(/^[\W_]+|[\W_]+$"/, '') # remove non-character elements from beginning and end of name
        "#{parameter.tr('-', '_')}_val"
      end
    end
  end
end
