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

      # Test Methodology

      Inferno will attempt to exchange the refresh token for a new access token and verify that the information returned
      contains the required fields and uses the proper headers.

      For more information see:

      * [The OAuth 2.0 Authorization Framework](https://tools.ietf.org/html/rfc6749)
      * [Using a refresh token to obtain a new access token](http://hl7.org/fhir/smart-app-launch/#step-5-later-app-uses-a-refresh-token-to-obtain-a-new-access-token)
              )

      test 'Refresh token exchange fails when supplied invalid Refresh Token or Client ID.' do

        metadata {
          id '01'
          link 'https://tools.ietf.org/html/rfc6749'
          desc %(
            If the request failed verification or is invalid, the authorization server returns an error response.          )
        }

        oauth2_params = {
            'grant_type' => 'refresh_token',
            'refresh_token' => 'INVALID REFRESH TOKEN',
            'client_id' => @instance.client_id
        }

        token_response = LoggedRestClient.post(@instance.oauth_token_endpoint, oauth2_params)
        assert_response_bad_or_unauthorized token_response

        oauth2_params = {
            'grant_type' => 'refresh_token',
            'refresh_token' => @instance.refresh_token,
            'client_id' => 'INVALID_CLIENT_ID'
        }

        token_response = LoggedRestClient.post(@instance.oauth_token_endpoint, oauth2_params)
        assert_response_bad_or_unauthorized token_response

      end

      test 'Server successfully exchanges refresh token at OAuth token endpoint.' do

        metadata {
          id '02'
          link 'https://tools.ietf.org/html/rfc6749'
          desc %(
            Server successfully exchanges refresh token at OAuth token endpoint.
          )
        }

        oauth2_params = {
            'grant_type' => 'refresh_token',
            'refresh_token' => @instance.refresh_token,
        }
        oauth2_headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }

        if @instance.confidential_client
          oauth2_headers['Authorization'] = "Basic #{Base64.strict_encode64(@instance.client_id +
                                                                                ':' +
                                                                                @instance.client_secret)}"
        else
          oauth2_params['client_id'] = @instance.client_id
        end

        @token_response = LoggedRestClient.post(@instance.oauth_token_endpoint, oauth2_params, oauth2_headers)
        assert_response_ok(@token_response)

      end

      test 'Data returned from refresh token exchange contains required information encoded in JSON.' do

        metadata {
          id '03'
          link 'http://www.hl7.org/fhir/smart-app-launch/'
          desc %(
           The EHR authorization server SHALL return a JSON structure that includes an access token or a message indicating that the authorization request has been denied.
           access_token, token_type, and scope are required. access_token must be Bearer.
          )
        }

        @token_response_headers = @token_response.headers
        @token_response_body = JSON.parse(@token_response.body)

        assert @token_response_body.has_key?('access_token'), "Token response did not contain access_token as required"

        token_retrieved_at = DateTime.now

        @instance.resource_references.each(&:destroy)
        @instance.resource_references << Inferno::Models::ResourceReference.new({resource_type: 'Patient', resource_id: @token_response_body['patient']}) if @token_response_body.key?('patient')

        @instance.save!

        @instance.update(token: @token_response_body['access_token'], token_retrieved_at: token_retrieved_at)

        ['token_type', 'scope'].each do |key|
          assert @token_response_body.has_key?(key), "Token response did not contain #{key} as required"
        end

        #case insentitive per https://tools.ietf.org/html/rfc6749#section-5.1
        assert @token_response_body['token_type'].downcase == 'bearer', 'Token type must be Bearer.'

        expected_scopes = @instance.scopes.split(' ')
        actual_scopes = @token_response_body['scope'].split(' ')

        warning {
          missing_scopes = (expected_scopes - actual_scopes)
          assert missing_scopes.empty?, "Token exchange response did not include expected scopes: #{missing_scopes}"

          assert @token_response_body.has_key?('patient'), 'No patient id provided in token exchange.'
        }

        scopes = @token_response_body['scope'] || @instance.scopes

        @instance.save!
        @instance.update(scopes: scopes)

        if @token_response_body.has_key?('id_token')
          @instance.save!
          @instance.update(id_token: @token_response_body['id_token'])
        end

        if @token_response_body.has_key?('refresh_token')
          @instance.save!
          @instance.update(refresh_token: @token_response_body['refresh_token'])
        end

      end

      test 'Response includes correct HTTP Cache-Control and Pragma headers' do

        metadata {
          id '04'
          link 'http://www.hl7.org/fhir/smart-app-launch/'
          desc %(
            The authorization servers response must include the HTTP Cache-Control response header field with a value of no-store, as well as the Pragma response header field with a value of no-cache.
          )
        }

        [:cache_control, :pragma].each do |key|
          assert @token_response_headers.has_key?(key), "Token response headers did not contain #{key} as is required in the SMART App Launch Guide."
        end

        assert @token_response_headers[:cache_control].downcase.include?('no-store'), 'Token response header must have cache_control containing no-store.'
        assert @token_response_headers[:pragma].downcase.include?('no-cache'), 'Token response header must have pragma containing no-cache.'
      end

    end

  end
end
