# frozen_string_literal: true

module Inferno
  module Sequence
    class ArgonautMedicationOrderSequence < SequenceBase
      title 'Medication Order'

      description 'Verify that MedicationOrder resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'ARMP'

      requires :token, :patient_id

      conformance_supports :MedicationOrder

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
        metadata do
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            An MedicationOrder search does not work without proper authorization.
          )
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(FHIR::DSTU2::MedicationOrder, patient: @instance.patient_id)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from MedicationOrder search by patient' do
        metadata do
          id '02'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server is capable of returning a patient's medications.
          )
        end

        reply = get_resource_by_params(FHIR::DSTU2::MedicationOrder, patient: @instance.patient_id)
        assert_bundle_response(reply)

        @no_resources_found = false
        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        @no_resources_found = true if resource_count === 0

        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        @medication_orders = reply&.resource&.entry&.map do |med_order|
          med_order&.resource
        end
        validate_search_reply(FHIR::DSTU2::MedicationOrder, reply)
        save_resource_ids_in_bundle(FHIR::DSTU2::MedicationOrder, reply)
      end

      test 'MedicationOrder read resource supported' do
        metadata do
          id '03'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.
          )
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        @medication_orders.each do |medication_order|
          validate_read_reply(medication_order, FHIR::DSTU2::MedicationOrder)
        end
      end

      test 'MedicationOrder history resource supported' do
        metadata do
          id '04'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.
          )
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        @medication_orders.each do |medication_order|
          validate_history_reply(medication_order, FHIR::DSTU2::MedicationOrder)
        end
      end

      test 'MedicationOrder vread resource supported' do
        metadata do
          id '05'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.
          )
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        @medication_orders.each do |medication_order|
          validate_vread_reply(medication_order, FHIR::DSTU2::MedicationOrder)
        end
      end

      test 'MedicationOrder resources associated with Patient conform to Argonaut profiles' do
        metadata do
          id '06'
          link 'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-medicationorder.html'
          desc %(
            MedicationOrder resources associated with Patient conform to Argonaut profiles.
          )
        end
        test_resources_against_profile('MedicationOrder')
      end

      test 'Referenced Medications conform to the Argonaut profile' do
        metadata do
          id '07'
          link 'https://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-medication.html'
          desc %(
            Medication resources must conform to the Argonaut profile
               )
        end

        medication_references = @medication_orders&.select do |medication_order|
          medication_order&.medicationReference unless medication_order.medicationReference.nil?
        end

        skip 'No medicationReferences available to test' if medication_references.empty?

        medication_references&.each do |medication|
          validate_read_reply(medication, FHIR::DSTU2::Medication)
        end
      end
    end
  end
end
