# frozen_string_literal: true

require 'erb'
require 'pry'
require 'fileutils'
require 'net/http'
require 'fhir_models'

OUT_PATH = '../../lib/app/modules'
RESOURCE_PATH = '../../resources/us_core_r4/'

def run
  redownload_files = (ARGV&.first == '-d')
  FileUtils.rm Dir.glob("#{RESOURCE_PATH}*") if redownload_files

  capability_statement_json = get_json_from_uri('https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.json')
  resources = capability_statement_json['rest'][0]['resource']
  metadata = extract_metadata(resources)
  generate_tests(metadata)
  generate_search_validators(metadata)
  metadata[:sequences].each do |sequence|
    generate_sequence(sequence)
  end
  generate_module(metadata)
end

def get_json_from_uri(uri)
  filename = RESOURCE_PATH + uri.split('/').last
  unless File.exist?(filename)
    puts "Downloading #{uri}\n"
    json_result = Net::HTTP.get(URI(uri))
    JSON.parse(json_result)
    File.write(filename, json_result)
  end

  JSON.parse(File.read(filename))
end

def extract_metadata(resources)
  data = {
    name: 'test',
    sequences: []
  }

  resources.each do |resource|
    resource['supportedProfile'].each do |supported_profile|
      new_sequence = {
        name: supported_profile.split('StructureDefinition/')[1].tr('-', '_'),
        classname: supported_profile.split('StructureDefinition/')[1].split('-').map(&:capitalize).join.gsub('UsCore', 'UsCoreR4') + 'Sequence',
        resource: resource['type'],
        profile: "https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-#{supported_profile.split('StructureDefinition/')[1]}.json", # links in capability statement currently incorrect
        interactions: [],
        search_params: [],
        search_combos: [],
        tests: []
      }
      search_params = resource['searchParam']
      search_params&.each do |search_param|
        new_search_param = {
          names: [search_param['name']],
          expectation: search_param['extension'][0]['valueCode']
        }
        if search_param['name'] == 'patient' # move patient search first
          new_sequence[:search_params].insert(0, new_search_param)
        else
          new_sequence[:search_params] << new_search_param
        end
      end
      # assume extension is just the search combinations
      # assume to be SHALL
      search_combos = resource['extension']
      search_combos&.each do |combo|
        next unless combo['url'] == 'http://hl7.org/fhir/StructureDefinition/capabilitystatement-search-parameter-combination'

        combo_params = combo['extension']
        new_search_combo = {
          expectation: combo_params[0]['valueCode'],
          names: []
        }
        combo_params.each do |param|
          new_search_combo[:names] << param['valueString'] if param.key?('valueString')
        end
        # special case - set search by category first for these two profiles
        if new_search_combo[:names] == ['patient', 'category'] && (new_sequence[:profile] == 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-diagnosticreport-lab.json' || new_sequence[:profile] == 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-observation-lab.json' || new_sequence[:profile] == 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-diagnosticreport-note.json')
          new_sequence[:search_params].insert(0, new_search_combo)
        else
          new_sequence[:search_params] << new_search_combo
        end
      end
      interactions = resource['interaction']
      interactions&.each do |interaction|
        new_interaction = {
          code: interaction['code'],
          expectation: interaction['extension'][0]['valueCode']
        }
        new_sequence[:interactions] << new_interaction
      end
      data[:sequences] << new_sequence
    end
  end
  data
end

def generate_search_validators(metadata)
  metadata[:sequences].each do |sequence|
    sequence[:search_validator] = create_search_validation(sequence[:resource], sequence[:profile], sequence[:search_params])
  end
end

def generate_tests(metadata)
  metadata[:sequences].each do |sequence|
    puts "Generating test #{sequence[:name]}"
    # authorization test
    create_authorization_test(sequence)

    # make tests for each SHALL and SHOULD search param, SHALL's first
    sequence[:search_params].each do |search_param|
      create_search_test(sequence, search_param) if search_param[:expectation] == 'SHALL'
    end

    sequence[:search_params].each do |search_param|
      create_search_test(sequence, search_param) if search_param[:expectation] == 'SHOULD'
    end

    # make tests for each SHALL and SHOULD interaction
    sequence[:interactions].each do |interaction|
      next unless interaction[:expectation] == 'SHALL' ||  interaction[:expectation] == 'SHOULD'

      # specific edge cases
      interaction[:code] = 'history' if interaction[:code] == 'history-instance'
      next if interaction[:code] == 'search-type'

      create_interaction_test(sequence, interaction)
    end

    create_resource_profile_test(sequence)
    create_references_resolved_test(sequence)
  end
end

def generate_sequence(sequence)
  puts "Generating #{sequence[:name]}\n"
  file_name = OUT_PATH + '/us_core_r4/' + sequence[:name].downcase + '_sequence.rb'

  template = ERB.new(File.read('./templates/sequence.rb.erb'))
  output =   template.result_with_hash(sequence)
  FileUtils.mkdir_p(OUT_PATH + '/us_core_r4') unless File.directory?(OUT_PATH + '/us_core_r4')
  File.write(file_name, output)
end

def get_search_param_json(resource, param)
  param = 'id' if param == '_id' # special case for _id
  uri = "https://build.fhir.org/ig/HL7/US-Core-R4/SearchParameter-us-core-#{resource}-#{param}.json"
  get_json_from_uri(uri)
rescue StandardError
end

def get_variable_type_from_structure_def(resource, profile, var)
  resource_struct_def = get_json_from_uri(profile)
  element_def = resource_struct_def['snapshot']['element'].select { |el| el['id'] == "#{resource}.#{var}" }.first unless resource_struct_def.nil?
  return element_def['type'].first['code'] unless element_def.nil?

  'test'
end

def get_variable_contains_multiple(resource, profile, var)
  resource_struct_def = get_json_from_uri(profile)
  element_def = resource_struct_def['snapshot']['element'].select { |el| el['id'] == "#{resource}.#{var}" }.first unless resource_struct_def.nil?
  return element_def['max'] == '*' unless element_def.nil?
end

def create_authorization_test(sequence)
  authorization_test = {
    tests_that: "Server rejects #{sequence[:resource]} search without authorization",
    index: format('%02d', (sequence[:tests].length + 1)),
    link: 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
  }

  authorization_test[:test_code] = %(
        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(versioned_resource_class('#{sequence[:resource]}'), {patient: @instance.patient_id})
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
  )

  sequence[:tests] << authorization_test
end

def create_search_test(sequence, search_param)
  search_test = {
    tests_that: "Server returns expected results from #{sequence[:resource]} search by #{search_param[:names].join('+')}",
    index: format('%02d', (sequence[:tests].length + 1)),
    link: 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
  }

  is_first_search = search_test[:index] == '02' # if first search - fix this check later
  search_test[:test_code] =
    if is_first_search
      %(
        #{get_search_params(sequence[:resource], sequence[:profile], search_param[:names])}
        reply = get_resource_by_params(versioned_resource_class('#{sequence[:resource]}'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        if resource_count > 0
          @resources_found = true
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @#{sequence[:resource].downcase} = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(versioned_resource_class('#{sequence[:resource]}'), reply, search_params)
        save_resource_ids_in_bundle(versioned_resource_class('#{sequence[:resource]}'), reply)
      )
    else
      %(
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@#{sequence[:resource].downcase}.nil?, 'Expected valid #{sequence[:resource]} resource to be present'
        #{get_search_params(sequence[:resource], sequence[:profile], search_param[:names])}
        reply = get_resource_by_params(versioned_resource_class('#{sequence[:resource]}'), search_params)
        assert_response_ok(reply)
      )
    end
  sequence[:tests] << search_test
end

def create_interaction_test(sequence, interaction)
  interaction_test = {
    tests_that: "#{sequence[:resource]} #{interaction[:code]} resource supported",
    index: format('%02d', (sequence[:tests].length + 1)),
    link: 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
  }

  interaction_test[:test_code] = %(
        skip_if_not_supported(:#{sequence[:resource]}, [:#{interaction[:code]}])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_#{interaction[:code]}_reply(@#{sequence[:resource].downcase}, versioned_resource_class('#{sequence[:resource]}'))
  )

  sequence[:tests] << interaction_test
end

def create_resource_profile_test(sequence)
  test = {
    tests_that: "#{sequence[:resource]} resources associated with Patient conform to Argonaut profiles",
    index: format('%02d', (sequence[:tests].length + 1)),
    link: sequence[:profile]
  }
  test[:test_code] = %(
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('#{sequence[:resource]}')
  )

  sequence[:tests] << test
end

def create_references_resolved_test(sequence)
  test = {
    tests_that: 'All references can be resolved',
    index: format('%02d', (sequence[:tests].length + 1)),
    link: 'https://www.hl7.org/fhir/DSTU2/references.html'
  }

  test[:test_code] = %(
        skip_if_not_supported(:#{sequence[:resource]}, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@#{sequence[:resource].downcase})
  )
  sequence[:tests] << test
end

def get_search_params(resource, profile, search_combo)
  search_param = []
  access_code = ''
  search_combo.each do |param|
    # manually set for now - try to find in metadata if available later
    if resource == 'CarePlan' && search_combo == ['patient', 'category']
      return %(
        search_params = {patient: @instance.patient_id, category: "assess-plan"}
      )
    end
    if resource == 'CareTeam' && search_combo == ['patient', 'status']
      return %(
        search_params = {patient: @instance.patient_id, status: "active"}
      )
    end
    if (resource == 'Location' || resource == 'Organization') && search_combo == ['name']
      return %(
        search_params = {patient: @instance.patient_id, name: "Boston"}
      )
    end
    if resource == 'Patient' && search_combo == ['_id']
      return %(
        search_params = {'_id': @instance.patient_id}
      )
    end
    if profile == 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-smokingstatus.json' && search_combo == ['patient', 'code']
      return %(
        search_params = {patient: @instance.patient_id, code: "72166-2"}
      )
    end
    if profile == 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-observation-lab.json' && search_combo == ['patient', 'category']
      return %(
        search_params = {patient: @instance.patient_id, category: "laboratory"}
      )
    end
    if profile == 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-pediatric-weight-for-height.json' && search_combo == ['patient', 'code']
      return %(
        search_params = {patient: @instance.patient_id, code: "77606-2"}
      )
    end
    if profile == 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-pediatric-bmi-for-age.json' && search_combo == ['patient', 'code']
      return %(
        search_params = {patient: @instance.patient_id, code: "59576-9"}
      )
    end
    if profile == 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-diagnosticreport-lab.json' && search_combo == ['patient', 'category']
      return %(
        search_params = {patient: @instance.patient_id, category: "LAB"}
      )
    end
    if profile == 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-diagnosticreport-note.json' && search_combo == ['patient', 'category']
      return %(
        search_params = {patient: @instance.patient_id, code: "LP29684-5"}
      )
    end
    if param == 'patient'
      access_code += %(
        patient_val = @instance.patient_id)
      search_param << "'#{param}': #{param.tr('-', '_')}_val"
      next
    end
    search_param_struct = get_search_param_json(resource.downcase, param)
    path = search_param_struct['xpath']
    path_parts = path.split('/f:')
    path_parts.delete_at(0)
    path_parts = ['id'] if param == '_id' # xpath for id doesn't follow the format of others
    element_name = path_parts.join('.')
    type = get_variable_type_from_structure_def(resource, profile, element_name)
    contains_multiple = get_variable_contains_multiple(resource, profile, path_parts[0])
    path_parts[0] += '.first' if contains_multiple
    access_code += %(
        #{param.tr('-', '_')}_val = @#{resource.downcase}&.#{path_parts.join('&.')})
    case type
    when 'CodeableConcept'
      access_code += '&.coding&.first&.code'
    when 'Reference'
      access_code += '&.reference.first'
    when 'Period'
      access_code += '&.start'
    when 'Identifier'
      access_code += '&.value'
    when 'Coding'
      access_code += '&.code'
    when 'HumanName'
      access_code += '&.family'
    end
    search_param << "'#{param}': #{param.tr('-', '_')}_val"
  end

  %(#{access_code}
        search_params = {#{search_param.join(', ')}}
  )
end

def create_search_validation(resource, profile, search_params)
  return if search_params.empty?

  search_validators = ''
  search_params.each do |search_param|
    next if search_param[:names].length != 1

    param = search_param[:names].first
    search_param_struct = get_search_param_json(resource.downcase, param)
    path = search_param_struct['xpath']
    path_parts = path.split('/f:')
    path_parts.delete_at(0)
    path_parts = ['id'] if param == '_id' # xpath for id doesn't follow the format of others
    element_name = path_parts.join('.')
    type = get_variable_type_from_structure_def(resource, profile, element_name)
    contains_multiple = get_variable_contains_multiple(resource, profile, element_name)
    resource_metadata = FHIR.const_get(resource).const_get('METADATA')
    case type
    when 'CodeableConcept'
      search_validators += %(
        when '#{param}'
          codings = resource&.#{path_parts.join('&.')}#{'.first' if contains_multiple}&.coding
          assert !codings.nil?, "#{param} on resource did not match #{param} requested"
          assert codings.any? {|coding| !coding.try(:code).nil? && coding.try(:code) == value}, "#{param} on resource did not match #{param} requested"
      )
    when 'Reference'
      search_validators += %(
        when '#{param}'
          assert (resource&.#{path_parts.join('&.')} && resource.#{path_parts.join('&.')}.reference.include?(value)), "#{param} on resource does not match #{param} requested"
      )
    when 'HumanName'
      # When a string search parameter refers to the types HumanName and Address, the search covers the elements of type string, and does not cover elements such as use and period
      # https://www.hl7.org/fhir/search.html#string
      search_validators += if resource_metadata[param]['max'] > 1
                             %(
                               when '#{param}'
                                 found = resource.#{path_parts.join('&.')}.any? do |name|
                                   name&.text&.include?(value) ||
                                     name&.family.include?(value) ||
                                     name&.given.any{|given| given&.include?(value)} ||
                                     name&.prefix.any{|prefix| prefix&.include?(value)} ||
                                     name&.suffix.any{|suffix| suffix&.include?(value)}
                                 end
                                 assert found, "#{param} on resource does not match #{param} requested"
                             )
                           else
                             %(
                               when '#{param}'
                                 name = resource&.#{path_parts.join('&.')}
                                 found = name&.text&.include?(value) ||
                                   name&.family.include?(value) ||
                                   name&.given.any{|given| given&.include?(value)} ||
                                   name&.prefix.any{|prefix| prefix&.include?(value)} ||
                                   name&.suffix.any{|suffix| suffix&.include?(value)}

                                 assert found, "#{param} on resource does not match #{param} requested"
                             )

                           end
    when 'code', 'string', 'id'
      search_validators += %(
        when '#{param}'
          assert resource&.#{path_parts.join('&.')} != nil && resource&.#{path_parts.join('&.')} == value, "#{param} on resource did not match #{param} requested"
      )
    when 'Coding'
      search_validators += %(
        when '#{param}'
          assert !resource&.#{path_parts.join('&.')}&.code.nil? && resource&.#{path_parts.join('&.')}&.code == value, "#{param} on resource did not match #{param} requested"
      )

    when 'Identifier'
      search_validators += %(
        when '#{param}'
          assert resource&.#{path_parts.join('&.')} != nil && resource.#{path_parts.join('&.')}.any?{|identifier| identifier.value == value}, "#{param} on resource did not match #{param} requested"
      )
    else
      search_validators += %(
        when '#{param}'
      )

    end
  rescue StandardError
    print "#{resource} - #{param}" # gets here if param is '_id' because it fails to get the search param definition
  end

  validate_function = ''

  unless search_validators.empty?
    validate_function = %(
        def validate_resource_item (resource, property, value)
          case property
          #{search_validators}
          end
        end
    )
  end

  validate_function
end

def generate_module(module_info)
  file_name = OUT_PATH + '/us_core_module.yml'

  template = ERB.new(File.read('./templates/module.yml.erb'))
  output = template.result_with_hash(module_info)

  File.write(file_name, output)
end

run
# print create_search_validation('AllergyIntolerance', 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-allergyintolerance.json', [{name:'patient'}, {name:'clinical-status'}])
