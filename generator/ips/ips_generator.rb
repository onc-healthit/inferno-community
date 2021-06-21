# frozen_string_literal: true

require_relative '../../lib/app/utils/validation'
require_relative '../generic/generic_generator'

module Inferno
  module Generator
    class IPSGenerator < Generator::GenericGenerator
      def generate_sequence(metadata)
        puts "Generating #{metadata.title}\n"
        file_name = File.join(sequence_out_path, metadata.file_name + '.rb')
        template = ERB.new(File.read(File.join(__dir__, 'templates/sequence.rb.erb')))
        output =   template.result_with_hash(metadata: metadata)
        FileUtils.mkdir_p(sequence_out_path + '/') unless File.directory?(sequence_out_path + '/')
        File.write(file_name, output)

        generate_sequence_definitions(metadata)
      end

      def generate_sequence_definitions(metadata)
        output_directory = File.join(sequence_out_path, 'profile_definitions')
        file_name = File.join(output_directory, metadata.file_name + '_definitions.rb')
        template = ERB.new(File.read(File.join(__dir__, 'templates/sequence_definition.rb.erb')))
        output = template.result_with_hash(sequence_definition_hash(metadata))
        FileUtils.mkdir_p(sequence_out_path + '/profile_definitions/') unless File.directory?(sequence_out_path + '/profile_definitions/')
        File.write(file_name, output)
      end

      def sequence_definition_hash(metadata)
        search_parameters = metadata.search_parameter_metadata&.map do |param_metadata|
          {
            url: param_metadata.url,
            code: param_metadata.code,
            expression: param_metadata.expression,
            multipleOr: param_metadata.multiple_or,
            multipleOrExpectation: param_metadata.multiple_or_expectation,
            multipleAnd: param_metadata.multiple_and,
            multipleAndExpectation: param_metadata.multiple_and_expectation,
            modifiers: param_metadata.modifiers,
            comparators: param_metadata.comparators
          }
        end
        search_parameters ||= []
        {
          module_name: module_name + 'ProfileDefinitions',
          class_name: metadata.class_name + 'Definition',
          profile_url: metadata.url,
          must_supports: structure_to_string(metadata.must_supports),
          search_parameters: structure_to_string(search_parameters)
        }
      end

      def generate_module
        file_name = module_file_path

        module_info = {
          sequences: sequence_metadata,
          resource_path: @path
        }
        template = ERB.new(File.read(File.join(__dir__, 'templates/module.yml.erb')))
        output = template.result_with_hash(module_info)

        File.write(file_name, output)
      end
    end
  end
end
