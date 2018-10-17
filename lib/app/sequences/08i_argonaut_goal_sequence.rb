module Inferno
  module Sequence
    class ArgonautGoalSequence < SequenceBase

      group 'Argonaut Profile Conformance'

      title 'Goal'

      description 'Verify that Goal resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'ADQ'

      requires :token, :patient_id
      conformance_supports :Goal

      test 'Server rejects Goal search without authorization' do

        metadata {
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A Goal search does not work without proper authorization.
          )
        }

        skip_if_not_supported(:Goal, [:search, :read])

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(FHIR::DSTU2::Goal, {patient: @instance.patient_id})
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply

      end

      test 'Server returns expected results from Goal search by patient' do

        metadata {
          id '02'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server is capable of returning all of a patient's goals.
          )
        }

        skip_if_not_supported(:Goal, [:search, :read])

        reply = get_resource_by_params(FHIR::DSTU2::Goal, {patient: @instance.patient_id})
        assert_bundle_response(reply)

        @no_resources_found = false
        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        if resource_count === 0
          @no_resources_found = true
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        @goal = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(FHIR::DSTU2::Goal, reply)
        save_resource_ids_in_bundle(FHIR::DSTU2::Goal, reply)

      end

      test 'Server returns expected results from Goal search by patient + date' do

        metadata {
          id '03'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server is capable of returning all of all of a patient's goals over a specified time period.
          )
        }

        skip_if_not_supported(:Goal, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        assert !@goal.nil?, 'Expected valid DSTU2 Goal resource to be present'
        date = @goal.try(:statusDate) || @goal.try(:targetDate) || @goal.try(:startDate)
        assert !date.nil?, "Goal statusDate, targetDate, nor startDate returned"
        reply = get_resource_by_params(FHIR::DSTU2::Goal, {patient: @instance.patient_id, date: date})
        validate_search_reply(FHIR::DSTU2::Goal, reply)

      end

      test 'Goal read resource supported' do

        metadata {
          id '04'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.
          )
        }

        skip_if_not_supported(:Goal, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        validate_read_reply(@goal, FHIR::DSTU2::Goal)

      end

      test 'Goal history resource supported' do

        metadata {
          id '05'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.
          )
        }

        skip_if_not_supported(:Goal, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        validate_history_reply(@goal, FHIR::DSTU2::Goal)

      end

      test 'Goal vread resource supported' do

        metadata {
          id '06'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.
          )
        }

        skip_if_not_supported(:Goal, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        validate_vread_reply(@goal, FHIR::DSTU2::Goal)

      end

      test 'Goal resources associated with Patient conform to Argonaut profiles' do

        metadata {
          id '07'
          link 'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-goal.html'
          desc %(
            Goal resources associated with Patient conform to Argonaut profiles.
          )
        }
        test_resources_against_profile('Goal')
      end


    end

  end
end
