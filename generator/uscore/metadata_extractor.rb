# frozen_string_literal: true

module Inferno
  module Generator
    module USCoreMetadataExtractor
      PROFILE_URIS = Inferno::ValidationUtil::US_CORE_R4_URIS

      def profile_uri(profile)
        "http://hl7.org/fhir/us/core/StructureDefinition/#{profile}"
      end

      def search_param_path(resource, param)
        param = 'id' if param == '_id'
        "SearchParameter/us-core-#{resource.downcase}-#{param}"
      end

      def extract_metadata
        metadata = {
          # The 'key' for the module is just the directory the IG is in
          name: @path
        }

        # Note: consider using the Ruby representation instead of JSON
        # We aren't right now because some information is being scrubbed
        # from SearchParameter resource

        capability_statement_json = capability_statement('server')
        add_metadata_from_ig(metadata, ig_resource)
        add_metadata_from_resources(metadata, capability_statement_json['rest'][0]['resource'])
        add_special_cases(metadata)
      end

      def add_metadata_from_ig(metadata, implementation_guide)
        metadata[:title] = "#{implementation_guide['title']} v#{implementation_guide['version']}"
        metadata[:description] = "#{implementation_guide['title']} v#{implementation_guide['version']}"
      end

      def generate_unique_test_id_prefix(title)
        module_prefix = 'USC'
        test_id_prefix = module_prefix + title.chars.select { |c| c.upcase == c && c != ' ' }.join
        last_title_word = title.split(test_id_prefix.last).last
        index = 0

        while claimed_test_id_prefixes.include?(test_id_prefix)
          raise "Could not generate a unique test_id prefix for #{title}" if index > last_title_word.length

          test_id_prefix += last_title_word[index].upcase
          index += 1
        end

        claimed_test_id_prefixes << test_id_prefix

        test_id_prefix
      end

      def build_new_sequence(resource, profile)
        base_path = profile.split('us/core/').last
        base_name = profile.split('StructureDefinition/').last
        profile_json = @resource_by_path[base_path]
        reformatted_version = ig_resource['version'].delete('.')
        profile_title = profile_json['title'].gsub(/US\s*Core\s*/, '').gsub(/\s*Profile/, '').strip
        test_id_prefix = generate_unique_test_id_prefix(profile_title)
        class_name = base_name.split('-').map(&:capitalize).join.gsub('UsCore', "USCore#{reformatted_version}") + 'Sequence'

        # In case the profile doesn't start with US Core
        class_name = "USCore#{reformatted_version}#{class_name}" unless class_name.start_with? 'USCore'

        {
          name: base_name.tr('-', '_'),
          class_name: class_name,
          test_id_prefix: test_id_prefix,
          resource: resource['type'],
          profile: profile_uri(base_name), # link in capability statement is incorrect,
          title: profile_title,
          interactions: [],
          searches: [],
          search_param_descriptions: {},
          element_descriptions: {},
          must_supports: [],
          tests: []
        }
      end

      def add_metadata_from_resources(metadata, resources)
        metadata[:sequences] = []

        resources.each do |resource|
          # This doesn't get ValueSet, which doesn't have a profile
          # because it is to check ValueSet expansion
          # We should update this to get that
          resource['supportedProfile']&.each do |supported_profile|
            new_sequence = build_new_sequence(resource, supported_profile)

            add_basic_searches(resource, new_sequence)
            add_combo_searches(resource, new_sequence)
            add_interactions(resource, new_sequence)

            base_path = new_sequence[:profile].split('us/core/').last
            profile_definition = @resource_by_path[base_path]
            add_must_support_elements(profile_definition, new_sequence)
            add_search_param_descriptions(profile_definition, new_sequence)
            add_element_definitions(profile_definition, new_sequence)

            metadata[:sequences] << new_sequence
          end
        end
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
                  path: path.gsub('[x]', type['code'].slice(0).capitalize + type['code'].slice(1..-1))
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
          search_param_definition = @resource_by_path[search_param_path(sequence[:resource], param.to_s)]
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
            comparators: {},
            values: []
          }
          if !profile_element.nil?
            param_metadata[:type] = profile_element['type'].first['code']
            param_metadata[:contains_multiple] = (profile_element['max'] == '*')
            if param_metadata[:contains_multiple]
              slices = profile_definition['snapshot']['element'].select { |el| el['path'] == path && el['sliceName'] }
              slices.each do |slice|
                param_metadata[:values] << slice['patternCodeableConcept']['coding'].first['code'] if slice['patternCodeableConcept']
              end
            end
            param_metadata[:values] << profile_element['patternCodeableConcept']['coding'].first['code'] if profile_element['patternCodeableConcept']
            fhir_metadata = FHIR.const_get(sequence[:resource])::METADATA[param.to_s]
            param_metadata[:values] = fhir_metadata['valid_codes'].values.flatten unless param_metadata[:values].any? || fhir_metadata.nil? || fhir_metadata['valid_codes'].nil?
          else
            # search is a variable type eg.) Condition.onsetDateTime - element in profile def is Condition.onset[x]
            param_metadata[:type] = search_param_definition['type']
            param_metadata[:contains_multiple] = false
          end
          search_param_definition['comparator']&.each_with_index do |comparator, index|
            expectation_extension = search_param_definition['_comparator']
            expectation = 'MAY'
            expectation = expectation_extension[index]['extension'].first['valueCode'] unless expectation_extension.nil?
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

      def add_special_cases(metadata)
        category_first_profiles = [
          PROFILE_URIS[:lab_results]
        ]

        # search by patient first
        metadata[:sequences].each do |sequence|
          patient_search = sequence[:searches].select { |param| param[:names] == ['patient'] } &.first
          unless patient_search.nil?
            sequence[:searches].delete(patient_search)
            sequence[:searches].unshift(patient_search)
          end
        end

        # search by patient + category first for these specific profiles
        metadata[:sequences].select { |sequence| category_first_profiles.include?(sequence[:profile]) }.each do |sequence|
          category_search = sequence[:searches].select { |param| param[:names] == ['patient', 'category'] } &.first
          unless category_search.nil?
            sequence[:searches].delete(category_search)
            sequence[:searches].unshift(category_search)
          end
        end

        # search by patient + intent first for medication request sequence
        medication_request_sequence = metadata[:sequences].find { |sequence| sequence[:resource] == 'MedicationRequest' }
        intent_search = medication_request_sequence[:searches].find { |param| param[:names] == ['patient', 'intent'] }
        unless intent_search.nil?
          medication_request_sequence[:searches].delete(intent_search)
          medication_request_sequence[:searches].unshift(intent_search)
        end

        metadata
      end
    end
  end
end
