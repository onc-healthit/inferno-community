require_relative './ehr_launch_sequence'

module Inferno
  module Sequence
    class OncEHRLaunchSequence < EHRLaunchSequence

      extends_sequence EHRLaunchSequence

      title 'ONC EHR Launch Sequence'

      description 'Demonstrate the ONC SMART EHR Launch Sequence.'

      test_id_prefix 'OELS'

      requires :client_id, :confidential_client, :client_secret, :oauth_authorize_endpoint, :oauth_token_endpoint, :scopes,:initiate_login_uri, :redirect_uris

      defines :token, :id_token, :refresh_token, :patient_id

      @@resourceTypes = [
      'Patient',
      'AllergyIntolerance',
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
      'Provenance']

      test 'Scopes follow Smart App Launch Guidelines' do
        metadata {
          id '11'
          link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html#quick-start'
          desc %(
            The scopes being input must follow the guidelines specified in the smart-app-launch guide
          )
        }
        scopes = @instance.scopes.split(' ') 

        assert scopes.include?('openid'), 'Scope did not include "openid"'
        scopes.delete('openid')
        assert scopes.include?( 'fhirUser'), 'Scope did not include "fhirUser"'
        scopes.delete('fhirUser')
        assert scopes.include?( 'launch'), 'Scope did not include "launch"'
        scopes.delete('launch')
        assert scopes.include?('offline_access'), 'Scope did not include "offline_access"'
        scopes.delete('offline_access')

        scopes.each do |scope|
          scope_pieces = scope.split('/')
          assert scope_pieces.count == 2, "Scope '#{scope}' does not follow the format: user/[ resource | * ].[ read | write | * ]"
          assert scope_pieces[0] == 'user', "Scope '#{scope}' does not follow the format: user/[ resource | * ].[ read | write | * ]"
          resource_access = scope_pieces[1].split('.')
          assert resource_access.count == 2, "Scope '#{scope}' does not follow the format: user/[ resource | * ].[ read | write | * ]"
          assert resource_access[0] == '*' || @@resourceTypes.include?(resource_access[0]), "'#{resource_access[0]}' must be either a valid resource type or '*'"
          assert resource_access[1] =~ /^(\*|read|write)/, "Scope '#{scope}' does not follow the format: user/[ resource | * ].[ read | write | * ]"
        end
      end

    end
  end
end
