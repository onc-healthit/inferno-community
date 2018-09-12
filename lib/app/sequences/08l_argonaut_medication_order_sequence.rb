module Inferno
  module Sequence
    class ArgonautMedicationOrderSequence < SequenceBase

      group 'Argonaut Profile Conformance'

      title 'Medication Order'

      description 'Verify that MedicationOrder resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'ARMP'

      requires :token, :patient_id

      preconditions 'Client must be authorized' do
        !@instance.token.nil?
      end

      # --------------------------------------------------
      # MedicationOrder Search
      # --------------------------------------------------

      test '01', '', 'Server rejects MedicationOrder search without authorization',
           'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
           'An MedicationOrder search does not work without proper authorization.' do

        skip_if_not_supported(:MedicationOrder, [:search, :read])

        @client.set_no_auth
        reply = get_resource_by_params(FHIR::DSTU2::MedicationOrder, {patient: @instance.patient_id})
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply

      end

      test '02', '', 'Server returns expected results from MedicationOrder search by patient',
           'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
           "A server is capable of returning a patient's medications." do

        skip_if_not_supported(:MedicationOrder, [:search, :read])

        reply = get_resource_by_params(FHIR::DSTU2::MedicationOrder, {patient: @instance.patient_id})
        @medicationorder = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(FHIR::DSTU2::MedicationOrder, reply)
        save_resource_ids_in_bundle(FHIR::DSTU2::MedicationOrder, reply)

      end

      test '03', '', 'MedicationOrder read resource supported',
           'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
           'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

        skip_if_not_supported(:MedicationOrder, [:search, :read])

        validate_read_reply(@medicationorder, FHIR::DSTU2::MedicationOrder)

      end

      test '04', '', 'MedicationOrder history resource supported',
           'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
           'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
           :optional do

        skip_if_not_supported(:MedicationOrder, [:history])

        validate_history_reply(@medicationorder, FHIR::DSTU2::MedicationOrder)

      end

      test '05', '', 'MedicationOrder vread resource supported',
           'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
           'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
           :optional do

        skip_if_not_supported(:MedicationOrder, [:vread])

        validate_vread_reply(@medicationorder, FHIR::DSTU2::MedicationOrder)

      end

      test '06', '', 'MedicationOrder resources associated with Patient conform to Argonaut profiles',
           'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-medicationorder.html',
           'MedicationOrder resources associated with Patient conform to Argonaut profiles.' do
        test_resources_against_profile('MedicationOrder')
      end

    end

  end
end
