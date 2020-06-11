# frozen_string_literal: true

require_relative './shared_onc_launch_tests'

module Inferno
  module Sequence
    class OncStandalonePublicLaunchSequence < SequenceBase
      include Inferno::Sequence::SharedONCLaunchTests

      title 'Public Client Standalone Launch with OpenID Connect'

      description 'Register Inferno as a public client with patient access and execute standalone launch.'

      test_id_prefix 'OSLSP'

      requires :onc_public_client_id,
               :onc_public_scopes,
               :onc_sl_oauth_authorize_endpoint,
               :onc_sl_oauth_token_endpoint,
               :initiate_login_uri,
               :redirect_uris

      defines :token, :id_token, :refresh_token, :patient_id

      show_uris

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
        ['launch/patient', 'openid', 'fhirUser']
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
        @instance.onc_public_client_id
      end

      def instance_confidential_client
        false
      end

      def instance_client_secret
        ''
      end

      def instance_scopes
        @instance.onc_public_scopes
      end

      test 'OAuth server redirects client browser to app redirect URI' do
        metadata do
          id '01'
          link 'http://www.hl7.org/fhir/smart-app-launch/'
          description %(
            Client browser redirected from OAuth server to redirect URI of
            client app as described in SMART authorization sequence.
          )
        end

        # We need to use the same endpoints that we discovered from the standalone launch
        @instance.oauth_authorize_endpoint = @instance.onc_sl_oauth_authorize_endpoint
        @instance.oauth_token_endpoint = @instance.onc_sl_oauth_token_endpoint

        @instance.save
        @instance.update(state: SecureRandom.uuid)

        oauth2_params = {
          'response_type' => 'code',
          'client_id' => instance_client_id,
          'redirect_uri' => @instance.redirect_uris,
          'scope' => instance_scopes,
          'state' => @instance.state,
          'aud' => instance_url
        }

        oauth_authorize_endpoint = @instance.oauth_authorize_endpoint

        assert_valid_http_uri oauth_authorize_endpoint, "OAuth2 Authorization Endpoint: \"#{@oauth_authorize_endpoint}\" is not a valid URI"

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

      code_and_state_received_test(index: '02')

      successful_token_exchange_test(index: '03')

      token_response_contents_test(index: '04')

      token_response_headers_test(index: '05')

      patient_context_test(index: '06')

      test :token_contains_id_token do
        metadata do
          id '07'
          name 'OAuth token exchange response contains OpenID Connect id_token'
          link 'http://hl7.org/fhir/smart-app-launch/'
          description %(
            This test requires that an OpenID Connect id_token is provided to demonstrate authentication capabilies
            for public clients.
          )
          versions :r4
        end
        assert @token_response_body.key?('id_token'), 'Token response did not provide an id_token as required.'
      end
    end
  end
end
