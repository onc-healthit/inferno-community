# frozen_string_literal: true

require_relative '../capability_statement_parser'
require_relative '../generator_base'
require_relative './search_test'
require_relative './interaction_test'
require_relative './read_test'
require_relative './profile_validation_test'
require_relative './create_test'
require_relative './update_test'

module Inferno
  module Generator
    class McodeGenerator < Generator::Base
      include CapabilityStatementParser
      include ProfileValidationTest
      include ReadTest
      include InteractionTest
      include SearchTest
      def generate
        generate_sequences('mCODERequirements')
        generate_module(extract_metadata('mCODERequirements'))
        puts "done"
      end

      def generate_sequences(capability_statement)
        metadata = extract_metadata(capability_statement)
        generate_tests(metadata)
        generate_search_validators(metadata)
        metadata[:sequences].each do |sequence|
          generate_sequence(sequence, metadata[:capability_statement])
        end
      end

      def generate_tests(metadata)
        metadata[:sequences].each do |sequence|
          puts "Generating test #{sequence[:name]}"

          # create_read_test(sequence) if metadata[:capability_statement].include? 'Pull'
          # make tests for each SHALL and SHOULD search param, SHALL's first
          sequence[:searches]
            .select { |search_param| search_param[:expectation] == 'SHALL' }
            .each { |search_param| create_search_test(sequence, search_param) }

          sequence[:searches]
            .select { |search_param| search_param[:expectation] == 'SHOULD' }
            .each { |search_param| create_search_test(sequence, search_param) }

          sequence[:searches]
            .select { |search_param| search_param[:expectation] == 'MAY' }
            .each { |search_param| create_search_test(sequence, search_param) }

          # make tests for each SHALL and SHOULD interaction
          sequence[:interactions]
            .select { |interaction| ['SHALL', 'SHOULD'].include? interaction[:expectation] }
            .reject { |interaction| interaction[:code] == 'search-type' }
            .each do |interaction|
            # specific edge cases
            interaction[:code] = 'history' if interaction[:code] == 'history-instance'
            create_create_test(sequence, interaction) if interaction[:code] == 'create'
            create_update_test(sequence, interaction) if interaction[:code] == 'update'
            create_read_test(sequence) if interaction[:code] = 'read'
          end
          create_profile_validation_test(sequence) #if metadata[:capability_statement].include? 'Pull'
          # # create_must_support_test(sequence)
          # # create_multiple_or_test(sequence) unless sequence[:delayed_sequence]
          # create_references_resolved_test(sequence)
        end
      end

      def generate_search_validators(metadata)
        metadata[:sequences].each do |sequence|
          sequence[:search_validator] = create_search_validation(sequence)
        end
      end

      def create_search_validation(sequence)
        search_validators = ''
        sequence[:search_param_descriptions].each do |element, definition|
          type = definition[:type]
          path = definition[:path]
            .gsub(/(?<!\w)class(?!\w)/, 'local_class')
            .split('.')
            .drop(1)
            .join('.')
          path += get_value_path_by_type(type) unless ['Period', 'date', 'HumanName', 'Address'].include? type
          search_validators += %(
              when '#{element}'
              values_found = resolve_path(resource, '#{path}')
              #{search_param_match_found_code(type, element)}
              assert match_found, "#{element} in #{sequence[:resource]}/\#{resource.id} (\#{values_found}) does not match #{element} requested (\#{value})"
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
        else
          # searching by patient requires special case because we are searching by a resource identifier
          # references can also be URL's, so we made need to resolve those url's
          if ['subject', 'patient'].include? element.to_s
            %(match_found = values_found.any? { |reference| [value, 'Patient/' + value].include? reference })
          else
            %(values = value.split(/(?<!\\\\),/).each { |str| str.gsub!('\\,', ',') }
              match_found = values_found.any? { |value_in_resource| values.include? value_in_resource })
          end
        end
      end

      def generate_sequence(sequence, capability_statement)
        puts "Generating #{sequence[:name]}\n"
        file_name = sequence_out_path + '/' + capability_statement + '/' + sequence[:name].downcase + '_sequence.rb'
        template = ERB.new(File.read(File.join(__dir__, 'templates/sequence.rb.erb')))
        output =   template.result_with_hash(sequence)
        FileUtils.mkdir_p(sequence_out_path + '/' + capability_statement) unless File.directory?(sequence_out_path + '/' + capability_statement)
        File.write(file_name, output)
      end

      def generate_module(module_info)
        file_name = "#{module_yml_out_path}/#{module_info[:capability_statement].downcase}_module.yml"

        template = ERB.new(File.read(File.join(__dir__, 'templates/module.yml.erb')))
        output = template.result_with_hash(module_info)
        File.write(file_name, output)
      end
    end
  end
end
