# frozen_string_literal: true

require_relative './metadata_extractor'
require_relative '../../lib/app/utils/validation'
require_relative '../generator_base'
require_relative './us_core_unit_test_generator'

module Inferno
  module Generator
    class USCoreGenerator < Generator::Base
      include USCoreMetadataExtractor

      PROFILE_URIS = Inferno::ValidationUtil::US_CORE_R4_URIS

      def unit_test_generator
        @unit_test_generator ||= USCoreUnitTestGenerator.new
      end

      def validation_profile_uri(sequence)
        profile_uri = PROFILE_URIS.key(sequence[:profile])
        "Inferno::ValidationUtil::US_CORE_R4_URIS[:#{profile_uri}]" if profile_uri
      end

      def generate
        metadata = extract_metadata
        generate_tests(metadata)
        generate_search_validators(metadata)
        metadata[:sequences].each do |sequence|
          generate_sequence(sequence)
          unit_test_generator.generate(sequence, sequence_out_path, metadata[:name])
        end
        generate_module(metadata)
      end

      def generate_search_validators(metadata)
        metadata[:sequences].each do |sequence|
          sequence[:search_validator] = create_search_validation(sequence)
        end
      end

      def generate_tests(metadata)
        # first isolate the profiles that don't have patient searches
        mark_delayed_sequences(metadata)

        metadata[:sequences].each do |sequence|
          puts "Generating test #{sequence[:name]}"

          # read reference if sequence contains no search sequences
          create_read_test(sequence) if sequence[:delayed_sequence]

          # authorization test
          create_authorization_test(sequence)

          # make tests for each SHALL and SHOULD search param, SHALL's first
          sequence[:searches]
            .select { |search_param| search_param[:expectation] == 'SHALL' }
            .each { |search_param| create_search_test(sequence, search_param) }

          sequence[:searches]
            .select { |search_param| search_param[:expectation] == 'SHOULD' }
            .each { |search_param| create_search_test(sequence, search_param) }

          sequence[:search_param_descriptions]
            .select { |_, description| description[:chain].present? }
            .each { |search_param, _| create_chained_search_test(sequence, search_param) }

          # make tests for each SHALL and SHOULD interaction
          sequence[:interactions]
            .select { |interaction| ['SHALL', 'SHOULD'].include? interaction[:expectation] }
            .reject { |interaction| interaction[:code] == 'search-type' }
            .each do |interaction|
              # specific edge cases
              interaction[:code] = 'history' if interaction[:code] == 'history-instance'
              next if interaction[:code] == 'read' && sequence[:delayed_sequence]

              create_interaction_test(sequence, interaction)
            end

          sequence[:operations]
            .select { |operation| operation[:expectation] == 'SHALL' }
            .each do |operation|
              create_docref_test(sequence) if operation[:operation] == 'docref'
            end

          create_include_test(sequence) if sequence[:include_params].any?
          create_revinclude_test(sequence) if sequence[:revincludes].any?
          create_resource_profile_test(sequence)
          create_must_support_test(sequence)
          create_multiple_or_test(sequence)
          create_references_resolved_test(sequence)
        end
      end

      def mark_delayed_sequences(metadata)
        metadata[:sequences].each do |sequence|
          sequence[:delayed_sequence] = sequence[:resource] != 'Patient' && sequence[:searches].none? { |search| search[:names].include? 'patient' }
        end
        metadata[:delayed_sequences] = metadata[:sequences].select { |seq| seq[:delayed_sequence] }
        metadata[:non_delayed_sequences] = metadata[:sequences].reject { |seq| seq[:resource] == 'Patient' || seq[:delayed_sequence] }
      end

      def find_first_search(sequence)
        sequence[:searches].find { |search_param| search_param[:expectation] == 'SHALL' } ||
          sequence[:searches].find { |search_param| search_param[:expectation] == 'SHOULD' }
      end

      def generate_sequence(sequence)
        puts "Generating #{sequence[:name]}\n"
        file_name = sequence_out_path + '/' + sequence[:name].downcase + '_sequence.rb'

        template = ERB.new(File.read(File.join(__dir__, 'templates/sequence.rb.erb')))
        output =   template.result_with_hash(sequence)
        FileUtils.mkdir_p(sequence_out_path) unless File.directory?(sequence_out_path)
        File.write(file_name, output)
      end

      def create_read_test(sequence)
        test_key = :resource_read
        read_test = {
          tests_that: "Server returns correct #{sequence[:resource]} resource from the #{sequence[:resource]} read interaction",
          key: test_key,
          index: sequence[:tests].length + 1,
          link: 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html',
          description: "Reference to #{sequence[:resource]} can be resolved and read."
        }

        read_test[:test_code] = %(
              skip_if_known_not_supported(:#{sequence[:resource]}, [:read])

              #{sequence[:resource].underscore}_references = @instance.resource_references.select { |reference| reference.resource_type == '#{sequence[:resource]}' }
              skip 'No #{sequence[:resource]} references found from the prior searches' if #{sequence[:resource].underscore}_references.blank?

              @#{sequence[:resource].underscore}_ary = #{sequence[:resource].underscore}_references.map do |reference|
                validate_read_reply(
                  FHIR::#{sequence[:resource]}.new(id: reference.resource_id),
                  FHIR::#{sequence[:resource]}
                )
              end
              @#{sequence[:resource].underscore} = @#{sequence[:resource].underscore}_ary.first
              @resources_found = @#{sequence[:resource].underscore}.present?)
        sequence[:tests] << read_test

        unit_test_generator.generate_resource_read_test(
          test_key: test_key,
          resource_type: sequence[:resource],
          class_name: sequence[:class_name]
        )
      end

      def create_authorization_test(sequence)
        test_key = :unauthorized_search
        authorization_test = {
          tests_that: "Server rejects #{sequence[:resource]} search without authorization",
          key: test_key,
          index: sequence[:tests].length + 1,
          link: 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html#behavior',
          description: 'A server SHALL reject any unauthorized requests by returning an HTTP 401 unauthorized response code.'
        }

        first_search = find_first_search(sequence)
        return if first_search.nil?

        search_parameters = first_search[:names]
        search_params = get_search_params(search_parameters, sequence, true)
        # unit_test_params = get_search_param_hash(search_parameters, sequence, true)
        reply_code = %(
          #{search_params}
          reply = get_resource_by_params(versioned_resource_class('#{sequence[:resource]}'), search_params)
          assert_response_unauthorized reply
        )
        unless sequence[:delayed_sequence]
          reply_code = %(
            patient_ids.each do |patient|
              #{reply_code}
            end
          )
        end

        authorization_test[:test_code] = %(
          skip_if_known_not_supported(:#{sequence[:resource]}, [:search])

          @client.set_no_auth
          omit 'Do not test if no bearer token set' if @instance.token.blank?
          #{reply_code}
          @client.set_bearer_token(@instance.token)
        )

        sequence[:tests] << authorization_test

        # unit_test_generator.generate_authorization_test(
        #   test_key: test_key,
        #   resource_type: sequence[:resource],
        #   search_params: unit_test_params,
        #   class_name: sequence[:class_name],
        #   sequence_name: sequence[:name]
        # )
      end

      def create_docref_test(sequence)
        docref_test = {
          tests_that: 'The server is capable of returning a reference to a generated CDA document in response to the $docref operation',
          index: sequence[:tests].length + 1,
          link: 'http://hl7.org/fhir/us/core/2019Sep/CapabilityStatement-us-core-server.html#documentreference',
          description: 'A server SHALL be capable of responding to a $docref operation and capable of returning at least a reference to a generated CCD document, if available.'
        }

        docref_test[:test_code] = %(
          skip_if_known_not_supported(:#{sequence[:resource]}, [], [:docref])
          search_string = "/DocumentReference/$docref?patient=\#{@instance.patient_id}"
          reply = @client.get(search_string, @client.fhir_headers)
          assert_response_ok(reply)
        )

        sequence[:tests] << docref_test
      end

      def create_include_test(sequence)
        include_test = {
          tests_that: "Server returns the appropriate resource from the following _includes: #{sequence[:include_params].join(', ')}",
          index: sequence[:tests].length + 1,
          optional: true,
          link: 'https://www.hl7.org/fhir/search.html#include',
          description: "A Server SHOULD be capable of supporting the following _includes: #{sequence[:include_params].join(', ')}",
          test_code: ''
        }
        first_search = find_first_search(sequence)
        search_params = first_search.nil? ? 'search_params = {}' : get_search_params(first_search[:names], sequence)
        resolve_param_from_resource = search_params.include? 'get_value_for_search_param'
        if resolve_param_from_resource && !sequence[:delayed_sequence]
          include_test[:test_code] += %(
            could_not_resolve_all = []
            resolved_one = false
            medication_results = false
            patient_ids.each do |patient|
          )
        end
        include_test[:test_code] += search_params
        sequence[:include_params].each do |include|
          resource_name = include.split(':').last.capitalize
          resource_variable = "#{resource_name.underscore}_results" # kind of a hack, but works for now - would have to otherwise figure out resource type of target profile
          operator = sequence[:delayed_sequence] ? '=' : '||='
          include_test[:test_code] += %(
            search_params['_include'] = '#{include}'
            reply = get_resource_by_params(versioned_resource_class('#{sequence[:resource]}'), search_params)
            assert_response_ok(reply)
            assert_bundle_response(reply)
            #{resource_variable} #{operator} reply&.resource&.entry&.map(&:resource)&.any? { |resource| resource.resourceType == '#{resource_name}' }
            #{"assert #{resource_variable}, 'No #{resource_name} resources were returned from this search'" if sequence[:delayed_sequence]}
          )
        end
        if resolve_param_from_resource && !sequence[:delayed_sequence]
          include_test[:test_code] += %(
            end
            #{skip_if_could_not_resolve}
            assert medication_results, 'No Medication resources were returned from this search'
          )
        end
        sequence[:tests] << include_test
      end

      def create_revinclude_test(sequence)
        first_search = find_first_search(sequence)
        return if first_search.blank?

        revinclude_test = {
          tests_that: "Server returns Provenance resources from #{sequence[:resource]} search by #{first_search[:names].join(' + ')} + _revIncludes: Provenance:target",
          index: sequence[:tests].length + 1,
          link: 'https://www.hl7.org/fhir/search.html#revinclude',
          description: "A Server SHALL be capable of supporting the following _revincludes: #{sequence[:revincludes].join(', ')}",
          test_code: ''
        }
        search_params = get_search_params(first_search[:names], sequence)
        resolve_param_from_resource = search_params.include? 'get_value_for_search_param'
        if resolve_param_from_resource && !sequence[:delayed_sequence]
          revinclude_test[:test_code] += %(
            could_not_resolve_all = []
            resolved_one = false
          )
        end

        revinclude = sequence[:revincludes].first
        resource_name = revinclude.split(':').first
        resource_variable = "#{resource_name.underscore}_results"
        revinclude_test[:test_code] += %(
          #{resource_variable} = []
          #{'patient_ids.each do |patient|' unless sequence[:delayed_sequence]}
          #{search_params}
        )
        revinclude_test[:test_code] += %(
              search_params['_revinclude'] = '#{revinclude}'
              reply = get_resource_by_params(versioned_resource_class('#{sequence[:resource]}'), search_params)
              assert_response_ok(reply)
              assert_bundle_response(reply)
              #{resource_variable} += fetch_all_bundled_resources(reply.resource).select { |resource| resource.resourceType == '#{resource_name}'}
              #{resource_variable}.each { |reference| @instance.save_resource_reference('#{resource_name}', reference.id) }
        )

        revinclude_test[:test_code] += %(
          #{'end' unless sequence[:delayed_sequence]}
          #{skip_if_could_not_resolve if resolve_param_from_resource && !sequence[:delayed_sequence]}
          skip 'No Provenance resources were returned from this search' unless #{resource_variable}.present?
        )
        sequence[:tests] << revinclude_test
      end

      def create_search_test(sequence, search_param)
        test_key = :"search_by_#{search_param[:names].map(&:underscore).join('_')}"
        search_test = {
          tests_that: "Server returns expected results from #{sequence[:resource]} search by #{search_param[:names].join('+')}",
          key: test_key,
          index: sequence[:tests].length + 1,
          link: 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html',
          optional: search_param[:expectation] != 'SHALL',
          description: %(
            A server #{search_param[:expectation]} support searching by #{search_param[:names].join('+')} on the #{sequence[:resource]} resource
          )
        }

        find_comparators(search_param[:names], sequence).each do |param, comparators|
          search_test[:description] += %(
              including support for these #{param} comparators: #{comparators.keys.join(', ')})
        end

        if sequence[:resource] == 'MedicationRequest'
          search_test[:description] += %(
            If any MedicationRequest resources use external references to
            Medications, the search will be repeated with
            _include=MedicationRequest:medication.
          )
        end

        is_first_search = search_param == find_first_search(sequence)

        comparator_search_code = get_comparator_searches(search_param[:names], sequence)

        search_test[:test_code] =
          if is_first_search
            # rcs question: are comparators ever be in the first search?
            get_first_search(search_param[:names], sequence)
          else
            search_params = get_search_params(search_param[:names], sequence)
            resolve_param_from_resource = search_params.include? 'get_value_for_search_param'
            resolved_one_str = %(
              could_not_resolve_all = []
              resolved_one = false
            )
            reply_code = %(
              #{search_params}
              reply = get_resource_by_params(versioned_resource_class('#{sequence[:resource]}'), search_params)
              validate_search_reply(versioned_resource_class('#{sequence[:resource]}'), reply, search_params)
              #{'test_medication_inclusion(reply.resource.entry.map(&:resource), search_params)' if sequence[:resource] == 'MedicationRequest'}
              #{comparator_search_code}
            )
            unless sequence[:delayed_sequence]
              reply_code = %(
                patient_ids.each do |patient|
                  #{reply_code}
                end
              )
            end
            %(
              #{skip_if_not_found(sequence)}
              #{resolved_one_str if resolve_param_from_resource && !sequence[:delayed_sequence]}
              #{reply_code}
              #{skip_if_could_not_resolve if resolve_param_from_resource && !sequence[:delayed_sequence]}
            )
          end
        sequence[:tests] << search_test

        # is_fixed_value_search = fixed_value_search?(search_param[:names], sequence)
        # fixed_value_search_param = is_fixed_value_search ? fixed_value_search_param(search_param[:names], sequence) : nil

        # unit_test_generator.generate_search_test(
        #   test_key: test_key,
        #   resource_type: sequence[:resource],
        #   search_params: get_search_param_hash(search_param[:names], sequence),
        #   is_first_search: is_first_search,
        #   is_fixed_value_search: is_fixed_value_search,
        #   has_comparator_tests: comparator_search_code.present?,
        #   fixed_value_search_param: fixed_value_search_param,
        #   class_name: sequence[:class_name],
        #   sequence_name: sequence[:name],
        #   delayed_sequence: sequence[:delayed_sequence]
        # )
      end

      def create_chained_search_test(sequence, search_param)
        # NOTE: This test is currently hard-coded because chained searches are
        # only required for PractitionerRole
        raise StandardError, 'Chained search tests only supported for PractitionerRole' if sequence[:resource] != 'PractitionerRole'

        chained_param_string = sequence[:search_param_descriptions][search_param][:chain]
          .map { |param| "#{search_param}.#{param[:chain]}" }
          .join(' and ')
        search_test = {
          tests_that: "Server returns expected results from #{sequence[:resource]} chained search by #{chained_param_string}",
          key: :"chained_search_by_#{search_param}",
          index: sequence[:tests].length + 1,
          link: 'https://www.hl7.org/fhir/us/core/StructureDefinition-us-core-practitionerrole.html#mandatory-search-parameters',
          optional: false,
          description: %(
            A server SHALL support searching the #{sequence[:resource]} resource
            with the chained parameters #{chained_param_string}
          )
        }

        search_test[:test_code] = %(
          #{skip_if_not_found(sequence)}

          practitioner_role = @practitioner_role_ary.find { |role| role.practitioner&.reference.present? }
          skip_if practitioner_role.blank?, 'No PractitionerRoles containing a Practitioner reference were found'

          begin
            practitioner = practitioner_role.practitioner.read
          rescue ClientException => e
            assert false, "Unable to resolve Practitioner reference: \#{e}"
          end

          assert practitioner.resourceType == 'Practitioner', "Expected FHIR Practitioner but found: \#{practitioner.resourceType}"

          name = practitioner.name&.first&.family
          skip_if name.blank?, 'Practitioner has no family name'

          name_search_response = @client.search(FHIR::PractitionerRole, search: { parameters: { 'practitioner.name': name }})
          assert_response_ok(name_search_response)
          assert_bundle_response(name_search_response)

          name_bundle_entries = fetch_all_bundled_resources(name_search_response.resource)

          practitioner_role_found = name_bundle_entries.any? { |entry| entry.id == practitioner_role.id }
          assert practitioner_role_found, "PractitionerRole with id \#{practitioner_role.id} not found in search results for practitioner.name = \#{name}"

          identifier = practitioner.identifier.first
          skip_if identifier.blank?, 'Practitioner has no identifier'
          identifier_string = "\#{identifier.system}|\#{identifier.value}"

          identifier_search_response = @client.search(
            FHIR::PractitionerRole,
            search: { parameters: { 'practitioner.identifier': identifier_string } }
          )
          assert_response_ok(identifier_search_response)
          assert_bundle_response(identifier_search_response)

          identifier_bundle_entries = fetch_all_bundled_resources(identifier_search_response.resource)

          practitioner_role_found = identifier_bundle_entries.any? { |entry| entry.id == practitioner_role.id }
          assert practitioner_role_found, "PractitionerRole with id \#{practitioner_role.id} not found in search results for practitioner.identifier = \#{identifier_string}"
        )

        sequence[:tests] << search_test
        # NOTE: unit test has an intermittent failure and is disabled until this
        # failure can be addressed
        # unit_test_generator.generate_chained_search_test(class_name: sequence[:class_name])
      end

      def create_interaction_test(sequence, interaction)
        return if interaction[:code] == 'create'

        test_key = :"#{interaction[:code]}_interaction"
        interaction_test = {
          tests_that: "Server returns correct #{sequence[:resource]} resource from #{sequence[:resource]} #{interaction[:code]} interaction",
          key: test_key,
          index: sequence[:tests].length + 1,
          link: 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html',
          description: "A server #{interaction[:expectation]} support the #{sequence[:resource]} #{interaction[:code]} interaction.",
          optional: interaction[:expectation] != 'SHALL'
        }

        interaction_test[:test_code] = %(
              skip_if_known_not_supported(:#{sequence[:resource]}, [:#{interaction[:code]}])
              skip 'No #{sequence[:resource]} resources could be found for this patient. Please use patients with more information.' unless @resources_found

              validate_#{interaction[:code]}_reply(@#{sequence[:resource].underscore}, versioned_resource_class('#{sequence[:resource]}')))

        sequence[:tests] << interaction_test

        if interaction[:code] == 'read' # rubocop:disable Style/GuardClause
          # unit_test_generator.generate_resource_read_test(
          #   test_key: test_key,
          #   resource_type: sequence[:resource],
          #   class_name: sequence[:class_name],
          #   interaction_test: true
          # )
        end
      end

      def create_must_support_test(sequence)
        test = {
          tests_that: "All must support elements are provided in the #{sequence[:resource]} resources returned.",
          index: sequence[:tests].length + 1,
          link: 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support',
          test_code: '',
          description: %(
            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through all #{sequence[:resource]} resources returned from prior searches to see if any of them provide the following must support elements:
          )
        }

        sequence[:must_supports] = sequence[:must_supports].uniq
        sequence[:must_supports].select { |must_support| must_support[:type] == 'element' }.each do |element|
          test[:description] += %(
            #{element[:path]}
          )
          # class is mapped to local_class in fhir_models. Update this after it
          # has been added to the description so that the description contains
          # the original path
          element[:path] = element[:path].gsub('.class', '.local_class')
        end

        sequence[:must_supports].each { |must_support| must_support[:path]&.gsub!('[x]', '') }
        must_support_extensions = sequence[:must_supports].select { |must_support| must_support[:type] == 'extension' }
        must_support_extensions.each do |extension|
          test[:description] += %(
            #{extension[:id]}
          )
        end

        test[:test_code] += %(
          #{skip_if_not_found(sequence)}
        )
        resource_array = sequence[:delayed_sequence] ? "@#{sequence[:resource].underscore}_ary" : "@#{sequence[:resource].underscore}_ary&.values&.flatten"

        if must_support_extensions.present?
          extensions_list = must_support_extensions.map { |extension| "'#{extension[:id]}': '#{extension[:url]}'" }

          test[:test_code] += %(
            must_support_extensions = {
              #{extensions_list.join(",\n          ")}
            }
            missing_must_support_extensions = must_support_extensions.reject do |_id, url|
              #{resource_array}&.any? do |resource|
                resource.extension.any? { |extension| extension.url == url }
              end
            end
      )
        end

        must_support_slices = sequence[:must_supports].select { |must_support| must_support[:type] == 'slice' }
        must_support_slices.each do |slice|
          test[:description] += %(
            #{slice[:name]}
          )
        end
        slices_list = must_support_slices.map do |slice_def|
          %({
              name: '#{slice_def[:name]}',
              path: '#{slice_def[:path]}',
              discriminator: #{structure_to_string(slice_def[:discriminator])}
            })
        end

        if must_support_slices.present?
          test[:test_code] += %(
            must_support_slices = [
              #{slices_list.join(",\n")}
            ]
            missing_slices = must_support_slices.reject do |slice|
              truncated_path = slice[:path].gsub('#{sequence[:resource]}.', '')
              @#{sequence[:resource].underscore}_ary#{'&.values&.flatten' unless sequence[:delayed_sequence]}&.any? do |resource|
                slice_found = find_slice(resource, truncated_path, slice[:discriminator])
                slice_found.present?
              end
            end
          )
        end
        elements_list = []
        sequence[:must_supports].select { |must_support| must_support[:type] == 'element' }.each do |element|
          element[:path] = element[:path].gsub('.class', '.local_class') # class is mapped to local_class in fhir_models
          element_list_parts = ["path: '#{element[:path]}'"]
          element_list_parts << ["fixed_value: '#{element[:fixed_value]}'"] if element[:fixed_value].present?
          elements_list << "{ #{element_list_parts.join(', ')} }"
        end

        if elements_list.present?
          test[:test_code] += %(
            must_support_elements = [
              #{elements_list.join(",\n")}
            ]

            missing_must_support_elements = must_support_elements.reject do |element|
              truncated_path = element[:path].gsub('#{sequence[:resource]}.', '')
              #{resource_array}&.any? do |resource|
                value_found = resolve_element_from_path(resource, truncated_path) { |value| element[:fixed_value].blank? || value == element[:fixed_value] }
                value_found.present?
              end
            end
            missing_must_support_elements.map! { |must_support| "\#{must_support[:path]}\#{': ' + must_support[:fixed_value] if must_support[:fixed_value].present?}" }
          )

          if must_support_extensions.present?
            test[:test_code] += %(
              missing_must_support_elements += missing_must_support_extensions.keys
            )
          end
          if must_support_slices.present?
            test[:test_code] += %(
              missing_must_support_elements += missing_slices.map { |slice| slice[:name] }
            )
          end

          test[:test_code] += %(
            skip_if missing_must_support_elements.present?,
              "Could not find \#{missing_must_support_elements.join(', ')} in the \#{#{resource_array}&.length} provided #{sequence[:resource]} resource(s)")
        end

        test[:test_code] += %(
          @instance.save!)

        sequence[:tests] << test
      end

      def structure_to_string(struct)
        if struct.is_a? Hash
          %({
            #{struct.map { |k, v| "#{k}: #{structure_to_string(v)}" }.join(",\n")}
          })
        elsif struct.is_a? Array
          %([
            #{struct.map { |el| structure_to_string(el) }.join(",\n")}
          ])
        elsif struct.is_a? String
          "'#{struct}'"
        else
          "''"
        end
      end

      def create_resource_profile_test(sequence)
        test_key = :validate_resources
        test = {
          tests_that: "#{sequence[:resource]} resources returned conform to US Core R4 profiles",
          key: test_key,
          index: sequence[:tests].length + 1,
          link: sequence[:profile],
          description: %(
            This test checks if the resources returned from prior searches conform to the US Core profiles.
            This includes checking for missing data elements and valueset verification.
          )
        }
        profile_uri = validation_profile_uri(sequence)
        test[:test_code] = %(
          #{skip_if_not_found(sequence)}
          test_resources_against_profile('#{sequence[:resource]}'#{', ' + profile_uri if profile_uri}))

        if sequence[:required_concepts].present?
          concept_string = sequence[:required_concepts].map { |concept| "'#{concept}'" }.join(' and ')
          test[:description] += %(
            This test also checks that the following CodeableConcepts with
            required ValueSet bindings include a code rather than just text:
            #{concept_string}
          )

          test[:test_code] += %( do |resource|
              #{sequence[:required_concepts].inspect.tr('"', "'")}.flat_map do |path|
                concepts = resolve_path(resource, path)
                next if concepts.blank?

                code_present = concepts.any? { |concept| concept.coding.any? { |coding| coding.code.present? } }

                unless code_present # rubocop:disable Style/IfUnlessModifier
                  "The CodeableConcept at '\#{path}' is bound to a required ValueSet but does not contain any codes."
                end
              end.compact
            end
          )
        end

        sequence[:tests] << test

        if sequence[:required_concepts].present? # rubocop:disable Style/GuardClause
          # unit_test_generator.generate_resource_validation_test(
          #   test_key: test_key,
          #   resource_type: sequence[:resource],
          #   class_name: sequence[:class_name],
          #   sequence_name: sequence[:name],
          #   required_concepts: sequence[:required_concepts],
          #   profile_uri: profile_uri
          # )
        end
      end

      def create_multiple_or_test(sequence)
        test = {
          tests_that: 'The server returns expected results when parameters use composite-or',
          index: sequence[:tests].length + 1,
          link: sequence[:profile],
          test_code: ''
        }

        multiple_or_params = get_multiple_or_params(sequence)

        multiple_or_params.each do |param|
          multiple_or_search = sequence[:searches].find { |search| (search[:names].include? param) && search[:expectation] == 'SHALL' }
          next if multiple_or_search.blank?

          second_val_var = "second_#{param}_val"
          resolve_el_str = "#{resolve_element_path(sequence[:search_param_descriptions][param.to_sym], sequence[:delayed_sequence])} { |el| get_value_for_search_param(el) != #{param_value_name(param)} }" # rubocop:disable Metrics/LineLength
          search_params = get_search_params(multiple_or_search[:names], sequence)
          resolve_param_from_resource = search_params.include? 'get_value_for_search_param'
          if resolve_param_from_resource
            test[:test_code] += %(
              could_not_resolve_all = []
              resolved_one = false
            )
          end
          test[:test_code] += %(
            found_second_val = false
            patient_ids.each do |patient|
              #{search_params}
              #{second_val_var} = #{resolve_el_str}
              next if #{second_val_var}.nil?
              found_second_val = true
              #{param_value_name(param)} += ',' + get_value_for_search_param(#{second_val_var})
              reply = get_resource_by_params(versioned_resource_class('#{sequence[:resource]}'), search_params)
              validate_search_reply(versioned_resource_class('#{sequence[:resource]}'), reply, search_params)
              assert_response_ok(reply)
            end
            skip 'Cannot find second value for #{param} to perform a multipleOr search' unless found_second_val
          )
        end
        sequence[:tests] << test if test[:test_code].present?
      end

      def get_multiple_or_params(sequence)
        sequence[:search_param_descriptions]
          .select { |_param, description| description[:multiple_or] == 'SHALL' }
          .map { |param, _description| param.to_s }
      end

      def create_references_resolved_test(sequence)
        test = {
          tests_that: "Every reference within #{sequence[:resource]} resource is valid and can be read.",
          index: sequence[:tests].length + 1,
          link: 'http://hl7.org/fhir/references.html',
          description: 'This test checks if references found in resources from prior searches can be resolved.'
        }

        resource_array = sequence[:delayed_sequence] ? "@#{sequence[:resource].underscore}_ary" : "@#{sequence[:resource].underscore}_ary&.values&.flatten"
        test[:test_code] = %(
              skip_if_known_not_supported(:#{sequence[:resource]}, [:search, :read])
              #{skip_if_not_found(sequence)}

              validated_resources = Set.new
              max_resolutions = 50

              #{resource_array}&.each do |resource|
                validate_reference_resolutions(resource, validated_resources, max_resolutions) if validated_resources.length < max_resolutions
              end)
        sequence[:tests] << test
      end

      def resolve_element_path(search_param_description, delayed_sequence)
        element_path = search_param_description[:path].gsub('.class', '.local_class') # match fhir_models because class is protected keyword in ruby
        path_parts = element_path.split('.')
        resource_val = delayed_sequence ? "@#{path_parts.shift.underscore}_ary" : "@#{path_parts.shift.underscore}_ary[patient]"
        "resolve_element_from_path(#{resource_val}, '#{path_parts.join('.')}')"
      end

      def get_value_path_by_type(type)
        case type
        when 'CodeableConcept'
          '.coding.code'
        when 'Reference'
          '.reference'
        when 'Period'
          '.start'
        when 'Identifier'
          '.value'
        when 'Coding'
          '.code'
        when 'HumanName'
          '.family'
        when 'Address'
          '.city'
        else
          ''
        end
      end

      def param_value_name(param)
        param_key = param.include?('-') ? "'#{param}'" : param
        "search_params[:#{param_key}]"
      end

      def get_first_search(search_parameters, sequence)
        save_resource_ids_in_bundle_arguments = [
          "versioned_resource_class('#{sequence[:resource]}')",
          'reply',
          validation_profile_uri(sequence)
        ].compact.join(', ')

        if fixed_value_search?(search_parameters, sequence)
          get_first_search_with_fixed_values(sequence, search_parameters, save_resource_ids_in_bundle_arguments)
        else
          get_first_search_by_patient(sequence, search_parameters, save_resource_ids_in_bundle_arguments)
        end
      end

      def fixed_value_search?(search_parameters, sequence)
        search_parameters != ['patient'] &&
          !sequence[:delayed_sequence] &&
          !search_param_constants(search_parameters, sequence)
      end

      def get_first_search_by_patient(sequence, search_parameters, save_resource_ids_in_bundle_arguments)
        if sequence[:delayed_sequence]
          %(
            #{get_search_params(search_parameters, sequence)}
            reply = get_resource_by_params(versioned_resource_class('#{sequence[:resource]}'), search_params)
            assert_response_ok(reply)
            assert_bundle_response(reply)
            @resources_found = reply&.resource&.entry&.any? { |entry| entry&.resource&.resourceType == '#{sequence[:resource]}' }
            #{skip_if_not_found(sequence)}
            @#{sequence[:resource].underscore} = reply.resource.entry
              .find { |entry| entry&.resource&.resourceType == '#{sequence[:resource]}' }
              .resource
            @#{sequence[:resource].underscore}_ary = fetch_all_bundled_resources(reply.resource)
            save_resource_ids_in_bundle(#{save_resource_ids_in_bundle_arguments})
            save_delayed_sequence_references(@#{sequence[:resource].underscore}_ary)
            validate_search_reply(versioned_resource_class('#{sequence[:resource]}'), reply, search_params)
          )
        else
          %(
            @#{sequence[:resource].underscore}_ary = {}
            patient_ids.each do |patient|
              #{get_search_params(search_parameters, sequence)}
              reply = get_resource_by_params(versioned_resource_class('#{sequence[:resource]}'), search_params)
              assert_response_ok(reply)
              assert_bundle_response(reply)

              any_resources = reply&.resource&.entry&.any? { |entry| entry&.resource&.resourceType == '#{sequence[:resource]}' }

              next unless any_resources

              @resources_found = true

              @#{sequence[:resource].underscore} = reply.resource.entry
                .find { |entry| entry&.resource&.resourceType == '#{sequence[:resource]}' }
                .resource
              @#{sequence[:resource].underscore}_ary[patient] = fetch_all_bundled_resources(reply.resource)
              save_resource_ids_in_bundle(#{save_resource_ids_in_bundle_arguments})
              save_delayed_sequence_references(@#{sequence[:resource].underscore}_ary[patient])
              validate_search_reply(versioned_resource_class('#{sequence[:resource]}'), reply, search_params)
            end

            #{skip_if_not_found(sequence)}
          )
        end
      end

      def fixed_value_search_param(search_parameters, sequence)
        name = search_parameters.find { |param| param != 'patient' }
        search_description = sequence[:search_param_descriptions][name.to_sym]
        values = search_description[:values]
        path =
          search_description[:path]
            .split('.')
            .drop(1)
            .map { |path_part| path_part == 'class' ? 'local_class' : path_part }
            .join('.')
        path += get_value_path_by_type(search_description[:type])

        {
          name: name,
          path: path,
          values: values
        }
      end

      def get_first_search_with_fixed_values(sequence, search_parameters, save_resource_ids_in_bundle_arguments)
        # assume only patient + one other parameter
        search_param = fixed_value_search_param(search_parameters, sequence)
        find_two_values = get_multiple_or_params(sequence).include? search_param[:name]
        values_variable_name = "#{search_param[:name].tr('-', '_')}_val"
        %(
          @#{sequence[:resource].underscore}_ary = {}
          @resources_found = false
          #{'values_found = 0' if find_two_values}
          #{values_variable_name} = [#{search_param[:values].map { |val| "'#{val}'" }.join(', ')}]
          patient_ids.each do |patient|
            @#{sequence[:resource].underscore}_ary[patient] = []
            #{values_variable_name}.each do |val|
              search_params = { 'patient': patient, '#{search_param[:name]}': val }
              reply = get_resource_by_params(versioned_resource_class('#{sequence[:resource]}'), search_params)
              assert_response_ok(reply)
              assert_bundle_response(reply)

              next unless reply&.resource&.entry&.any? { |entry| entry&.resource&.resourceType == '#{sequence[:resource]}' }

              @resources_found = true
              @#{sequence[:resource].underscore} = reply.resource.entry
                .find { |entry| entry&.resource&.resourceType == '#{sequence[:resource]}' }
                .resource
              @#{sequence[:resource].underscore}_ary[patient] += fetch_all_bundled_resources(reply.resource)
              #{'values_found += 1' if find_two_values}

              save_resource_ids_in_bundle(#{save_resource_ids_in_bundle_arguments})
              save_delayed_sequence_references(@#{sequence[:resource].underscore}_ary[patient])
              validate_search_reply(versioned_resource_class('#{sequence[:resource]}'), reply, search_params)
              #{'test_medication_inclusion(@medication_request_ary[patient], search_params)' if sequence[:resource] == 'MedicationRequest'}
              break#{' if values_found == 2' if find_two_values}
            end
          end
          #{skip_if_not_found(sequence)})
      end

      def get_search_params(search_parameters, sequence, grab_first_value = false)
        search_params = get_search_param_hash(search_parameters, sequence, grab_first_value)
        search_param_string = %(
          search_params = {
            #{search_params.map { |param, value| search_param_to_string(param, value) }.join(",\n")}
          }
        )

        if search_param_string.include? 'get_value_for_search_param'
          search_param_value_check = if sequence[:delayed_sequence]
                                       "search_params.each { |param, value| skip \"Could not resolve \#{param} in given resource\" if value.nil? }"
                                     else %(
                                        if search_params.any? { |_param, value| value.nil? }
                                          could_not_resolve_all = search_params.keys
                                          next
                                        end
                                        resolved_one = true
                                      )
                                     end
          search_param_string = %(
            #{search_param_string}
            #{search_param_value_check}
            )
        end

        search_param_string
      end

      def search_param_to_string(param, value)
        value_string = "'#{value}'" unless value.start_with?('@', 'get_value_for_search_param', 'patient')
        "'#{param}': #{value_string || value}"
      end

      def get_search_param_hash(search_parameters, sequence, grab_first_value = false)
        search_params = search_param_constants(search_parameters, sequence)
        return search_params if search_params.present?

        search_parameters.each_with_object({}) do |param, params|
          params[param] =
            if param == 'patient'
              'patient'
            elsif grab_first_value && !sequence[:delayed_sequence]
              sequence[:search_param_descriptions][param.to_sym][:values].first
            else
              "get_value_for_search_param(#{resolve_element_path(sequence[:search_param_descriptions][param.to_sym], sequence[:delayed_sequence])})"
            end
        end
      end

      def get_comparator_searches(search_params, sequence)
        search_code = ''
        search_assignments = search_params.map do |param|
          "'#{param}': #{param_value_name(param)}"
        end
        search_assignments_str = "{ #{search_assignments.join(', ')} }"
        param_comparators = find_comparators(search_params, sequence)
        param_comparators.each do |param, comparators|
          param_val_name = param_value_name(param)
          param_info = sequence[:search_param_descriptions][param.to_sym]
          type = param_info[:type]
          case type
          when 'Period', 'date'
            search_code += %(\n
              [#{comparators.keys.map { |comparator| "'#{comparator}'" }.join(', ')}].each do |comparator|
                comparator_val = date_comparator_value(comparator, #{param_val_name})
                comparator_search_params = #{search_assignments_str.gsub(param_val_name, 'comparator_val')}
                reply = get_resource_by_params(versioned_resource_class('#{sequence[:resource]}'), comparator_search_params)
                validate_search_reply(versioned_resource_class('#{sequence[:resource]}'), reply, comparator_search_params)
              end)
          end
        end
        search_code
      end

      def find_comparators(search_params, sequence)
        search_params.each_with_object({}) do |param, param_comparators|
          param_info = sequence[:search_param_descriptions][param.to_sym]
          comparators = param_info[:comparators].select { |_comparator, expectation| ['SHALL', 'SHOULD'].include? expectation }
          param_comparators[param] = comparators if comparators.present?
        end
      end

      def skip_if_not_found(sequence)
        use_other_patient = ' Please use patients with more information.'
        "skip 'No #{sequence[:resource]} resources appear to be available.#{use_other_patient unless sequence[:delayed_sequence]}' unless @resources_found"
      end

      def skip_if_could_not_resolve
        %(skip "Could not resolve all parameters (\#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one)
      end

      def search_param_constants(search_parameters, sequence)
        return { '_id': 'patient' } if search_parameters == ['_id'] && sequence[:resource] == 'Patient'
      end

      def create_search_validation(sequence)
        search_validators = ''
        sequence[:search_param_descriptions].each do |element, definition|
          search_validators += %(
              when '#{element}')
          type = definition[:type]
          path_parts = definition[:path].split('.')
          path_parts = path_parts.map { |part| part == 'class' ? 'local_class' : part }
          path_parts.shift
          case type
          when 'Period', 'date'
            search_validators += %(
                value_found = resolve_element_from_path(resource, '#{path_parts.join('.')}') { |date| validate_date_search(value, date) }
                assert value_found.present?, '#{element} on resource does not match #{element} requested'
      )
          when 'HumanName'
            # When a string search parameter refers to the types HumanName and Address,
            # the search covers the elements of type string, and does not cover elements such as use and period
            # https://www.hl7.org/fhir/search.html#string
            search_validators += %(
                value = value.downcase
                value_found = resolve_element_from_path(resource, '#{path_parts.join('.')}') do |name|
                  name&.text&.start_with?(value) ||
                    name&.family&.downcase&.include?(value) ||
                    name&.given&.any? { |given| given.downcase.start_with?(value) } ||
                    name&.prefix&.any? { |prefix| prefix.downcase.start_with?(value) } ||
                    name&.suffix&.any? { |suffix| suffix.downcase.start_with?(value) }
                end
                assert value_found.present?, '#{element} on resource does not match #{element} requested'
      )
          when 'Address'
            search_validators += %(
                value_found = resolve_element_from_path(resource, '#{path_parts.join('.')}') do |address|
                  address&.text&.start_with?(value) ||
                    address&.city&.start_with?(value) ||
                    address&.state&.start_with?(value) ||
                    address&.postalCode&.start_with?(value) ||
                    address&.country&.start_with?(value)
                end
                assert value_found.present?, '#{element} on resource does not match #{element} requested'
            )
          else
            # searching by patient requires special case because we are searching by a resource identifier
            # references can also be URL's, so we made need to resolve those url's
            path = path_parts.join('.') + get_value_path_by_type(type)
            search_validators +=
              if ['subject', 'patient'].include? element.to_s
                %(
                value_found = resolve_element_from_path(resource, '#{path}') { |reference| [value, 'Patient/' + value].include? reference }
                assert value_found.present?, '#{element} on resource does not match #{element} requested'
      )
              else
                %(
                value_found = resolve_element_from_path(resource, '#{path}') { |value_in_resource| value.split(',').include? value_in_resource }
                assert value_found.present?, '#{element} on resource does not match #{element} requested'
      )
              end
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

        if sequence[:resource] == 'MedicationRequest'
          validate_function += %(
            def test_medication_inclusion(medication_requests, search_params)
              requests_with_external_references =
                medication_requests
                  .select { |request| request&.medicationReference&.present? }
                  .reject { |request| request&.medicationReference&.reference&.start_with? '#' }

              return if requests_with_external_references.blank?

              search_params.merge!(_include: 'MedicationRequest:medication')
              response = get_resource_by_params(FHIR::MedicationRequest, search_params)
              assert_response_ok(response)
              assert_bundle_response(response)
              requests_with_medications = fetch_all_bundled_resources(response.resource)

              medications = requests_with_medications.select { |resource| resource.resourceType == 'Medication' }
              assert medications.present?, 'No Medications were included in the search results'
            end
          )
        end

        validate_function
      end

      def generate_module(module_info)
        file_name = "#{module_yml_out_path}/#{@path}_module.yml"

        template = ERB.new(File.read(File.join(__dir__, 'templates/module.yml.erb')))
        output = template.result_with_hash(module_info)

        File.write(file_name, output)
      end
    end
  end
end
