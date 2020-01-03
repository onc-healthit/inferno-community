# frozen_string_literal: true

require_relative '../smart/standalone_launch_sequence'

module Inferno
  module Sequence
    class OncStandaloneLaunchSequence < StandaloneLaunchSequence
      extends_sequence StandaloneLaunchSequence

      title 'ONC Standalone Launch Sequence'

      description 'Demonstrate the ONC SMART Standalone Launch Sequence.'

      test_id_prefix 'OSLS'

      requires :client_id, :confidential_client, :client_secret, :oauth_authorize_endpoint, :oauth_token_endpoint, :scopes, :initiate_login_uri, :redirect_uris

      defines :token, :id_token, :refresh_token, :patient_id

      def valid_resource_types
        [
          '*',
          'Patient',
          'AllergyIntolerance',
          'CarePlan',
          'CareTeam',
          'Condition',
          'Device',
          'DiagnosticReport',
          'DocumentReference',
          'Encounter',
          'Goal',
          'Immunization',
          'Location',
          'Medication',
          'MedicationOrder',
          'MedicationRequest',
          'MedicationStatement',
          'Observation',
          'Organization',
          'Practitioner',
          'PractitionerRole',
          'Procedure',
          'Provenance'
        ]
      end

      def required_scopes
        ['openid', 'fhirUser', 'launch/patient', 'offline_access']
      end

      test :onc_scopes do
        metadata do
          id '10'
          name 'Patient-level access with OpenID Connect and Refresh Token scopes used.'
          link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html#quick-start'
          description %(
            The scopes being input must follow the guidelines specified in the smart-app-launch guide
          )
        end

        scopes = @instance.received_scopes.split(' ')

        missing_scopes = required_scopes - scopes
        assert missing_scopes.empty?, "Required scopes missing: #{missing_scopes.join(', ')}"

        scopes -= required_scopes
        # Other 'okay' scopes
        scopes.delete('online_access')

        patient_scope_found = false

        scopes.each do |scope|
          bad_format_message = "Scope '#{scope}' does not follow the format: patient/[ resource | * ].[ read | * ]"
          scope_pieces = scope.split('/')

          assert scope_pieces.count == 2, bad_format_message
          assert scope_pieces[0] == 'patient', bad_format_message

          resource_access = scope_pieces[1].split('.')
          bad_resource_message = "'#{resource_access[0]}' must be either a valid resource type or '*'"

          assert resource_access.count == 2, bad_format_message
          assert valid_resource_types.include?(resource_access[0]), bad_resource_message
          assert resource_access[1] =~ /^(\*|read)/, bad_format_message

          patient_scope_found = true
        end

        assert patient_scope_found, 'Must contain a patient-level scope in the format: patient/[ resource | * ].[ read | *].'
      end
    end
  end
end
