# frozen_string_literal: true

module Inferno
  module Sequence
    class UsCoreR4MedicationrequestSequence < SequenceBase
      group 'US Core R4 Profile Conformance'

      title 'Medicationrequest Tests'

      description 'Verify that MedicationRequest resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'MedicationRequest' # change me

      requires :token, :patient_id
      conformance_supports :MedicationRequest

      def validate_resource_item(resource, property, value)
        case property

        when 'status'
          assert resource&.status == value, 'status on resource did not match status requested'

        when 'patient'
          assert resource&.subject&.reference&.include?(value), 'patient on resource does not match patient requested'

        when 'authoredon'

        end
      end

      details %(

        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [Medicationrequest Argonaut Profile](https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-medicationrequest)

      )

      @resources_found = false

      test 'Server rejects MedicationRequest search without authorization' do
        metadata do
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
          )
          versions :r4
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(versioned_resource_class('MedicationRequest'), patient: @instance.patient_id)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from MedicationRequest search by patient' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        patient_val = @instance.patient_id
        search_params = { 'patient': patient_val }

        reply = get_resource_by_params(versioned_resource_class('MedicationRequest'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        @resources_found = true if resource_count.positive?

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @medicationrequest = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(versioned_resource_class('MedicationRequest'), reply, search_params)
        save_resource_ids_in_bundle(versioned_resource_class('MedicationRequest'), reply)
      end

      test 'Server returns expected results from MedicationRequest search by patient+status' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@medicationrequest.nil?, 'Expected valid MedicationRequest resource to be present'

        patient_val = @instance.patient_id
        status_val = @medicationrequest&.status
        search_params = { 'patient': patient_val, 'status': status_val }

        reply = get_resource_by_params(versioned_resource_class('MedicationRequest'), search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from MedicationRequest search by patient+authoredon' do
        metadata do
          id '04'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@medicationrequest.nil?, 'Expected valid MedicationRequest resource to be present'

        patient_val = @instance.patient_id
        authoredon_val = @medicationrequest&.authoredOn
        search_params = { 'patient': patient_val, 'authoredon': authoredon_val }

        reply = get_resource_by_params(versioned_resource_class('MedicationRequest'), search_params)
        assert_response_ok(reply)
      end

      test 'MedicationRequest read resource supported' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:MedicationRequest, [:read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@medicationrequest, versioned_resource_class('MedicationRequest'))
      end

      test 'MedicationRequest vread resource supported' do
        metadata do
          id '06'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:MedicationRequest, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@medicationrequest, versioned_resource_class('MedicationRequest'))
      end

      test 'MedicationRequest history resource supported' do
        metadata do
          id '07'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:MedicationRequest, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@medicationrequest, versioned_resource_class('MedicationRequest'))
      end

      test 'Demonstrates that the server can supply must supported elements' do
        metadata do
          id '08'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/general-guidance.html/#must-support'
          desc %(
          )
          versions :r4
        end

        element_found = @instance.must_support_confirmed.include?('MedicationRequest.status') || can_resolve_path(@medicationrequest, 'status')
        skip 'Could not find MedicationRequest.status in the provided resource' unless element_found
        @instance.must_support_confirmed += 'MedicationRequest.status,'
        element_found = @instance.must_support_confirmed.include?('MedicationRequest.medicationCodeableConcept') || can_resolve_path(@medicationrequest, 'medicationCodeableConcept')
        skip 'Could not find MedicationRequest.medicationCodeableConcept in the provided resource' unless element_found
        @instance.must_support_confirmed += 'MedicationRequest.medicationCodeableConcept,'
        element_found = @instance.must_support_confirmed.include?('MedicationRequest.medicationReference') || can_resolve_path(@medicationrequest, 'medicationReference')
        skip 'Could not find MedicationRequest.medicationReference in the provided resource' unless element_found
        @instance.must_support_confirmed += 'MedicationRequest.medicationReference,'
        element_found = @instance.must_support_confirmed.include?('MedicationRequest.subject') || can_resolve_path(@medicationrequest, 'subject')
        skip 'Could not find MedicationRequest.subject in the provided resource' unless element_found
        @instance.must_support_confirmed += 'MedicationRequest.subject,'
        element_found = @instance.must_support_confirmed.include?('MedicationRequest.authoredOn') || can_resolve_path(@medicationrequest, 'authoredOn')
        skip 'Could not find MedicationRequest.authoredOn in the provided resource' unless element_found
        @instance.must_support_confirmed += 'MedicationRequest.authoredOn,'
        element_found = @instance.must_support_confirmed.include?('MedicationRequest.requester') || can_resolve_path(@medicationrequest, 'requester')
        skip 'Could not find MedicationRequest.requester in the provided resource' unless element_found
        @instance.must_support_confirmed += 'MedicationRequest.requester,'
        element_found = @instance.must_support_confirmed.include?('MedicationRequest.dosageInstruction') || can_resolve_path(@medicationrequest, 'dosageInstruction')
        skip 'Could not find MedicationRequest.dosageInstruction in the provided resource' unless element_found
        @instance.must_support_confirmed += 'MedicationRequest.dosageInstruction,'
        element_found = @instance.must_support_confirmed.include?('MedicationRequest.dosageInstruction.text') || can_resolve_path(@medicationrequest, 'dosageInstruction.text')
        skip 'Could not find MedicationRequest.dosageInstruction.text in the provided resource' unless element_found
        @instance.must_support_confirmed += 'MedicationRequest.dosageInstruction.text,'
        @instance.save!
      end

      test 'MedicationRequest resources associated with Patient conform to Argonaut profiles' do
        metadata do
          id '09'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-medicationrequest.json'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('MedicationRequest')
      end

      test 'All references can be resolved' do
        metadata do
          id '10'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:MedicationRequest, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@medicationrequest)
      end
    end
  end
end
