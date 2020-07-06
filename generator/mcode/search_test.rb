# frozen_string_literal: true

module Inferno
  module Generator
    module SearchTest
      def create_search_test(sequence, search_param)
        test_key = :"search_by_#{search_param[:names].map(&:underscore).join('_')}"
        search_test = {
          tests_that: "Server returns valid results for #{sequence[:resource]} search by #{search_param[:names].join('+')}.",
          key: test_key,
          index: sequence[:tests].length + 1,
          optional: search_param[:expectation] != 'SHALL',
          description: %(
            A server #{search_param[:expectation]} support searching by #{search_param[:names].join('+')} on the #{sequence[:resource]} resource.
            This test will pass if resources are returned and match the search criteria.
            )
        }
        search_params = get_search_params(search_param[:names], sequence)
        search_test[:test_code] = %(
          #{search_params}
          skip 'Could not find parameter value for #{search_param[:names]} to search by.' if search_params.any? { |_param, value| value.nil? }

          reply = get_resource_by_params(versioned_resource_class('#{sequence[:resource]}'), search_params)

          assert_response_ok(reply)
          assert_bundle_response(reply)

          bundled_resources = fetch_all_bundled_resources(reply)
          save_resource_references(versioned_resource_class('#{sequence[:resource]}'), bundled_resources, '#{sequence[:profile]}')
          validate_reply_entries(bundled_resources, search_params)
        )
        sequence[:tests] << search_test
      end

      def get_search_params(search_parameters, sequence)
        search_params = get_search_param_hash(search_parameters, sequence)
        search_param_string = %(
          search_params = {
            #{search_params.map { |param, value| "'#{param}': #{value}" }.join(",\n")}
          })

        search_param_string
      end

      def get_search_param_hash(search_parameters, sequence)
        search_parameters.each_with_object({}) do |param, params|
          search_param_description = sequence[:search_param_descriptions][param.to_sym]
          params[param] =
            "get_value_for_search_param(#{resolve_element_path(search_param_description, sequence[:delayed_sequence])} { |el| get_value_for_search_param(el).present? })"
        end
      end

      def resolve_element_path(search_param_description, _delayed_sequence)
        element_path = search_param_description[:path].gsub(/(?<!\w)class(?!\w)/, 'local_class')
        path_parts = element_path.split('.')
        path_parts.shift
        "resolve_element_from_path(@resource_found, '#{path_parts.join('.')}')"
      end
    end
  end
end
