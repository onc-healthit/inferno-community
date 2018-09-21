module Inferno
  module Sequence
    class ArgonautConditionSequence < SequenceBase

      group 'Argonaut Profile Conformance'

      title 'Condition'

      description 'Verify that Condition resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'ARCO'

      requires :token, :patient_id

      test 'Server rejects Condition search without authorization' do

        metadata {
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A Condition search does not work without proper authorization.
          )
        }

        skip_if_not_supported(:Condition, [:search, :read])

        @client.set_no_auth
        reply = get_resource_by_params(FHIR::DSTU2::Condition, {patient: @instance.patient_id})
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply

      end

      test 'Server returns expected results from Condition search by patient' do

        metadata {
          id '02'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server is capable of returning a patients conditions list.
          )
        }

        skip_if_not_supported(:Condition, [:search, :read])

        reply = get_resource_by_params(FHIR::DSTU2::Condition, {patient: @instance.patient_id})
        assert_bundle_response(reply)

        @no_resources_found = false
        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        if resource_count === 0
          @no_resources_found = true
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        @condition = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(FHIR::DSTU2::Condition, reply)
        save_resource_ids_in_bundle(FHIR::DSTU2::Condition, reply)

      end

      test 'Server returns expected results from Condition search by patient + clinicalstatus' do

        metadata {
          id '03'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            A server SHOULD be capable returning all of a patients active problems and health concerns.
          )
        }

        skip_if_not_supported(:Condition, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        reply = get_resource_by_params(FHIR::DSTU2::Condition, {patient: @instance.patient_id, clinicalstatus: "active,recurrance,remission"})
        validate_search_reply(FHIR::DSTU2::Condition, reply)

      end

      test 'Server returns expected results from Condition search by patient + problem category' do

        metadata {
          id '04'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            A server SHOULD be capable returning all of a patients problems or all of patients health concerns.
          )
        }

        skip_if_not_supported(:Condition, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        reply = get_resource_by_params(FHIR::DSTU2::Condition, {patient: @instance.patient_id, category: "problem"})
        validate_search_reply(FHIR::DSTU2::Condition, reply)

      end

      test 'Server returns expected results from Condition search by patient + health-concern category' do

        metadata {
          id '05'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            A server SHOULD be capable returning all of a patients problems or all of patients health concerns.
          )
        }

        skip_if_not_supported(:Condition, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        reply = get_resource_by_params(FHIR::DSTU2::Condition, {patient: @instance.patient_id, category: "health-concern"})
        validate_search_reply(FHIR::DSTU2::Condition, reply)

      end

      test 'Condition read resource supported' do

        metadata {
          id '06'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.
          )
        }

        skip_if_not_supported(:Condition, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        validate_read_reply(@condition, FHIR::DSTU2::Condition)

      end

      test 'Condition history resource supported' do

        metadata {
          id '07'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.
          )
        }

        skip_if_not_supported(:Condition, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        validate_history_reply(@condition, FHIR::DSTU2::Condition)

      end

      test 'Condition vread resource supported' do

        metadata {
          id '08'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.
          )
        }

        skip_if_not_supported(:Condition, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        validate_vread_reply(@condition, FHIR::DSTU2::Condition)

      end

      test 'Condition resources associated with Patient conform to Argonaut profiles' do

        metadata {
          id '09'
          link 'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-condition.html'
          desc %(
            Condition resources associated with Patient conform to Argonaut profiles.
          )
        }
        test_resources_against_profile('Condition')
      end

    end

  end
end
