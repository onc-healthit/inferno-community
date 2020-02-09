# frozen_string_literal: true

module Inferno
  module Sequence
    class USCore310MedicationrequestSequence < SequenceBase
      title 'MedicationRequest Tests'

      description 'Verify that MedicationRequest resources on the FHIR server follow the US Core Implementation Guide'

      test_id_prefix 'USCMR'

      requires :token, :patient_ids
      conformance_supports :MedicationRequest

      def validate_resource_item(resource, property, value)
        case property

        when 'status'
          value_found = resolve_element_from_path(resource, 'status') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'status on resource does not match status requested'

        when 'intent'
          value_found = resolve_element_from_path(resource, 'intent') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'intent on resource does not match intent requested'

        when 'patient'
          value_found = resolve_element_from_path(resource, 'subject.reference') { |reference| [value, 'Patient/' + value].include? reference }
          assert value_found.present?, 'patient on resource does not match patient requested'

        when 'encounter'
          value_found = resolve_element_from_path(resource, 'encounter.reference') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'encounter on resource does not match encounter requested'

        when 'authoredon'
          value_found = resolve_element_from_path(resource, 'authoredOn') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'authoredon on resource does not match authoredon requested'

        end
      end

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

      def perform_search_with_status(reply, search_param)
        begin
          parsed_reply = JSON.parse(reply.body)
          assert parsed_reply['resourceType'] == 'OperationOutcome', 'Server returned a status of 400 without an OperationOutcome.'
        rescue JSON::ParserError
          assert false, 'Server returned a status of 400 without an OperationOutcome.'
        end

        warning do
          assert @instance.server_capabilities.search_documented?('MedicationRequest'),
                 %(Server returned a status of 400 with an OperationOutcome, but the
                 search interaction for this resource is not documented in the
                 CapabilityStatement. If this response was due to the server
                 requiring a status parameter, the server must document this
                 requirement in its CapabilityStatement.)
        end

        ['active,on-hold,cancelled,completed,entered-in-error,stopped,draft,unknown'].each do |status_value|
          params_with_status = search_param.merge('status': status_value)
          reply = get_resource_by_params(versioned_resource_class('MedicationRequest'), params_with_status)
          assert_response_ok(reply)
          assert_bundle_response(reply)

          entries = reply.resource.entry.select { |entry| entry.resource.resourceType == 'MedicationRequest' }
          next if entries.blank?

          search_param.merge!('status': status_value)
          break
        end

        reply
      end

      details %(
        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.
      )

      def patient_ids
        @instance.patient_ids.split(',').map(&:strip)
      end

      @resources_found = false

      test :unauthorized_search do
        metadata do
          id '01'
          name 'Server rejects MedicationRequest search without authorization'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html#behavior'
          description %(
            A server SHALL reject any unauthorized requests by returning an HTTP 401 unauthorized response code.
          )
          versions :r4
        end

        skip_if_known_not_supported(:MedicationRequest, [:search])

        @client.set_no_auth
        omit 'Do not test if no bearer token set' if @instance.token.blank?

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'intent': 'proposal'
          }

          reply = get_resource_by_params(versioned_resource_class('MedicationRequest'), search_params)
          assert_response_unauthorized reply
        end

        @client.set_bearer_token(@instance.token)
      end

      test :search_by_patient_intent do
        metadata do
          id '02'
          name 'Server returns expected results from MedicationRequest search by patient+intent'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by patient+intent on the MedicationRequest resource

            If any MedicationRequest resources use external references to
            Medications, the search will be repeated with
            _include=MedicationRequest:medication.

          )
          versions :r4
        end

        @medication_request_ary = {}
        @resources_found = false

        intent_val = ['proposal', 'plan', 'order', 'original-order', 'reflex-order', 'filler-order', 'instance-order', 'option']
        patient_ids.each do |patient|
          @medication_request_ary[patient] = []
          intent_val.each do |val|
            search_params = { 'patient': patient, 'intent': val }
            reply = get_resource_by_params(versioned_resource_class('MedicationRequest'), search_params)

            reply = perform_search_with_status(reply, search_params) if reply.code == 400

            assert_response_ok(reply)
            assert_bundle_response(reply)

            next unless reply&.resource&.entry&.any? { |entry| entry&.resource&.resourceType == 'MedicationRequest' }

            @resources_found = true
            @medication_request = reply.resource.entry
              .find { |entry| entry&.resource&.resourceType == 'MedicationRequest' }
              .resource
            @medication_request_ary[patient] += fetch_all_bundled_resources(reply.resource)

            save_resource_ids_in_bundle(versioned_resource_class('MedicationRequest'), reply)
            save_delayed_sequence_references(@medication_request_ary[patient])
            validate_search_reply(versioned_resource_class('MedicationRequest'), reply, search_params)
            test_medication_inclusion(@medication_request_ary[patient], search_params)
            break
          end
        end
        skip 'No MedicationRequest resources appear to be available. Please use patients with more information.' unless @resources_found
      end

      test :search_by_patient_intent_status do
        metadata do
          id '03'
          name 'Server returns expected results from MedicationRequest search by patient+intent+status'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by patient+intent+status on the MedicationRequest resource

            If any MedicationRequest resources use external references to
            Medications, the search will be repeated with
            _include=MedicationRequest:medication.

          )
          versions :r4
        end

        skip 'No MedicationRequest resources appear to be available. Please use patients with more information.' unless @resources_found

        could_not_resolve_all = []
        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'intent': get_value_for_search_param(resolve_element_from_path(@medication_request_ary[patient], 'intent')),
            'status': get_value_for_search_param(resolve_element_from_path(@medication_request_ary[patient], 'status'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('MedicationRequest'), search_params)

          validate_search_reply(versioned_resource_class('MedicationRequest'), reply, search_params)
          test_medication_inclusion(reply.resource.entry.map(&:resource), search_params)
        end

        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
      end

      test :search_by_patient_intent_encounter do
        metadata do
          id '04'
          name 'Server returns expected results from MedicationRequest search by patient+intent+encounter'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by patient+intent+encounter on the MedicationRequest resource

            If any MedicationRequest resources use external references to
            Medications, the search will be repeated with
            _include=MedicationRequest:medication.

          )
          versions :r4
        end

        skip 'No MedicationRequest resources appear to be available. Please use patients with more information.' unless @resources_found

        could_not_resolve_all = []
        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'intent': get_value_for_search_param(resolve_element_from_path(@medication_request_ary[patient], 'intent')),
            'encounter': get_value_for_search_param(resolve_element_from_path(@medication_request_ary[patient], 'encounter'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('MedicationRequest'), search_params)

          reply = perform_search_with_status(reply, search_params) if reply.code == 400

          validate_search_reply(versioned_resource_class('MedicationRequest'), reply, search_params)
          test_medication_inclusion(reply.resource.entry.map(&:resource), search_params)
        end

        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
      end

      test :search_by_patient_intent_authoredon do
        metadata do
          id '05'
          name 'Server returns expected results from MedicationRequest search by patient+intent+authoredon'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by patient+intent+authoredon on the MedicationRequest resource

              including support for these authoredon comparators: gt, lt, le, ge
            If any MedicationRequest resources use external references to
            Medications, the search will be repeated with
            _include=MedicationRequest:medication.

          )
          versions :r4
        end

        skip 'No MedicationRequest resources appear to be available. Please use patients with more information.' unless @resources_found

        could_not_resolve_all = []
        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'intent': get_value_for_search_param(resolve_element_from_path(@medication_request_ary[patient], 'intent')),
            'authoredon': get_value_for_search_param(resolve_element_from_path(@medication_request_ary[patient], 'authoredOn'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('MedicationRequest'), search_params)

          reply = perform_search_with_status(reply, search_params) if reply.code == 400

          validate_search_reply(versioned_resource_class('MedicationRequest'), reply, search_params)
          test_medication_inclusion(reply.resource.entry.map(&:resource), search_params)
        end

        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
      end

      test :read_interaction do
        metadata do
          id '06'
          name 'Server returns correct MedicationRequest resource from MedicationRequest read interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            A server SHALL support the MedicationRequest read interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:MedicationRequest, [:read])
        skip 'No MedicationRequest resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@medication_request, versioned_resource_class('MedicationRequest'))
      end

      test :vread_interaction do
        metadata do
          id '07'
          name 'Server returns correct MedicationRequest resource from MedicationRequest vread interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the MedicationRequest vread interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:MedicationRequest, [:vread])
        skip 'No MedicationRequest resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@medication_request, versioned_resource_class('MedicationRequest'))
      end

      test :history_interaction do
        metadata do
          id '08'
          name 'Server returns correct MedicationRequest resource from MedicationRequest history interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the MedicationRequest history interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:MedicationRequest, [:history])
        skip 'No MedicationRequest resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@medication_request, versioned_resource_class('MedicationRequest'))
      end

      test 'Server returns the appropriate resource from the following _includes: MedicationRequest:medication' do
        metadata do
          id '09'
          link 'https://www.hl7.org/fhir/search.html#include'
          optional
          description %(
            A Server SHOULD be capable of supporting the following _includes: MedicationRequest:medication
          )
          versions :r4
        end

        could_not_resolve_all = []
        resolved_one = false
        medication_results = false
        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'intent': get_value_for_search_param(resolve_element_from_path(@medication_request_ary[patient], 'intent'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          search_params['_include'] = 'MedicationRequest:medication'
          reply = get_resource_by_params(versioned_resource_class('MedicationRequest'), search_params)
          assert_response_ok(reply)
          assert_bundle_response(reply)
          medication_results ||= reply&.resource&.entry&.map(&:resource)&.any? { |resource| resource.resourceType == 'Medication' }
        end
        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
        assert medication_results, 'No Medication resources were returned from this search'
      end

      test 'Server returns Provenance resources from MedicationRequest search by patient + intent + _revIncludes: Provenance:target' do
        metadata do
          id '10'
          link 'https://www.hl7.org/fhir/search.html#revinclude'
          description %(
            A Server SHALL be capable of supporting the following _revincludes: Provenance:target
          )
          versions :r4
        end

        could_not_resolve_all = []
        resolved_one = false

        provenance_results = []
        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'intent': get_value_for_search_param(resolve_element_from_path(@medication_request_ary[patient], 'intent'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          search_params['_revinclude'] = 'Provenance:target'
          reply = get_resource_by_params(versioned_resource_class('MedicationRequest'), search_params)

          reply = perform_search_with_status(reply, search_params) if reply.code == 400

          assert_response_ok(reply)
          assert_bundle_response(reply)
          provenance_results += fetch_all_bundled_resources(reply.resource).select { |resource| resource.resourceType == 'Provenance' }
          provenance_results.each { |reference| @instance.save_resource_reference('Provenance', reference.id) }
        end
        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
        skip 'No Provenance resources were returned from this search' unless provenance_results.present?
      end

      test :validate_resources do
        metadata do
          id '11'
          name 'MedicationRequest resources returned conform to US Core R4 profiles'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-medicationrequest'
          description %(

            This test checks if the resources returned from prior searches conform to the US Core profiles.
            This includes checking for missing data elements and valueset verification.

          )
          versions :r4
        end

        skip 'No MedicationRequest resources appear to be available. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('MedicationRequest')
      end

      test 'All must support elements are provided in the MedicationRequest resources returned.' do
        metadata do
          id '12'
          link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
          description %(

            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through all MedicationRequest resources returned from prior searches to see if any of them provide the following must support elements:

            MedicationRequest.status

            MedicationRequest.intent

            MedicationRequest.reported[x]

            MedicationRequest.medication[x]

            MedicationRequest.subject

            MedicationRequest.encounter

            MedicationRequest.authoredOn

            MedicationRequest.requester

            MedicationRequest.dosageInstruction

            MedicationRequest.dosageInstruction.text

          )
          versions :r4
        end

        skip 'No MedicationRequest resources appear to be available. Please use patients with more information.' unless @resources_found

        must_support_elements = [
          { path: 'MedicationRequest.status' },
          { path: 'MedicationRequest.intent' },
          { path: 'MedicationRequest.reported' },
          { path: 'MedicationRequest.medication' },
          { path: 'MedicationRequest.subject' },
          { path: 'MedicationRequest.encounter' },
          { path: 'MedicationRequest.authoredOn' },
          { path: 'MedicationRequest.requester' },
          { path: 'MedicationRequest.dosageInstruction' },
          { path: 'MedicationRequest.dosageInstruction.text' }
        ]

        missing_must_support_elements = must_support_elements.reject do |element|
          truncated_path = element[:path].gsub('MedicationRequest.', '')
          @medication_request_ary&.values&.flatten&.any? do |resource|
            value_found = resolve_element_from_path(resource, truncated_path) { |value| element[:fixed_value].blank? || value == element[:fixed_value] }
            value_found.present?
          end
        end
        missing_must_support_elements.map! { |must_support| "#{must_support[:path]}#{': ' + must_support[:fixed_value] if must_support[:fixed_value].present?}" }

        skip_if missing_must_support_elements.present?,
                "Could not find #{missing_must_support_elements.join(', ')} in the #{@medication_request_ary&.values&.flatten&.length} provided MedicationRequest resource(s)"
        @instance.save!
      end

      test 'The server returns expected results when parameters use composite-or' do
        metadata do
          id '13'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-medicationrequest'
          description %(

          )
          versions :r4
        end

        could_not_resolve_all = []
        resolved_one = false

        found_second_val = false
        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'intent': get_value_for_search_param(resolve_element_from_path(@medication_request_ary[patient], 'intent')),
            'status': get_value_for_search_param(resolve_element_from_path(@medication_request_ary[patient], 'status'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          second_status_val = resolve_element_from_path(@medication_request_ary[patient], 'status') { |el| get_value_for_search_param(el) != search_params[:status] }
          next if second_status_val.nil?

          found_second_val = true
          search_params[:status] += ',' + get_value_for_search_param(second_status_val)
          reply = get_resource_by_params(versioned_resource_class('MedicationRequest'), search_params)
          validate_search_reply(versioned_resource_class('MedicationRequest'), reply, search_params)
          assert_response_ok(reply)
          resources_returned = fetch_all_bundled_resources(reply.resource)
          missing_values = search_params[:status].split(',').reject do |val|
            resolve_element_from_path(resources_returned, 'status') { |val_found| val_found == val }
          end
          assert missing_values.blank?, "Could not find #{missing_values.join(',')} values from status in any of the resources returned"
        end
        skip 'Cannot find second value for status to perform a multipleOr search' unless found_second_val
      end

      test 'Every reference within MedicationRequest resource is valid and can be read.' do
        metadata do
          id '14'
          link 'http://hl7.org/fhir/references.html'
          description %(
            This test checks if references found in resources from prior searches can be resolved.
          )
          versions :r4
        end

        skip_if_known_not_supported(:MedicationRequest, [:search, :read])
        skip 'No MedicationRequest resources appear to be available. Please use patients with more information.' unless @resources_found

        validated_resources = Set.new
        max_resolutions = 50

        @medication_request_ary&.values&.flatten&.each do |resource|
          validate_reference_resolutions(resource, validated_resources, max_resolutions) if validated_resources.length < max_resolutions
        end
      end
    end
  end
end
