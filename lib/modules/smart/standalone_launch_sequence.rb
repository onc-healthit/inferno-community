# frozen_string_literal: true

require_relative './shared_launch_tests'

module Inferno
  module Sequence
    class StandaloneLaunchSequence < SequenceBase
      include SharedLaunchTests

      title 'Standalone Launch Sequence'
      description 'Demonstrate the SMART Standalone Launch Sequence.'
      test_id_prefix 'SLS'

      requires :client_id,
               :client_secret,
               :confidential_client,
               :oauth_authorize_endpoint,
               :oauth_token_endpoint,
               :redirect_uris,
               :scopes

      defines :token, :id_token, :refresh_token, :patient_id

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

      preconditions 'Client must be registered' do
        !@instance.client_id.nil?
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

        @instance.save!
        @instance.update!(state: SecureRandom.uuid)

        oauth2_params = {
          'response_type' => 'code',
          'client_id' => @instance.client_id,
          'redirect_uri' => @instance.redirect_uris,
          'scope' => @instance.scopes,
          'state' => @instance.state,
          'aud' => @instance.url
        }

        oauth_authorize_endpoint = @instance.oauth_authorize_endpoint

        assert_valid_http_uri oauth_authorize_endpoint, "OAuth2 Authorization Endpoint: \"#{oauth_authorize_endpoint}\" is not a valid URI"

        oauth2_auth_query = oauth_authorize_endpoint

        oauth2_auth_query += if @instance.oauth_authorize_endpoint.include? '?'
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
    end
  end
end
