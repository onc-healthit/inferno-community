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
      }

      def generate
        structure = JSON.parse(File.read(File.join(__dir__, 'bdt-structure.json')))

        revised_structure = revise_structure_sequence(structure)

        metadata = extract_metadata(revised_structure)

        metadata[:groups].map { |g| g[:sequences] }.flatten.each { |s| generate_sequence(s) }
        generate_module(metadata)
        copy_base
      end

      def generate_sequence(sequence)
        puts "Generating #{sequence[:name]}\n"
        file_name = sequence_out_path + '/' + sequence[:name].downcase.gsub(' ', '_') + '_sequence.rb'

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
        metadata = {
          name: 'test',
          groups: []
        }

        source['children'].each do |group|
          new_group = {
            name: group['name'],
            sequences: []
          }

          group['children'].each do |sequence|
            new_sequence = {
              name: sequence['name'],
              description: BDT_DESCRIPTIONS[sequence['name']],
              tests: []
            }

            sequence['children'].each do |test|

              new_test = {
                name: clean_test_name(test['name']),
                path: test['path'],
                id: test['id'],
                description: test['description']
              } 

              new_sequence[:tests] << new_test

            end

            new_sequence[:id] = new_sequence[:tests].first&.dig(:id)&.split('-')&.first
            new_sequence[:sequence_class_name] = 'BDT' + new_sequence[:id].split('_').map(&:capitalize).join + 'Sequence'

            new_group[:sequences] << new_sequence
          end

          metadata[:groups] << new_group
        end

        metadata
      end

      def copy_base
        source_file = File.join(__dir__, 'templates/bdt_base.rb')
        out_file_name = sequence_out_path + '/bdt_base.rb'
        FileUtils.cp(source_file, out_file_name)
      end

      # This organizes into a single bulk data group
      # With a sequence per 
      def revise_structure_sequence(structure)
        bulk = { 'name' => 'Bulk Data Test', 'type' => 'group', 'children' => []}

        structure['children'].each do |seq_level|
          tests = []
          seq_level['children'].each do |test_level|
            tests.concat(collapse_sequence(test_level))
          end
          seq_level['children'] = tests
          bulk['children'] << seq_level
        end

        structure['children'] = [bulk]
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
        test_name.gsub("'", '"')
      end
    end
  end
end
