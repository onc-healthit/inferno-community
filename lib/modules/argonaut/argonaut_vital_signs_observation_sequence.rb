# frozen_string_literal: true

module Inferno
  module Sequence
    class ArgonautVitalSignsSequence < SequenceBase
      PROFILE = Inferno::ValidationUtil::ARGONAUT_URIS[:vital_signs]

      title 'Vital Signs'

      description 'Verify that Vital Signs are collected on the FHIR server according to the Argonaut Data Query Implementation Guide'

      test_id_prefix 'ARVS'

      requires :token, :patient_id
      conformance_supports :Observation

      def validate_resource_item(resource, property, value)
        case property
        when 'patient'
          assert resource.subject&.reference&.include?(value), 'Subject on resource does not match patient requested'
        when 'category'
          codings = resource.try(:category).try(:coding)
          assert !codings.nil?, 'Category on resource did not match category requested'
          assert codings.any? { |coding| !coding.try(:code).nil? && coding.try(:code) == value }, 'Category on resource did not match category requested'
        when 'date'
          # todo
        when 'code'
          codings = resource.try(:code).try(:coding)
          assert !codings.nil?, 'Code on resource did not match code requested'
          assert codings.any? { |coding| !coding.try(:code).nil? && coding.try(:code) == value }, 'Code on resource did not match code requested'
        end
      end

      details %(
        # Background

        The #{title} Sequence tests the #{title} associated with the provided patient.  The resources
        returned will be checked for consistency against the [#{title} Argonaut Profile](https://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-#{title.gsub(/\s+/, '').downcase}.html)

        # Test Methodology

        This test suite accesses the server endpoint at `/Observation/?category=vital-signs&patient={id}` using a `GET` request.
        It parses the #{title} and verifies that it conforms to the profile.

        It collects the following information that is saved in the testing session for use by later tests:

        * List of `Observation` resources

        For more information on the #{title}, visit these links:

        * [FHIR DSTU2 Observation](https://www.hl7.org/fhir/DSTU2/observation.html)
        * [Argonauts #{title} Profile](https://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-#{title.gsub(/\s+/, '').downcase}.html)
              )

      @resource_found = false

      test 'Server rejects Vital Signs search without authorization' do
        metadata do
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          description %(
            A Vital Signs search does not work without proper authorization.
          )
          versions :dstu2
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(versioned_resource_class('Observation'), patient: @instance.patient_id, category: 'vital-signs')
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from Vital Signs search by patient + category' do
        metadata do
          id '02'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          description %(
            A server is capable of returning all of a patient's vital signs that it supports.
          )
          versions :dstu2
        end

        search_params = { patient: @instance.patient_id, category: 'vital-signs' }
        reply = get_resource_by_params(versioned_resource_class('Observation'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        @resources_found = true if resource_count.positive?

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @vitalsigns = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(versioned_resource_class('Observation'), reply, search_params)
        save_resource_ids_in_bundle(versioned_resource_class('Observation'), reply, PROFILE)
      end

      test 'Server returns expected results from Vital Signs search by patient + category + date' do
        metadata do
          id '03'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          description %(
            A server is capable of returning all of a patient's vital signs queried by date range.
          )
          versions :dstu2
        end

        skip_if_not_supported(:Observation, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        assert !@vitalsigns.nil?, 'Expected valid Observation resource to be present'
        date = @vitalsigns.try(:effectiveDateTime)
        assert !date.nil?, 'Observation effectiveDateTime not returned'
        search_params = { patient: @instance.patient_id, category: 'vital-signs', date: date }
        reply = get_resource_by_params(versioned_resource_class('Observation'), search_params)
        validate_search_reply(versioned_resource_class('Observation'), reply, search_params)
      end

      test 'Server returns expected results from Vital Signs search by patient + category + code' do
        metadata do
          id '04'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          description %(
            A server is capable of returning any of a patient's vital signs queried by one or more of the specified codes.
          )
          versions :dstu2
        end

        skip_if_not_supported(:Observation, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        assert !@vitalsigns.nil?, 'Expected valid Observation resource to be present'
        code = @vitalsigns.try(:code).try(:coding).try(:first).try(:code)
        assert !code.nil?, 'Observation code not returned'
        search_params = { patient: @instance.patient_id, category: 'vital-signs', code: code }
        reply = get_resource_by_params(versioned_resource_class('Observation'), search_params)
        validate_search_reply(versioned_resource_class('Observation'), reply, search_params)
      end

      test 'Server returns expected results from Vital Signs search by patient + category + code + date' do
        metadata do
          id '05'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          description %(
            A server SHOULD be capable of returning any of a patient's vital signs queried by one or more of the codes listed below and date range.
          )
          versions :dstu2
        end

        skip_if_not_supported(:Observation, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        assert !@vitalsigns.nil?, 'Expected valid Observation resource to be present'
        code = @vitalsigns.try(:code).try(:coding).try(:first).try(:code)
        assert !code.nil?, 'Observation code not returned'
        date = @vitalsigns.try(:effectiveDateTime)
        assert !date.nil?, 'Observation effectiveDateTime not returned'
        search_params = { patient: @instance.patient_id, category: 'vital-signs', code: code, date: date }
        reply = get_resource_by_params(versioned_resource_class('Observation'), search_params)
        validate_search_reply(versioned_resource_class('Observation'), reply, search_params)
      end

      test 'Vital Signs resources associated with Patient conform to Argonaut profiles' do
        metadata do
          id '06'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          description %(
            Vital Signs resources associated with Patient conform to Argonaut profiles.
          )
          versions :dstu2
        end

        test_resources_against_profile('Observation', PROFILE)
        skip_unless @profiles_encountered.include?(PROFILE), 'No Vital Sign Observations found.'
        assert !@profiles_failed.include?(PROFILE), "Vital Sign Observations failed validation.<br/>#{@profiles_failed[PROFILE]}"
      end
    end
  end
end
