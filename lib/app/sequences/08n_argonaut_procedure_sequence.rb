module Inferno
  module Sequence
    class ArgonautProcedureSequence < SequenceBase

      group 'Argonaut Profile Conformance'

      title 'Procedure'

      description 'Verify that Procedure resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'ARPR'

      requires :token, :patient_id

      @resources_found = false

      test 'Server rejects Procedure search without authorization' do

        metadata {
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A Procedure search does not work without proper authorization.
          )
        }

        skip_if_not_supported(:Procedure, [:search, :read])

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(FHIR::DSTU2::Procedure, {patient: @instance.patient_id})
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
        save_resource_ids_in_bundle(FHIR::DSTU2::Procedure, reply)

      end

      test 'Server returns expected results from Procedure search by patient' do

        metadata {
          id '02'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server is capable of returning a patient's procedures.
          )
        }

        skip_if_not_supported(:Procedure, [:search, :read])

        reply = get_resource_by_params(FHIR::DSTU2::Procedure, {patient: @instance.patient_id})
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        if resource_count > 0
          @resources_found = true
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @procedure = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(FHIR::DSTU2::Procedure, reply)

      end

      test 'Server returns expected results from Procedure search by patient + date' do

        metadata {
          id '03'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server is capable of returning all of all of a patient's procedures over a specified time period.
          )
        }

        skip_if_not_supported(:Procedure, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        assert !@procedure.nil?, 'Expected valid DSTU2 Procedure resource to be present'
        date = @procedure.try(:performedDateTime) || @procedure.try(:performedPeriod).try(:start)
        assert !date.nil?, "Procedure performedDateTime or performedPeriod not returned"
        reply = get_resource_by_params(FHIR::DSTU2::Procedure, {patient: @instance.patient_id, date: date})
        validate_search_reply(FHIR::DSTU2::Procedure, reply)

      end

      test 'Procedure read resource supported' do

        metadata {
          id '04'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.
          )
        }

        skip_if_not_supported(:Procedure, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@procedure, FHIR::DSTU2::Procedure)

      end

      test 'Procedure history resource supported' do

        metadata {
          id '05'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.
          )
        }

        skip_if_not_supported(:Procedure, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@procedure, FHIR::DSTU2::Procedure)

      end

      test 'Procedure vread resource supported' do

        metadata {
          id '06'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.
          )
        }

        skip_if_not_supported(:Procedure, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@procedure, FHIR::DSTU2::Procedure)

      end

      test 'Procedure resources associated with Patient conform to Argonaut profiles' do

        metadata {
          id '07'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            Procedure resources associated with Patient conform to Argonaut profiles.
          )
        }
        test_resources_against_profile('Procedure')
      end

      test 'All references can be resolved' do

        metadata {
          id '08'
          link ''
          desc %(
            All references in the Procedure resource should be resolveable.
          )
        }

        skip_if_not_supported(:Procedure, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@procedure)

      end


    end

  end
end
