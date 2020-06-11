# frozen_string_literal: true

require 'http' # for streaming http client
Dir['lib/modules/uscore_v3.1.0/profile_definitions/*'].sort.each { |file| require './' + file }

module Inferno
  module Sequence
    class BulkDataGroupExportValidationSequence < SequenceBase
      group 'Bulk Data Group Export Validation'

      title 'Group Compartment Export Validation Tests'

      description 'Verify that Group compartment export from the Bulk Data server follow US Core Implementation Guide'

      test_id_prefix 'BDGV'

      requires :bulk_status_output, :bulk_lines_to_validate, :bulk_patient_ids_in_group, :bulk_device_types_in_group

      attr_accessor :requires_access_token, :output, :patient_ids_seen

      MAX_RECENT_LINE_SIZE = 100
      MIN_RESOURCE_COUNT = 2

      US_CORE_R4_URIS = Inferno::ValidationUtil::US_CORE_R4_URIS

      include Inferno::USCore310ProfileDefinitions

      def initialize(instance, client, disable_tls_tests = false, sequence_result = nil)
        super(instance, client, disable_tls_tests, sequence_result)

        return unless @instance.bulk_status_output.present?

        status_response = JSON.parse(@instance.bulk_status_output)
        @output = status_response['output']
        requires_access_token = status_response['requiresAccessToken']
        @requires_access_token = requires_access_token.to_s.downcase == 'true' if requires_access_token.present?
        @patient_ids_seen = Set.new
      end

      def test_output_against_profile(klass,
                                      profile_definitions = [],
                                      output = @output,
                                      bulk_lines_to_validate = @instance.bulk_lines_to_validate)
        skip 'Bulk Data Server response does not have output data' unless output.present?

        lines_to_validate_parameter = get_lines_to_validate(bulk_lines_to_validate)

        file_list = output.find_all { |item| item['type'] == klass }

        omit_or_skip_empty_resources(klass) if file_list.empty?

        validate_all = lines_to_validate_parameter[:validate_all]
        lines_to_validate = lines_to_validate_parameter[:lines_to_validate]

        omit 'Validate has been omitted because line_to_validate is 0' if !validate_all && lines_to_validate.zero? && klass != 'Patient'

        success_count = 0

        file_list.each do |file|
          success_count += check_file_request(file, klass, validate_all, lines_to_validate, profile_definitions)
        end

        omit_or_skip_empty_resources(klass) if success_count.zero? && (validate_all || lines_to_validate.positive?)

        pass "Successfully validated #{success_count} resource(s)."
      end

      def omit_or_skip_empty_resources(klass)
        omit 'No Medication resources provided, and Medication resources are optional.' if klass == 'Medication'
        skip "Bulk Data Server export did not provide any #{klass} resources."
      end

      def get_lines_to_validate(input)
        if input.nil? || input.strip.empty?
          validate_all = true
          lines_to_validate = 0
        else
          lines_to_validate = input.to_i
        end

        {
          validate_all: validate_all,
          lines_to_validate: lines_to_validate
        }
      end

      def check_file_request(file, klass, validate_all = true, lines_to_validate = 0, profile_definitions = [])
        headers = { accept: 'application/fhir+ndjson' }
        headers['Authorization'] = "Bearer #{@instance.bulk_access_token}" if @requires_access_token && @instance.bulk_access_token.present?

        line_count = 0
        validation_error_collection = {}
        line_collection = []

        request_for_log = {
          method: 'GET',
          url: file['url'],
          headers: headers
        }

        response_for_log = {
          body: String.new
        }

        streamed_ndjson_get(file['url'], headers) do |response, resource|
          assert response.headers['Content-Type'] == 'application/fhir+ndjson', "Content type must be 'application/fhir+ndjson' but is '#{response.headers['Content-type']}'"

          break if !validate_all && line_count >= lines_to_validate && (klass != 'Patient' || @patient_ids_seen.length >= MIN_RESOURCE_COUNT)

          response_for_log[:code] = response.code unless response_for_log.key?(:code)
          response_for_log[:headers] = response.headers unless response_for_log.key?(:headers)
          line_collection << resource if line_count < MAX_RECENT_LINE_SIZE

          line_count += 1

          resource = versioned_resource_class.from_contents(resource)
          resource_type = resource.class.name.demodulize
          assert resource_type == klass, "Resource type \"#{resource_type}\" at line \"#{line_count}\" does not match type defined in output \"#{klass}\")"

          @patient_ids_seen << resource.id if klass == 'Patient'

          p = guess_profile(resource, @instance.fhir_version.to_sym)

          if p && @instance.fhir_version == 'r4'
            resource_validation_errors = Inferno::RESOURCE_VALIDATOR.validate(resource, versioned_resource_class, p.url)
          else
            warn { assert false, 'No profiles found for this Resource' }
            resource_validation_errors = Inferno::RESOURCE_VALIDATOR.validate(resource, versioned_resource_class)
          end

          process_profile_definition(profile_definitions, p, resource, resource_validation_errors)

          # Remove warnings if using internal FHIRModelsValidator. FHIRModelsValidator has an issue with FluentPath.
          resource_validation_errors = [] if resource_validation_errors[:errors].empty? &&
                                             (Inferno::RESOURCE_VALIDATOR.is_a?(Inferno::FHIRModelsValidator) ||
                                             (resource_validation_errors[:warnings].empty? && resource_validation_errors[:information].empty?))

          validation_error_collection[line_count] = resource_validation_errors unless resource_validation_errors.empty?
        end

        unless validate_all
          response_for_log[:body] = line_collection.join
          LoggedRestClient.record_response(request_for_log, response_for_log)
        end

        process_validation_errors(validation_error_collection, line_count, klass)

        assert_must_supports_found(profile_definitions) if line_count.positive?

        if file.key?('count') && validate_all
          warning do
            assert file['count'].to_s == line_count.to_s, "Count in status output (#{file['count']}) did not match actual number of resources returned (#{line_count})"
          end
        end

        line_count
      end

      def guess_profile(resource, version)
        # if Device type code is not in predefined type code list, validate using FHIR base profile
        return nil if resource.resourceType == 'Device' && !predefined_device_type?(resource)

        # validate Location using FHIR base profile
        return nil if resource.resourceType == 'Location'

        Inferno::ValidationUtil.guess_profile(resource, version)
      end

      def predefined_device_type?(resource)
        return false if resource.nil?

        return true if @instance.bulk_device_types_in_group.blank?

        expected_types = Set.new(@instance.bulk_device_types_in_group.split(',').map(&:strip))

        actual_types = resource&.type&.coding&.select { |coding| coding.system.nil? || coding.system == 'http://snomed.info/sct' }&.map { |coding| coding.code }

        (expected_types & actual_types).any?
      end

      def process_profile_definition(profile_definitions, profile, resource, resource_validation_errors)
        return unless profile.present? && profile_definitions.present?

        if profile_definitions.length > 1 && profile
          profile_must_support = profile_definitions.find { |profile_definition| profile_definition[:profile] == profile.url }
          must_support_info = profile_must_support.present? ? profile_must_support[:must_support_info] : nil
          binding_info = profile_must_support.present? ? profile_must_support[:binding_info] : nil
        else
          must_support_info = profile_definitions.first[:must_support_info]
          binding_info = profile_definitions.first[:binding_info]
        end

        process_must_support(must_support_info, resource) if must_support_info.present?

        return unless binding_info.present?

        terminology_validation_errors = validate_bindings(binding_info, Array(resource))
        resource_validation_errors[:errors].concat(terminology_validation_errors[:errors])
        resource_validation_errors[:warnings].concat(terminology_validation_errors[:warnings])
      end

      def process_must_support(must_support_info, resource)
        return unless must_support_info.present?

        must_support_info[:elements].reject! do |ms_element|
          resolve_element_from_path(resource, ms_element[:path]) { |value| ms_element[:fixed_value].blank? || value == ms_element[:fixed_value] }
        end

        must_support_info[:extensions].reject! do |ms_extension|
          resource.extension.any? { |extension| extension.url == ms_extension[:url] }
        end

        must_support_info[:slices].reject! do |ms_slice|
          find_slice(resource, ms_slice[:path], ms_slice[:discriminator])
        end
      end

      def validate_bindings(bindings, resources)
        return unless bindings.present?

        invalid_binding_messages = []
        invalid_binding_resources = Set.new
        validation_errors = { errors: [], warnings: [] }
        bindings.select { |binding_def| binding_def[:strength] == 'required' }.each do |binding_def|
          begin
            invalid_bindings = resources_with_invalid_binding(binding_def, resources)
          rescue Inferno::Terminology::UnknownValueSetException => e
            validation_errors[:warnings] << e.message
            invalid_bindings = []
          end
          invalid_bindings.each { |invalid| invalid_binding_resources << "#{invalid[:resource]&.resourceType}/#{invalid[:resource].id}" }
          invalid_binding_messages.concat(invalid_bindings.map { |invalid| invalid_binding_message(invalid, binding_def) })
        end

        unless invalid_binding_messages.blank?
          validation_errors[:errors] << "#{invalid_binding_messages.count} invalid required #{'binding'.pluralize(invalid_binding_messages.count)}" \
            " found in #{invalid_binding_resources.count} #{'resource'.pluralize(invalid_binding_resources.count)}: " \
            "#{invalid_binding_messages.join('. ')}"
          return validation_errors
        end

        bindings.select { |binding_def| binding_def[:strength] == 'extensible' }.each do |binding_def|
          begin
            invalid_bindings = resources_with_invalid_binding(binding_def, resources)
            binding_def_new = binding_def
            # If the valueset binding wasn't valid, check if the codes are in the stated codesystem
            if invalid_bindings.present?
              invalid_bindings = resources_with_invalid_binding(binding_def.except(:system), resources)
              binding_def_new = binding_def.except(:system)
            end
          rescue Inferno::Terminology::UnknownValueSetException, Inferno::Terminology::ValueSet::UnknownCodeSystemException => e
            validation_errors[:warnings] << e.message
            invalid_bindings = []
          end

          validation_errors[:warnings].concat(invalid_bindings.map { |invalid| invalid_binding_message(invalid, binding_def_new) })
        end

        validation_errors
      end

      def process_validation_errors(validation_error_collection, line_count, klass)
        error_count = 0
        first_error = String.new
        first_warning = []

        validation_error_collection.each do |line_number, resource_validation_errors|
          unless resource_validation_errors[:errors].empty?
            error_count += 1
            first_error = "The first failed is line ##{line_number}:\n\n* #{resource_validation_errors[:errors].join("\n* ")}" if first_error.empty?
          end

          if first_warning.empty? && resource_validation_errors[:warnings].count.positive?
            first_warning.concat(resource_validation_errors[:warnings].map { |e| "Line ##{line_number}: #{e}" })
          end

          @information_messages.concat(resource_validation_errors[:information].map { |e| "Line ##{line_number}: #{e}" })
        end

        @test_warnings.concat(first_warning)
        assert error_count.zero?, "#{error_count} / #{line_count} #{klass} resources failed profile validation. #{first_error}"
      end

      def assert_must_supports_found(profile_definitions)
        profile_definitions.each do |must_support|
          error_string = "Could not verify presence#{' for profile ' + must_support[:profile] if must_support[:profile].present?} of the following must support %s: %s"
          missing_must_supports = must_support[:must_support_info]

          missing_elements_list = missing_must_supports[:elements].map { |el| "#{el[:path]}#{': ' + el[:fixed_value] if el[:fixed_value].present?}" }
          assert missing_elements_list.empty?, format(error_string, 'elements', missing_elements_list.join(', '))

          missing_slices_list = missing_must_supports[:slices].map { |slice| slice[:name] }
          assert missing_slices_list.empty?, format(error_string, 'slices', missing_slices_list.join(', '))

          missing_extensions_list = missing_must_supports[:extensions].map { |extension| extension[:id] }
          assert missing_extensions_list.empty?, format(error_string, 'extensions', missing_extensions_list.join(', '))
        end
      end

      def log_and_reraise_if_error(request, response, truncated)
        yield
      rescue StandardError
        response[:body] = "NOTE: RESPONSE TRUNCATED\nINFERNO ONLY DISPLAYS FIRST #{MAX_RECENT_LINE_SIZE} LINES\n\n#{response[:body]}" if truncated
        LoggedRestClient.record_response(request, response)
        raise
      end

      def streamed_ndjson_get(url, headers)
        ctx = OpenSSL::SSL::SSLContext.new
        ctx.verify_mode = OpenSSL::SSL::VERIFY_PEER # set globally to VERIFY_NONE if disable_verify_peer set
        ctx.set_params unless OpenSSL::SSL::VERIFY_PEER == OpenSSL::SSL::VERIFY_NONE
        response = HTTP.headers(headers).get(url, ssl_context: ctx)

        # We need to log the request, but don't know what will be in the body
        # until later.  These serve as simple summaries to get turned into
        # logged requests.

        request_for_log = {
          method: 'GET',
          url: url,
          headers: headers
        }

        response_for_log = {
          code: response.status,
          headers: response.headers,
          body: String.new,
          truncated: false
        }

        # We don't want to keep a huge log of everything that came through,
        # but we also want to show up to a reasonable number.
        recent_lines = []
        line_count = 0

        body = response.body

        next_block = String.new

        until (chunk = body.readpartial).nil?
          next_block << chunk
          resource_list = next_block.lines

          # Skip process the last line since the it may not complete (still appending from stream)
          next_block = resource_list.pop
          # Skip if the last_line is empty
          # Cannot use .blank? since docker-compose complains "invalid byte sequence in US-ASCII" during unit test
          next_block = String.new next_block unless next_block.nil? || next_block.strip.empty?

          resource_list.each do |resource|
            # NDJSON does not specify empty line is NOT allowed.
            # So just skip an empty line.
            next if resource.nil? || resource.strip.empty?

            recent_lines << resource if line_count < MAX_RECENT_LINE_SIZE
            line_count += 1

            response_for_log[:body] = recent_lines.join
            log_and_reraise_if_error(request_for_log, response_for_log, line_count > MAX_RECENT_LINE_SIZE) do
              yield(response, resource)
            end
          end
        end

        # NDJSON does not specify empty line is NOT allowed.
        # So just skip if last line is empty.
        unless next_block.nil? || next_block.strip.empty?
          recent_lines << next_block if line_count < MAX_RECENT_LINE_SIZE
          line_count += 1
          response_for_log[:body] = recent_lines.join

          log_and_reraise_if_error(request_for_log, response_for_log, line_count > MAX_RECENT_LINE_SIZE) do
            yield(response, next_block)
          end
        end

        if line_count > MAX_RECENT_LINE_SIZE
          response_for_log[:body] = "NOTE: RESPONSE TRUNCATED\nINFERNO ONLY DISPLAYS FIRST #{MAX_RECENT_LINE_SIZE} LINES\n\n#{response_for_log[:body]}"
        end
        LoggedRestClient.record_response(request_for_log, response_for_log)

        line_count
      end

      def get_file(file, use_token: true)
        headers = { accept: 'application/fhir+ndjson' }
        headers['Authorization'] = 'Bearer ' + @instance.bulk_access_token if use_token && @requires_access_token && @instance.bulk_access_token.present?

        url = file['url']
        LoggedRestClient.get(url, headers)
      end

      test :require_tls do
        metadata do
          id '01'
          name 'Bulk Data Server is secured by transport layer security'
          link 'http://hl7.org/fhir/uv/bulkdata/export/index.html#security-considerations'
          description %(
            All exchanges described herein between a client and a server SHALL be secured using Transport Layer Security (TLS) Protocol Version 1.2 (RFC5246)
          )
        end

        skip 'Could not verify this functionality when output is empty' unless @output.present?

        omit_if_tls_disabled

        assert_tls_1_2 @output[0]['url']
        assert_deny_previous_tls @output[0]['url']
      end

      test :require_access_token do
        metadata do
          id '02'
          name 'NDJSON download requires access token if requireAccessToken is true'
          link 'http://hl7.org/fhir/uv/bulkdata/export/index.html#file-request'
          description %(
            If the requiresAccessToken field in the Complete Status body is set to true, the request SHALL include a valid access token.

            [FHIR R4 Security](http://build.fhir.org/security.html#AccessDenied) and
            [The OAuth 2.0 Authorization Framework: Bearer Token Usage](https://tools.ietf.org/html/rfc6750#section-3.1)
            recommend using HTTP status code 401 for invalid token but also allow the actual result be controlled by policy and context.
          )
        end

        skip 'Could not verify this functionality when requireAccessToken is false' unless @requires_access_token
        skip 'Could not verify this functionality when bearer token is not set' if @instance.bulk_access_token.blank?

        reply = get_file(@output[0], use_token: false)

        assert_response_bad_or_unauthorized(reply)
      end

      test :validate_patient do
        metadata do
          id '03'
          name 'Patient resources returned conform to the US Core Patient Profile'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient'
          description %(
            This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
          )
        end

        profile_definitions = [
          {
            profile: nil,
            must_support_info: USCore310PatientSequenceDefinitions::MUST_SUPPORTS.dup,
            binding_info: USCore310PatientSequenceDefinitions::BINDINGS.dup
          }
        ]

        test_output_against_profile('Patient', profile_definitions)
      end

      test :validate_two_patients do
        metadata do
          id '04'
          name 'Group export has at least two patients'
          link 'http://ndjson.org/'
          description %(
            This test verifies that the Group export has at least two patients.
          )
        end

        skip 'Bulk Data Server export did not provide any Patient resources.' unless @patient_ids_seen.present?

        assert @patient_ids_seen.length >= MIN_RESOURCE_COUNT, 'Bulk Data Server export did not have multple Patient resources.'
      end

      test :validate_patient_ids_in_group do
        metadata do
          id '05'
          name 'Patient IDs match those expected in Group'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient'
          description %(
            This test checks that the list of patient IDs that are expected match those that are returned.
            If no patient ids are provided to the test, then the test will be omitted.
          )
        end

        omit 'No patient ids were given' unless @instance.bulk_patient_ids_in_group.present?

        expected_patients = Set.new(@instance.bulk_patient_ids_in_group.split(',').map(&:strip))

        patient_diff = expected_patients ^ @patient_ids_seen

        assert patient_diff.empty?, "Mismatch between patient ids seen (#{@patient_ids_seen.to_a.join(', ')}) and patient ids expected (#{@instance.bulk_patient_ids_in_group})"
      end

      test :validate_allergyintolerance do
        metadata do
          id '06'
          name 'AllergyIntolerance resources returned conform to the US Core AllergyIntolerance Profile'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-allergyintolerance'
          description %(
            This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
          )
        end

        profile_definitions = [
          {
            profile: nil,
            must_support_info: USCore310AllergyintoleranceSequenceDefinitions::MUST_SUPPORTS.dup,
            binding_info: USCore310AllergyintoleranceSequenceDefinitions::BINDINGS.dup
          }
        ]
        test_output_against_profile('AllergyIntolerance', profile_definitions)
      end

      test :validate_careplan do
        metadata do
          id '07'
          name 'CarePlan resources returned conform to the US Core CarePlan Profile'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-careplan'
          description %(
            This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
          )
        end

        profile_definitions = [
          {
            profile: nil,
            must_support_info: USCore310CareplanSequenceDefinitions::MUST_SUPPORTS.dup,
            binding_info: USCore310CareplanSequenceDefinitions::BINDINGS.dup
          }
        ]
        test_output_against_profile('CarePlan', profile_definitions)
      end

      test :validate_careteam do
        metadata do
          id '08'
          name 'CareTeam resources returned conform to the US Core CareTeam Profile'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-careteam'
          description %(
            This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
          )
        end

        profile_definitions = [
          {
            profile: nil,
            must_support_info: USCore310CareteamSequenceDefinitions::MUST_SUPPORTS.dup,
            binding_info: USCore310CareteamSequenceDefinitions::BINDINGS.dup
          }
        ]
        test_output_against_profile('CareTeam', profile_definitions)
      end

      test :validate_condition do
        metadata do
          id '09'
          name 'Condition resources returned conform to the US Core Condition Profile'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-condition'
          description %(
            This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
          )
        end

        profile_definitions = [
          {
            profile: nil,
            must_support_info: USCore310ConditionSequenceDefinitions::MUST_SUPPORTS.dup,
            binding_info: USCore310ConditionSequenceDefinitions::BINDINGS.dup
          }
        ]
        test_output_against_profile('Condition', profile_definitions)
      end

      test :validate_device do
        metadata do
          id '10'
          name 'Device resources returned conform to the US Core Implantable Device Profile'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-implantable-device'
          description %(
            This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
          )
        end

        must_supports = [
          {
            profile: nil,
            must_support_info: USCore310ImplantableDeviceSequenceDefinitions::MUST_SUPPORTS.dup,
            binding_info: USCore310ImplantableDeviceSequenceDefinitions::BINDINGS.dup
          }
        ]

        test_output_against_profile('Device', must_supports)
      end

      test :validate_diagnosticreport do
        metadata do
          id '11'
          name 'DiagnosticReport resources returned conform to the US Core DiagnosticReport Profiles'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-lab'
          description %(
            This test verifies that the resources returned from bulk data export conform to the following US Core profiles. This includes checking for missing data elements and value set verification.

            * http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-lab
            * http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-note
          )
        end

        profile_definitions = [
          {
            profile: US_CORE_R4_URIS[:diagnostic_report_lab],
            must_support_info: USCore310DiagnosticreportLabSequenceDefinitions::MUST_SUPPORTS.dup,
            binding_info: USCore310DiagnosticreportLabSequenceDefinitions::BINDINGS.dup
          },
          {
            profile: US_CORE_R4_URIS[:diagnostic_report_note],
            must_support_info: USCore310DiagnosticreportNoteSequenceDefinitions::MUST_SUPPORTS.dup,
            binding_info: USCore310DiagnosticreportNoteSequenceDefinitions::BINDINGS.dup
          }
        ]
        test_output_against_profile('DiagnosticReport', profile_definitions)
      end

      test :validate_documentreference do
        metadata do
          id '12'
          name 'DocumentReference resources returned conform to the US Core DocumentationReference Profile'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-documentreference'
          description %(
            This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
          )
        end

        profile_definitions = [
          {
            profile: nil,
            must_support_info: USCore310DocumentreferenceSequenceDefinitions::MUST_SUPPORTS.dup,
            binding_info: USCore310DocumentreferenceSequenceDefinitions::BINDINGS.dup
          }
        ]
        test_output_against_profile('DocumentReference', profile_definitions)
      end

      test :validate_goal do
        metadata do
          id '13'
          name 'Goal resources returned conform to the US Core Goal Profile'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-goal'
          description %(
            This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
          )
        end

        profile_definitions = [
          {
            profile: nil,
            must_support_info: USCore310GoalSequenceDefinitions::MUST_SUPPORTS.dup,
            binding_info: USCore310GoalSequenceDefinitions::BINDINGS.dup
          }
        ]
        test_output_against_profile('Goal', profile_definitions)
      end

      test :validate_immunization do
        metadata do
          id '14'
          name 'Immunization resources returned conform to the US Core Immunization Profile'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-immunization'
          description %(
            This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
          )
        end

        profile_definitions = [
          {
            profile: nil,
            must_support_info: USCore310ImmunizationSequenceDefinitions::MUST_SUPPORTS.dup,
            binding_info: USCore310ImmunizationSequenceDefinitions::BINDINGS.dup
          }
        ]
        test_output_against_profile('Immunization', profile_definitions)
      end

      test :validate_medicationrequest do
        metadata do
          id '15'
          name 'MedicationRequest resources returned conform to the US Core MeidcationRequest Profile'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-medicationrequest'
          description %(
            This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
          )
        end

        profile_definitions = [
          {
            profile: nil,
            must_support_info: USCore310MedicationrequestSequenceDefinitions::MUST_SUPPORTS.dup,
            binding_info: USCore310MedicationrequestSequenceDefinitions::BINDINGS.dup
          }
        ]
        test_output_against_profile('MedicationRequest', profile_definitions)
      end

      test :validate_observation do
        metadata do
          id '16'
          name 'Observation resources returned conform to the US Core Observation Profiles'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-observation-lab'
          description %(
            This test verifies that the resources returned from bulk data export conform to the following US Core profiles. This includes checking for missing data elements and value set verification.

            * http://hl7.org/fhir/us/core/StructureDefinition/pediatric-bmi-for-age
            * http://hl7.org/fhir/us/core/StructureDefinition/pediatric-weight-for-height
            * http://hl7.org/fhir/us/core/StructureDefinition/us-core-observation-lab
            * http://hl7.org/fhir/us/core/StructureDefinition/us-core-pulse-oximetry
            * http://hl7.org/fhir/us/core/StructureDefinition/us-core-smokingstatus
          )
        end

        profile_definitions = [
          {
            profile: US_CORE_R4_URIS[:pediatric_bmi_age],
            must_support_info: USCore310PediatricBmiForAgeSequenceDefinitions::MUST_SUPPORTS.dup,
            binding_info: USCore310PediatricBmiForAgeSequenceDefinitions::BINDINGS.dup
          },
          {
            profile: US_CORE_R4_URIS[:pediatric_weight_height],
            must_support_info: USCore310PediatricWeightForHeightSequenceDefinitions::MUST_SUPPORTS.dup,
            binding_info: USCore310PediatricWeightForHeightSequenceDefinitions::BINDINGS.dup
          },
          {
            profile: US_CORE_R4_URIS[:pulse_oximetry],
            must_support_info: USCore310PulseOximetrySequenceDefinitions::MUST_SUPPORTS.dup,
            binding_info: USCore310PulseOximetrySequenceDefinitions::BINDINGS.dup
          },
          {
            profile: US_CORE_R4_URIS[:lab_results],
            must_support_info: USCore310ObservationLabSequenceDefinitions::MUST_SUPPORTS.dup,
            binding_info: USCore310ObservationLabSequenceDefinitions::BINDINGS.dup
          },
          {
            profile: US_CORE_R4_URIS[:smoking_status],
            must_support_info: USCore310SmokingstatusSequenceDefinitions::MUST_SUPPORTS.dup,
            binding_info: USCore310SmokingstatusSequenceDefinitions::BINDINGS.dup
          }
        ]

        test_output_against_profile('Observation', profile_definitions)
      end

      test :validate_procedure do
        metadata do
          id '17'
          name 'Procedure resources returned conform to the US Core Procedure Profile'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-procedure'
          description %(
            This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
          )
        end

        profile_definitions = [
          {
            profile: nil,
            must_support_info: USCore310ProcedureSequenceDefinitions::MUST_SUPPORTS.dup,
            binding_info: USCore310ProcedureSequenceDefinitions::BINDINGS.dup
          }
        ]
        test_output_against_profile('Procedure', profile_definitions)
      end

      test :validate_encounter do
        metadata do
          id '18'
          name 'Encounter resources returned conform to the US Core Encounter Profile'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-encounter'
          description %(
            This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.

            The following US Core profiles have "Must Support" data element which reference Encounter resources:

            * [DiagnosticReport Note](http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-note)
            * [DocumentReference](http://hl7.org/fhir/us/core/StructureDefinition/us-core-documentreference)
            * [MedicationRequest](http://hl7.org/fhir/us/core/StructureDefinition/us-core-medicationrequest)
          )
        end

        profile_definitions = [
          {
            profile: nil,
            must_support_info: USCore310EncounterSequenceDefinitions::MUST_SUPPORTS.dup,
            binding_info: USCore310EncounterSequenceDefinitions::BINDINGS.dup
          }
        ]
        test_output_against_profile('Encounter', profile_definitions)
      end

      test :validate_organization do
        metadata do
          id '19'
          name 'Organization resources returned conform to the US Core Organization Profile'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-organization'
          description %(
            This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.

            The following US Core profiles have "Must Support" data element which reference Organization resources:

            * [CareTeam](http://hl7.org/fhir/us/core/StructureDefinition/us-core-careteam)
            * [DiagnosticReport Lab](http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-lab)
            * [DiagnosticReport Note](http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-note)
            * [DocumentReference](http://hl7.org/fhir/us/core/StructureDefinition/us-core-documentreference)
            * [MedicationRequest](http://hl7.org/fhir/us/core/StructureDefinition/us-core-medicationrequest)
            * [Provenance](http://hl7.org/fhir/us/core/StructureDefinition/us-core-provenance)
          )
        end

        profile_definitions = [
          {
            profile: nil,
            must_support_info: USCore310OrganizationSequenceDefinitions::MUST_SUPPORTS.dup,
            binding_info: USCore310OrganizationSequenceDefinitions::BINDINGS.dup
          }
        ]
        test_output_against_profile('Organization', profile_definitions)
      end

      test :validate_practitioner do
        metadata do
          id '20'
          name 'Practitioner resources returned conform to the US Core Practitioner Profile'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-practitioner'
          description %(
            This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.

            The following US Core profiles have "Must Support" data element which reference Practitioner resources:

            * [CareTeam](http://hl7.org/fhir/us/core/StructureDefinition/us-core-careteam)
            * [DiagnosticReport Lab](http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-lab)
            * [DiagnosticReport Note](http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-note)
            * [DocumentReference](http://hl7.org/fhir/us/core/StructureDefinition/us-core-documentreference)
            * [Encounter](http://hl7.org/fhir/us/core/StructureDefinition/us-core-encounter)
            * [MedicationRequest](http://hl7.org/fhir/us/core/StructureDefinition/us-core-medicationrequest)
            * [Provenance](http://hl7.org/fhir/us/core/StructureDefinition/us-core-provenance)
          )
        end

        profile_definitions = [
          {
            profile: nil,
            must_support_info: USCore310PractitionerSequenceDefinitions::MUST_SUPPORTS.dup,
            binding_info: USCore310PractitionerSequenceDefinitions::BINDINGS.dup
          }
        ]
        test_output_against_profile('Practitioner', profile_definitions)
      end

      test :validate_provenance do
        metadata do
          id '21'
          name 'Provenance resources returned conform to the US Core Provenance Profile'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-provenance'
          description %(
            This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
          )
        end

        profile_definitions = [
          {
            profile: nil,
            must_support_info: USCore310ProvenanceSequenceDefinitions::MUST_SUPPORTS.dup,
            binding_info: USCore310ProvenanceSequenceDefinitions::BINDINGS.dup
          }
        ]
        test_output_against_profile('Provenance', profile_definitions)
      end

      test :validate_location do
        metadata do
          id '22'
          name 'Location resources returned conform to the HL7 FHIR Specification Location Resource'
          link 'http://hl7.org/fhir/StructureDefinition/Location'
          description %(
            This test verifies that the resources returned from bulk data export conform to the HL7 FHIR Specification. This includes checking for missing data elements.

            The following US Core profiles have "Must Support" data elements which reference Location resources:

            * [Encounter](http://hl7.org/fhir/us/core/StructureDefinition/us-core-encounter)
          )
        end

        test_output_against_profile('Location')
      end

      test :validate_medication do
        metadata do
          id '23'
          name 'Medication resources returned conform to the US Core Medication Profile if FHIR server has Medication resources'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-medication'
          description %(
            This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
            This test is omitted if bulk data export does not return any Medication resources.

            The following US Core profiles have "Must Support" data elements which reference Medication resources:

            * [MedicationRequest](http://hl7.org/fhir/us/core/StructureDefinition/us-core-medicationrequest)
          )
        end

        test_output_against_profile('Medication')
      end
    end
  end
end
