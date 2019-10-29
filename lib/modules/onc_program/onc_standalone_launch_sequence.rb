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

      @@resource_types = [
        'Patient',
        'AllergyIntolerance',
        'Encounter',
        'CarePlan',
        'Condition',
        'Device',
        'DiagnosticReport',
        'DocumentReference',
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

      test :onc_scopes do
        metadata do
          id '09'
          name 'Patient-level access with OpenID Connect and Refresh Token scopes used.'
          link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html#quick-start'
          description %(
            The scopes being input must follow the guidelines specified in the smart-app-launch guide
          )
        end
        scopes = @instance.scopes.split(' ')

        assert scopes.include?('openid'), 'Scope did not include "openid"'
        scopes.delete('openid')
        assert scopes.include?('fhirUser'), 'Scope did not include "fhirUser"'
        scopes.delete('fhirUser')
        assert scopes.include?('launch/patient'), 'Scope did not include "launch/patient"'
        scopes.delete('launch/patient')
        assert scopes.include?('offline_access'), 'Scope did not include "offline_access"'
        scopes.delete('offline_access')

        # Other 'okay' scopes
        scopes.delete('online_access')

        patient_scope_found = false

        scopes.each do |scope|
          scope_pieces = scope.split('/')
          assert scope_pieces.count == 2, "Scope '#{scope}' does not follow the format: patient/[ resource | * ].[ read | * ]"
          assert scope_pieces[0] == 'patient', "Scope '#{scope}' does not follow the format: patient/[ resource | * ].[ read | * ]"
          resource_access = scope_pieces[1].split('.')
          assert resource_access.count == 2, "Scope '#{scope}' does not follow the format: patient/[ resource | * ].[ read | * ]"
          assert resource_access[0] == '*' || @@resource_types.include?(resource_access[0]), "'#{resource_access[0]}' must be either a valid resource type or '*'"
          assert resource_access[1] =~ /^(\*|read)/, "Scope '#{scope}' does not follow the format: patient/[ resource | * ].[ read | * ]"

          patient_scope_found = true
        end

        assert patient_scope_found, 'Must contain a patient-level scope in the format: patient/[ resource | * ].[ read | *].'
      end
    end
  end
end
