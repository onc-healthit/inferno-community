# frozen_string_literal: true

require_relative './data_absent_reason_checker'
require_relative './profile_definitions/us_core_procedure_definitions'

module Inferno
  module Sequence
    class USCore311ProcedureSequence < SequenceBase
      include Inferno::DataAbsentReasonChecker
      include Inferno::USCore311ProfileDefinitions

      title 'Procedure Tests'

      description 'Verify support for the server capabilities required by the US Core Procedure Profile.'

      details %(
        # Background

        The US Core #{title} sequence verifies that the system under test is able to provide correct responses
        for Procedure queries.  These queries must contain resources conforming to US Core Procedure Profile as specified
        in the US Core v3.1.1 Implementation Guide.

        # Testing Methodology


        ## Searching
        This test sequence will first perform each required search associated with this resource. This sequence will perform searches
        with the following parameters:

          * patient
          * patient + date



        ### Search Parameters
        The first search uses the selected patient(s) from the prior launch sequence. Any subsequent searches will look for its
        parameter values from the results of the first search. For example, the `identifier` search in the patient sequence is
        performed by looking for an existing `Patient.identifier` from any of the resources returned in the `_id` search. If a
        value cannot be found this way, the search is skipped.

        ### Search Validation
        Inferno will retrieve up to the first 20 bundle pages of the reply for Procedure resources and save them
        for subsequent tests.
        Each of these resources is then checked to see if it matches the searched parameters in accordance
        with [FHIR search guidelines](https://www.hl7.org/fhir/search.html). The test will fail, for example, if a patient search
        for gender=male returns a female patient.

        ## Must Support
        Each profile has a list of elements marked as "must support". This test sequence expects to see each of these elements
        at least once. If at least one cannot be found, the test will fail. The test will look through the Procedure
        resources found for these elements.

        ## Profile Validation
        Each resource returned from the first search is expected to conform to the [US Core Procedure Profile](http://hl7.org/fhir/us/core/StructureDefinition/us-core-procedure).
        Each element is checked against teminology binding and cardinality requirements.

        Elements with a required binding is validated against its bound valueset. If the code/system in the element is not part
        of the valueset, then the test will fail.

        ## Reference Validation
        Each reference within the resources found from the first search must resolve. The test will attempt to read each reference found
        and will fail if any attempted read fails.
      )

      test_id_prefix 'USCPROC'

      requires :token, :patient_ids
      conformance_supports :Procedure

      def validate_resource_item(resource, property, value)
        case property

        when 'status'
          values_found = resolve_path(resource, 'status')
          values = value.split(/(?<!\\),/).each { |str| str.gsub!('\,', ',') }
          match_found = values_found.any? { |value_in_resource| values.include? value_in_resource }
          assert match_found, "status in Procedure/#{resource.id} (#{values_found}) does not match status requested (#{value})"

        when 'patient'
          values_found = resolve_path(resource, 'subject.reference')
          value = value.split('Patient/').last
          match_found = values_found.any? { |reference| [value, 'Patient/' + value, "#{@instance.url}/Patient/#{value}"].include? reference }
          assert match_found, "patient in Procedure/#{resource.id} (#{values_found}) does not match patient requested (#{value})"

        when 'date'
          values_found = resolve_path(resource, 'performed')
          match_found = values_found.any? { |date| validate_date_search(value, date) }
          assert match_found, "date in Procedure/#{resource.id} (#{values_found}) does not match date requested (#{value})"

        when 'code'
          values_found = resolve_path(resource, 'code')
          coding_system = value.split('|').first.empty? ? nil : value.split('|').first
          coding_value = value.split('|').last
          match_found = values_found.any? do |codeable_concept|
            if value.include? '|'
              codeable_concept.coding.any? { |coding| coding.system == coding_system && coding.code == coding_value }
            else
              codeable_concept.coding.any? { |coding| coding.code == value }
            end
          end
          assert match_found, "code in Procedure/#{resource.id} (#{values_found}) does not match code requested (#{value})"

        end
      end

      def perform_search_with_status(reply, search_param)
        begin
          parsed_reply = JSON.parse(reply.body)
          assert parsed_reply['resourceType'] == 'OperationOutcome', 'Server returned a status of 400 without an OperationOutcome.'
        rescue JSON::ParserError
          assert false, 'Server returned a status of 400 without an OperationOutcome.'
        end

        warning do
          assert @instance.server_capabilities&.search_documented?('Procedure'),
                 %(Server returned a status of 400 with an OperationOutcome, but the
                 search interaction for this resource is not documented in the
                 CapabilityStatement. If this response was due to the server
                 requiring a status parameter, the server must document this
                 requirement in its CapabilityStatement.)
        end

        ['preparation,in-progress,not-done,on-hold,stopped,completed,entered-in-error,unknown'].each do |status_value|
          params_with_status = search_param.merge('status': status_value)
          reply = get_resource_by_params(versioned_resource_class('Procedure'), params_with_status)
          assert_response_ok(reply)
          assert_bundle_response(reply)

          entries = reply.resource.entry.select { |entry| entry.resource.resourceType == 'Procedure' }
          next if entries.blank?

          search_param.merge!('status': status_value)
          break
        end

        reply
      end

      def patient_ids
        @instance.patient_ids.split(',').map(&:strip)
      end

      @resources_found = false

      test :search_by_patient do
        metadata do
          id '01'
          name 'Server returns valid results for Procedure search by patient.'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by patient on the Procedure resource.
            This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.
            Because this is the first search of the sequence, resources in the response will be used for subsequent tests.
          )
          versions :r4
        end

        skip_if_known_search_not_supported('Procedure', ['patient'])
        @procedure_ary = {}
        patient_ids.each do |patient|
          search_params = {
            'patient': patient
          }

          reply = get_resource_by_params(versioned_resource_class('Procedure'), search_params)

          reply = perform_search_with_status(reply, search_params) if reply.code == 400

          assert_response_ok(reply)
          assert_bundle_response(reply)

          any_resources = reply&.resource&.entry&.any? { |entry| entry&.resource&.resourceType == 'Procedure' }

          next unless any_resources

          @procedure_ary[patient] = fetch_all_bundled_resources(reply, check_for_data_absent_reasons)

          @procedure = @procedure_ary[patient]
            .find { |resource| resource.resourceType == 'Procedure' }
          @resources_found = @procedure.present?

          save_resource_references(versioned_resource_class('Procedure'), @procedure_ary[patient])
          save_delayed_sequence_references(@procedure_ary[patient], USCore311ProcedureSequenceDefinitions::DELAYED_REFERENCES)
          validate_reply_entries(@procedure_ary[patient], search_params)

          search_params = search_params.merge('patient': "Patient/#{patient}")
          reply = get_resource_by_params(versioned_resource_class('Procedure'), search_params)
          assert_response_ok(reply)
          assert_bundle_response(reply)
          search_with_type = fetch_all_bundled_resources(reply, check_for_data_absent_reasons)
          assert search_with_type.length == @procedure_ary[patient].length, 'Expected search by Patient/ID to have the same results as search by ID'
        end

        skip_if_not_found(resource_type: 'Procedure', delayed: false)
      end

      test :search_by_patient_date do
        metadata do
          id '02'
          name 'Server returns valid results for Procedure search by patient+date.'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by patient+date on the Procedure resource.
            This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.

              This will also test support for these date comparators: gt, ge, lt, le. Comparator values are created by taking
              a date value from a resource returned in the first search of this sequence and adding/subtracting a day. For example, a date
              of 05/05/2020 will create comparator values of lt2020-05-06 and gt2020-05-04

          )
          versions :r4
        end

        skip_if_known_search_not_supported('Procedure', ['patient', 'date'])
        skip_if_not_found(resource_type: 'Procedure', delayed: false)

        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'date': get_value_for_search_param(resolve_element_from_path(@procedure_ary[patient], 'performed') { |el| get_value_for_search_param(el).present? })
          }

          next if search_params.any? { |_param, value| value.nil? }

          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Procedure'), search_params)

          reply = perform_search_with_status(reply, search_params) if reply.code == 400

          validate_search_reply(versioned_resource_class('Procedure'), reply, search_params)

          ['gt', 'ge', 'lt', 'le'].each do |comparator|
            comparator_val = date_comparator_value(comparator, resolve_element_from_path(@procedure_ary[patient], 'performed') { |el| get_value_for_search_param(el).present? })
            comparator_search_params = search_params.merge('date': comparator_val)
            reply = get_resource_by_params(versioned_resource_class('Procedure'), comparator_search_params)
            validate_search_reply(versioned_resource_class('Procedure'), reply, comparator_search_params)
          end
        end

        skip 'Could not resolve all parameters (patient, date) in any resource.' unless resolved_one
      end

      test :search_by_patient_status do
        metadata do
          id '03'
          name 'Server returns valid results for Procedure search by patient+status.'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by patient+status on the Procedure resource.
            This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.

          )
          versions :r4
        end

        skip_if_known_search_not_supported('Procedure', ['patient', 'status'])
        skip_if_not_found(resource_type: 'Procedure', delayed: false)

        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'status': get_value_for_search_param(resolve_element_from_path(@procedure_ary[patient], 'status') { |el| get_value_for_search_param(el).present? })
          }

          next if search_params.any? { |_param, value| value.nil? }

          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Procedure'), search_params)

          validate_search_reply(versioned_resource_class('Procedure'), reply, search_params)
        end

        skip 'Could not resolve all parameters (patient, status) in any resource.' unless resolved_one
      end

      test :search_by_patient_code_date do
        metadata do
          id '04'
          name 'Server returns valid results for Procedure search by patient+code+date.'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by patient+code+date on the Procedure resource.
            This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.

              This will also test support for these date comparators: gt, ge, lt, le. Comparator values are created by taking
              a date value from a resource returned in the first search of this sequence and adding/subtracting a day. For example, a date
              of 05/05/2020 will create comparator values of lt2020-05-06 and gt2020-05-04

          )
          versions :r4
        end

        skip_if_known_search_not_supported('Procedure', ['patient', 'code', 'date'])
        skip_if_not_found(resource_type: 'Procedure', delayed: false)

        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'code': get_value_for_search_param(resolve_element_from_path(@procedure_ary[patient], 'code') { |el| get_value_for_search_param(el).present? }),
            'date': get_value_for_search_param(resolve_element_from_path(@procedure_ary[patient], 'performed') { |el| get_value_for_search_param(el).present? })
          }

          next if search_params.any? { |_param, value| value.nil? }

          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Procedure'), search_params)

          reply = perform_search_with_status(reply, search_params) if reply.code == 400

          validate_search_reply(versioned_resource_class('Procedure'), reply, search_params)

          ['gt', 'ge', 'lt', 'le'].each do |comparator|
            comparator_val = date_comparator_value(comparator, resolve_element_from_path(@procedure_ary[patient], 'performed') { |el| get_value_for_search_param(el).present? })
            comparator_search_params = search_params.merge('date': comparator_val)
            reply = get_resource_by_params(versioned_resource_class('Procedure'), comparator_search_params)
            validate_search_reply(versioned_resource_class('Procedure'), reply, comparator_search_params)
          end

          value_with_system = get_value_for_search_param(resolve_element_from_path(@procedure_ary[patient], 'code'), true)
          token_with_system_search_params = search_params.merge('code': value_with_system)
          reply = get_resource_by_params(versioned_resource_class('Procedure'), token_with_system_search_params)
          validate_search_reply(versioned_resource_class('Procedure'), reply, token_with_system_search_params)
        end

        skip 'Could not resolve all parameters (patient, code, date) in any resource.' unless resolved_one
      end

      test :read_interaction do
        metadata do
          id '05'
          name 'Server returns correct Procedure resource from Procedure read interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            A server SHALL support the Procedure read interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Procedure, [:read])
        skip_if_not_found(resource_type: 'Procedure', delayed: false)

        validate_read_reply(@procedure, versioned_resource_class('Procedure'), check_for_data_absent_reasons)
      end

      test :vread_interaction do
        metadata do
          id '06'
          name 'Server returns correct Procedure resource from Procedure vread interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Procedure vread interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Procedure, [:vread])
        skip_if_not_found(resource_type: 'Procedure', delayed: false)

        validate_vread_reply(@procedure, versioned_resource_class('Procedure'))
      end

      test :history_interaction do
        metadata do
          id '07'
          name 'Server returns correct Procedure resource from Procedure history interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Procedure history interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Procedure, [:history])
        skip_if_not_found(resource_type: 'Procedure', delayed: false)

        validate_history_reply(@procedure, versioned_resource_class('Procedure'))
      end

      test 'Server returns Provenance resources from Procedure search by patient + _revIncludes: Provenance:target' do
        metadata do
          id '08'
          link 'https://www.hl7.org/fhir/search.html#revinclude'
          description %(

            A Server SHALL be capable of supporting the following _revincludes: Provenance:target.

            This test will perform a search for patient + _revIncludes: Provenance:target and will pass
            if a Provenance resource is found in the reponse.

          )
          versions :r4
        end

        skip_if_known_revinclude_not_supported('Procedure', 'Provenance:target')
        skip_if_not_found(resource_type: 'Procedure', delayed: false)

        provenance_results = []
        patient_ids.each do |patient|
          search_params = {
            'patient': patient
          }

          search_params['_revinclude'] = 'Provenance:target'
          reply = get_resource_by_params(versioned_resource_class('Procedure'), search_params)

          reply = perform_search_with_status(reply, search_params) if reply.code == 400

          assert_response_ok(reply)
          assert_bundle_response(reply)
          provenance_results += fetch_all_bundled_resources(reply, check_for_data_absent_reasons)
            .select { |resource| resource.resourceType == 'Provenance' }
        end
        save_resource_references(versioned_resource_class('Provenance'), provenance_results)
        save_delayed_sequence_references(provenance_results, USCore311ProvenanceSequenceDefinitions::DELAYED_REFERENCES)

        skip 'No Provenance resources were returned from this search' unless provenance_results.present?
      end

      test 'All must support elements are provided in the Procedure resources returned.' do
        metadata do
          id '09'
          link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
          description %(

            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through the Procedure resources found previously for the following must support elements:

            * code
            * performed[x]
            * status
            * subject

          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'Procedure', delayed: false)
        must_supports = USCore311ProcedureSequenceDefinitions::MUST_SUPPORTS

        missing_must_support_elements = must_supports[:elements].reject do |element|
          @procedure_ary&.values&.flatten&.any? do |resource|
            value_found = resolve_element_from_path(resource, element[:path]) do |value|
              value_without_extensions = value.respond_to?(:to_hash) ? value.to_hash.reject { |key, _| key == 'extension' } : value
              value_without_extensions.present? && (element[:fixed_value].blank? || value == element[:fixed_value])
            end

            value_found.present?
          end
        end
        missing_must_support_elements.map! { |must_support| "#{must_support[:path]}#{': ' + must_support[:fixed_value] if must_support[:fixed_value].present?}" }

        skip_if missing_must_support_elements.present?,
                "Could not find #{missing_must_support_elements.join(', ')} in the #{@procedure_ary&.values&.flatten&.length} provided Procedure resource(s)"
        @instance.save!
      end

      test 'Every reference within Procedure resources can be read.' do
        metadata do
          id '10'
          link 'http://hl7.org/fhir/references.html'
          description %(

            This test will attempt to read the first 50 reference found in the resources from the first search.
            The test will fail if Inferno fails to read any of those references.

          )
          versions :r4
        end

        skip_if_known_not_supported(:Procedure, [:search, :read])
        skip_if_not_found(resource_type: 'Procedure', delayed: false)

        validated_resources = Set.new
        max_resolutions = 50

        @procedure_ary&.values&.flatten&.each do |resource|
          validate_reference_resolutions(resource, validated_resources, max_resolutions) if validated_resources.length < max_resolutions
        end
      end
    end
  end
end
