# frozen_string_literal: true

require 'erb'
require 'pry'
require 'fileutils'
require 'net/http'
require 'fhir_models'
require_relative './metadata_extractor'

OUT_PATH = '../../lib/app/modules'
RESOURCE_PATH = '../../resources/us_core_r4/'

def run
  redownload_files = (ARGV&.first == '-d')
  FileUtils.rm Dir.glob("#{RESOURCE_PATH}*") if redownload_files

  metadata_extractor = MetadataExtractor.new
  metadata = metadata_extractor.extract_metadata
  generate_tests(metadata)
  generate_search_validators(metadata)
  metadata[:sequences].each do |sequence|
    generate_sequence(sequence)
  end
  generate_module(metadata)
end

def generate_search_validators(metadata)
  metadata[:sequences].each do |sequence|
    sequence[:search_validator] = create_search_validation(sequence)
  end
end

def generate_tests(metadata)
  metadata[:sequences].each do |sequence|
    puts "Generating test #{sequence[:name]}"
    # authorization test
    create_authorization_test(sequence)

    # make tests for each SHALL and SHOULD search param, SHALL's first
    sequence[:searches]
      .select { |search_param| search_param[:expectation] == 'SHALL' }
      .each { |search_param| create_search_test(sequence, search_param) }

    sequence[:searches]
      .select { |search_param| search_param[:expectation] == 'SHOULD' }
      .each { |search_param| create_search_test(sequence, search_param) }

    # make tests for each SHALL and SHOULD interaction
    sequence[:interactions]
      .select { |interaction| ['SHALL', 'SHOULD'].include? interaction[:expectation] }
      .reject { |interaction| interaction[:code] == 'search-type' }
      .each do |interaction|
        # specific edge cases
        interaction[:code] = 'history' if interaction[:code] == 'history-instance'

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

def create_authorization_test(sequence)
  authorization_test = {
    tests_that: "Server rejects #{sequence[:resource]} search without authorization",
    index: format('%02d', (sequence[:tests].length + 1)),
    link: 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
  }

  authorization_test[:test_code] = %(
        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(versioned_resource_class('#{sequence[:resource]}'), patient: @instance.patient_id)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply)

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
      %(#{get_search_params(search_param[:names], sequence)}
        reply = get_resource_by_params(versioned_resource_class('#{sequence[:resource]}'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        @resources_found = true if resource_count.positive?

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @#{sequence[:resource].downcase} = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(versioned_resource_class('#{sequence[:resource]}'), reply, search_params)
        save_resource_ids_in_bundle(versioned_resource_class('#{sequence[:resource]}'), reply))
    else
      %(
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@#{sequence[:resource].downcase}.nil?, 'Expected valid #{sequence[:resource]} resource to be present'
#{get_search_params(search_param[:names], sequence)}
        reply = get_resource_by_params(versioned_resource_class('#{sequence[:resource]}'), search_params)
        assert_response_ok(reply))
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

        validate_#{interaction[:code]}_reply(@#{sequence[:resource].downcase}, versioned_resource_class('#{sequence[:resource]}')))

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
        test_resources_against_profile('#{sequence[:resource]}'))

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

        validate_reference_resolutions(@#{sequence[:resource].downcase}))
  sequence[:tests] << test
end

def get_safe_access_path(param, search_param_descriptions, element_descriptions)
  element_path = search_param_descriptions[param.to_sym][:path]
  path_parts = element_path.split('.')
  parts_with_multiple = []
  path_parts.each_with_index do |part, index|
    next if index.zero?
    next if element_path == 'Procedure.occurrenceDateTime' # bug in us core?

    cur_path = path_parts[0..index].join('.')
    path_parts[index] = 'local_class' if part == 'class' # match fhir_models because class is protected keyword in ruby
    parts_with_multiple << index if element_descriptions[cur_path.downcase.to_sym][:contains_multiple]
  end
  parts_with_multiple.each do |index|
    path_parts[index] += '&.first'
  end
  path_parts[0] = "@#{path_parts[0].downcase}"

  path_parts.join('&.')
end

def get_value_path_by_type(type)
  case type
  when 'CodeableConcept'
    '&.coding&.first&.code'
  when 'Reference'
    '&.reference&.first'
  when 'Period'
    '&.start'
  when 'Identifier'
    '&.value'
  when 'Coding'
    '&.code'
  when 'HumanName'
    '&.family'
  else
    ''
  end
end

def get_search_params(search_parameters, sequence)
  unless search_param_constants(search_parameters, sequence).nil?
    return %(
        search_params = { #{search_param_constants(search_parameters, sequence)} }\n)
  end
  search_values = []
  search_assignments = []
  search_parameters.each do |param|
    type = sequence[:search_param_descriptions][param.to_sym][:type]
    variable_name =
      if param == '_id'
        'id_val'
      else
        param.tr('-', '_') + '_val'
      end
    variable_value =
      if param == 'patient'
        '@instance.patient_id'
      else
        get_safe_access_path(param, sequence[:search_param_descriptions], sequence[:element_descriptions]) + get_value_path_by_type(type)
      end
    search_values << "#{variable_name} = #{variable_value}"
    search_assignments << "'#{param}': #{variable_name}"
  end

  search_code = ''
  search_values.each do |value|
    search_code += %(
        #{value})
  end
  search_code += %(
        search_params = { #{search_assignments.join(', ')} }
)
  search_code
end

def search_param_constants(search_parameters, sequence)
  return "patient: @instance.patient_id, category: 'assess-plan'" if search_parameters == ['patient', 'category'] && sequence[:resource] == 'CarePlan'
  return "patient: @instance.patient_id, status: 'active'" if search_parameters == ['patient', 'status'] && sequence[:resource] == 'CareTeam'
  return "patient: @instance.patient_id, name: 'Boston'" if search_parameters == ['name'] && (['Location', 'Organization'].include? sequence[:resource])
  return "'_id': @instance.patient_id" if search_parameters == ['_id'] && sequence[:resource] == 'Patient'
  return "patient: @instance.patient_id, code: '72166-2'" if search_parameters == ['patient', 'code'] && sequence[:profile] == 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-smokingstatus.json'
  return "patient: @instance.patient_id, category: 'laboratory'" if search_parameters == ['patient', 'category'] && sequence[:profile] == 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-observation-lab.json'
  return "patient: @instance.patient_id, code: '77606-2'" if search_parameters == ['patient', 'code'] && sequence[:profile] == 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-pediatric-weight-for-height.json'
  return "patient: @instance.patient_id, code: '59576-9'" if search_parameters == ['patient', 'code'] && sequence[:profile] == 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-pediatric-bmi-for-age.json'
  return "patient: @instance.patient_id, category: 'LAB'" if search_parameters == ['patient', 'category'] && sequence[:profile] == 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-diagnosticreport-lab.json'
  return "patient: @instance.patient_id, code: 'LP29684-5'" if search_parameters == ['patient', 'category'] && sequence[:profile] == 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-diagnosticreport-note.json'
end

def create_search_validation(sequence)
  search_validators = ''
  sequence[:search_param_descriptions].each do |element, definition|
    type = definition[:type]
    contains_multiple = definition[:contains_multiple]
    path_parts = definition[:path].split('.')
    path_parts[0] = 'resource'
    path_parts = path_parts.map { |part| part == 'class' ? 'local_class' : part }
    case type
    when 'CodeableConcept'
      search_validators += %(
        when '#{element}'
          codings = #{path_parts.join('&.')}#{'&.first' if contains_multiple}&.coding
          assert !codings.nil?, '#{element} on resource did not match #{element} requested'
          assert codings.any? { |coding| !coding.try(:code).nil? && coding.try(:code) == value }, '#{element} on resource did not match #{element} requested'
)
    when 'Reference'
      search_validators += %(
        when '#{element}'
          assert #{path_parts.join('&.')}&.reference&.include?(value), '#{element} on resource does not match #{element} requested'
)
    when 'HumanName'
      # When a string search parameter refers to the types HumanName and Address, the search covers the elements of type string, and does not cover elements such as use and period
      # https://www.hl7.org/fhir/search.html#string
      search_validators +=
        if contains_multiple
          %(
        when '#{element}'
          found = #{path_parts.join('&.')}&.any? do |name|
            name.text&.include?(value) ||
              name.family.include?(value) ||
              name.given.any { |given| given&.include?(value) } ||
              name.prefix.any { |prefix| prefix.include?(value) } ||
              name.suffix.any { |suffix| suffix.include?(value) }
          end
          assert found, '#{element} on resource does not match #{element} requested')
        else
          %(
        when '#{element}'
          name = #{path_parts.join('&.')}
          found = name&.text&.include?(value) ||
              name.family.include?(value) ||
              name.given.any { |given| given&.include?(value) } ||
              name.prefix.any { |prefix| prefix.include?(value) } ||
              name.suffix.any { |suffix| suffix.include?(value) }
          assert found, '#{element} on resource does not match #{element} requested')
        end
    when 'code', 'string', 'id'
      search_validators += %(
        when '#{element}'
          assert #{path_parts.join('&.')} == value, '#{element} on resource did not match #{element} requested'
)
    when 'Coding'
      search_validators += %(
        when '#{element}'
          assert #{path_parts.join('&.')}&.code == value, '#{element} on resource did not match #{element} requested'
)
    when 'Identifier'
      search_validators += %(
        when '#{element}'
          assert #{path_parts.join('&.')}&.any? { |identifier| identifier.value == value }, '#{element} on resource did not match #{element} requested'
)
    else
      search_validators += %(
        when '#{element}'
)
    end
  end

  validate_function = ''

  unless search_validators.empty?
    validate_function = %(
      def validate_resource_item(resource, property, value)
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
