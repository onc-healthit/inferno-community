module Inferno
  module Sequence
    class ArgonautMedicationOrderSequence < SequenceBase

      title 'Medication Order'

      description 'Verify that MedicationOrder resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'ARMP'

      requires :token, :patient_id

      test 'Server rejects MedicationOrder search without authorization' do

        metadata {
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            An MedicationOrder search does not work without proper authorization.
          )
        }

        skip_if_not_supported(:MedicationOrder, [:search, :read])

        @client.set_no_auth
        reply = get_resource_by_params(FHIR::DSTU2::MedicationOrder, {patient: @instance.patient_id})
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
        }

        skip_if_not_supported(:MedicationOrder, [:search, :read])

        reply = get_resource_by_params(FHIR::DSTU2::MedicationOrder, {patient: @instance.patient_id})
        assert_bundle_response(reply)

        @no_resources_found = false
        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        if resource_count === 0
          @no_resources_found = true
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        @medicationorder = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(FHIR::DSTU2::MedicationOrder, reply)
        save_resource_ids_in_bundle(FHIR::DSTU2::MedicationOrder, reply)

      end

      test 'MedicationOrder read resource supported' do

        metadata {
          id '03'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.
          )
        }

        skip_if_not_supported(:MedicationOrder, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        validate_read_reply(@medicationorder, FHIR::DSTU2::MedicationOrder)

      end

      test 'MedicationOrder history resource supported' do

        metadata {
          id '04'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.
          )
        }

        skip_if_not_supported(:MedicationOrder, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        validate_history_reply(@medicationorder, FHIR::DSTU2::MedicationOrder)

      end

      test 'MedicationOrder vread resource supported' do

        metadata {
          id '05'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.
          )
        }

        skip_if_not_supported(:MedicationOrder, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        validate_vread_reply(@medicationorder, FHIR::DSTU2::MedicationOrder)

      end

      test 'MedicationOrder resources associated with Patient conform to Argonaut profiles' do

        metadata {
          id '06'
          link 'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-medicationorder.html'
          desc %(
            MedicationOrder resources associated with Patient conform to Argonaut profiles.
          )
        }
        test_resources_against_profile('MedicationOrder')
      end

    end

  end
end
