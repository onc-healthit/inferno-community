# frozen_string_literal: true

module Inferno
  module Sequence
    class USCoreR4PatientReadOnlySequence < SequenceBase
      title 'Patient'

      description %(
        Verify that Patient resources on the FHIR server follow the US Core
        Implementation Guide
      )

      test_id_prefix 'ARPA'

      requires :token, :patient_id
      conformance_supports :Patient

      test :unauthenticated_read do
        metadata do
          id '01'
          name 'Server rejects unauthorized Patient read request'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html#behavior'
          description %(
            A server SHALL reject any unauthorized requests by returning an HTTP
            401 unauthorized response code.
          )
          versions :r4
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = @client.read(versioned_resource_class('Patient'), @instance.patient_id)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test :authenticated_read do
        metadata do
          id '02'
          name 'Server returns Patient resource for an authorized read request'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html#behavior'
          description %(
            The US Core Server SHALL support the US Core Patient resource
            profile.
          )
          versions :r4
        end

        patient_read_response = @client.read(versioned_resource_class('Patient'), @instance.patient_id)
        assert_response_ok patient_read_response
        @patient = patient_read_response.resource
        assert !@patient.nil?, 'Expected response to be a Patient resource'
        assert @patient.is_a?(versioned_resource_class('Patient')), 'Expected response to be a Patient resource'
      end
    end
  end
end
