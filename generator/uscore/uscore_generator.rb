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
          unit_test_generator.generate(sequence, sequence_out_path)
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

          create_include_test(sequence) if sequence[:include_params].any?
          create_revinclude_test(sequence) if sequence[:revincludes].any?
          create_resource_profile_test(sequence)
          create_must_support_test(sequence)
          create_references_resolved_test(sequence)
        end
      end

      def mark_delayed_sequences(metadata)
        metadata[:sequences].each do |sequence|
          sequence[:delayed_sequence] = sequence[:resource] != 'Patient' && sequence[:searches].none? { |search| search[:names].include? 'patient' }
        end
        metadata[:delayed_sequences] = metadata[:sequences].select { |seq| seq[:delayed_sequence] }
        metadata[:non_delayed_sequences] = metadata[:sequences].reject { |seq| seq[:delayed_sequence] }
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
        key = :resource_read
        read_test = {
          tests_that: "Can read #{sequence[:resource]} from the server",
          key: key,
          index: sequence[:tests].length + 1,
          link: 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
        }

        read_test[:test_code] = %(
              #{sequence[:resource].downcase}_id = @instance.resource_references.find { |reference| reference.resource_type == '#{sequence[:resource]}' }&.resource_id
              skip 'No #{sequence[:resource]} references found from the prior searches' if #{sequence[:resource].downcase}_id.nil?
              @#{sequence[:resource].downcase} = fetch_resource('#{sequence[:resource]}', #{sequence[:resource].downcase}_id)
              @#{sequence[:resource].downcase}_ary = Array.wrap(@#{sequence[:resource].downcase})
              @resources_found = !@#{sequence[:resource].downcase}.nil?)
        sequence[:tests] << read_test

        unit_test_generator.generate_resource_read_test(
          key: key,
          resource_type: sequence[:resource],
          class_name: sequence[:class_name]
        )
      end

      def create_authorization_test(sequence)
        key = :unauthorized_search
        authorization_test = {
          tests_that: "Server rejects #{sequence[:resource]} search without authorization",
          key: key,
          index: sequence[:tests].length + 1,
          link: 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html#behavior'
        }

        first_search = find_first_search(sequence)
        return if first_search.nil?

        authorization_test[:test_code] = %(
              @client.set_no_auth
              omit 'Do not test if no bearer token set' if @instance.token.blank?
              search_params = { patient: @instance.patient_id }
              reply = get_resource_by_params(versioned_resource_class('#{sequence[:resource]}'), search_params)
              @client.set_bearer_token(@instance.token)
              assert_response_unauthorized reply)

        sequence[:tests] << authorization_test

        unit_test_generator.generate_authorization_test(
          key: key,
          resource_type: sequence[:resource],
          search_params: { patient: '@instance.patient_id' },
          class_name: sequence[:class_name]
        )
      end

      def create_include_test(sequence)
        include_test = {
          tests_that: "Server returns the appropriate resource from the following _includes: #{sequence[:include_params].join(', ')}",
          index: sequence[:tests].length + 1,
          link: 'https://www.hl7.org/fhir/search.html#include'
        }
        first_search = find_first_search(sequence)
        search_params = first_search.nil? ? 'search_params = {}' : get_search_params(first_search[:names], sequence)
        include_test[:test_code] = search_params
        sequence[:include_params].each do |include|
          resource_name = include.split(':').last.capitalize
          resource_variable = "#{resource_name.downcase}_results" # kind of a hack, but works for now - would have to otherwise figure out resource type of target profile
          include_test[:test_code] += %(
                search_params['_include'] = '#{include}'
                reply = get_resource_by_params(versioned_resource_class('#{sequence[:resource]}'), search_params)
                assert_response_ok(reply)
                assert_bundle_response(reply)
                #{resource_variable} = reply&.resource&.entry&.map(&:resource)&.any? { |resource| resource.resourceType == '#{resource_name}' }
                assert #{resource_variable}, 'No #{resource_name} resources were returned from this search'
          )
        end
        sequence[:tests] << include_test
      end

      def create_revinclude_test(sequence)
        revinclude_test = {
          tests_that: "Server returns the appropriate resources from the following _revincludes: #{sequence[:revincludes].join(',')}",
          index: sequence[:tests].length + 1,
          link: 'https://www.hl7.org/fhir/search.html#revinclude'
        }
        first_search = find_first_search(sequence)
        search_params = first_search.nil? ? "\nsearch_params = {}" : get_search_params(first_search[:names], sequence)
        revinclude_test[:test_code] = search_params
        sequence[:revincludes].each do |revinclude|
          resource_name = revinclude.split(':').first
          resource_variable = "#{resource_name.downcase}_results"
          revinclude_test[:test_code] += %(
                search_params['_revinclude'] = '#{revinclude}'
                reply = get_resource_by_params(versioned_resource_class('#{sequence[:resource]}'), search_params)
                assert_response_ok(reply)
                assert_bundle_response(reply)
                #{resource_variable} = reply&.resource&.entry&.map(&:resource)&.any? { |resource| resource.resourceType == '#{resource_name}' }
                assert #{resource_variable}, 'No #{resource_name} resources were returned from this search'
          )
        end
        sequence[:tests] << revinclude_test
      end

      def create_search_test(sequence, search_param)
        search_test = {
          tests_that: "Server returns expected results from #{sequence[:resource]} search by #{search_param[:names].join('+')}",
          index: sequence[:tests].length + 1,
          link: 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html',
          optional: search_param[:expectation] != 'SHALL'
        }

        is_first_search = search_param == find_first_search(sequence)

        search_test[:test_code] =
          if is_first_search
            get_first_search(search_param[:names], sequence)
          else
            %(
              skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
              assert !@#{sequence[:resource].downcase}.nil?, 'Expected valid #{sequence[:resource]} resource to be present'
      #{get_search_params(search_param[:names], sequence)}
              reply = get_resource_by_params(versioned_resource_class('#{sequence[:resource]}'), search_params)
              validate_search_reply(versioned_resource_class('#{sequence[:resource]}'), reply, search_params)
              assert_response_ok(reply))
          end
        search_test[:test_code] += get_comparator_searches(search_param[:names], sequence)
        sequence[:tests] << search_test
      end

      def create_interaction_test(sequence, interaction)
        interaction_test = {
          tests_that: "#{sequence[:resource]} #{interaction[:code]} resource supported",
          index: sequence[:tests].length + 1,
          link: 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
        }

        interaction_test[:test_code] = %(
              skip_if_not_supported(:#{sequence[:resource]}, [:#{interaction[:code]}])
              skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

              validate_#{interaction[:code]}_reply(@#{sequence[:resource].downcase}, versioned_resource_class('#{sequence[:resource]}')))

        sequence[:tests] << interaction_test
      end

      def create_must_support_test(sequence)
        test = {
          tests_that: "At least one of every must support element is provided in any #{sequence[:resource]} for this patient.",
          index: sequence[:tests].length + 1,
          link: 'https://build.fhir.org/ig/HL7/US-Core-R4/general-guidance.html/#must-support',
          test_code: ''
        }

        test[:test_code] += %(
              skip 'No resources appear to be available for this patient. Please use patients with more information' unless @#{sequence[:resource].downcase}_ary&.any?)

        test[:test_code] += %(
              must_support_confirmed = {})

        extensions_list = []
        sequence[:must_supports].select { |must_support| must_support[:type] == 'extension' }.each do |extension|
          extensions_list << "'#{extension[:id]}': '#{extension[:url]}'"
        end
        if extensions_list.any?
          test[:test_code] += %(
              extensions_list = {
                #{extensions_list.join(",\n          ")}
              }
              extensions_list.each do |id, url|
                @#{sequence[:resource].downcase}_ary&.each do |resource|
                  must_support_confirmed[id] = true if resource.extension.any? { |extension| extension.url == url }
                  break if must_support_confirmed[id]
                end
                skip_notification = "Could not find \#{id} in any of the \#{@#{sequence[:resource].downcase}_ary.length} provided #{sequence[:resource]} resource(s)"
                skip skip_notification unless must_support_confirmed[id]
              end
      )
        end
        elements_list = []
        sequence[:must_supports].select { |must_support| must_support[:type] == 'element' }.each do |element|
          element[:path] = element[:path].gsub('.class', '.local_class') # class is mapped to local_class in fhir_models
          elements_list << "'#{element[:path]}'"
        end

        if elements_list.any?
          test[:test_code] += %(
              must_support_elements = [
                #{elements_list.join(",\n          ")}
              ]
              must_support_elements.each do |path|
                @#{sequence[:resource].downcase}_ary&.each do |resource|
                  truncated_path = path.gsub('#{sequence[:resource]}.', '')
                  must_support_confirmed[path] = true if can_resolve_path(resource, truncated_path)
                  break if must_support_confirmed[path]
                end
                resource_count = @#{sequence[:resource].downcase}_ary.length

                skip "Could not find \#{path} in any of the \#{resource_count} provided #{sequence[:resource]} resource(s)" unless must_support_confirmed[path]
              end)
        end

        test[:test_code] += %(
              @instance.save!)

        sequence[:tests] << test
      end

      def create_resource_profile_test(sequence)
        test = {
          tests_that: "#{sequence[:resource]} resources associated with Patient conform to US Core R4 profiles",
          index: sequence[:tests].length + 1,
          link: sequence[:profile]
        }
        test[:test_code] = %(
              skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
              test_resources_against_profile('#{sequence[:resource]}'#{', ' + validation_profile_uri(sequence) if validation_profile_uri(sequence)}))

        sequence[:tests] << test
      end

      def create_references_resolved_test(sequence)
        test = {
          tests_that: 'All references can be resolved',
          index: sequence[:tests].length + 1,
          link: 'https://www.hl7.org/fhir/DSTU2/references.html'
        }

        test[:test_code] = %(
              skip_if_not_supported(:#{sequence[:resource]}, [:search, :read])
              skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

              validate_reference_resolutions(@#{sequence[:resource].downcase}))
        sequence[:tests] << test
      end

      def resolve_element_path(search_param_description)
        element_path = search_param_description[:path].gsub('.class', '.local_class') # match fhir_models because class is protected keyword in ruby
        path_parts = element_path.split('.')
        resource_val = "@#{path_parts.shift.downcase}_ary"
        "get_value_for_search_param(resolve_element_from_path(#{resource_val}, '#{path_parts.join('.')}'))"
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

        search_code = if search_parameters == ['patient'] || sequence[:delayed_sequence] || search_param_constants(search_parameters, sequence)
                        get_first_search_by_patient(sequence, search_parameters, save_resource_ids_in_bundle_arguments)
                      else
                        get_first_search_with_fixed_values(sequence, search_parameters, save_resource_ids_in_bundle_arguments)
                      end
        search_code
      end

      def get_first_search_by_patient(sequence, search_parameters, save_resource_ids_in_bundle_arguments)
        %(
          #{get_search_params(search_parameters, sequence)}
          reply = get_resource_by_params(versioned_resource_class('#{sequence[:resource]}'), search_params)
          assert_response_ok(reply)
          assert_bundle_response(reply)

          resource_count = reply&.resource&.entry&.length || 0
          @resources_found = true if resource_count.positive?

          skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

          @#{sequence[:resource].downcase} = reply&.resource&.entry&.first&.resource
          @#{sequence[:resource].downcase}_ary = fetch_all_bundled_resources(reply&.resource)
          save_resource_ids_in_bundle(#{save_resource_ids_in_bundle_arguments})
          save_delayed_sequence_references(@#{sequence[:resource].downcase}_ary)
          validate_search_reply(versioned_resource_class('#{sequence[:resource]}'), reply, search_params)
        )
      end

      def get_first_search_with_fixed_values(sequence, search_parameters, save_resource_ids_in_bundle_arguments)
        # assume only patient + one other parameter
        non_patient_search_param = search_parameters.find { |param| param != 'patient' }
        non_patient_values = sequence[:search_param_descriptions][non_patient_search_param.to_sym][:values]
        values_variable_name = "#{non_patient_search_param.tr('-', '_')}_val"
        %(
          #{values_variable_name} = [#{non_patient_values.map { |val| "'#{val}'" }.join(', ')}]
          #{values_variable_name}.each do |val|
            search_params = { 'patient': @instance.patient_id, '#{non_patient_search_param}': val }
            reply = get_resource_by_params(versioned_resource_class('#{sequence[:resource]}'), search_params)
            assert_response_ok(reply)
            assert_bundle_response(reply)

            resource_count = reply&.resource&.entry&.length || 0
            @resources_found = true if resource_count.positive?
            next unless @resources_found

            @#{sequence[:resource].downcase} = reply&.resource&.entry&.first&.resource
            @#{sequence[:resource].downcase}_ary = fetch_all_bundled_resources(reply&.resource)

            save_resource_ids_in_bundle(#{save_resource_ids_in_bundle_arguments})
            save_delayed_sequence_references(@#{sequence[:resource].downcase}_ary)
            validate_search_reply(versioned_resource_class('#{sequence[:resource]}'), reply, search_params)
            break
          end
          skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found)
      end

      def get_search_params(search_parameters, sequence)
        search_params = get_search_param_hash(search_parameters, sequence)
        search_param_string = %(
          search_params = {
            #{search_params.map { |param, value| search_param_to_string(param, value) }.join(",\n")}
          }
        )

        if search_param_string.include? 'get_value_for_search_param'
          search_param_value_check =
            %(search_params.each { |param, value| skip "Could not resolve \#{param} in given resource" if value.nil? }\n)
          return [search_param_string, search_param_value_check].join('')
        end

        search_param_string
      end

      def search_param_to_string(param, value)
        value_string = "'#{value}'" unless value.start_with?('@', 'get_value_for_search_param')
        "'#{param}': #{value_string || value}"
      end

      def get_search_param_hash(search_parameters, sequence)
        search_params = search_param_constants(search_parameters, sequence)
        return search_params if search_params.present?

        search_parameters.each_with_object({}) do |param, params|
          params[param] =
            if param == 'patient'
              '@instance.patient_id'
            else
              resolve_element_path(sequence[:search_param_descriptions][param.to_sym])
            end
        end
      end

      def get_comparator_searches(search_params, sequence)
        search_code = ''
        search_assignments = search_params.map do |param|
          "'#{param}': #{param_value_name(param)}"
        end
        search_assignments_str = "{ #{search_assignments.join(', ')} }"
        search_params.each do |param|
          param_val_name = param_value_name(param)
          param_info = sequence[:search_param_descriptions][param.to_sym]
          comparators = param_info[:comparators].select { |_comparator, expectation| ['SHALL', 'SHOULD'].include? expectation }
          next if comparators.empty?

          type = param_info[:type]
          case type
          when 'Period', 'date'
            search_code += %(\n
              [#{comparators.keys.map { |comparator| "'#{comparator}'" }.join(', ')}].each do |comparator|
                comparator_val = date_comparator_value(comparator, #{param_val_name})
                comparator_search_params = #{search_assignments_str.gsub(param_val_name, 'comparator_val')}
                reply = get_resource_by_params(versioned_resource_class('#{sequence[:resource]}'), comparator_search_params)
                validate_search_reply(versioned_resource_class('#{sequence[:resource]}'), reply, comparator_search_params)
                assert_response_ok(reply)
              end)
          end
        end
        search_code
      end

      def search_param_constants(search_parameters, sequence)
        return { patient: '@instance.patient_id', category: 'assess-plan' } if search_parameters == ['patient', 'category'] &&
                                                                               sequence[:resource] == 'CarePlan'
        return { patient: '@instance.patient_id', status: 'active' } if search_parameters == ['patient', 'status'] &&
                                                                        sequence[:resource] == 'CareTeam'
        return { '_id': '@instance.patient_id' } if search_parameters == ['_id'] && sequence[:resource] == 'Patient'
        return { patient: '@instance.patient_id', code: '72166-2' } if search_parameters == ['patient', 'code'] &&
                                                                       sequence[:profile] == PROFILE_URIS[:smoking_status]
        return { patient: '@instance.patient_id', category: 'laboratory' } if search_parameters == ['patient', 'category'] &&
                                                                              sequence[:profile] == PROFILE_URIS[:lab_results]
        return { patient: '@instance.patient_id', code: '77606-2' } if search_parameters == ['patient', 'code'] &&
                                                                       sequence[:profile] == PROFILE_URIS[:pediatric_weight_height]
        return { patient: '@instance.patient_id', code: '59576-9' } if search_parameters == ['patient', 'code'] &&
                                                                       sequence[:profile] == PROFILE_URIS[:pediatric_bmi_age]
        return { patient: '@instance.patient_id', category: 'LAB' } if search_parameters == ['patient', 'category'] &&
                                                                       sequence[:profile] == PROFILE_URIS[:diagnostic_report_lab]
        return { patient: '@instance.patient_id', code: 'LP29684-5' } if search_parameters == ['patient', 'category'] &&
                                                                         sequence[:profile] == PROFILE_URIS[:diagnostic_report_note]
        return { patient: '@instance.patient_id', code: '59408-5' } if search_parameters == ['patient', 'code'] &&
                                                                       sequence[:profile] == PROFILE_URIS[:pulse_oximetry]
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
          when 'Period'
            search_validators += %(
                value_found = can_resolve_path(resource, '#{path_parts.join('.')}') do |period|
                  validate_period_search(value, period)
                end
                assert value_found, '#{element} on resource does not match #{element} requested'
      )
          when 'date'
            search_validators += %(
                value_found = can_resolve_path(resource, '#{path_parts.join('.')}') do |date|
                  validate_date_search(value, date)
                end
                assert value_found, '#{element} on resource does not match #{element} requested'
      )
          when 'HumanName'
            # When a string search parameter refers to the types HumanName and Address,
            # the search covers the elements of type string, and does not cover elements such as use and period
            # https://www.hl7.org/fhir/search.html#string
            search_validators += %(
                value = value.downcase
                value_found = can_resolve_path(resource, '#{path_parts.join('.')}') do |name|
                  name&.text&.start_with?(value) ||
                    name&.family&.downcase&.include?(value) ||
                    name&.given&.any? { |given| given.downcase.start_with?(value) } ||
                    name&.prefix&.any? { |prefix| prefix.downcase.start_with?(value) } ||
                    name&.suffix&.any? { |suffix| suffix.downcase.start_with?(value) }
                end
                assert value_found, '#{element} on resource does not match #{element} requested'
      )
          when 'Address'
            search_validators += %(
                value_found = can_resolve_path(resource, '#{path_parts.join('.')}') do |address|
                  address&.text&.start_with?(value) ||
                    address&.city&.start_with?(value) ||
                    address&.state&.start_with?(value) ||
                    address&.postalCode&.start_with?(value) ||
                    address&.country&.start_with?(value)
                end
                assert value_found, '#{element} on resource does not match #{element} requested'
            )
          else
            # searching by patient requires special case because we are searching by a resource identifier
            # references can also be URL's, so we made need to resolve those url's
            search_validators +=
              if ['subject', 'patient'].include? element.to_s
                %(
                value_found = can_resolve_path(resource, '#{path_parts.join('.') + get_value_path_by_type(type)}') { |reference| [value, 'Patient/' + value].include? reference }
                assert value_found, '#{element} on resource does not match #{element} requested'
      )
              else
                %(
                value_found = can_resolve_path(resource, '#{path_parts.join('.') + get_value_path_by_type(type)}') { |value_in_resource| value_in_resource == value }
                assert value_found, '#{element} on resource does not match #{element} requested'
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
