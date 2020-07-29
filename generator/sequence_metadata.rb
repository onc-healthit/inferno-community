# frozen_string_literal: true

module Inferno
  module Generator
    class SequenceMetadata
      attr_reader :profile,
                  :tests,
                  :capabilities
      attr_writer :class_name,
                  :file_name,
                  :requirements,
                  :sequence_name,
                  :test_id_prefix,
                  :title,
                  :url,
                  :searches,
                  :must_supports,
                  :search_parameters

      def initialize(profile, capability_statement = nil)
        @profile = profile
        @tests = []
        @capabilities = if capability_statement.present?
                          capability_statement['rest']
                            .find { |rest| rest['mode'] == 'server' }['resource']
                            .find { |resource| resource['type'] == profile['type'] }
                        end
      end

      def resource_type
        profile['type']
      end

      def sequence_name
        @sequence_name ||= initial_sequence_name
      end

      def class_name
        @class_name ||= sequence_name + 'Sequence'
      end

      def file_name
        @file_name ||= sequence_name.underscore + '_sequence'
      end

      def title
        @title ||= profile['title'] || profile['name']
      end

      def test_id_prefix
        # this needs to be made more generic
        @test_id_prefix ||= profile['name'].chars.select { |c| c.upcase == c && c != ' ' }.join
      end

      def requirements
        @requirements ||= [":#{resource_type.underscore}_id"]
      end

      def url
        @url ||= profile['url']
      end

      def add_test(test)
        @tests << test
      end

      def searches
        @searches ||= searches_from_capability_statement(capabilities)
      end

      def searches_from_capability_statement(capabilities)
        return [] unless capabilities.present?

        capability_statement_expectation_url = 'http://hl7.org/fhir/StructureDefinition/capabilitystatement-expectation'
        search_combo_url = 'http://hl7.org/fhir/StructureDefinition/capabilitystatement-search-parameter-combination'

        searches = []
        basic_searches = capabilities['searchParam']
        basic_searches&.each do |search_param|
          new_search = {
            parameters: [search_param['name']],
            expectation: search_param['extension'].find { |ext| ext['url'] == capability_statement_expectation_url } ['valueCode']
          }
          searches << new_search

          param_url = search_param['definition']
        end

        capabilities['extension']
          .select { |ext| ext['url'] == search_combo_url }
          .each do |combo|
            expectation = combo['extension'].find { |ext| ext['url'] == capability_statement_expectation_url }['valueCode']
            combo_params = combo['extension']
              .reject { |ext| ext['url'] == capability_statement_expectation_url }
              .map { |ext| ext['valueString'] }
            new_search = {
              parameters: combo_params,
              expectation: expectation
            }
            searches << new_search
          end
        searches
      end

      private

      def initial_sequence_name
        return profile['name'] unless profile['name'].include?('-')

        profile['name'].split('-').map(&:capitalize).join
      end
    end
  end
end
