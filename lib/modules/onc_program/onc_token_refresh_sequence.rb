# frozen_string_literal: true

require_relative './shared_onc_launch_tests'

module Inferno
  module Sequence
    class OncTokenRefreshSequence < SequenceBase
      include Inferno::Sequence::SharedONCLaunchTests

      title 'Token Refresh'
      test_id_prefix 'OTR'

      title 'Token Refresh'
      description 'Demonstrate token refresh capability.'
      test_id_prefix 'TR'

      requires :client_id, :confidential_client, :client_secret, :refresh_token, :oauth_token_endpoint
      defines :token

      details %(
      # Background

      The #{title} Sequence tests the ability of the system to successfuly exchange a refresh token for an access token.
      Refresh tokens are typically longer lived than access tokens and allow client applications to obtain a new access token
      Refresh tokens themselves cannot provide access to resources on the server.

      Token refreshes are accomplished through a `POST` request to the token exchange endpoint as described in the
      [SMART App Launch Framework](http://www.hl7.org/fhir/smart-app-launch/#step-5-later-app-uses-a-refresh-token-to-obtain-a-new-access-token)

      # Test Methodology

      This test attempts to exchange the refresh token for a new access token and verify that the information returned
      contains the required fields and uses the proper headers.

      For more information see:

      * [The OAuth 2.0 Authorization Framework](https://tools.ietf.org/html/rfc6749)
      * [Using a refresh token to obtain a new access token](http://hl7.org/fhir/smart-app-launch/#step-5-later-app-uses-a-refresh-token-to-obtain-a-new-access-token)
              )

      INVALID_CLIENT_ID = 'INVALID_CLIENT_ID'
      INVALID_REFRESH_TOKEN = 'INVALID_REFRESH_TOKEN'

      def url_property
        'url'
      end

      def instance_url
        @instance.send(url_property)
      end

      def instance_client_id
        @instance.client_id
      end

      def instance_confidential_client
        @instance.confidential_client
      end

      def instance_client_secret
        @instance.client_secret
      end

      def instance_scopes
        @instance.scopes
      end

      test :invalid_refresh_token do
        metadata do
          id '01'
          name 'Refresh token exchange fails when supplied invalid Refresh Token'
          link 'https://tools.ietf.org/html/rfc6749'
          description %(
            If the request failed verification or is invalid, the authorization server returns an error response.          )
        end

        @client = FHIR::Client.for_testing_instance(@instance, url_property: url_property)
        @client.set_bearer_token(@instance.token) unless @client.nil? || @instance.nil? || @instance.token.nil?
        @client&.monitor_requests

        skip_if_no_refresh_token

        token_response = perform_refresh_request(instance_client_id, INVALID_REFRESH_TOKEN)
        assert_response_bad_or_unauthorized token_response
      end

      test :invalid_client_id do
        metadata do
          id '02'
          name 'Refresh token exchange fails when supplied invalid Client ID'
          link 'https://tools.ietf.org/html/rfc6749'
          description %(
            If the request failed verification or is invalid, the authorization server returns an error response.          )
        end

        omit 'This test is only applicable to confidential clients.' unless instance_confidential_client

        skip_if_no_refresh_token

        token_response = perform_refresh_request(INVALID_CLIENT_ID, @instance.refresh_token)
        assert_response_bad_or_unauthorized token_response
      end

      test :refresh_without_scope do
        metadata do
          id '03'
          name 'Refresh token exchange succeeds when optional scope parameter omitted'
          link 'https://tools.ietf.org/html/rfc6749'
          description %(
            Server successfully exchanges refresh token at OAuth token endpoint without providing scope in
            the body of the request.

            The EHR authorization server SHALL return a JSON structure that includes an access token or a message indicating that the authorization request has been denied.
            access_token, expires_in, token_type, and scope are required. access_token must be Bearer.

            Although not required in the token refresh portion of the SMART App Launch Guide,
            the token refresh response should include the HTTP Cache-Control response header field with a value of no-store, as well as the Pragma response header field with a value of no-cache
            to be consistent with the requirements of the inital access token exchange.

          )
        end

        skip_if_no_refresh_token

        specify_scopes = false

        @previous_refresh_token = @instance.refresh_token

        token_response = perform_refresh_request(instance_client_id, @instance.refresh_token, specify_scopes)

        assert_response_ok(token_response)

        validate_and_save_refresh_response(token_response)
        @refresh_successful = true
      end

      test :refresh_with_scope do
        metadata do
          id '04'
          name 'Refresh token exchange succeeds when optional scope parameter provided'
          link 'https://tools.ietf.org/html/rfc6749'
          description %(
            Server successfully exchanges refresh token at OAuth token endpoint while providing scope in
            the body of the request.

            The EHR authorization server SHALL return a JSON structure that includes an access token or a message indicating that the authorization request has been denied.
            access_token, token_type, and scope are required. access_token must be Bearer.

            Although not required in the token refresh portion of the SMART App Launch Guide,
            the token refresh response should include the HTTP Cache-Control response header field with a value of no-store, as well as the Pragma response header field with a value of no-cache
            to be consistent with the requirements of the inital access token exchange.
          )
        end

        skip_if_no_refresh_token

        specify_scopes = true

        token_response = perform_refresh_request(instance_client_id, @instance.refresh_token, specify_scopes)
        assert_response_ok(token_response)

        validate_and_save_refresh_response(token_response)
        @refresh_successful = true
      end

      def skip_if_no_refresh_token
        skip_if @instance.refresh_token.blank?, 'No refresh token was received during the SMART launch'
      end

      def validate_and_save_refresh_response(token_response)
        validate_token_response_contents(token_response, require_expires_in: true)
        warning { validate_token_response_headers(token_response) }
      end

      def encoded_secret(client_id, client_secret)
        "Basic #{Base64.strict_encode64(client_id + ':' + client_secret)}"
      end

      def perform_refresh_request(client_id, refresh_token, provide_scope = false)
        oauth2_params = {
          'grant_type' => 'refresh_token',
          'refresh_token' => refresh_token
        }
        oauth2_headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }

        oauth2_headers['Authorization'] = encoded_secret(client_id, instance_client_secret) if instance_confidential_client

        oauth2_params['scope'] = instance_scopes if provide_scope

        LoggedRestClient.post(@instance.oauth_token_endpoint, oauth2_params, oauth2_headers)
      end

      patient_context_test(index: '05', refresh: true)

      test :refresh_token_refreshed do
        metadata do
          id '06'
          name 'Server supplies new refresh token as required by ONC certification criteria.'
          link 'https://www.federalregister.gov/documents/2020/05/01/2020-07419/21st-century-cures-act-interoperability-information-blocking-and-the-onc-health-it-certification'
          description %(
            The ONC certification criteria requires that refresh tokens can be refreshed.  While `refresh_token`
            is optional in the refresh token response in the OAuth 2.0 specification, this test requires that a
            new refresh token is provided that does not match the previous refresh token.

            ```
            An application capable of storing a client secret must be issued a new refresh token valid for a new
            period of no less than three months.
            ```

          )
        end

        omit 'Applies to confidential clients only' unless instance_confidential_client

        skip_if @previous_refresh_token.blank? && @instance.refresh_token.blank?, 'No refresh token was received during the SMART launch'

        assert @previous_refresh_token != @instance.refresh_token, "Refresh response did not provide a new refresh token as required by ONC certification criteria.  Old Refresh Token: `#{@previous_refresh_token}`; New Refresh Token: `#{@instance.refresh_token}`"
      end
    end
  end
end
