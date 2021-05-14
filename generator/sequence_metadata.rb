# frozen_string_literal: true

require_relative './generic_generator_utilities'

module Inferno
  module Generator
    class SequenceMetadata
      include Inferno::Generator::GenericGeneratorUtilties

      attr_reader :profile,
                  :tests,
                  :capabilities,
                  :search_parameter_metadata,
                  :module_name
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

      def initialize(profile, module_name, all_search_parameter_metadata, capability_statement = nil)
        @profile = profile
        @tests = []
        @module_name = module_name
        @search_parameter_metadata = []
        return unless capability_statement.present?

        @capabilities = capability_statement['rest']
          .find { |rest| rest['mode'] == 'server' }['resource']
          .find { |resource| resource['type'] == profile['type'] }

        return unless capabilities.present?

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

      def must_supports
        @must_supports ||= add_must_support_elements(@profile)
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

        capabilities['searchParam']&.map do |search_param|
          {
            parameters: [search_param['name']],
            expectation: search_param['extension'].find { |ext| ext['url'] == EXPECTATION_URL }['valueCode']
          }
        end || []
      end

      def search_combinations_from_capability_statement
        return [] unless capabilities.present?

        search_combo_url = 'http://hl7.org/fhir/StructureDefinition/capabilitystatement-search-parameter-combination'
        capabilities['extension']
          &.select { |ext| ext['url'] == search_combo_url }
          &.map do |combo|
            # rubocop:disable Layout/IndentationWidth, Layout/CommentIndentation:
            expectation = combo['extension'].find { |ext| ext['url'] == EXPECTATION_URL }['valueCode']
            combo_params = combo['extension']
              .reject { |ext| ext['url'] == EXPECTATION_URL }
              .map { |ext| ext['valueString'] }
            {
              parameters: combo_params,
              expectation: expectation
            }
            # rubocop:enable Layout/IndentationWidth, Layout/CommentIndentation:
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
        delimiters = ['-', '_', '.']
        (@module_name + '.' + profile['name'])
          .split(Regexp.union(delimiters))
          .map(&:capitalize)
          .join
      end

      def add_must_support_elements(profile_definition)
        must_supports = {
          extensions: [],
          slices: [],
          elements: []
        }

        profile_elements = profile_definition['snapshot']['element']
        resource = resource_type

        profile_elements.select { |el| el['mustSupport'] }.each do |element|
          if element['path'].end_with? 'extension'
            next if element['type'].first['profile'].nil?
            must_supports[:extensions] <<
              {
                id: element['id'],
                url: element['type'].first['profile'].first
              }
          elsif element['sliceName'].present?
            el_id = element['id'][0..element['id'].rindex(':')-1]
            array_el = profile_elements.find { |el| el['id'] == el_id }
            discriminators = array_el['slicing']['discriminator']
            must_support_element = { name: element['id'], path: element['path'].gsub(resource + '.', '') }
            if discriminators.first['type'] == 'pattern'
              discriminator_path = discriminators.first['path']
              discriminator_path = '' if discriminator_path == '$this'
              pattern_element = discriminator_path.present? ? profile_elements.find { |el| el['id'] == element['id'] + '.' + discriminator_path } : element
              if pattern_element['patternCodeableConcept'].present?
                must_support_element[:discriminator] = {
                  type: 'patternCodeableConcept',
                  path: discriminator_path,
                  code: pattern_element['patternCodeableConcept']['coding'].first['code'],
                  system: pattern_element['patternCodeableConcept']['coding'].first['system']
                }
              elsif pattern_element['patternIdentifier'].present?
                must_support_element[:discriminator] = {
                  type: 'patternIdentifier',
                  path: discriminator_path,
                  system: pattern_element['patternIdentifier']['system']
                }
              elsif pattern_element['binding'].present?
                must_support_element[:discriminator] = {
                  type: 'binding',
                  path: discriminator_path,
                  valueset: pattern_element['binding']['valueSet']
                }
              end
            elsif discriminators.first['type'] == 'type'
              type_path = discriminators.first['path']
              type_path = '' if type_path == '$this'
              type_element = type_path.present? ? profile_elements.find { |el| el['id'] == "#{element['id']}.#{type_path}[x]" } : element
              type_code = type_element['type'].first['code']
              must_support_element[:discriminator] = {
                type: 'type',
                code: type_code.upcase_first
              }
            elsif discriminators.first['type'] == 'value'
              must_support_element[:discriminator] = {
                type: 'value',
                values: []
              }
              discriminators.each do |discriminator|
                fixed_el = profile_elements.find { |el| el['id'].starts_with?(element['id']) && el['path'] == element['path'] + '.' + discriminator['path'] }
                fixed_value = fixed_el['fixedUri'] || fixed_el['fixedCode']
                must_support_element[:discriminator][:values] << {
                  path: discriminator['path'],
                  value: fixed_value
                }
              end
            elsif discriminators.first['type'] == 'profile'
              profile_path = discriminators.first['path']
              profile_path = '' if profile_path.start_with?('$this')
              profile_element = profile_path.present? ? profile_elements.find { |el| el['id'] == "#{element['id']}.#{profile_path}" } : element
              
              must_support_element[:discriminator] = {
                type: 'profile',
                path: profile_path,
                profile: profile_element['type'].first['profile'] || profile_element['type'].first['targetProfile']
              }
            end
            must_supports[:slices] << must_support_element
          else
            path = element['path'].gsub(resource + '.', '')
            must_support_element = { path: path }
            if element['fixedUri'].present?
              must_support_element[:fixed_value] = element['fixedUri']
            elsif element['patternCodeableConcept'].present?
              must_support_element[:fixed_value] = element['patternCodeableConcept']['coding'].first['code']
              must_support_element[:path] += '.coding.code'
            elsif element['fixedCode'].present?
              must_support_element[:fixed_value] = element['fixedCode']
            elsif element['patternIdentifier'].present?
              must_support_element[:fixed_value] = element['patternIdentifier']['system']
              must_support_element[:path] += '.system'
            end
            must_supports[:elements].delete_if { |must_support| must_support[:path] == must_support_element[:path] && must_support[:fixed_value].blank? }
            must_supports[:elements] << must_support_element
          end
        end
        must_supports[:elements].uniq!
        must_supports
      end


    end
  end
end
