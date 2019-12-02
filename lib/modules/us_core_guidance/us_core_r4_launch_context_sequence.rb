# frozen_string_literal: true

module Inferno
  module Sequence
    class USCoreR4LaunchContextSequence < SequenceBase
      title 'Patient'

      description %(
        Verify the access token, patient ID, and encounter ID received in the
        launch context
      )

      test_id_prefix 'USCLC'

      requires :token, :patient_id, :encounter_id
      conformance_supports :Patient

      test :unauthenticated_read do
        metadata do
          id '01'
          name 'Server rejects unauthorized Patient read request'
          link 'http://hl7.org/fhir/us/core/2019Jan/CapabilityStatement-us-core-server.html#behavior'
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

      test :patient_read do
        metadata do
          id '02'
          name 'Server returns Patient resource for an authorized read request'
          link 'http://hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html#launch-context-arrives-with-your-access_token'
          description %(
            The `patient` field in the launch context contains a string value
            with a Patient ID, indicating that the app was launched in the
            context of that FHIR Patient
          )
          versions :r4
        end

        patient_read_response = @client.read(versioned_resource_class('Patient'), @instance.patient_id)
        assert_response_ok patient_read_response
        patient = patient_read_response.resource
        assert patient.present?, 'Expected response to be a Patient resource'
        assert patient.is_a?(versioned_resource_class('Patient')), 'Expected response to be a Patient resource'
      end

      test :encounter_read do
        metadata do
          id '03'
          name 'Server returns Encounter resource for an authorized read request'
          link 'http://hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html#launch-context-arrives-with-your-access_token'
          description %(
            The `encounter` field in the launch context contains a string value
            with an Encounter ID, indicating that the app was launched in the
            context of that FHIR Encounter
          )
          versions :r4
        end

        skip_if @instance.encounter_id.blank?, 'No Encounter ID found in launch context'

        encounter_read_response = @client.read(versioned_resource_class('Encounter'), @instance.encounter_id)
        assert_response_ok encounter_read_response
        encounter = encounter_read_response.resource
        assert encounter.present?, 'Expected response to be a Encounter resource'
        assert encounter.is_a?(versioned_resource_class('Encounter')), 'Expected response to be a Encounter resource'
      end
    end
  end
end
