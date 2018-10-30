module Inferno
  module Sequence
    class ArgonautSmokingStatusSequence < SequenceBase

      group 'Argonaut Profile Conformance'

      title 'Smoking Status'

      description 'Verify that Smoking Status is collected on the FHIR server according to the Argonaut Data Query Implementation Guide'

      test_id_prefix 'ARSS'

      requires :token, :patient_id
      conformance_supports :Observation

      test 'Server rejects Smoking Status search without authorization' do

        metadata {
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A Smoking Status search does not work without proper authorization.
          )
        }

         

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, code: "72166-2"})
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply

      end

      test 'Server returns expected results from Smoking Status search by patient + code' do

        metadata {
          id '02'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server is capable of returning a patient's smoking status.
          )
        }

         

        reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, code: "72166-2"})
        validate_search_reply(FHIR::DSTU2::Observation, reply)
        # TODO check for 72166-2
        save_resource_ids_in_bundle(FHIR::DSTU2::Observation, reply)

      end

      test 'Smoking Status resources associated with Patient conform to Argonaut profiles' do

        metadata {
          id '03'
          link 'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-smokingstatus.html'
          desc %(
            Smoking Status resources associated with Patient conform to Argonaut profiles
          )
        }
        test_resources_against_profile('Observation', Inferno::ValidationUtil::SMOKING_STATUS_URL)
        skip_unless @profiles_encountered.include?(Inferno::ValidationUtil::SMOKING_STATUS_URL), 'No Smoking Status Observations found.'
        assert !@profiles_failed.include?(Inferno::ValidationUtil::SMOKING_STATUS_URL), "Smoking Status Observations failed validation.<br/>#{@profiles_failed[Inferno::ValidationUtil::SMOKING_STATUS_URL]}"
      end

    end

  end
end
