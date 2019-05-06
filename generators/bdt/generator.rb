require 'erb'
require 'pry'
require 'fileutils'

GEN_PATH = './generators/bdt'
OUT_PATH = './lib/app/modules'

def run()

  copy_base()

  revised_structure = revise_structure(GEN_PATH + '/bdt-structure.json')

  metadata = extract_metadata(revised_structure)

  metadata[:groups].map{|g| g[:sequences]}.flatten.each{|s| generate_sequence(s)}
  generate_module(metadata)

end

def copy_base()
  FileUtils.cp(GEN_PATH + '/templates/bdt_base.rb', OUT_PATH + '/bdt/')
end

def revise_structure(json_path)

  structure = JSON.parse(File.read(json_path))

  auth_group = structure['children'][0]

  auth_group['children'].each do |seq_level|

    new_name = 'Auth_' + seq_level['name'].gsub(' ','_')

    match = seq_level['name'].match(/([^\s]+\-level)+/)
    unless match.nil?
      new_name = 'Auth_' + match[1].gsub('-','_')
    end

    seq_level['children'].each do |test|
      test['id'].gsub!('Auth', new_name)
    end
  end

  data_group = {
    'name' => 'Bulk Transfer',
    'type' => 'group',
    'children' => structure['children'].drop(1)
  }

  structure['children'] = [auth_group,data_group]
  structure
end

def generate_sequence(sequence)

  file_name = OUT_PATH + '/bdt/bdt_' + sequence[:id].downcase + '_sequence.rb'

  template = ERB.new(File.read(GEN_PATH + '/templates/sequence.rb.erb'))
  output =   template.result_with_hash(sequence)

  File.write(file_name, output)

end

def generate_module(module_info)

  file_name = OUT_PATH + '/bdt_module.yml'

  template = ERB.new(File.read(GEN_PATH + '/templates/module.yml.erb'))
  output = template.result_with_hash(module_info)

  File.write(file_name, output)

end

def clean_test_name(test_name)
  test_name.gsub("'",'"')
end

def extract_test_from_group(group, list)
  group['children'].each do |child|
    if(child['type'] == group)
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

def extract_metadata(source)

  data = {
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

      new_sequence[:id] = new_sequence[:tests].first&.dig(:id)&.split("-").first
      new_sequence[:name] = new_sequence[:id].split('_').map(&:capitalize).join(' ')
      new_sequence[:description] = sequence['name']
      new_sequence[:sequence_class_name] = 'BDT'+ new_sequence[:id].split('_').map(&:capitalize).join + 'Sequence'

      new_group[:sequences]  << new_sequence

    end

    data[:groups] << new_group
  end

  data
end


run()




