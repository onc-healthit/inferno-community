# frozen_string_literal: true

module Inferno
  module Sequence
    class ArgonautMedicationOrderSequence < SequenceBase
      title 'Medication Order'

      description 'Verify that MedicationOrder resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'ARMP'

      requires :token, :patient_id

      conformance_supports :MedicationOrder

      def validate_resource_item (resource, property, value)
        case property
        when "patient"
          assert (resource.patient && resource.patient.reference.include?(value)), "Patient on resource does not match patient requested"
        end
      end

      details %(
        # Background
         The #{title} Sequence tests the [#{title}](https://www.hl7.org/fhir/DSTU2/medicationorder.html)
        resource provided by a FHIR server.  The #{title} provided must be consistent with the [#{title}
        Argonaut Profile](https://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-medicationorder.html).

        # Test Methodology

        This test suite accesses the server endpoint at `/MedicationOrder?patient={id}` using a `GET` request.
        It parses the #{title} and verifies that it contains:

        * The date written
        * The status of the order
        * A reference to the patient to whom the medication will be given
        * A reference to the person authorizing the perscription
        * A reference or code representing the medication being given

        It collects the following information that is saved in the testing session for use by later tests:

        * List of Medications

        For more information on the #{title}, visit these links:

        * [FHIR DSTU2 #{title}](https://www.hl7.org/fhir/DSTU2/medicationorder.html)
        * [Argonauts #{title} Profile](https://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-medicationorder.html)
      )


      test 'Server rejects MedicationOrder search without authorization' do
        metadata {
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            An MedicationOrder search does not work without proper authorization.
          )
          versions :dstu2
        }

        @resources_found = false
        skip_if_not_supported(:MedicationOrder, [:search, :read])

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(versioned_resource_class('MedicationOrder'), {patient: @instance.patient_id})
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from MedicationOrder search by patient' do
        metadata {
          id '02'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server is capable of returning a patient's medications.
          )
          versions :dstu2
        }

        skip_if_not_supported(:MedicationOrder, [:search, :read])

        search_params = {patient: @instance.patient_id}
        reply = get_resource_by_params(versioned_resource_class('MedicationOrder'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        if resource_count > 0
          @resources_found = true
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @medication_orders = reply&.resource&.entry&.map do |med_order|
          med_order&.resource
        end
        validate_search_reply(versioned_resource_class('MedicationOrder'), reply, search_params)
        save_resource_ids_in_bundle(versioned_resource_class('MedicationOrder'), reply)
      end

      test 'MedicationOrder read resource supported' do
        metadata {
          id '03'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.
          )
          versions :dstu2
        }

        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found


        skip_if_not_supported(:MedicationOrder, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @medication_orders.each do |medication_order|
          validate_read_reply(medication_order, versioned_resource_class('MedicationOrder'))
        end
      end

      test 'MedicationOrder history resource supported' do
        metadata {
          id '04'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.
          )
          versions :dstu2
        }

        skip_if_not_supported(:MedicationOrder, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @medication_orders.each do |medication_order|
          validate_history_reply(medication_order, versioned_resource_class('MedicationOrder'))
        end
      end

      test 'MedicationOrder vread resource supported' do
        metadata {
          id '05'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.
          )
          versions :dstu2
        }

        skip_if_not_supported(:MedicationOrder, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @medication_orders.each do |medication_order|
          validate_vread_reply(medication_order, versioned_resource_class('MedicationOrder'))
        end
      end

      test 'MedicationOrder resources associated with Patient conform to Argonaut profiles' do
        metadata {
          id '06'
          link 'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-medicationorder.html'
          desc %(
            MedicationOrder resources associated with Patient conform to Argonaut profiles.
          )
          versions :dstu2
        }
        test_resources_against_profile('MedicationOrder')
      end

      test 'Referenced Medications support read interactions' do
        metadata do
          id '07'
          link 'https://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-medication.html'
          desc %(
            Medication resources must conform to the Argonaut profile
               )
        end

        @medication_references = @medication_orders&.select do |medication_order|
          !medication_order.medicationReference.nil?
        end&.map do |ref|
          ref.medicationReference
        end

        pass 'Test passes because medication resource references are not used in any medication orders.' if @medication_references.nil? || @medication_references.empty?

        not_contained_refs = @medication_references&.select {|ref| !ref.contained?}

        pass 'Test passes because all medication resource references are contained within the medication orders.' if not_contained_refs.empty?

        not_contained_refs&.each do |medication|
          validate_read_reply(medication, versioned_resource_class('Medication'))
        end
      end

      test 'All references can be resolved' do

        metadata {
          id '08'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
            All references in the MedicationOrder resource should be resolveable.
          )
          versions :dstu2
        }

        skip_if_not_supported(:MedicationOrder, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @medication_orders.each do |medication_order|
          validate_reference_resolutions(medication_order)
        end

      end

      test 'Referenced Medications conform to the Argonaut profile' do
        metadata do
          id '09'
          link 'https://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-medication.html'
          desc %(
            Medication resources must conform to the Argonaut profile
               )
        end

        pass 'Test passes because medication resource references are not used in any medication orders.' if @medication_references.nil? || @medication_references.empty?

        @medication_references&.each do |medication|
          medication_resource = medication.read
          check_resource_against_profile(medication_resource, 'Medication')
        end
      end
    end
  end
end
