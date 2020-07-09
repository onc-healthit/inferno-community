# frozen_string_literal: true

require_relative '../generator_base'
require_relative './read_test'
require_relative './profile_validation_test'

module Inferno
  module Generator
    class SanerGenerator < Generator::Base
      include ReadTest
      include ProfileValidationTest

      def generate
        profile_metadata = read_profile_structure_definitions
        generate_sequences(profile_metadata)
        generate_module(profile_metadata)
      end

      def read_profile_structure_definitions
        # I couldn't find a way to distinguish profiles in the IG besides this. Unsure if there will be non-profile structure definitions
        profiles_structure_defs = resources_by_type['StructureDefinition'].reject { |definition| definition['type'] == 'Extension' }
        profiles_structure_defs.map do |structure_def|
          extract_metadata(structure_def)
        end
      end

      def extract_metadata(structure_definition)
        resource_type = structure_definition['type']
        sequence_name = structure_definition['name']
          .split('-')
          .map(&:capitalize)
          .join
        {
          class_name: sequence_name + 'Sequence',
          file_name: sequence_name + '_sequence',
          resource_type: structure_definition['type'],
          title: structure_definition['title'] || structure_definition['name'],
          test_id_prefix: structure_definition['name'].chars.select { |c| c.upcase == c && c != ' ' }.join, # this needs to be made more generics
          requirements: [":#{resource_type.downcase}_id"],
          url: structure_definition['url'],
          tests: []
        }
      end

      def generate_sequences(profile_metadata)
        profile_metadata.each do |metadata|
          create_read_test(metadata)
          create_profile_validation_test(metadata)
          generate_sequence(metadata)
        end
      end

      def generate_sequence(metadata)
        puts "Generating #{metadata[:title]}\n"
        file_name = sequence_out_path + '/' + metadata[:file_name].downcase + '.rb'
        template = ERB.new(File.read(File.join(__dir__, 'templates/sequence.rb.erb')))
        output =   template.result_with_hash(metadata)
        FileUtils.mkdir_p(sequence_out_path + '/') unless File.directory?(sequence_out_path + '/')
        File.write(file_name, output)
      end

      def generate_module(profile_metadata)
        file_name = "#{module_yml_out_path}/#{@path}_module.yml"

        module_info = {
          title: @path,
          sequences: profile_metadata,
          description: ''
        }
        template = ERB.new(File.read(File.join(__dir__, 'templates/module.yml.erb')))
        output = template.result_with_hash(module_info)

        File.write(file_name, output)
      end
    end
  end
end
