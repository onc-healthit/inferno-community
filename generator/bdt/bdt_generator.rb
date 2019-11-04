# frozen_string_literal: true

require_relative '../generator_base'

module Inferno
  module Generator
    class BDTGenerator < Generator::Base
      GEN_PATH = './generator/bdt'
      OUT_PATH = './lib/app/modules'

      def generate
        structure = JSON.parse(File.read(GEN_PATH + '/bdt-structure.json'))

        revised_structure = revise_structure(structure)

        metadata = extract_metadata(revised_structure)

        metadata[:groups].map { |g| g[:sequences] }.flatten.each { |s| generate_sequence(s) }
        generate_module(metadata)
        copy_base
      end

      def extract_test_from_group(group, list)
        group['children'].each do |child|
          if child['type'] == group
            extract_test_from_group(child, list)
          else

            new_test = {
              name: clean_test_name(child['name']),
              path: child['path'],
              id: child['id'],
              description: child['description']
            }

            list << new_test

          end
        end
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
              tests: []
            }

            extract_test_from_group(sequence, new_sequence[:tests])

            new_sequence[:id] = new_sequence[:tests].first&.dig(:id)&.split('-')&.first
            new_sequence[:name] = new_sequence[:id].split('_').map(&:capitalize).join(' ')
            new_sequence[:description] = sequence['name']
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

      def revise_structure(structure)
        auth_group = structure['children'][0]

        auth_group['children'].each do |seq_level|
          new_name = 'Auth_' + seq_level['name'].gsub(' ', '_')

          match = seq_level['name'].match(/([^\s]+\-level)+/)
          new_name = 'Auth_' + match[1].gsub('-', '_') unless match.nil?

          seq_level['children'].each do |test|
            test['id'].gsub!('Auth', new_name)
          end
        end

        data_group = {
          'name' => 'Bulk Transfer',
          'type' => 'group',
          'children' => structure['children'].drop(1)
        }

        structure['children'] = [auth_group, data_group]
        structure
      end

      # def generate_sequence(sequence)

      #   file_name = OUT_PATH + '/bdt/bdt_' + sequence[:id].downcase + '_sequence.rb'

      #   template = ERB.new(File.read(GEN_PATH + '/templates/sequence.rb.erb'))
      #   output =   template.result_with_hash(sequence)

      #   File.write(file_name, output)

      # end

      # def generate_module(module_info)

      # end

      def clean_test_name(test_name)
        test_name.gsub("'", '"')
      end
    end
  end
end
