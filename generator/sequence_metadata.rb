# frozen_string_literal: true

require_relative './generic_generator_utilities'

module Inferno
  module Generator
    class SequenceMetadata
      include Inferno::Generator::GenericGeneratorUtilties

      attr_reader :profile,
                  :tests,
                  :capabilities,
                  :search_parameter_metadata
      attr_writer :class_name,
                  :file_name,
                  :requirements,
                  :sequence_name,
                  :test_id_prefix,
                  :title,
                  :url,
                  :searches,
                  :must_supports,
                  :interactions

      def initialize(profile, all_search_parameter_metadata, capability_statement = nil)
        @profile = profile
        @tests = []
        return unless capability_statement.present?

        @capabilities = capability_statement['rest']
          .find { |rest| rest['mode'] == 'server' }['resource']
          .find { |resource| resource['type'] == profile['type'] }

        @search_parameter_metadata = capabilities['searchParam']&.map do |param|
          all_search_parameter_metadata.find { |param_metadata| param_metadata.url == param['definition'] }
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

      def interactions
        @interactions ||= interactions_from_capability_statement
      end

      def interactions_from_capability_statement
        return [] unless capabilities.present?

        capabilities['interaction'].map do |interaction|
          {
            code: interaction['code'],
            expectation: interaction['extension'].find { |ext| ext['url'] == EXPECTATION_URL } ['valueCode']
          }
        end
      end

      def searches
        @searches ||= basic_searches_from_capability_statement + search_combinations_from_capability_statement
      end

      def basic_searches_from_capability_statement
        return [] unless capabilities.present?

        searches = []
        basic_searches = capabilities['searchParam']
        basic_searches&.each do |search_param|
          new_search = {
            parameters: [search_param['name']],
            expectation: search_param['extension'].find { |ext| ext['url'] == EXPECTATION_URL } ['valueCode']
          }
          searches << new_search
        end
        searches
      end

      def search_combinations_from_capability_statement
        search_combo_url = 'http://hl7.org/fhir/StructureDefinition/capabilitystatement-search-parameter-combination'
        capabilities['extension']
          &.select { |ext| ext['url'] == search_combo_url }
          &.map do |combo|
          expectation = combo['extension'].find { |ext| ext['url'] == EXPECTATION_URL }['valueCode']
          combo_params = combo['extension']
            .reject { |ext| ext['url'] == EXPECTATION_URL }
            .map { |ext| ext['valueString'] }
          {
            parameters: combo_params,
            expectation: expectation
          }
        end || []
      end

      def add_test(test)
        @tests << test
      end

      def element_type_by_path(path)
        profile_element = profile['snapshot']['element'].select { |el| el['id'] == path }.first
        return nil if profile_element.nil?

        profile_element['type'].first['code']
      end

      private

      def initial_sequence_name
        return profile['name'] unless profile['name'].include?('-')

        profile['name'].split('-').map(&:capitalize).join
      end
    end
  end
end
