module Inferno
  module Sequence
    class ArgonautImmunizationSequence < SequenceBase

      group 'Argonaut Profile Conformance'

      title 'Immunization'

      description 'Verify that Immunization resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'ARIM'

      requires :token, :patient_id

      test 'Server rejects Immunization search without authorization' do

        metadata {
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            An Immunization search does not work without proper authorization.
          )
        }

        skip_if_not_supported(:Immunization, [:search, :read])

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(FHIR::DSTU2::Immunization, {patient: @instance.patient_id})
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply

      end

      test 'Server supports Immunization search by patient' do

        metadata {
          id '02'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A client has connected to a server and fetched all immunizations for a patient.          )
        }

        skip_if_not_supported(:Immunization, [:search, :read])

        reply = get_resource_by_params(FHIR::DSTU2::Immunization, {patient: @instance.patient_id})
        assert_bundle_response(reply)

        @no_resources_found = false
        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        if resource_count === 0
          @no_resources_found = true
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        @immunization = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(FHIR::DSTU2::Immunization, reply)
        save_resource_ids_in_bundle(FHIR::DSTU2::Immunization, reply)

      end

      test 'Immunization read resource supported' do

        metadata {
          id '03'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.
          )
        }

        skip_if_not_supported(:Immunization, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        validate_read_reply(@immunization, FHIR::DSTU2::Immunization)

      end

      test 'Immunization history resource supported' do

        metadata {
          id '04'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.
          )
        }

        skip_if_not_supported(:Immunization, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        validate_history_reply(@immunization, FHIR::DSTU2::Immunization)

      end

      test 'Immunization vread resource supported' do

        metadata {
          id '05'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.
          )
        }

        skip_if_not_supported(:Immunization, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        validate_vread_reply(@immunization, FHIR::DSTU2::Immunization)

      end

      test 'Immunization resources associated with Patient conform to Argonaut profiles' do

        metadata {
          id '06'
          link 'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-immunization.html'
          desc %(
            Immunization resources associated with Patient conform to Argonaut profiles.
          )
        }
        test_resources_against_profile('Immunization')
      end

    end

  end
end
