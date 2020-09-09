# frozen_string_literal: true

module Inferno
  module Generator
    module USCoreMetadataExtractor
      PROFILE_URIS = Inferno::ValidationUtil::US_CORE_R4_URIS

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
        fix_metadata_errors(metadata)
        add_mandatory_and_must_support_search_exclusions(metadata)
        add_special_cases(metadata)
      end

      def add_metadata_from_ig(metadata, implementation_guide)
        metadata[:title] = "#{implementation_guide['title']} v#{implementation_guide['version']}"
        metadata[:description] = "#{implementation_guide['title']} v#{implementation_guide['version']}"
        metadata[:version] = "v#{implementation_guide['version']}"
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

      def get_base_path(profile)
        if profile.include? 'us/core/'
          profile.split('us/core/').last
        else
          profile.split('fhir/').last
        end
      end

      def build_new_sequence(resource, profile, version)
        base_path = get_base_path(profile)
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
          version: version,
          reformatted_version: reformatted_version,
          test_id_prefix: test_id_prefix,
          resource: resource['type'],
          profile: profile,
          profile_name: profile_json['title'],
          title: profile_title,
          interactions: [],
          operations: [],
          searches: [],
          search_param_descriptions: {},
          references: [],
          must_supports: {
            extensions: [],
            slices: [],
            elements: []
          },
          mandatory_elements: [],
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
            new_sequence = build_new_sequence(resource, supported_profile, metadata[:version])

            add_basic_searches(resource, new_sequence)
            add_combo_searches(resource, new_sequence)
            add_interactions(resource, new_sequence)
            add_operations(resource, new_sequence)
            add_include_search(resource, new_sequence)
            add_revinclude_targets(resource, new_sequence)

            base_path = get_base_path(supported_profile)
            profile_definition = @resource_by_path[base_path]
            add_required_codeable_concepts(profile_definition, new_sequence)
            add_must_support_elements(profile_definition, new_sequence)
            add_mandatory_elements(profile_definition, new_sequence)
            add_terminology_bindings(profile_definition, new_sequence)
            add_search_param_descriptions(profile_definition, new_sequence)
            add_references(profile_definition, new_sequence)

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

      def add_operations(resource, sequence)
        operations = resource['operation']
        operations&.each do |operation|
          new_operation = {
            operation: operation['name'],
            expectation: operation['extension'][0]['valueCode']
          }
          sequence[:operations] << new_operation
        end
      end

      def add_include_search(resource, sequence)
        sequence[:include_params] = resource['searchInclude'] || []
      end

      def add_revinclude_targets(resource, sequence)
        sequence[:revincludes] = resource['searchRevInclude'] || []
      end

      def add_required_codeable_concepts(profile_definition, sequence)
        required_concepts = profile_definition['snapshot']['element']
          .select { |element| element['type']&.any? { |type| type['code'] == 'CodeableConcept' } }
          .select { |e| e.dig('binding', 'strength') == 'required' }

        # The base FHIR vital signs profile has a required binding that isn't
        # relevant for any of its child profiles
        return if sequence[:resource] == 'Observation'

        sequence[:required_concepts] = required_concepts.map do |concept|
          concept['path']
            .gsub("#{sequence[:resource]}.", '')
            .gsub('[x]', 'CodeableConcept')
        end
      end

      def add_terminology_bindings(profile_definition, sequence)
        profile_elements = profile_definition['snapshot']['element']
        elements_with_bindings = profile_elements
          .select { |e| e['binding'].present? }
          .reject do |e|
            case e['type'].first['code']
            when 'Quantity'
              quantity_code = profile_elements.find { |el| el['path'] == e['path'] + '.code' }
              quantity_system = profile_elements.find { |el| el['path'] == e['path'] + '.system' }
              (quantity_code.present? && quantity_code['fixedCode']) || (quantity_system.present? && quantity_system['fixedUri'])
            when 'code'
              e['fixedCode'].present?
            end
          end

        sequence[:bindings] = elements_with_bindings.map do |e|
          {
            type: e['type'].first['code'],
            strength: e.dig('binding', 'strength'),
            system: e.dig('binding', 'valueSet')&.split('|')&.first,
            path: e['path'].gsub('[x]', '').gsub("#{sequence[:resource]}.", '')
          }
        end
        extensions = profile_elements.select { |e| e['type'].present? && e['type'].first['code'] == 'Extension' }
        extensions.each { |extension| add_terminology_bindings_from_extension(extension, sequence) }
      end

      def add_terminology_bindings_from_extension(extension, sequence)
        profile = extension['type'].first['profile']
        return unless profile.present?

        extension_def = @resource_by_path[get_base_path(profile.first)]
        return unless extension_def.present?

        extension_url = profile.first
        extension_elements = extension_def['snapshot']['element']
        binding_els = extension_elements.select { |e| e['binding'].present? && !(e['id'].include? 'Extension.extension') }
        sequence[:bindings] += binding_els.map do |e|
          {
            type: e['type'].first['code'],
            strength: e.dig('binding', 'strength'),
            system: e.dig('binding', 'valueSet')&.split('|')&.first,
            path: e['path'].gsub('[x]', '').gsub('Extension.', ''),
            extensions: [extension_url]
          }
        end

        extensions_of_extension = extension_elements.select { |e| e['path'] == 'Extension.extension' }
        extensions_of_extension.each do |extension_squared|
          url_el = extension_elements.find { |e| e['id'] == extension_squared['id'] + '.url' }
          next unless url_el.present?

          extension_squared_url = url_el['fixedUri']
          binding_els = extension_elements.select { |e| (e['id'].include? extension_squared['id']) && e['binding'].present? }
          sequence[:bindings] += binding_els.map do |e|
            {
              type: e['type'].first['code'],
              strength: e.dig('binding', 'strength'),
              system: e.dig('binding', 'valueSet')&.split('|')&.first,
              path: e['path'].gsub('[x]', '').gsub('Extension.extension.', ''),
              extensions: [extension_url, extension_squared_url]
            }
          end
        end
      end

      def add_must_support_elements(profile_definition, sequence)
        profile_elements = profile_definition['snapshot']['element']
        profile_elements.select { |el| el['mustSupport'] }.each do |element|
          # not including components in vital-sign profiles because they don't make sense outside of BP
          next if profile_definition['baseDefinition'] == 'http://hl7.org/fhir/StructureDefinition/vitalsigns' && element['path'].include?('component')
          next if profile_definition['name'] == 'observation-bp' && element['path'].include?('Observation.value[x]')
          next if profile_definition['name'].include?('Pediatric') && element['path'] == 'Observation.dataAbsentReason'

          if element['path'].end_with? 'extension'
            sequence[:must_supports][:extensions] <<
              {
                id: element['id'],
                url: element['type'].first['profile'].first
              }
            next
          elsif element['sliceName'].present?
            array_el = profile_elements.find { |el| el['id'] == element['path'] }
            discriminators = array_el['slicing']['discriminator']
            must_support_element = { name: element['id'], path: element['path'].gsub(sequence[:resource] + '.', '') }
            if discriminators.first['type'] == 'pattern'
              discriminator_path = discriminators.first['path']
              discriminator_path = '' if discriminator_path == '$this'
              pattern_element = discriminator_path.present? ? profile_elements.find { |el| el['id'] == element['id'] + '.' + discriminator_path } : element
              if pattern_element['patternCodeableConcept'].present?
                must_support_element[:discriminator] = {
                  type: 'patternCodeableConcept',
                  path: discriminator_path,
                  code: pattern_element['patternCodeableConcept']['coding'].first['code'],
                  system: pattern_element['patternCodeableConcept']['coding'].first['system']
                }
              elsif pattern_element['patternIdentifier'].present?
                must_support_element[:discriminator] = {
                  type: 'patternIdentifier',
                  path: discriminator_path,
                  system: pattern_element['patternIdentifier']['system']
                }
              end
            elsif discriminators.first['type'] == 'type'
              type_path = discriminators.first['path']
              type_path = '' if type_path == '$this'
              type_element = type_path.present? ? profile_element.find { |el| el['id'] == element['id'] + '.' + type_path } : element
              type_code = type_element['type'].first['code']
              must_support_element[:discriminator] = {
                type: 'type',
                code: capitalize_first_letter(type_code)
              }
            elsif discriminators.first['type'] == 'value'
              must_support_element[:discriminator] = {
                type: 'value',
                values: []
              }
              discriminators.each do |discriminator|
                fixed_el = profile_elements.find { |el| el['id'].starts_with?(element['id']) && el['path'] == element['path'] + '.' + discriminator['path'] }
                fixed_value = fixed_el['fixedUri'] || fixed_el['fixedCode']
                must_support_element[:discriminator][:values] << {
                  path: discriminator['path'],
                  value: fixed_value
                }
              end
            end
            sequence[:must_supports][:slices] << must_support_element
            next
          end
          path = element['path'].gsub(sequence[:resource] + '.', '')
          must_support_element = { path: path }
          if element['fixedUri'].present?
            must_support_element[:fixed_value] = element['fixedUri']
          elsif element['patternCodeableConcept'].present?
            must_support_element[:fixed_value] = element['patternCodeableConcept']['coding'].first['code']
            must_support_element[:path] += '.coding.code'
          elsif element['fixedCode'].present?
            must_support_element[:fixed_value] = element['fixedCode']
          elsif element['patternIdentifier'].present?
            must_support_element[:fixed_value] = element['patternIdentifier']['system']
            must_support_element[:path] += '.system'
          end
          sequence[:must_supports][:elements].delete_if { |must_support| must_support[:path] == must_support_element[:path] && must_support[:fixed_value].blank? }
          sequence[:must_supports][:elements] << must_support_element
        end
      end

      def add_mandatory_elements(profile_definition, sequence)
        profile_elements = profile_definition['snapshot']['element']
        sequence[:mandatory_elements] = profile_elements
          .select { |el| el['min'].positive? }
          .map { |el| el['path'] }
      end

      def add_search_param_descriptions(profile_definition, sequence)
        sequence[:search_param_descriptions].each_key do |param|
          search_param_definition = @resource_by_path[search_param_path(sequence[:resource], param.to_s)]
          path = search_param_definition['expression']
          path = path.gsub(/.where\((.*)/, '')
          as_type = path.scan(/.as\((.*?)\)/).flatten.first
          path = path.gsub(/.as\((.*?)\)/, capitalize_first_letter(as_type)) if as_type.present?
          profile_element = profile_definition['snapshot']['element'].select { |el| el['id'] == path }.first
          param_metadata = {
            path: path,
            comparators: {},
            values: Set.new
          }
          if !profile_element.nil?
            param_metadata[:type] = profile_element['type'].first['code']
            param_metadata[:contains_multiple] = (profile_element['max'] == '*')
            search_path = param_metadata[:path].gsub("#{sequence[:resource]}.", '')
            add_valid_codes(
              profile_definition,
              profile_element,
              FHIR.const_get(sequence[:resource])::METADATA[search_path],
              param_metadata
            )
          else
            # search is a variable type, eg. Condition.onsetDateTime - element
            # in profile def is Condition.onset[x]
            param_metadata[:type] = search_param_definition['type']
            param_metadata[:contains_multiple] = false
          end
          search_param_definition['comparator']&.each_with_index do |comparator, index|
            expectation_extension = search_param_definition['_comparator']
            expectation = 'MAY'
            expectation = expectation_extension[index]['extension'].first['valueCode'] unless expectation_extension.nil?
            param_metadata[:comparators][comparator.to_sym] = expectation
          end

          multiple_or_expectation = search_param_definition['_multipleOr']['extension'].first['valueCode']
          param_metadata[:multiple_or] = multiple_or_expectation

          if search_param_definition['chain'].present?
            expectations =
              search_param_definition['_chain']
                .map { |expectation| expectation['extension'].first['valueCode'] }
            param_metadata[:chain] =
              search_param_definition['chain'].zip(expectations)
                .map { |chain, expectation| { chain: chain, expectation: expectation } }
          end

          sequence[:search_param_descriptions][param] = param_metadata
        end
      end

      def add_valid_codes(profile_definition, profile_element, fhir_metadata, param_metadata)
        if param_metadata[:contains_multiple]
          add_values_from_slices(param_metadata, profile_definition, param_metadata[:path])
        elsif param_metadata[:type] == 'CodeableConcept'
          add_values_from_fixed_codes(param_metadata, profile_definition, profile_element)
          add_values_from_patterncodeableconcept(param_metadata, profile_element)
        end
        add_values_from_valueset_binding(param_metadata, profile_element)
        add_values_from_resource_metadata(param_metadata, fhir_metadata)
      end

      def add_values_from_slices(param_metadata, profile_definition, path)
        slices = profile_definition['snapshot']['element'].select { |el| el['path'] == path && el['sliceName'] }
        slices.each do |slice|
          param_metadata[:values] << slice['patternCodeableConcept']['coding'].first['code'] if slice['patternCodeableConcept']
        end
      end

      def add_values_from_fixed_codes(param_metadata, profile_definition, profile_element)
        fixed_code_els = profile_definition['snapshot']['element'].select { |el| el['path'] == "#{profile_element['path']}.coding.code" && el['fixedCode'].present? }
        param_metadata[:values] += fixed_code_els.map { |el| el['fixedCode'] }
      end

      def add_values_from_valueset_binding(param_metadata, profile_element)
        valueset_binding = profile_element['binding']
        return unless valueset_binding

        value_set = resources_by_type['ValueSet'].find { |res| res['url'] == valueset_binding['valueSet'] }
        systems = value_set['compose']['include'].reject { |code| code['concept'].nil? } if value_set.present?

        param_metadata[:values] += systems.flat_map { |system| system['concept'].map { |code| code['code'] } } if systems.present?
      end

      def add_values_from_patterncodeableconcept(param_metadata, profile_element)
        param_metadata[:values] << profile_element['patternCodeableConcept']['coding'].first['code'] if profile_element['patternCodeableConcept']
      end

      def add_values_from_resource_metadata(param_metadata, fhir_metadata)
        use_valid_codes = param_metadata[:values].blank? && fhir_metadata.present? && fhir_metadata['valid_codes'].present?
        param_metadata[:values] = fhir_metadata['valid_codes'].values.flatten if use_valid_codes
      end

      def add_references(profile_definition, sequence)
        references = profile_definition['snapshot']['element'].select { |el| el['type'].present? && el['type'].first['code'] == 'Reference' }
        sequence[:references] = references.map do |ref_def|
          {
            path: ref_def['path'],
            profiles: ref_def['type'].first['targetProfile']
          }
        end
      end

      def fix_metadata_errors(metadata)
        if metadata[:version] == 'v3.1.0'
          # Procedure's date search param definition says Procedure.occurenceDateTime even though Procedure doesn't have an occurenceDateTime
          procedure_sequence = metadata[:sequences].find { |sequence| sequence[:resource] == 'Procedure' }
          procedure_sequence[:search_param_descriptions][:date][:path] = 'Procedure.performed'
          
          goal_sequence = metadata[:sequences].find { |sequence| sequence[:resource] == 'Goal' }
          goal_sequence[:search_param_descriptions][:'target-date'][:path] = 'Goal.target.dueDate'
          goal_sequence[:search_param_descriptions][:'target-date'][:type] = 'date'

          # add the missing ge comparator for USCore v3.1.0 - the metadata is missing it for some reason
          # This code segment has no impact for USCore v3.1.1 and forward.
          metadata[:sequences].each do |sequence|
            sequence[:search_param_descriptions].each do |_param, description|
              param_comparators = description[:comparators]
              param_comparators[:ge] = param_comparators[:le] if param_comparators.key? :le
            end
          end  
        end      
      end

      def add_mandatory_and_must_support_search_exclusions(metadata)
        # must be performed after we fix the metadata
        metadata[:sequences].each do |sequence|
          sequence[:searches].each do |search|
            search[:names_not_must_support_or_mandatory] = search[:names].reject do |name|
              path = sequence[:search_param_descriptions][name.to_sym][:path]
              any_must_support_elements = sequence[:must_supports][:elements].any? do |element|
                full_must_support_path = "#{sequence[:resource]}.#{element[:path]}"

                # allow for non-choice, choice types, and _id
                name == '_id' || full_must_support_path == path || full_must_support_path == "#{path}[x]"
              end

              any_must_support_slices = sequence[:must_supports][:slices].any? do |slice|
                # only handle type slices because that is all we need for now
                if slice[:discriminator] && slice[:discriminator][:type] == 'type'
                  full_must_support_path = "#{sequence[:resource]}.#{slice[:path].sub('[x]', slice[:discriminator][:code])}"
                  full_must_support_path == path
                else
                  false
                end
              end

              any_mandatory_elements = sequence[:mandatory_elements].any? do |element|
                element == path
              end

              any_must_support_elements || any_must_support_slices || any_mandatory_elements
            end

            search[:must_support_or_mandatory] = search[:names_not_must_support_or_mandatory].empty?
          end
        end
      end

      def add_special_cases(metadata)
        category_first_profiles = [
          PROFILE_URIS[:lab_results]
        ]

        # search by patient first
        metadata[:sequences].each do |sequence|
          set_first_search(sequence, ['patient'])
        end

        # search by patient + category first for these specific profiles
        metadata[:sequences].select { |sequence| category_first_profiles.include?(sequence[:profile]) }.each do |sequence|
          set_first_search(sequence, ['patient', 'category'])
        end

        # search by patient + intent first for medication request sequence
        medication_request_sequence = metadata[:sequences].find { |sequence| sequence[:resource] == 'MedicationRequest' }
        set_first_search(medication_request_sequence, ['patient', 'intent'])

        metadata[:sequences]
          .select { |sequence| sequence[:resource] == 'DiagnosticReport' }
          .each do |sequence|
            set_first_search(sequence, ['patient', 'category'])
          end

        metadata
      end

      def set_first_search(sequence, params)
        search = sequence[:searches].find { |param| param[:names] == params }
        return if search.nil?

        sequence[:searches].delete(search)
        sequence[:searches].unshift(search)
      end

      def capitalize_first_letter(str)
        str.slice(0).capitalize + str.slice(1..-1)
      end
    end
  end
end
