# frozen_string_literal: true

class MetadataExtractor
  CAPABILITY_STATEMENT_URI = 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.json'
  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

  def profile_uri(profile)
    "https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-#{profile}.json"
  end

  def search_param_uri(resource, param)
    param = 'id' if param == '_id'
    "https://build.fhir.org/ig/HL7/US-Core-R4/SearchParameter-us-core-#{resource.downcase}-#{param}.json"
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

  def extract_metadata
    capability_statement_json = get_json_from_uri(CAPABILITY_STATEMENT_URI)
    @metadata = extract_metadata_from_resources(capability_statement_json['rest'][0]['resource'])
    add_special_cases
    @metadata
  end

  def build_new_sequence(resource, profile)
    base_name = profile.split('StructureDefinition/')[1]
    {
      name: base_name.tr('-', '_'),
      classname: base_name
        .split('-')
        .map(&:capitalize)
        .join
        .gsub('UsCore', 'UsCoreR4') + 'Sequence',
      resource: resource['type'],
      profile: profile_uri(base_name), # link in capability statement is incorrect
      interactions: [],
      searches: [],
      search_param_descriptions: {},
      element_descriptions: {},
      must_supports: [],
      tests: []
    }
  end

  def extract_metadata_from_resources(resources)
    data = {
      sequences: []
    }

    resources.each do |resource|
      resource['supportedProfile'].each do |supported_profile|
        new_sequence = build_new_sequence(resource, supported_profile)

        add_basic_searches(resource, new_sequence)
        add_combo_searches(resource, new_sequence)
        add_interactions(resource, new_sequence)

        profile_definition = get_json_from_uri(new_sequence[:profile])
        add_must_support_elements(profile_definition, new_sequence)
        add_search_param_descriptions(profile_definition, new_sequence)
        add_element_definitions(profile_definition, new_sequence)

        data[:sequences] << new_sequence
      end
    end
    data
  end

  def add_basic_searches(resource, sequence)
    basic_searches = resource['searchParam']
    basic_searches&.each do |search_param|
      new_search_param = {
        names: [search_param['name']],
        expectation: search_param['extension'][0]['valueCode']
      }
      sequence[:searches] << new_search_param
      sequence[:search_param_descriptions][search_param['name'].to_sym] = {}
    end
  end

  def add_combo_searches(resource, sequence)
    search_combos = resource['extension'] || []
    search_combo_url = 'http://hl7.org/fhir/StructureDefinition/capabilitystatement-search-parameter-combination'
    search_combos
      .select { |combo| combo['url'] == search_combo_url }
      .each do |combo|
        combo_params = combo['extension']
        new_search_combo = {
          expectation: combo_params[0]['valueCode'],
          names: []
        }
        combo_params.each do |param|
          next unless param.key?('valueString')

          new_search_combo[:names] << param['valueString']
          sequence[:search_param_descriptions][param['valueString'].to_sym] = {}
        end
        sequence[:searches] << new_search_combo
      end
  end

  def add_interactions(resource, sequence)
    interactions = resource['interaction']
    interactions&.each do |interaction|
      new_interaction = {
        code: interaction['code'],
        expectation: interaction['extension'][0]['valueCode']
      }
      sequence[:interactions] << new_interaction
    end
  end

  def add_must_support_elements(profile_definition, sequence)
    profile_definition['snapshot']['element'].select { |el| el['mustSupport'] }.each do |element|
      if element['path'].end_with? 'extension'
        sequence[:must_supports] <<
          {
            type: 'extension',
            id: element['id'],
            path: element['path'],
            url: element['type'].first['profile'].first
          }
        next
      end

      path = element['path']
      if path.include? '[x]'
        choice_el = profile_definition['snapshot']['element'].find { |el| el['id'] == (path.split('[x]').first + '[x]') }
        choice_el['type'].each do |type|
          sequence[:must_supports] <<
            {
              type: 'element',
              path: path.gsub('[x]', type['code'])
            }
        end
      else
        sequence[:must_supports] <<
          {
            type: 'element',
            path: path
          }
      end
    end
  end

  def add_search_param_descriptions(profile_definition, sequence)
    sequence[:search_param_descriptions].each_key do |param|
      search_param_definition = get_json_from_uri(search_param_uri(sequence[:resource], param.to_s))
      path_parts = search_param_definition['xpath'].split('/f:')
      if param.to_s != '_id'
        path_parts[0] = sequence[:resource]
        path = path_parts.join('.')
      else
        path = path_parts[0]
      end
      profile_element = profile_definition['snapshot']['element'].select { |el| el['id'] == path }.first
      param_metadata = {
        path: path,
        comparators: {}
      }
      if !profile_element.nil?
        param_metadata[:type] = profile_element['type'].first['code']
        param_metadata[:contains_multiple] = (profile_element['max'] == '*')
      else
        # search is a variable type eg.) Condition.onsetDateTime - element in profile def is Condition.onset[x]
        param_metadata[:type] = search_param_definition['type']
        param_metadata[:contains_multiple] = false
      end
      search_param_definition['comparator']&.each_with_index do |comparator, index|
        expectation = search_param_definition['_comparator'][index]['extension'].first['valueCode']
        param_metadata[:comparators][comparator.to_sym] = expectation
      end
      sequence[:search_param_descriptions][param] = param_metadata
    end
  end

  def add_element_definitions(profile_definition, sequence)
    profile_definition['snapshot']['element'].each do |element|
      next if element['type'].nil? # base profile

      path = element['id']
      if path.include? '[x]'
        element['type'].each do |type|
          sequence[:element_descriptions][path.gsub('[x]', type['code']).downcase.to_sym] = { type: type['code'], contains_multiple: element['max'] == '*' }
        end
      else
        sequence[:element_descriptions][path.downcase.to_sym] = { type: element['type'].first['code'], contains_multiple: element['max'] == '*' }
      end
    end
  end

  def add_special_cases
    category_first_profiles = [
      'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-diagnosticreport-lab.json',
      'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-observation-lab.json',
      'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-diagnosticreport-note.json'
    ]

    # search by patient first
    @metadata[:sequences].each do |sequence|
      patient_search = sequence[:searches].select { |param| param[:names] == ['patient'] } &.first
      unless patient_search.nil?
        sequence[:searches].delete(patient_search)
        sequence[:searches].unshift(patient_search)
      end
    end

    # search by patient + category first for these specific profiles
    @metadata[:sequences].select { |sequence| category_first_profiles.include?(sequence[:profile]) }.each do |sequence|
      category_search = sequence[:searches].select { |param| param[:names] == ['patient', 'category'] } &.first
      unless category_search.nil?
        sequence[:searches].delete(category_search)
        sequence[:searches].unshift(category_search)
      end
    end
  end
end
