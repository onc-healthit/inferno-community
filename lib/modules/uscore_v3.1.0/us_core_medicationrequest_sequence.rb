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
          value_found = can_resolve_path(resource, 'status') { |value_in_resource| value_in_resource == value }
          assert value_found, 'status on resource does not match status requested'

        when 'intent'
          value_found = can_resolve_path(resource, 'intent') { |value_in_resource| value_in_resource == value }
          assert value_found, 'intent on resource does not match intent requested'

        when 'patient'
          value_found = can_resolve_path(resource, 'subject.reference') { |reference| [value, 'Patient/' + value].include? reference }
          assert value_found, 'patient on resource does not match patient requested'

        when 'encounter'
          value_found = can_resolve_path(resource, 'encounter.reference') { |value_in_resource| value_in_resource == value }
          assert value_found, 'encounter on resource does not match encounter requested'

        when 'authoredon'
          value_found = can_resolve_path(resource, 'authoredOn') { |value_in_resource| value_in_resource == value }
          assert value_found, 'authoredon on resource does not match authoredon requested'

        end
      end

      details %(
        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.
      )

      @resources_found = false

      test :unauthorized_search do
        metadata do
          id '01'
          name 'Server rejects MedicationRequest search without authorization'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html#behavior'
          description %(
          )
          versions :r4
        end

        skip_if_not_supported(:MedicationRequest, [:search])

        @client.set_no_auth
        omit 'Do not test if no bearer token set' if @instance.token.blank?
        search_params = { 'patient': @instance.patient_id, 'intent': proposal }
        reply = get_resource_by_params(versioned_resource_class('MedicationRequest'), search_params)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from MedicationRequest search by patient+intent' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
          )
          versions :r4
        end

        intent_val = ['proposal', 'plan', 'order', 'original-order', 'reflex-order', 'filler-order', 'instance-order', 'option']
        intent_val.each do |val|
          search_params = { 'patient': @instance.patient_id, 'intent': val }
          reply = get_resource_by_params(versioned_resource_class('MedicationRequest'), search_params)
          assert_response_ok(reply)
          assert_bundle_response(reply)

          resource_count = reply&.resource&.entry&.length || 0
          @resources_found = true if resource_count.positive?
          next unless @resources_found

          @medication_request = reply&.resource&.entry&.first&.resource
          @medication_request_ary = fetch_all_bundled_resources(reply&.resource)

          save_resource_ids_in_bundle(versioned_resource_class('MedicationRequest'), reply)
          save_delayed_sequence_references(@medication_request_ary)
          validate_search_reply(versioned_resource_class('MedicationRequest'), reply, search_params)
          break
        end
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
      end

      test 'Server returns expected results from MedicationRequest search by patient+intent+status' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@medication_request.nil?, 'Expected valid MedicationRequest resource to be present'

        search_params = {
          'patient': @instance.patient_id,
          'intent': get_value_for_search_param(resolve_element_from_path(@medication_request_ary, 'intent')),
          'status': get_value_for_search_param(resolve_element_from_path(@medication_request_ary, 'status'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('MedicationRequest'), search_params)
        validate_search_reply(versioned_resource_class('MedicationRequest'), reply, search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from MedicationRequest search by patient+intent+encounter' do
        metadata do
          id '04'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          optional
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@medication_request.nil?, 'Expected valid MedicationRequest resource to be present'

        search_params = {
          'patient': @instance.patient_id,
          'intent': get_value_for_search_param(resolve_element_from_path(@medication_request_ary, 'intent')),
          'encounter': get_value_for_search_param(resolve_element_from_path(@medication_request_ary, 'encounter'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('MedicationRequest'), search_params)
        validate_search_reply(versioned_resource_class('MedicationRequest'), reply, search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from MedicationRequest search by patient+intent+authoredon' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          optional
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@medication_request.nil?, 'Expected valid MedicationRequest resource to be present'

        search_params = {
          'patient': @instance.patient_id,
          'intent': get_value_for_search_param(resolve_element_from_path(@medication_request_ary, 'intent')),
          'authoredon': get_value_for_search_param(resolve_element_from_path(@medication_request_ary, 'authoredOn'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('MedicationRequest'), search_params)
        validate_search_reply(versioned_resource_class('MedicationRequest'), reply, search_params)
        assert_response_ok(reply)
      end

      test :read_interaction do
        metadata do
          id '06'
          name 'MedicationRequest read interaction supported'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
          )
          versions :r4
        end

        skip_if_not_supported(:MedicationRequest, [:read])
        skip 'No MedicationRequest resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@medication_request, versioned_resource_class('MedicationRequest'))
      end

      test :vread_interaction do
        metadata do
          id '07'
          name 'MedicationRequest vread interaction supported'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
          )
          versions :r4
        end

        skip_if_not_supported(:MedicationRequest, [:vread])
        skip 'No MedicationRequest resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@medication_request, versioned_resource_class('MedicationRequest'))
      end

      test :history_interaction do
        metadata do
          id '08'
          name 'MedicationRequest history interaction supported'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
          )
          versions :r4
        end

        skip_if_not_supported(:MedicationRequest, [:history])
        skip 'No MedicationRequest resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@medication_request, versioned_resource_class('MedicationRequest'))
      end

      test 'Server returns the appropriate resource from the following _includes: MedicationRequest:medication' do
        metadata do
          id '09'
          link 'https://www.hl7.org/fhir/search.html#include'
          description %(
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

      test 'Server returns the appropriate resources from the following _revincludes: Provenance:target' do
        metadata do
          id '10'
          link 'https://www.hl7.org/fhir/search.html#revinclude'
          description %(
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
        provenance_results = reply&.resource&.entry&.map(&:resource)&.any? { |resource| resource.resourceType == 'Provenance' }
        assert provenance_results, 'No Provenance resources were returned from this search'
      end

      test 'MedicationRequest resources associated with Patient conform to US Core R4 profiles' do
        metadata do
          id '11'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-medicationrequest'
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('MedicationRequest')
      end

      test 'At least one of every must support element is provided in any MedicationRequest for this patient.' do
        metadata do
          id '12'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/general-guidance.html/#must-support'
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information' unless @medication_request_ary&.any?
        must_support_confirmed = {}
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
        must_support_elements.each do |path|
          @medication_request_ary&.each do |resource|
            truncated_path = path.gsub('MedicationRequest.', '')
            must_support_confirmed[path] = true if can_resolve_path(resource, truncated_path)
            break if must_support_confirmed[path]
          end
          resource_count = @medication_request_ary.length

          skip "Could not find #{path} in any of the #{resource_count} provided MedicationRequest resource(s)" unless must_support_confirmed[path]
        end
        @instance.save!
      end

      test 'All references can be resolved' do
        metadata do
          id '13'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          description %(
          )
          versions :r4
        end

        skip_if_not_supported(:MedicationRequest, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@medication_request)
      end
    end
  end
end
