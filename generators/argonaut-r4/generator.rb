require 'erb'
require 'pry'
require 'fileutils'
require 'net/http'
require 'fhir_models'

OUT_PATH = '../../lib/app/modules'
RESOURCE_PATH = '../../resources/us_core_r4/'

search_parameter_combination_url = "http://hl7.org/fhir/StructureDefinition/capabilitystatement-search-parameter-combination"

def run()

  redownload_files = (ARGV&.first == '-d')
  if redownload_files
    FileUtils.rm Dir.glob("#{RESOURCE_PATH}*")
  end

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
  if !File.exists?(filename)
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
    resource['supportedProfile'].each do |supportedProfile|
      new_sequence = {
        name: supportedProfile.split('StructureDefinition/')[1].gsub('-','_'),
        classname: supportedProfile.split('StructureDefinition/')[1].split('-').map(&:capitalize).join.gsub('UsCore','UsCoreR4') + 'Sequence',
        resource: resource['type'],
        profile: "https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-#{supportedProfile.split('StructureDefinition/')[1]}.json", #links in capability statement currently incorrect
        interactions: [],
        search_params: [],
        search_combos: [],
        tests: []
      }
      searchParams = resource['searchParam']
      if !searchParams.nil? then 
        searchParams.each do |searchParam|
          new_search_param = {
            name: searchParam['name'],
            expectation: searchParam['extension'][0]['valueCode']
          }
          new_sequence[:search_params] << new_search_param
        end
      end
      # assume extension is just the search combinations
      # assume to be SHALL
      search_combos = resource['extension']
      if !search_combos.nil? then
        search_combos.each do |combo|
          if combo['url'] == "http://hl7.org/fhir/StructureDefinition/capabilitystatement-search-parameter-combination" then
            combo_params = combo['extension']
            new_search_combo = {
              expectation:  combo_params[0]['valueCode'],
              names: []
            }
            combo_params.each do |param|
              if param.key?('valueString') then
                new_search_combo[:names] << param['valueString']
              end
            end
            new_sequence[:search_combos] << new_search_combo
          end
        end
      end
      interactions = resource['interaction']
      if !interactions.nil? then
        interactions.each do |interaction|
          new_interaction = {
            code: interaction['code'],
            expectation:  interaction['extension'][0]['valueCode']
          }
          new_sequence[:interactions] << new_interaction
        end
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
      if search_param[:expectation] == "SHALL"  then
        create_search_test(sequence, search_param)
      end
    end

    sequence[:search_params].each do |search_param|
      if search_param[:expectation] == "SHOULD" then
        create_search_test(sequence, search_param)
      end
    end

    sequence[:search_combos].each do |search_combo|
      if search_combo[:expectation] == "SHALL" then
        create_search_combo_test(sequence, search_combo)
      end
    end

    sequence[:search_combos].each do |search_combo|
      if search_combo[:expectation] == "SHOULD" then
        create_search_combo_test(sequence, search_combo)
      end
    end

    # make tests for each SHALL and SHOULD interaction
    sequence[:interactions].each do |interaction|
      if interaction[:expectation] == "SHALL" ||  interaction[:expectation] == "SHOULD" then
        # specific edge cases
        interaction[:code] = "history" if interaction[:code] == "history-instance"
        next if interaction[:code] == "search-type"
        create_interaction_test(sequence, interaction)
      end
    end

    create_resource_profile_test(sequence)
    create_references_resolved_test(sequence)
  end
end

def generate_sequence(sequence)
  puts "Generating #{sequence[:name]}\n"
  file_name = OUT_PATH + '/us_core_r4/'+ sequence[:name].downcase + '_sequence.rb'

  template = ERB.new(File.read('./templates/sequence.rb.erb'))
  output =   template.result_with_hash(sequence)
  unless File.directory?(OUT_PATH + '/us_core_r4')
    FileUtils.mkdir_p(OUT_PATH + '/us_core_r4')
  end
  File.write(file_name, output)
end

def get_search_param_json(resource, param)
  begin
    uri = "https://build.fhir.org/ig/HL7/US-Core-R4/SearchParameter-us-core-#{resource}-#{param}.json"
    get_json_from_uri(uri)
  rescue
  end
end

def get_variable_type_from_structure_def(resource, profile, var)
  resource_struct_def = get_json_from_uri(profile)
  element_def = resource_struct_def['snapshot']['element'].select{|el| el['id'] == "#{resource}.#{var}"}.first if !resource_struct_def.nil?
  return element_def['type'].first['code'] if !element_def.nil?
  return 'test'
end

def create_authorization_test(sequence)
  authorization_test = {
    tests_that: "Server rejects #{sequence[:resource]} search without authorization",
    index: sequence[:tests].length + 1,
    link: "http://www.fhir.org/guides/argonaut/r2/Conformance-server.html"
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
    tests_that: "Server returns expected results from #{sequence[:resource]} search by #{search_param[:name]}",
    index: sequence[:tests].length + 1,
    link: "https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html"
  }

  search_test[:test_code] = %(
        search_params = {patient: @instance.patient_id}
        reply = get_resource_by_params(versioned_resource_class('#{sequence[:resource]}'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_search_reply(versioned_resource_class('#{sequence[:resource]}'), reply, search_params)
  )

  if search_test[:index] == 2 then
    # if first search - fix this check later
    search_test[:test_code] += %(
        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        if resource_count > 0
          @resources_found = true
        end
        @#{sequence[:resource].downcase} = reply.try(:resource).try(:entry).try(:first).try(:resource)
        save_resource_ids_in_bundle(versioned_resource_class('#{sequence[:resource]}'), reply)
    )
  end

  sequence[:tests] << search_test
end

def create_search_combo_test(sequence, search_combo)
  search_combo_test = {
    tests_that: "Server returns expected results from #{sequence[:resource]} search by #{search_combo[:names].join(' + ')}",
    index: sequence[:tests].length + 1,
    link: "https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html"
  }

  search_params = []
  search_combo[:names].each do |param|
    search_params << ("'#{param}': ") 
  end
  search_combo_test[:test_code] = %(
        #{get_search_params(sequence[:resource], sequence[:profile], search_combo[:names])}
        reply = get_resource_by_params(versioned_resource_class('#{sequence[:resource]}'), search_params)
        validate_search_reply(versioned_resource_class('#{sequence[:resource]}'), reply, search_params)
  )

  if search_combo_test[:index] == 2 then
    # if first search - fix this check later
    search_combo_test[:test_code] += %(
        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        if resource_count > 0
          @resources_found = true
        end
        @#{sequence[:resource].downcase} = reply.try(:resource).try(:entry).try(:first).try(:resource)
        save_resource_ids_in_bundle(versioned_resource_class('#{sequence[:resource]}'), reply)

    )
  end

  sequence[:tests] << search_combo_test
end

def create_interaction_test(sequence, interaction)

  interaction_test = {
    tests_that: "#{sequence[:resource]} #{interaction[:code]} resource supported",
    index: sequence[:tests].length + 1,
    link: "https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html"
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
    index: sequence[:tests].length + 1,
    link: ''
  }
  test[:test_code] = %(
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('#{sequence[:resource]}')
  )

  sequence[:tests] << test
end

def create_references_resolved_test(sequence)
  test = {
    tests_that: "All references can be resolved",
    index: sequence[:tests].length + 1,
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
  accessCode = ""
  search_combo.each do |param|
    if param == 'patient' then
      accessCode += %(
        patient_val = @instance.patient_id)
        search_param << ("'#{param}': #{param.gsub('-','_')}_val") 
      next
    end
    search_param_struct = get_search_param_json(resource.downcase, param)
    path = search_param_struct['xpath']
    path_parts = path.split('/f:')
    element_name = path_parts[1] # assume this for now
    type = get_variable_type_from_structure_def(resource, profile, element_name)
    accessCode += %(
        #{param.gsub('-','_')}_val = @#{resource.downcase}.try(:#{element_name}))
    if type == 'CodeableConcept' then
      accessCode += ".try(:coding).try(:first).try(:code)"
    end
    search_param << ("'#{param}': #{param.gsub('-','_')}_val") 
  end


  return %(#{accessCode}
        search_params = {#{search_param.join(', ')}}
  )
end

def create_search_validation(resource, profile, search_params)

  
  search_validators = ""
  search_params.each do |search_param|
    begin
      param = search_param[:name]
      search_param_struct = get_search_param_json(resource.downcase, param)
      path = search_param_struct['xpath']
      path_parts = path.split('/f:')
      element_name = path_parts[1] # assume this for now
      type = get_variable_type_from_structure_def(resource, profile, element_name)
      resource_metadata = FHIR.const_get(resource).const_get('METADATA')
      binding.pry if resource == 'Medication'
      case type
      when 'CodeableConcept'
        search_validators += %(
          when '#{param}'
            codings = resource.try(:#{element_name}).try(:coding)
            assert !codings.nil?, "#{param} on resource did not match #{param} requested"
            assert codings.any? {|coding| !coding.try(:code).nil? && coding.try(:code) == value}, "#{param} on resource did not match #{param} requested"
        )
      when 'Reference'
        search_validators += %(
          when '#{param}'
            assert (resource.#{param} && resource.#{param}.reference.include?(value)), "#{param} on resource does not match #{param} requested"
        ) 
      when 'HumanName'
        # When a string search parameter refers to the types HumanName and Address, the search covers the elements of type string, and does not cover elements such as use and period
        # https://www.hl7.org/fhir/search.html#string
        if resource_metadata[param]['max'] > 1
          search_validators += %(
            when '#{param}'
              found = resource.#{param}.any? do |name|
                name&.text&.include?(value) ||
                  name&.family.include?(value) || 
                  name&.given.any{|given| given&.include?(value)} ||
                  name&.prefix.any{|prefix| prefix&.include?(value)} ||
                  name&.suffix.any{|suffix| suffix&.include?(value)}
              end
              assert found, "#{param} on resource does not match #{param} requested"
          ) 

        else
          search_validators += %(
            when '#{param}'
              name = resource.#{param}
              found = name&.text&.include?(value) ||
                name&.family.include?(value) ||
                name&.given.any{|given| given&.include?(value)} ||
                name&.prefix.any{|prefix| prefix&.include?(value)} ||
                name&.suffix.any{|suffix| suffix&.include?(value)}

              assert found, "#{param} on resource does not match #{param} requested"
          ) 

        end
      
      end
    rescue => e
      print "#{resource} - #{param}" # gets here if param is '_id' because it fails to get the search param definition
    end


  end

  validate_function = ''

  if !search_validators.empty?
    validate_function =  %(
        def validate_resource_item (resource, property, value)
          case property
          #{search_validators}
          end
        end
    )
  end

  binding.pry if resource == 'Medication'

  validate_function
end

def generate_module(module_info)

  file_name = OUT_PATH + '/us_core_module.yml'

  template = ERB.new(File.read('./templates/module.yml.erb'))
  output = template.result_with_hash(module_info)

  File.write(file_name, output)

end


run()
# print create_search_validation('AllergyIntolerance', 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-allergyintolerance.json', [{name:'patient'}, {name:'clinical-status'}])