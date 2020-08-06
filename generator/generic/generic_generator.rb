# frozen_string_literal: true

require_relative '../generator_base'
require_relative '../sequence_metadata'
require_relative './read_test'
require_relative './profile_validation_test'

module Inferno
  module Generator
    class GenericGenerator < Generator::Base
      include ReadTest
      include ProfileValidationTest

      def resource_profiles
        resources_by_type['StructureDefinition'].reject { |definition| definition['type'] == 'Extension' }
      end

      def sequence_metadata
        @sequence_metadata ||= resource_profiles.map { |profile| SequenceMetadata.new(profile) }
      end

      def generate
        generate_sequences
        generate_module
      end

      def generate_sequences
        sequence_metadata.each do |metadata|
          create_read_test(metadata)
          create_profile_validation_test(metadata)
          generate_sequence(metadata)
        end
      end

      def generate_sequence(metadata)
        puts "Generating #{metadata.title}\n"
        file_name = File.join(sequence_out_path, metadata.file_name + '.rb')
        template = ERB.new(File.read(File.join(__dir__, 'templates/sequence.rb.erb')))
        output =   template.result_with_hash(metadata: metadata)
        FileUtils.mkdir_p(sequence_out_path + '/') unless File.directory?(sequence_out_path + '/')
        File.write(file_name, output)
      end

      def module_file_path
        "#{module_yml_out_path}/#{@path}_module.yml"
      end

      def generate_module
        file_name = module_file_path

        module_info = {
          title: @path,
          sequences: sequence_metadata,
          resource_path: @path,
          description: ''
        }
        template = ERB.new(File.read(File.join(__dir__, 'templates/module.yml.erb')))
        output = template.result_with_hash(module_info)

        File.write(file_name, output)
      end
    end
  end
end
