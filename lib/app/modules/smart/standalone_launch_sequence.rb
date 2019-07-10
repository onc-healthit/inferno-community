# frozen_string_literal: true

module Inferno
  module Sequence
    class StandaloneLaunchSequence < SequenceBase
      title 'Standalone Launch Sequence'
      description 'Demonstrate the SMART Standalone Launch Sequence.'
      test_id_prefix 'SLS'

      requires :client_id, :confidential_client, :client_secret, :oauth_authorize_endpoint, :oauth_token_endpoint, :scopes, :redirect_uris
      defines :token, :id_token, :refresh_token, :patient_id

      details %(
        # Background

        The [Standalone Launch](http://hl7.org/fhir/smart-app-launch/#standalone-launch-sequence) Sequence allows an app,
        like Inferno, to be launched independent of an existing EHR session.  It is one of the two launch methods described in
        the SMART App Launch Framework alongside EHR Launch.  The app will request authorization for the provided scope from the
        authorization endpoint, ultimately receiving an authorization token which can be used to gain access to resources
        on the FHIR server.

        # Test Methodology

        Inferno will redirect the user to the the authorization endpoint so that they may provide any required credentials
        and authorize the application.  Upon successful authorization, Inferno will exchange the authorization code provided
        for an access token.

        For more information on the #{title}:

        * [Standalone Launch Sequence](http://hl7.org/fhir/smart-app-launch/#standalone-launch-sequence)

              )

      preconditions 'Client must be registered' do
        !@instance.client_id.nil?
      end

      OAUTH_REDIRECT_FAILED = "Redirect to OAuth server failed"
      NO_TOKEN = "No valid token"

      test 'OAuth 2.0 authorize endpoint secured by transport layer security' do
        metadata do
          id '01'
          link 'http://www.hl7.org/fhir/smart-app-launch/'
          desc %(
            The client registration endpoint MUST be protected by a transport layer security.
          )
        end

        skip_if_tls_disabled
        assert_tls_1_2 @instance.oauth_authorize_endpoint
        warning do
          assert_deny_previous_tls @instance.oauth_authorize_endpoint
        end
      end

      test 'OAuth server redirects client browser to app redirect URI' do
        metadata do
          id '02'
          link 'http://www.hl7.org/fhir/smart-app-launch/'
          desc %(
            Client browser redirected from OAuth server to redirect URI of client app as described in SMART authorization sequence.
          )
        end

        @instance.state = SecureRandom.uuid
        @instance.save!

        oauth2_params = {
          'response_type' => 'code',
          'client_id' => @instance.client_id,
          'redirect_uri' => @instance.redirect_uris,
          'scope' => @instance.scopes,
          'state' => @instance.state,
          'aud' => @instance.url
        }


        oauth_authorize_endpoint = @instance.oauth_authorize_endpoint

        # Confirm that oauth2_auth_endpoint is valid before moving forward
        assert_is_valid_uri oauth_authorize_endpoint

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

      test 'Client app receives code parameter and correct state parameter from OAuth server at redirect URI' do
        metadata do
          id '03'
          link 'http://www.hl7.org/fhir/smart-app-launch/'
          desc %(
            Code and state are required querystring parameters. State must be the exact value received from the client.
          )
        end

        # Confirm that there is a @params object from the redirect 
        assert !@params.nil?, OAUTH_REDIRECT_FAILED 

        assert @params['error'].nil?, "Error returned from authorization server:  code #{@params['error']}, description: #{@params['error_description']}"
        assert @params['state'] == @instance.state, "OAuth server state querystring parameter (#{@params['state']}) did not match state from app #{@instance.state}"
        assert !@params['code'].nil?, 'Expected code to be submitted in request'
      end

      test 'OAuth token exchange endpoint secured by transport layer security' do
        metadata do
          id '04'
          link 'http://www.hl7.org/fhir/smart-app-launch/'
          desc %(
            Apps must assure that sensitive information (authentication secrets, authorization codes, tokens) is transmitted ONLY to authenticated servers, over TLS-secured channels.
          )
        end

        skip_if_tls_disabled
        assert_tls_1_2 @instance.oauth_token_endpoint
        warning do
          assert_deny_previous_tls @instance.oauth_token_endpoint
        end
      end

      test 'OAuth token exchange fails when supplied invalid Refresh Token or Client ID' do
        metadata do
          id '05'
          link 'https://tools.ietf.org/html/rfc6749'
          desc %(
            If the request failed verification or is invalid, the authorization server returns an error response.
          )
        end

        headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }

        oauth2_params = {
          'grant_type' => 'authorization_code',
          'code' => 'INVALID_CODE',
          'redirect_uri' => @instance.redirect_uris,
          'client_id' => @instance.client_id
        }

        token_response = LoggedRestClient.post(@instance.oauth_token_endpoint, oauth2_params.to_json, headers)
        assert_response_bad_or_unauthorized token_response

        # Confirm that there is a @params object from the redirect 
        assert !@params.nil?, OAUTH_REDIRECT_FAILED 


        oauth2_params = {
          'grant_type' => 'authorization_code',
          'code' => @params['code'],
          'redirect_uri' => @instance.redirect_uris,
          'client_id' => 'INVALID_CLIENT_ID'
        }

        token_response = LoggedRestClient.post(@instance.oauth_token_endpoint, oauth2_params.to_json, headers)
        assert_response_bad_or_unauthorized token_response
      end

      test 'OAuth token exchange request succeeds when supplied correct information' do
        metadata do
          id '06'
          link 'http://www.hl7.org/fhir/smart-app-launch/'
          desc %(
            After obtaining an authorization code, the app trades the code for an access token via HTTP POST to the EHR authorization server's token endpoint URL, using content-type application/x-www-form-urlencoded, as described in section 4.1.3 of RFC6749.
          )
        end

        # Confirm that there is a @params object from the redirect 
        assert !@params.nil?, OAUTH_REDIRECT_FAILED 

        oauth2_params = {
          'grant_type' => 'authorization_code',
          'code' => @params['code'],
          'redirect_uri' => @instance.redirect_uris
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

      test 'Data returned from token exchange contains required information encoded in JSON' do
        metadata do
          id '07'
          link 'http://www.hl7.org/fhir/smart-app-launch/'
          desc %(
            The EHR authorization server shall return a JSON structure that includes an access token or a message indicating that the authorization request has been denied.
            access_token, token_type, and scope are required. access_token must be Bearer.
          )
        end

        # Confirm that there is valid token 
        assert !@token_response.nil?, NO_TOKEN 

        @token_response_headers = @token_response.headers
        assert_valid_json(@token_response.body)
        @token_response_body = JSON.parse(@token_response.body)

        if @token_response_body.key?('id_token')
          @instance.save!
          @instance.update(id_token: @token_response_body['id_token'])
        end

        if @token_response_body.key?('refresh_token')
          @instance.save!
          @instance.update(refresh_token: @token_response_body['refresh_token'])
        end

        assert @token_response_body.key?('access_token'), 'Token response did not contain access_token as required'

        token_retrieved_at = DateTime.now

        @instance.resource_references.each(&:destroy)
        @instance.resource_references << Inferno::Models::ResourceReference.new(resource_type: 'Patient', resource_id: @token_response_body['patient']) if @token_response_body.key?('patient')

        @instance.save!

        @instance.update(token: @token_response_body['access_token'], token_retrieved_at: token_retrieved_at)

        ['token_type', 'scope'].each do |key|
          assert @token_response_body.key?(key), "Token response did not contain #{key} as required"
        end

        # case insentitive per https://tools.ietf.org/html/rfc6749#section-5.1
        assert @token_response_body['token_type'].casecmp('bearer').zero?, 'Token type must be Bearer.'

        expected_scopes = @instance.scopes.split(' ')
        actual_scopes = @token_response_body['scope'].split(' ')

        warning do
          missing_scopes = (expected_scopes - actual_scopes)
          assert missing_scopes.empty?, "Token exchange response did not include expected scopes: #{missing_scopes}"

          assert @token_response_body.key?('patient'), 'No patient id provided in token exchange.'
        end

        scopes = @token_response_body['scope'] || @instance.scopes

        @instance.save!
        @instance.update(scopes: scopes)
      end

      test 'Response includes correct HTTP Cache-Control and Pragma headers' do
        metadata do
          id '08'
          link 'http://www.hl7.org/fhir/smart-app-launch/'
          desc %(
            The authorization servers response must include the HTTP Cache-Control response header field with a value of no-store, as well as the Pragma response header field with a value of no-cache.
          )
        end

        # Confirm that there is valid token 
        assert !@token_response.nil?, NO_TOKEN 

        [:cache_control, :pragma].each do |key|
          assert @token_response_headers.key?(key), "Token response headers did not contain #{key} as is required in the SMART App Launch Guide."
        end

        assert @token_response_headers[:cache_control].downcase.include?('no-store'), 'Token response header must have cache_control containing no-store.'
        assert @token_response_headers[:pragma].downcase.include?('no-cache'), 'Token response header must have pragma containing no-cache.'
      end
    end
  end
end
