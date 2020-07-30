# frozen_string_literal: true

module Inferno
  module Generator
    class SequenceMetadata
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
                  :must_supports

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

      def create_search_validation
        search_validators = ''
        search_parameter_metadata&.each do |parameter_metadata|
          type = parameter_metadata.type
          path = parameter_metadata.expression
            .gsub(/(?<!\w)class(?!\w)/, 'local_class')
            .split('.')
            .drop(1)
            .join('.')
          path += get_value_path_by_type(type) unless ['Period', 'date', 'HumanName', 'Address', 'CodeableConcept', 'Coding', 'Identifier'].include? type
          search_validators += %(
              when '#{parameter_metadata.code}'
              values_found = resolve_path(resource, '#{path}')
              #{search_param_match_found_code(type, parameter_metadata.code)}
              assert match_found, "#{parameter_metadata.code} in #{resource_type}/\#{resource.id} (\#{values_found}) does not match #{parameter_metadata.code} requested (\#{value})"
            )
        end

        validate_functions =
          if search_validators.empty?
            ''
          else
            %(
              def validate_resource_item(resource, property, value)
                case property
                  #{search_validators}
                end
              end
            )
          end
        validate_functions
      end

      def search_param_match_found_code(type, element)
        case type
        when 'Period', 'date'
          %(match_found = values_found.any? { |date| validate_date_search(value, date) })
        when 'HumanName'
          # When a string search parameter refers to the types HumanName and Address,
          # the search covers the elements of type string, and does not cover elements such as use and period
          # https://www.hl7.org/fhir/search.html#string
          %(value_downcase = value.downcase
            match_found = values_found.any? do |name|
              name&.text&.downcase&.start_with?(value_downcase) ||
                name&.family&.downcase&.include?(value_downcase) ||
                name&.given&.any? { |given| given.downcase.start_with?(value_downcase) } ||
                name&.prefix&.any? { |prefix| prefix.downcase.start_with?(value_downcase) } ||
                name&.suffix&.any? { |suffix| suffix.downcase.start_with?(value_downcase) }
            end)
        when 'Address'
          %(match_found = values_found.any? do |address|
              address&.text&.start_with?(value) ||
              address&.city&.start_with?(value) ||
              address&.state&.start_with?(value) ||
              address&.postalCode&.start_with?(value) ||
              address&.country&.start_with?(value)
            end)
        when 'CodeableConcept'
          %(coding_system = value.split('|').first.empty? ? nil : value.split('|').first
            coding_value = value.split('|').last
            match_found = values_found.any? do |codeable_concept|
              if value.include? '|'
                codeable_concept.coding.any? { |coding| coding.system == coding_system && coding.code == coding_value }
              else
                codeable_concept.coding.any? { |coding| coding.code == value }
              end
            end)
        when 'Identifier'
          %(identifier_system = value.split('|').first.empty? ? nil : value.split('|').first
            identifier_value = value.split('|').last
            match_found = values_found.any? do |identifier|
              identifier.value == identifier_value && (!value.include?('|') || identifier.system == identifier_system)
            end)
        else
          # searching by patient requires special case because we are searching by a resource identifier
          # references can also be URL's, so we made need to resolve those url's
          if ['subject', 'patient'].include? element.to_s
            %(value = value.split('Patient/').last
              match_found = values_found.any? { |reference| [value, 'Patient/' + value, "\#{@instance.url}/Patient/\#{value}"].include? reference })
          else
            %(values = value.split(/(?<!\\\\),/).each { |str| str.gsub!('\\,', ',') }
              match_found = values_found.any? { |value_in_resource| values.include? value_in_resource })
          end
        end
      end

      def get_value_path_by_type(type)
        case type
        when 'CodeableConcept'
          '.coding.code'
        when 'Reference'
          '.reference'
        when 'Period'
          '.start'
        when 'Identifier'
          '.value'
        when 'Coding'
          '.code'
        when 'HumanName'
          '.family'
        when 'Address'
          '.city'
        else
          ''
        end
      end

      private

      def initial_sequence_name
        return profile['name'] unless profile['name'].include?('-')

        profile['name'].split('-').map(&:capitalize).join
      end
    end
  end
end
