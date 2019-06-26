# frozen_string_literal: true

module Inferno
  module Sequence
    class ArgonautSmokingStatusSequence < SequenceBase
      PROFILE = Inferno::ValidationUtil::ARGONAUT_URIS[:smoking_status]

      group 'Argonaut Profile Conformance'

      title 'Smoking Status'

      description 'Verify that Smoking Status is collected on the FHIR server according to the Argonaut Data Query Implementation Guide'

      test_id_prefix 'ARSS'

      requires :token, :patient_id
      conformance_supports :Observation

      def validate_resource_item(resource, property, value)
        case property
        when 'patient'
          assert (resource.subject&.reference&.include?(value)), 'Patient on resource does not match patient requested'
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

        This test suite accesses the server endpoint at `/Observation/?code=72166-2&patient={id}` using a `GET` request.
        It parses the #{title} and verifies that it conforms to the profile.

        It collects the following information that is saved in the testing session for use by later tests:

        * List of `Observation` resources

        For more information on the #{title}, visit these links:

        * [FHIR DSTU2 Observation](https://www.hl7.org/fhir/DSTU2/observation.html)
        * [Argonauts #{title} Profile](https://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-#{title.gsub(/\s+/, '').downcase}.html)
              )

      test 'Server rejects Smoking Status search without authorization' do
        metadata do
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A Smoking Status search does not work without proper authorization.
          )
          versions :dstu2
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(versioned_resource_class('Observation'), patient: @instance.patient_id, code: '72166-2')
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      @resources_found = false

      test 'Server returns expected results from Smoking Status search by patient + code' do
        metadata do
          id '02'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server is capable of returning a patient's smoking status.
          )
          versions :dstu2
        end

        search_params = { patient: @instance.patient_id, code: '72166-2' }
        reply = get_resource_by_params(versioned_resource_class('Observation'), search_params)

        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        @resources_found = true if resource_count.positive?

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        validate_search_reply(versioned_resource_class('Observation'), reply, search_params)
        save_resource_ids_in_bundle(versioned_resource_class('Observation'), reply, PROFILE)
      end

      test 'Smoking Status resources associated with Patient conform to Argonaut profiles' do
        metadata do
          id '03'
          link 'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-smokingstatus.html'
          desc %(
            Smoking Status resources associated with Patient conform to Argonaut profiles
          )
          versions :dstu2
        end
        test_resources_against_profile('Observation', PROFILE)
        skip_unless @profiles_encountered.include?(PROFILE), 'No Smoking Status Observations found.'
        assert !@profiles_failed.include?(PROFILE), "Smoking Status Observations failed validation.<br/>#{@profiles_failed[PROFILE]}"
      end
    end
  end
end
