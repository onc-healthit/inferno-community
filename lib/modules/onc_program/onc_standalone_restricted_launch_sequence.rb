# frozen_string_literal: true

require_relative './shared_onc_launch_tests'

module Inferno
  module Sequence
    class OncStandaloneRestrictedLaunchSequence < SequenceBase
      include Inferno::Sequence::SharedONCLaunchTests

      title 'ONC Standalone Launch Sequence'

      description 'Demonstrate the ONC SMART Standalone Launch Sequence.'

      test_id_prefix 'OSRLS'

      requires :onc_sl_url,
               :onc_sl_client_id,
               :onc_sl_confidential_client,
               :onc_sl_client_secret,
               :onc_sl_scopes,
               :onc_sl_expected_resources,
               :oauth_authorize_endpoint,
               :oauth_token_endpoint,
               :initiate_login_uri,
               :redirect_uris

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
          'Provenance',
          'RelatedPerson'
        ]
      end

      def required_scopes
        ['launch/patient']
      end

      details %(
        # Background

        The [Standalone
        Launch](http://hl7.org/fhir/smart-app-launch/#standalone-launch-sequence)
        Sequence allows an app, like Inferno, to be launched independent of an
        existing EHR session. It is one of the two launch methods described in
        the SMART App Launch Framework alongside EHR Launch. The app will
        request authorization for the provided scope from the authorization
        endpoint, ultimately receiving an authorization token which can be used
        to gain access to resources on the FHIR server.

        # Test Methodology

        Inferno will redirect the user to the the authorization endpoint so that
        they may provide any required credentials and authorize the application.
        Upon successful authorization, Inferno will exchange the authorization
        code provided for an access token.

        For more information on the #{title}:

        * [Standalone Launch Sequence](http://hl7.org/fhir/smart-app-launch/#standalone-launch-sequence)
      )

      def url_property
        'onc_sl_url'
      end

      def instance_url
        @instance.send(url_property)
      end

      def instance_client_id
        @instance.onc_sl_client_id
      end

      def instance_confidential_client
        @instance.onc_sl_confidential_client
      end

      def instance_client_secret
        @instance.onc_sl_client_secret
      end

      def instance_scopes
        @instance.onc_sl_scopes
      end

      auth_endpoint_tls_test(index: '01')

      test 'OAuth server redirects client browser to app redirect URI' do
        metadata do
          id '02'
          link 'http://www.hl7.org/fhir/smart-app-launch/'
          description %(
            Client browser redirected from OAuth server to redirect URI of
            client app as described in SMART authorization sequence.
          )
        end

        @instance.save
        @instance.update(state: SecureRandom.uuid)

        oauth2_params = {
          'response_type' => 'code',
          'client_id' => @instance.onc_sl_client_id,
          'redirect_uri' => @instance.redirect_uris,
          'scope' => instance_scopes,
          'state' => @instance.state,
          'aud' => @instance.onc_sl_url
        }

        oauth_authorize_endpoint = @instance.oauth_authorize_endpoint

        assert_valid_http_uri oauth_authorize_endpoint, "OAuth2 Authorization Endpoint: \"#{oauth_authorize_endpoint}\" is not a valid URI"

        oauth2_auth_query = oauth_authorize_endpoint

        oauth2_auth_query += if oauth_authorize_endpoint.include? '?'
                               '&'
                             else
                               '?'
                             end

        oauth2_params.each do |key, value|
          oauth2_auth_query += "#{key}=#{CGI.escape(value)}&"
        end

        redirect oauth2_auth_query[0..-2], 'redirect'
      end

      code_and_state_received_test(index: '03')

      token_endpoint_tls_test(index: '04')

      invalid_code_test(index: '05')

      invalid_client_id_test(index: '06')

      successful_token_exchange_test(index: '07')

      token_response_contents_test(index: '08')

      token_response_headers_test(index: '09')

      patient_context_test(index: '10')

      def scope_granting_access(resource, scopes)
        scopes.split(' ').find do |scope|
          scope.start_with?("patient/#{resource}", 'patient/*') && scope.end_with?('*', 'read')
        end
      end

      test :onc_restricted_scopes do
        metadata do
          id '11'
          name 'OAuth token exchange response grants scope that is limited to those selected by user'
          link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html#quick-start'
          description %(
            The ONC certification criteria requires that patients are capable of choosing which
            FHIR resources to authorize to the application, and patients must be
            given the choice to grant `offline_access`.  For this test, the tester specifies
            which resources will be selected during authorization, and this verifies that only
            those resources are granted according to the scopes returned during the access token
            response.
          )
        end

        skip_if_auth_failed

        received_scopes = @instance.received_scopes || ''

        all_resources = [
          'AllergyIntolerance',
          'CarePlan',
          'CareTeam',
          'Condition',
          'Device',
          'DiagnosticReport',
          'DocumentReference',
          'Goal',
          'Immunization',
          'MedicationRequest',
          'Observation',
          'Procedure',
          'Patient'
        ]

        expected_resources = all_resources.select { |resource| @instance.onc_sl_expected_resources.split(',').map(&:strip).map(&:downcase).include?(resource.downcase) }
        expected_denied_resources = all_resources - expected_resources

        improperly_granted_resources = expected_denied_resources.select { |resource| scope_granting_access(resource, received_scopes).present? }

        assert improperly_granted_resources.empty?, "User expected to deny the following resources that were granted: #{improperly_granted_resources.join(', ')}"

        assert !received_scopes.split(' ').include?('offline_access'), 'Scopes returned in access token response contained offline_access.  User must deny this scope to pass this test.'
      end
    end
  end
end
