module Inferno
  module Sequence
    class ArgonautVitalSignsSequence < SequenceBase

      title 'Vital Signs'

      description 'Verify that Vital Signs are collected on the FHIR server according to the Argonaut Data Query Implementation Guide'

      test_id_prefix 'ARVS'

      requires :token, :patient_id

      test 'Server rejects Vital Signs search without authorization' do

        metadata {
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A Vital Signs search does not work without proper authorization.
          )
        }

        skip_if_not_supported(:Observation, [:search, :read])

        @client.set_no_auth
        reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "vital-signs"})
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply

      end

      test 'Server returns expected results from Vital Signs search by patient + category' do

        metadata {
          id '02'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server is capable of returning all of a patient's vital signs that it supports.
          )
        }

        skip_if_not_supported(:Observation, [:search, :read])

        reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "vital-signs"})
        assert_bundle_response(reply)

        @no_resources_found = false
        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        if resource_count === 0
          @no_resources_found = true
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        @vitalsigns = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(FHIR::DSTU2::Observation, reply)
        # TODO check for `vital-signs` category
        save_resource_ids_in_bundle(FHIR::DSTU2::Observation, reply)

      end

      test 'Server returns expected results from Vital Signs search by patient + category + date' do

        metadata {
          id '03'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server is capable of returning all of a patient's vital signs queried by date range.
          )
        }

        skip_if_not_supported(:Observation, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        assert !@vitalsigns.nil?, 'Expected valid DSTU2 Observation resource to be present'
        date = @vitalsigns.try(:effectiveDateTime)
        assert !date.nil?, "Observation effectiveDateTime not returned"
        reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "vital-signs", date: date})
        validate_search_reply(FHIR::DSTU2::Observation, reply)

      end

      test 'Server returns expected results from Vital Signs search by patient + category + code' do

        metadata {
          id '04'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server is capable of returning any of a patient's vital signs queried by one or more of the specified codes.
          )
        }

        skip_if_not_supported(:Observation, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        assert !@vitalsigns.nil?, 'Expected valid DSTU2 Observation resource to be present'
        code = @vitalsigns.try(:code).try(:coding).try(:first).try(:code)
        assert !code.nil?, "Observation code not returned"
        reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "vital-signs", code: code})
        validate_search_reply(FHIR::DSTU2::Observation, reply)

      end

      test 'Server returns expected results from Vital Signs search by patient + category + code + date' do

        metadata {
          id '05'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server SHOULD be capable of returning any of a patient's vital signs queried by one or more of the codes listed below and date range.
          )
        }

        skip_if_not_supported(:Observation, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        assert !@vitalsigns.nil?, 'Expected valid DSTU2 Observation resource to be present'
        code = @vitalsigns.try(:code).try(:coding).try(:first).try(:code)
        assert !code.nil?, "Observation code not returned"
        date = @vitalsigns.try(:effectiveDateTime)
        assert !date.nil?, "Observation effectiveDateTime not returned"
        reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "vital-signs", code: code, date: date})
        validate_search_reply(FHIR::DSTU2::Observation, reply)

      end

      test 'Vital Signs resources associated with Patient conform to Argonaut profiles' do

        metadata {
          id '06'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            Vital Signs resources associated with Patient conform to Argonaut profiles.
          )
        }

        test_resources_against_profile('Observation', Inferno::ValidationUtil::VITAL_SIGNS_URL)
        skip_unless @profiles_encountered.include?(Inferno::ValidationUtil::VITAL_SIGNS_URL), 'No Vital Sign Observations found.'
        assert !@profiles_failed.include?(Inferno::ValidationUtil::VITAL_SIGNS_URL), "Vital Sign Observations failed validation.<br/>#{@profiles_failed[Inferno::ValidationUtil::VITAL_SIGNS_URL]}"
      end

    end

  end
end
