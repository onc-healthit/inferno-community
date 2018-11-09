# frozen_string_literal: true

module Inferno
  module Sequence
    class ArgonautMedicationStatementSequence < SequenceBase
      title 'Medication Statement'

      description 'Verify that MedicationStatement resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'ARMS'

      requires :token, :patient_id
      conformance_supports :MedicationStatement

      details %(
        # Background
        The #{title} Sequence tests the [#{title}](https://www.hl7.org/fhir/DSTU2/medicationstatement.html)
        resource provided by a FHIR server.  The #{title} provided must be consistent with the [#{title}
        Argonaut Profile](https://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-medicationstatement.html).

        )

      test 'Server rejects MedicationStatement search without authorization' do
        metadata do
          id '01'
          link 'https://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-medicationstatement.html'
          desc %(
            A MedicationStatement search does not work without proper authorization.
          )
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(FHIR::DSTU2::MedicationStatement, patient: @instance.patient_id)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from MedicationStatement search by patient' do
        metadata do
          id '02'
          link 'https://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-medicationstatement.html'
          desc %(
            A server is capable of returning a patient's medications.
          )
        end

        reply = get_resource_by_params(FHIR::DSTU2::MedicationStatement, patient: @instance.patient_id)
        assert_bundle_response(reply)

        @no_resources_found = false
        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        @no_resources_found = true if resource_count === 0

        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        @medication_statements = reply&.resource&.entry&.map do |med_order|
          med_order&.resource
        end
        validate_search_reply(FHIR::DSTU2::MedicationStatement, reply)
        save_resource_ids_in_bundle(FHIR::DSTU2::MedicationStatement, reply)
      end

      test 'MedicationStatement read resource supported' do
        metadata do
          id '03'
          link 'https://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-medicationstatement.html'
          desc %(
            All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.
          )
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        @medication_statements.each do |medication_statement|
          validate_read_reply(medication_statment, FHIR::DSTU2::MedicationStatement)
        end
      end

      test 'MedicationStatement history resource supported' do
        metadata do
          id '04'
          link 'https://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-medicationstatement.html'
          optional
          desc %(
            All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.
          )
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        @medication_statements.each do |medication_statement|
          validate_history_reply(medication_statment, FHIR::DSTU2::MedicationStatement)
        end
      end

      test 'MedicationStatement vread resource supported' do
        metadata do
          id '05'
          link 'https://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-medicationstatement.html'
          optional
          desc %(
            All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.
          )
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        @medication_statements.each do |medication_statement|
          validate_vread_reply(medication_statment, FHIR::DSTU2::MedicationStatement)
        end
      end

      test 'MedicationStatement resources associated with Patient conform to Argonaut profiles' do
        metadata do
          id '06'
          link 'https://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-medicationstatement.html'
          desc %(
            MedicationStatement resources associated with Patient conform to Argonaut profiles.
          )
        end
        test_resources_against_profile('MedicationStatement')
      end
    end
  end
end
