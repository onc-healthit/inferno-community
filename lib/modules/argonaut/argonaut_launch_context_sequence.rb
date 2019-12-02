# frozen_string_literal: true

module Inferno
  module Sequence
    class ArgonautLaunchContextSequence < SequenceBase
      title 'Patient'

      description %(
        Verify that Patient resources on the FHIR server follow the Argonaut
        Data Query Implementation Guide
      )

      test_id_prefix 'ARPA'

      requires :token, :patient_id
      conformance_supports :Patient

      test :unauthenticated_read do
        metadata do
          id '01'
          name 'Server rejects unauthorized Patient read request'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          description %(
            A patient read does not work without authorization.
          )
          versions :dstu2
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
          versions :dstu2
        end

        patient_read_response = @client.read(versioned_resource_class('Patient'), @instance.patient_id)
        assert_response_ok patient_read_response
        patient = patient_read_response.resource
        assert !patient.nil?, 'Expected response to be a Patient resource'
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
          versions :dstu2
        end

        skip_if @instance.encounter_id.blank?, 'No Encounter ID found in launch context'

        encounter_read_response = @client.read(versioned_resource_class('Encounter'), @instance.encounter_id)
        assert_response_ok encounter_read_response
        encounter = encounter_read_response.resource
        assert !encounter.nil?, 'Expected response to be a Encounter resource'
        assert encounter.is_a?(versioned_resource_class('Encounter')), 'Expected response to be a Encounter resource'
      end
    end
  end
end
