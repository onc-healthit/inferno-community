module Inferno
  module Sequence
    class ArgonautVitalSignsSequence < SequenceBase

      title 'Vital Signs'

      description 'Verify that Vital Signs are collected on the FHIR server according to the Argonaut Data Query Implementation Guide'

      test_id_prefix 'ARVS'

      requires :token, :patient_id
      conformance_supports :Observation

      @resource_found = false

      test 'Server rejects Vital Signs search without authorization' do

        metadata {
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A Vital Signs search does not work without proper authorization.
          )
          versions :dstu2
        }

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(versioned_resource_class('Observation'), {patient: @instance.patient_id, category: "vital-signs"})
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
          versions :dstu2
        }

        reply = get_resource_by_params(versioned_resource_class('Observation'), {patient: @instance.patient_id, category: "vital-signs"})
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        if resource_count > 0
          @resources_found = true
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @vitalsigns = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(versioned_resource_class('Observation'), reply)
        # TODO check for `vital-signs` category
        save_resource_ids_in_bundle(versioned_resource_class('Observation'), reply)

      end

      test 'Server returns expected results from Vital Signs search by patient + category + date' do

        metadata {
          id '03'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server is capable of returning all of a patient's vital signs queried by date range.
          )
          versions :dstu2
        }

        skip_if_not_supported(:Observation, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        assert !@vitalsigns.nil?, 'Expected valid Observation resource to be present'
        date = @vitalsigns.try(:effectiveDateTime)
        assert !date.nil?, "Observation effectiveDateTime not returned"
        reply = get_resource_by_params(versioned_resource_class('Observation'), {patient: @instance.patient_id, category: "vital-signs", date: date})
        validate_search_reply(versioned_resource_class('Observation'), reply)

      end

      test 'Server returns expected results from Vital Signs search by patient + category + code' do

        metadata {
          id '04'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server is capable of returning any of a patient's vital signs queried by one or more of the specified codes.
          )
          versions :dstu2
        }

        skip_if_not_supported(:Observation, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        assert !@vitalsigns.nil?, 'Expected valid Observation resource to be present'
        code = @vitalsigns.try(:code).try(:coding).try(:first).try(:code)
        assert !code.nil?, "Observation code not returned"
        reply = get_resource_by_params(versioned_resource_class('Observation'), {patient: @instance.patient_id, category: "vital-signs", code: code})
        validate_search_reply(versioned_resource_class('Observation'), reply)

      end

      test 'Server returns expected results from Vital Signs search by patient + category + code + date' do

        metadata {
          id '05'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server SHOULD be capable of returning any of a patient's vital signs queried by one or more of the codes listed below and date range.
          )
          versions :dstu2
        }

        skip_if_not_supported(:Observation, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        assert !@vitalsigns.nil?, 'Expected valid Observation resource to be present'
        code = @vitalsigns.try(:code).try(:coding).try(:first).try(:code)
        assert !code.nil?, "Observation code not returned"
        date = @vitalsigns.try(:effectiveDateTime)
        assert !date.nil?, "Observation effectiveDateTime not returned"
        reply = get_resource_by_params(versioned_resource_class('Observation'), {patient: @instance.patient_id, category: "vital-signs", code: code, date: date})
        validate_search_reply(versioned_resource_class('Observation'), reply)

      end

      test 'Vital Signs resources associated with Patient conform to Argonaut profiles' do

        metadata {
          id '06'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            Vital Signs resources associated with Patient conform to Argonaut profiles.
          )
          versions :dstu2
        }

        test_resources_against_profile('Observation', Inferno::ValidationUtil::ARGONAUT_URIS[:vital_signs])
        skip_unless @profiles_encountered.include?(Inferno::ValidationUtil::ARGONAUT_URIS[:vital_signs]), 'No Vital Sign Observations found.'
        assert !@profiles_failed.include?(Inferno::ValidationUtil::ARGONAUT_URIS[:vital_signs]), "Vital Sign Observations failed validation.<br/>#{@profiles_failed[Inferno::ValidationUtil::ARGONAUT_URIS[:vital_signs]]}"
      end

    end

  end
end
