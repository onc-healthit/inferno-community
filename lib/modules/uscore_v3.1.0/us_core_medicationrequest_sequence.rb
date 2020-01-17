# frozen_string_literal: true

module Inferno
  module Sequence
    class USCore310MedicationrequestSequence < SequenceBase
      title 'MedicationRequest Tests'

      description 'Verify that MedicationRequest resources on the FHIR server follow the US Core Implementation Guide'

      test_id_prefix 'USCMR'

      requires :token, :patient_id
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

      details %(
        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.
      )

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

        search_params = {
          'patient': @instance.patient_id,
          'intent': 'proposal'
        }

        reply = get_resource_by_params(versioned_resource_class('MedicationRequest'), search_params)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
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

        @medication_request_ary = []

        intent_val = ['proposal', 'plan', 'order', 'original-order', 'reflex-order', 'filler-order', 'instance-order', 'option']
        intent_val.each do |val|
          search_params = { 'patient': @instance.patient_id, 'intent': val }
          reply = get_resource_by_params(versioned_resource_class('MedicationRequest'), search_params)
          assert_response_ok(reply)
          assert_bundle_response(reply)

          next unless reply&.resource&.entry&.any? { |entry| entry&.resource&.resourceType == 'MedicationRequest' }

          @resources_found = true
          @medication_request = reply.resource.entry
            .find { |entry| entry&.resource&.resourceType == 'MedicationRequest' }
            .resource
          @medication_request_ary += fetch_all_bundled_resources(reply.resource)

          save_resource_ids_in_bundle(versioned_resource_class('MedicationRequest'), reply)
          save_delayed_sequence_references(@medication_request_ary)
          validate_search_reply(versioned_resource_class('MedicationRequest'), reply, search_params)
          test_medication_inclusion(@medication_request_ary, search_params)
          break
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

        search_params = {
          'patient': @instance.patient_id,
          'intent': get_value_for_search_param(resolve_element_from_path(@medication_request_ary, 'intent')),
          'status': get_value_for_search_param(resolve_element_from_path(@medication_request_ary, 'status'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('MedicationRequest'), search_params)
        validate_search_reply(versioned_resource_class('MedicationRequest'), reply, search_params)
        test_medication_inclusion(reply.resource.entry.map(&:resource), search_params)
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

        search_params = {
          'patient': @instance.patient_id,
          'intent': get_value_for_search_param(resolve_element_from_path(@medication_request_ary, 'intent')),
          'encounter': get_value_for_search_param(resolve_element_from_path(@medication_request_ary, 'encounter'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('MedicationRequest'), search_params)
        validate_search_reply(versioned_resource_class('MedicationRequest'), reply, search_params)
        test_medication_inclusion(reply.resource.entry.map(&:resource), search_params)
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

        search_params = {
          'patient': @instance.patient_id,
          'intent': get_value_for_search_param(resolve_element_from_path(@medication_request_ary, 'intent')),
          'authoredon': get_value_for_search_param(resolve_element_from_path(@medication_request_ary, 'authoredOn'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('MedicationRequest'), search_params)
        validate_search_reply(versioned_resource_class('MedicationRequest'), reply, search_params)
        test_medication_inclusion(reply.resource.entry.map(&:resource), search_params)
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

        search_params = {
          'patient': @instance.patient_id,
          'intent': get_value_for_search_param(resolve_element_from_path(@medication_request_ary, 'intent'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        search_params['_include'] = 'MedicationRequest:medication'
        reply = get_resource_by_params(versioned_resource_class('MedicationRequest'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)
        medication_results = reply&.resource&.entry&.map(&:resource)&.any? { |resource| resource.resourceType == 'Medication' }
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

        search_params = {
          'patient': @instance.patient_id,
          'intent': get_value_for_search_param(resolve_element_from_path(@medication_request_ary, 'intent'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        search_params['_revinclude'] = 'Provenance:target'
        reply = get_resource_by_params(versioned_resource_class('MedicationRequest'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)
        provenance_results = fetch_all_bundled_resources(reply.resource).select { |resource| resource.resourceType == 'Provenance' }
        skip 'No Provenance resources were returned from this search' unless provenance_results.present?
        provenance_results.each { |reference| @instance.save_resource_reference('Provenance', reference.id) }
      end

      test 'MedicationRequest resources returned conform to US Core R4 profiles' do
        metadata do
          id '11'
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

            MedicationRequest.reportedBoolean

            MedicationRequest.reportedReference

            MedicationRequest.medicationCodeableConcept

            MedicationRequest.medicationReference

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
          'MedicationRequest.status',
          'MedicationRequest.intent',
          'MedicationRequest.reportedBoolean',
          'MedicationRequest.reportedReference',
          'MedicationRequest.medicationCodeableConcept',
          'MedicationRequest.medicationReference',
          'MedicationRequest.subject',
          'MedicationRequest.encounter',
          'MedicationRequest.authoredOn',
          'MedicationRequest.requester',
          'MedicationRequest.dosageInstruction',
          'MedicationRequest.dosageInstruction.text'
        ]

        missing_must_support_elements = must_support_elements.reject do |path|
          truncated_path = path.gsub('MedicationRequest.', '')
          @medication_request_ary&.any? do |resource|
            resolve_element_from_path(resource, truncated_path).present?
          end
        end

        skip_if missing_must_support_elements.present?,
                "Could not find #{missing_must_support_elements.join(', ')} in the #{@medication_request_ary&.length} provided MedicationRequest resource(s)"

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

        search_params = {
          'patient': @instance.patient_id,
          'intent': get_value_for_search_param(resolve_element_from_path(@medication_request_ary, 'intent')),
          'status': get_value_for_search_param(resolve_element_from_path(@medication_request_ary, 'status'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        second_status_val = resolve_element_from_path(@medication_request_ary, 'status') { |el| get_value_for_search_param(el) != search_params[:status] }
        skip 'Cannot find second value for status to perform a multipleOr search' if second_status_val.nil?
        search_params[:status] += ',' + get_value_for_search_param(second_status_val)
        reply = get_resource_by_params(versioned_resource_class('MedicationRequest'), search_params)
        validate_search_reply(versioned_resource_class('MedicationRequest'), reply, search_params)
        assert_response_ok(reply)
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

        validate_reference_resolutions(@medication_request)
      end
    end
  end
end
