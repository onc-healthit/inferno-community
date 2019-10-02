# frozen_string_literal: true

module Inferno
  module Sequence
    class TokenRefreshSequence < SequenceBase
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

      def encoded_secret(client_id, client_secret)
        "Basic #{Base64.strict_encode64(client_id + ':' + client_secret)}"
      end

      def perform_refresh_request(client_id, refresh_token, provide_scope = false)
        oauth2_params = {
          'grant_type' => 'refresh_token',
          'refresh_token' => refresh_token
        }
        oauth2_headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }

        if @instance.confidential_client
          oauth2_headers['Authorization'] = encoded_secret(client_id, @instance.client_secret)
        else
          oauth2_params['client_id'] = client_id
        end

        oauth2_params['scope'] = @instance.scopes if provide_scope

        LoggedRestClient.post(@instance.oauth_token_endpoint, oauth2_params, oauth2_headers)
      end

      INVALID_REFRESH_TOKEN_TEST = 'Refresh token exchange fails when provided invalid Refresh Token.'
      test INVALID_REFRESH_TOKEN_TEST do
        metadata do
          id '01'
          link 'https://tools.ietf.org/html/rfc6749'
          description %(
            If the request failed verification or is invalid, the authorization server returns an error response.          )
        end

        token_response = perform_refresh_request(@instance.client_id, INVALID_REFRESH_TOKEN)
        assert_response_bad_or_unauthorized token_response
      end

      INVALID_CLIENT_ID_TEST = 'Refresh token exchange fails when provided invalid Client ID.'
      test INVALID_CLIENT_ID_TEST do
        metadata do
          id '02'
          link 'https://tools.ietf.org/html/rfc6749'
          description %(
            If the request failed verification or is invalid, the authorization server returns an error response.          )
        end

        token_response = perform_refresh_request(INVALID_CLIENT_ID, @instance.refresh_token)
        assert_response_bad_or_unauthorized token_response
      end

      def validate_and_save_refresh_response(token_response)
        assert_response_ok(token_response)
        assert_valid_json(token_response.body)
        token_response_body = JSON.parse(token_response.body)

        # The minimum we need to 'progress' is the access token,
        # so first just check and save access token, before validating rest of payload.
        # This is done to make things easier for developers.

        assert token_response_body.key?('access_token'), 'Token response did not contain access_token as required'

        token_retrieved_at = DateTime.now

        @instance.resource_references.each(&:destroy)
        @instance.resource_references << Inferno::Models::ResourceReference.new(resource_type: 'Patient', resource_id: token_response_body['patient']) if token_response_body.key?('patient')

        @instance.save!

        @instance.update(token: token_response_body['access_token'], token_retrieved_at: token_retrieved_at)

        ['expires_in', 'token_type', 'scope'].each do |key|
          assert token_response_body.key?(key), "Token response did not contain #{key} as required"
        end

        # case insentitive per https://tools.ietf.org/html/rfc6749#section-5.1
        assert token_response_body['token_type'].casecmp('bearer').zero?, 'Token type must be Bearer.'

        expected_scopes = @instance.scopes.split(' ')
        actual_scopes = token_response_body['scope'].split(' ')

        warning do
          missing_scopes = (expected_scopes - actual_scopes)
          assert missing_scopes.empty?, "Token exchange response did not include expected scopes: #{missing_scopes}"

          assert token_response_body.key?('patient'), 'No patient id provided in token exchange.'
        end

        scopes = token_response_body['scope'] || @instance.scopes

        @instance.save!
        @instance.update(scopes: scopes)

        if token_response_body.key?('id_token')
          @instance.save!
          @instance.update(id_token: token_response_body['id_token'])
        end

        if token_response_body.key?('refresh_token')
          @instance.save!
          @instance.update(refresh_token: token_response_body['refresh_token'])
        end

        warning do
          # These should be required but due to a gap in the SMART App Launch Guide they are not currently required
          # See https://github.com/HL7/smart-app-launch/issues/293
          [:cache_control, :pragma].each do |key|
            assert token_response.headers.key?(key), "Token response headers did not contain #{key} as is recommended for token exchanges."
          end

          assert token_response.headers[:cache_control].downcase.include?('no-store'), 'Token response header should have cache_control containing no-store.'
          assert token_response.headers[:pragma].downcase.include?('no-cache'), 'Token response header should have pragma containing no-cache.'
        end
      end

      REFRESH_WITHOUT_SCOPE_PARAMETER_TEST =
        'Server successfully refreshes the access token when optional scope parameter omitted.'
      test REFRESH_WITHOUT_SCOPE_PARAMETER_TEST do
        metadata do
          id '03'
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

        specify_scopes = false

        token_response = perform_refresh_request(@instance.client_id, @instance.refresh_token, specify_scopes)
        validate_and_save_refresh_response(token_response)
      end

      REFRESH_WITH_SCOPE_PARAMETER_TEST =
        'Server successfully refreshes the access token when optional scope parameter provided.'
      test REFRESH_WITH_SCOPE_PARAMETER_TEST do
        metadata do
          id '04'
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

        specify_scopes = true

        token_response = perform_refresh_request(@instance.client_id, @instance.refresh_token, specify_scopes)
        validate_and_save_refresh_response(token_response)
      end
    end
  end
end
