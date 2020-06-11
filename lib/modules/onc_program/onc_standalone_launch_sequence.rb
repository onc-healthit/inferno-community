# frozen_string_literal: true

require_relative './shared_onc_launch_tests'

module Inferno
  module Sequence
    class OncStandaloneLaunchSequence < SequenceBase
      include Inferno::Sequence::SharedONCLaunchTests

      title 'ONC Standalone Launch Sequence'

      description 'Demonstrate the ONC SMART Standalone Launch Sequence.'

      test_id_prefix 'OSLS'

      requires :onc_sl_client_id,
               :onc_sl_confidential_client,
               :onc_sl_client_secret,
               :onc_sl_scopes,
               :oauth_authorize_endpoint,
               :oauth_token_endpoint,
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
        ['openid', 'fhirUser', 'launch/patient', 'offline_access']
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

      required_scope_test(index: '10', patient_or_user: 'patient')

      test :unauthorized_read do
        metadata do
          id '11'
          name 'Server rejects unauthorized access'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html#behavior'
          description %(
            A server SHALL reject any unauthorized requests by returning an HTTP
            401 unauthorized response code.
          )
          versions :r4
        end

        @client.set_no_auth
        skip_if_auth_failed

        skip_if @instance.patient_id.nil?, 'Patient context expected to verify unauthorized read.'

        reply = @client.read(FHIR::Patient, @instance.patient_id)
        @client.set_bearer_token(@instance.token)

        assert_response_unauthorized reply
      end

      patient_context_test(index: '12')
    end
  end
end
