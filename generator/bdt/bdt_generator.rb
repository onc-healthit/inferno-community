# frozen_string_literal: true

require_relative '../generator_base'

module Inferno
  module Generator
    class BDTGenerator < Generator::Base
      BDT_DESCRIPTIONS = {
        'Authorization' => 'Verify that the bulk data export conforms to the SMART Backend Services specification.',
        'Download Endpoint' => 'Verify the Download Endpoint conforms to the SMART Bulk Data IG for Export.',
        'Patient-level export' => 'Verify the system is capable of performing a Patient-Level Export that conforms to the SMART Bulk Data IG.',
        'System-level export' => 'Verify the system is capable of performing a System-Level Export that conforms to the SMART Bulk Data IG.',
        'Group-level export' => 'Verify the system is capable of performing a Group-Level Export that conforms to the SMART Bulk Data IG.',
        'Status Endpoint' => 'Verify the status endpoint conforms to the SMART Bulk Data IG for Export.'
      }.freeze

      def generate
        structure = JSON.parse(File.read(File.join(__dir__, 'bdt-structure.json')))

        revised_structure = revise_structure_sequence(structure)

        metadata = extract_metadata(revised_structure)

        metadata[:groups]
          .flat_map { |group| group[:sequences] }
          .each { |sequence| generate_sequence(sequence) }
        generate_module(metadata)
        copy_base
      end

      def generate_sequence(sequence)
        puts "Generating #{sequence[:name]}\n"
        file_name = sequence_out_path + '/' + sequence[:name].downcase.gsub(/[ -]/, '_') + '_sequence.rb'

        template = ERB.new(File.read(File.join(__dir__, 'templates/sequence.rb.erb')))
        output =   template.result_with_hash(sequence)
        FileUtils.mkdir_p(sequence_out_path) unless File.directory?(sequence_out_path)
        File.write(file_name, output)
      end

      def generate_module(module_info)
        file_name = "#{module_yml_out_path}/#{@path}_module.yml"

        template = ERB.new(File.read(File.join(__dir__, 'templates/module.yml.erb')))
        output = template.result_with_hash(module_info)

        File.write(file_name, output)
      end

      def extract_metadata(source)
        {
          name: 'test',
          groups: source['children'].map { |group| new_group(group) }
        }
      end

      def new_group(group_metadata)
        {
          name: group_metadata['name'],
          sequences: group_metadata['children'].map { |sequence| new_sequence(sequence) }
        }
      end

      def new_sequence(sequence_metadata)
        {
          name: sequence_metadata['name'],
          description: BDT_DESCRIPTIONS[sequence_metadata['name']],
          tests: sequence_metadata['children'].map { |test| new_test(test) }
        }.tap do |sequence|
          sequence[:id] = sequence[:tests].first&.dig(:id)&.split('-')&.first
          sequence[:sequence_class_name] = 'BDT' + sequence[:id].camelize + 'Sequence'
        end
      end

      def new_test(test_metadata)
        {
          name: clean_test_name(test_metadata['name']),
          path: test_metadata['path'],
          id: test_metadata['id'],
          description: test_metadata['description']
        }
      end

      def copy_base
        source_file = File.join(__dir__, 'templates/bdt_base.rb')
        out_file_name = sequence_out_path + '/bdt_base.rb'
        FileUtils.cp(source_file, out_file_name)
      end

      # This organizes into a single bulk data group
      # With a sequence per
      def revise_structure_sequence(structure)
        sequences = structure['children'].map do |sequence|
          sequence['children'] = sequence['children'].flat_map do |tests|
            collapse_sequence(tests)
          end
          sequence
        end

        structure['children'] = [
          {
            'name' => 'Bulk Data Test',
            'type' => 'group',
            'children' => sequences
          }
        ]

        structure
      end

      def collapse_sequence(sequence)
        out = []

        if sequence['children'].nil?
          out = [sequence]
        else
          sequence['children'].each do |child|
            child['name'][0] = child['name'][0].downcase
            child['name'] = "#{sequence['name']} #{child['name']}"
            out.concat(collapse_sequence(child))
          end
        end

        out.flatten
      end

      def clean_test_name(test_name)
        test_name.tr("'", '"')
      end
    end
  end
end
