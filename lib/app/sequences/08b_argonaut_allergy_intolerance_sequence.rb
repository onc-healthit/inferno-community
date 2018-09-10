module Inferno
  module Sequence
    class ArgonautAllergyIntoleranceSequence < SequenceBase

      group 'Argonaut Profile Conformance'

      title 'Allergy Intolerance'

      description 'Verify that AllergyIntolerance resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'ARAI'

      requires :token, :patient_id

      preconditions 'Client must be authorized' do
        !@instance.token.nil?
      end

      # --------------------------------------------------
      # AllergyIntolerance Search
      # --------------------------------------------------

      test '01', '', 'Server rejects AllergyIntolerance search without authorization',
           'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
           'An AllergyIntolerance search does not work without proper authorization.' do

        skip_if_not_supported(:AllergyIntolerance, [:search, :read])

        @client.set_no_auth
        reply = get_resource_by_params(FHIR::DSTU2::AllergyIntolerance, {patient: @instance.patient_id})
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply

      end

      test '02', '', 'Server returns expected results from AllergyIntolerance search by patient',
           'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
           "A server is capable of returning a patient's allergies." do

        skip_if_not_supported(:AllergyIntolerance, [:search, :read])

        reply = get_resource_by_params(FHIR::DSTU2::AllergyIntolerance, {patient: @instance.patient_id})
        assert_bundle_response(reply)

        @no_resources_found = false
        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        if resource_count === 0
          @no_resources_found = true
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        @allergyintolerance = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(FHIR::DSTU2::AllergyIntolerance, reply)
        save_resource_ids_in_bundle(FHIR::DSTU2::AllergyIntolerance, reply)

      end

      test '03', '', 'Server returns expected results from AllergyIntolerance read resource',
           'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
           'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

        skip_if_not_supported(:AllergyIntolerance, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        validate_read_reply(@allergyintolerance, FHIR::DSTU2::AllergyIntolerance)

      end

      test '04', '', 'AllergyIntolerance history resource supported',
           'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
           'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
           :optional do

        skip_if_not_supported(:AllergyIntolerance, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found
        validate_history_reply(@allergyintolerance, FHIR::DSTU2::AllergyIntolerance)

      end

      test '05', '', 'AllergyIntolerance vread resource supported',
           'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
           'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
           :optional do

        skip_if_not_supported(:AllergyIntolerance, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        validate_vread_reply(@allergyintolerance, FHIR::DSTU2::AllergyIntolerance)

      end

      test '06', '', 'AllergyIntolerance resources associated with Patient conform to Argonaut profiles',
           'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-allergyintolerance.html',
           'AllergyIntolerance resources associated with Patient conform to Argonaut profiles.' do
        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found
        test_resources_against_profile('AllergyIntolerance')
      end


    end

  end
end
