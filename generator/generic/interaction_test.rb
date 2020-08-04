# frozen_string_literal: true

require_relative '../test_metadata'

module Inferno
  module Generator
    module InteractionTest
      def create_interaction_tests(metadata)
        metadata.interactions.each do |interaction|
          next if ['read', 'search-type'].include? interaction[:code] # already have tests for
          next if ['create', 'update', 'patch', 'delete', 'history-type'].include? interaction[:code] # not currently supported

          interaction[:code] = 'history' if interaction[:code] == 'history-instance' # how the history interaction is called already

          interaction_test = TestMetadata.new(
            title: "Server supports the  #{metadata.resource_type} #{interaction[:code]} interaction",
            key: "resource_#{interaction[:code].gsub('-', '_').downcase}".to_sym,
            description: "This test will verify that #{metadata.resource_type} #{interaction[:code]} interactions are supported by the server.",
            optional: interaction[:expectation] != 'SHALL'
          )

          validate_reply_args = [
            '@resource_found',
            "versioned_resource_class('#{metadata.resource_type}')"
          ]
          validate_reply_args_string = validate_reply_args.join(', ')

          interaction_test.code = %(
              skip 'No resource found from Read test' unless @resource_found.present?
              validate_#{interaction[:code].gsub('-', '_')}_reply(#{validate_reply_args_string})
            )
          metadata.add_test(interaction_test)
        end
      end
    end
  end
end
