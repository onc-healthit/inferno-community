# frozen_string_literal: true

module Inferno
  module Sequence
    class USCoreR4PatientReadOnlySequence < SequenceBase
      title 'Patient'

      description 'Verify that Patient resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'ARPA'

      requires :token, :patient_id
      conformance_supports :Patient

      test 'Server rejects patient read without proper authorization' do
        metadata do
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          description %(
            A patient read does not work without authorization.
          )
          versions :r4
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = @client.read(versioned_resource_class('Patient'), @instance.patient_id)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from Patient read resource' do
        metadata do
          id '02'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          description %(
            All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.
          )
          versions :r4
        end

        patient_read_response = @client.read(versioned_resource_class('Patient'), @instance.patient_id)
        assert_response_ok patient_read_response
        @patient = patient_read_response.resource
        assert !@patient.nil?, 'Expected valid Patient resource to be present'
        assert @patient.is_a?(versioned_resource_class('Patient')), 'Expected resource to be valid Patient'
      end
    end
  end
end
