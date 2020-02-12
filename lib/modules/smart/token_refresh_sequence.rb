# frozen_string_literal: true

require_relative './shared_launch_tests'

module Inferno
  module Sequence
    class TokenRefreshSequence < SequenceBase
      include SharedLaunchTests

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

      test :invalid_refresh_token do
        metadata do
          id '01'
          name 'Refresh token exchange fails when supplied invalid Refresh Token'
          link 'https://tools.ietf.org/html/rfc6749'
          description %(
            If the request failed verification or is invalid, the authorization server returns an error response.          )
        end

        skip_if_no_refresh_token

        token_response = perform_refresh_request(@instance.client_id, INVALID_REFRESH_TOKEN)
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

        omit 'This test is only applicable to confidential clients.' unless @instance.confidential_client

        skip_if_no_refresh_token

        token_response = perform_refresh_request(INVALID_CLIENT_ID, @instance.refresh_token)
        assert_response_bad_or_unauthorized token_response
      end

      test :refresh_without_scope do
        metadata do
          id '03'
          name 'Server successfully refreshes the access token when optional scope parameter omitted'
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

        token_response = perform_refresh_request(@instance.client_id, @instance.refresh_token, specify_scopes)
        assert_response_ok(token_response)

        validate_and_save_refresh_response(token_response)
        @refresh_successful = true
      end

      test :refresh_with_scope do
        metadata do
          id '04'
          name 'Server successfully refreshes the access token when optional scope parameter provided'
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

        token_response = perform_refresh_request(@instance.client_id, @instance.refresh_token, specify_scopes)
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

        oauth2_headers['Authorization'] = encoded_secret(client_id, @instance.client_secret) if @instance.confidential_client

        oauth2_params['scope'] = @instance.scopes if provide_scope

        LoggedRestClient.post(@instance.oauth_token_endpoint, oauth2_params, oauth2_headers)
      end
    end
  end
end
