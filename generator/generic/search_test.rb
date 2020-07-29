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
            description: "This test will verify that #{metadata.resource_type} resources can be searched from the server."
          )

          search_param_assignment = search[:parameters]
            .map { |parameter| "#{parameter}_val = get_value_for" }
          search_test.code = %(
              return unless @resource_found.present?
              
          )
          metadata.add_test(search_test)
        end
      end
    end
  end
end
