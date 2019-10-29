# frozen_string_literal: true

require_relative '../smart/ehr_launch_sequence'

module Inferno
  module Sequence
    class OncEHRLaunchSequence < EHRLaunchSequence
      extends_sequence EHRLaunchSequence

      title 'ONC EHR Launch Sequence'

      description 'Demonstrate the ONC SMART EHR Launch Sequence.'

      test_id_prefix 'OELS'

      requires :client_id, :confidential_client, :client_secret, :oauth_authorize_endpoint, :oauth_token_endpoint, :scopes, :initiate_login_uri, :redirect_uris

      defines :token, :id_token, :refresh_token, :patient_id

      def valid_resource_types
        [
          '*',
          'Patient',
          'AllergyIntolerance',
          'CarePlan',
          'Condition',
          'Device',
          'DiagnosticReport',
          'DocumentReference',
          'Encounter',
          'ExplanationOfBenefit',
          'Goal',
          'Immunization',
          'Medication',
          'MedicationDispense',
          'MedicationStatement',
          'MedicationOrder',
          'Observation',
          'Procedure',
          'DocumentReference',
          'Provenance'
        ]
      end

      def required_scopes
        ['openid', 'fhirUser', 'launch', 'offline_access']
      end

      test :onc_scopes do
        metadata do
          id '11'
          name 'Scopes enabling user-level access with OpenID Connect and Refresh Token present'
          link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html#quick-start'
          description %(
            The scopes being input must follow the guidelines specified in the smart-app-launch guide
          )
        end

        scopes = @instance.scopes.split(' ')

        missing_scopes = required_scopes - scopes
        assert missing_scopes.empty?, "Required scopes missing: #{missing_scopes.join(', ')}"

        scopes -= required_scopes
        # Other 'okay' scopes
        scopes.delete('online_access')

        user_scope_found = false

        scopes.each do |scope|
          bad_format_message = "Scope '#{scope}' does not follow the format: user/[ resource | * ].[ read | * ]"
          scope_pieces = scope.split('/')

          assert scope_pieces.count == 2, bad_format_message
          assert scope_pieces[0] == 'user', bad_format_message

          resource_access = scope_pieces[1].split('.')
          bad_resource_message = "'#{resource_access[0]}' must be either a valid resource type or '*'"

          assert resource_access.count == 2, bad_format_message
          assert valid_resource_types.include?(resource_access[0]), bad_resource_message
          assert resource_access[1] =~ /^(\*|read)/, bad_format_message

          user_scope_found = true
        end

        assert user_scope_found, 'Must contain a user-level scope in the format: user/[ resource | * ].[ read | *].'
      end
    end
  end
end
