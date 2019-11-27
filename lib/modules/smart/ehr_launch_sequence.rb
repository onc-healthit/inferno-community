# frozen_string_literal: true

module Inferno
  module Sequence
    class EHRLaunchSequence < SequenceBase
      title 'EHR Launch Sequence'

      description 'Demonstrate the SMART EHR Launch Sequence.'

      test_id_prefix 'ELS'

      requires :client_id, :confidential_client, :client_secret, :oauth_authorize_endpoint, :oauth_token_endpoint, :scopes, :initiate_login_uri, :redirect_uris

      defines :token, :id_token, :refresh_token, :patient_id

      details %(
        # Background
        The [EHR Launch](http://hl7.org/fhir/smart-app-launch/index.html#ehr-launch-sequence) is one of two ways in which
        an app can be launched, the other being Standalone launch.  In an EHR launch, the app is launched from an existing EHR session
        or portal by a redirect to the registered launch URL.  The EHR provides the app two parameters:

        * `iss` - Which contains the FHIR server url
        * `launch` - An identifier needed for authorization

        # Test Methodology

        Inferno will wait for the EHR server redirect upon execution.  When the redirect is received Inferno will
        check for the presence of the `iss` and `launch` parameters.  The security of the authorization endpoint is then checked
        and authorization is attempted using the provided `launch` identifier.

        For more information on the #{title} see:

        * [SMART EHR Launch Sequence](http://hl7.org/fhir/smart-app-launch/index.html#ehr-launch-sequence)
              )

      NO_TOKEN = 'No valid token'

      test 'EHR server redirects client browser to app launch URI' do
        metadata do
          id '01'
          link 'http://www.hl7.org/fhir/smart-app-launch/'
          description %(
            Client browser sent from EHR server to launch URI of client app as described in SMART EHR Launch Sequence.
          )
        end

        wait_at_endpoint 'launch'
      end

      test 'EHR provides iss and launch parameter to the launch URI via the client browser querystring' do
        metadata do
          id '02'
          link 'http://www.hl7.org/fhir/smart-app-launch/'
          description %(
            The EHR is required to provide a reference to the EHR FHIR endpoint in the iss queystring parameter, and an
            opaque identifier for the launch in the launch querystring parameter.
          )
        end

        assert !@params['iss'].nil?, 'Expecting "iss" as a querystring parameter.'
        assert !@params['launch'].nil?, 'Expecting "launch" as a querystring parameter.'

        warning do
          assert @params['iss'] == @instance.url, "'iss' param [#{@params['iss']}] does not match url of testing instance [#{@instance.url}]"
        end
      end

      test 'OAuth authorize endpoint secured by transport layer security' do
        metadata do
          id '03'
          link 'http://www.hl7.org/fhir/smart-app-launch/'
          description %(
            Apps MUST assure that sensitive information (authentication secrets, authorization codes, tokens) is transmitted ONLY to authenticated servers, over TLS-secured channels.
            opaque identifier for the launch in the launch querystring parameter.
          )
        end

        omit_if_tls_disabled
        assert_tls_1_2 @instance.oauth_authorize_endpoint
        warning do
          assert_deny_previous_tls @instance.oauth_authorize_endpoint
        end
      end

      test 'OAuth server redirects client browser to app redirect URI' do
        metadata do
          id '04'
          link 'http://www.hl7.org/fhir/smart-app-launch/'
          description %(
           Client browser redirected from OAuth server to redirect URI of client app as described in SMART authorization sequence.
          )
        end

        # construct querystring to oauth and redirect after
        @instance.state = SecureRandom.uuid
        @instance.save!

        oauth2_params = {
          'response_type' => 'code',
          'client_id' => @instance.client_id,
          'redirect_uri' => @instance.redirect_uris,
          'scope' => @instance.scopes,
          'launch' => @params['launch'],
          'state' => @instance.state,
          'aud' => @params['iss']
        }

        oauth2_auth_query = @instance.oauth_authorize_endpoint + '?'
        oauth2_params.each do |key, value|
          oauth2_auth_query += "#{key}=#{CGI.escape(value)}&" unless value.nil? || key.nil?
        end

        redirect oauth2_auth_query[0..-2], 'redirect'
      end

      test 'Client app receives code parameter and correct state parameter from OAuth server at redirect URI' do
        metadata do
          id '05'
          link 'http://www.hl7.org/fhir/smart-app-launch/'
          description %(
            Code and state are required querystring parameters. State must be the exact value received from the client.
          )
        end

        assert @params['error'].nil?, "Error returned from authorization server:  code #{@params['error']}, description: #{@params['error_description']}"
        assert @params['state'] == @instance.state, "OAuth server state querystring parameter (#{@params['state']}) did not match state from app #{@instance.state}"
        assert !@params['code'].nil?, 'Expected code to be submitted in request'
      end

      test 'OAuth token exchange endpoint secured by transport layer security' do
        metadata do
          id '06'
          link 'http://www.hl7.org/fhir/smart-app-launch/'
          description %(
            Apps MUST assure that sensitive information (authentication secrets, authorization codes, tokens) is transmitted ONLY to authenticated servers, over TLS-secured channels.
          )
        end

        omit_if_tls_disabled
        assert_tls_1_2 @instance.oauth_token_endpoint
        warning do
          assert_deny_previous_tls @instance.oauth_token_endpoint
        end
      end

      test 'OAuth token exchange fails when supplied invalid Refresh Token or Client ID' do
        metadata do
          id '07'
          link 'https://tools.ietf.org/html/rfc6749'
          description %(
            If the request failed verification or is invalid, the authorization server returns an error response.
          )
        end
        oauth2_params = {
          'grant_type' => 'authorization_code',
          'code' => 'INVALID_CODE',
          'redirect_uri' => @instance.redirect_uris,
          'client_id' => @instance.client_id
        }

        token_response = LoggedRestClient.post(@instance.oauth_token_endpoint, oauth2_params)
        assert_response_bad_or_unauthorized token_response

        oauth2_params = {
          'grant_type' => 'authorization_code',
          'code' => @params['code'],
          'redirect_uri' => @instance.redirect_uris,
          'client_id' => 'INVALID_CLIENT_ID'
        }

        token_response = LoggedRestClient.post(@instance.oauth_token_endpoint, oauth2_params)
        assert_response_bad_or_unauthorized token_response
      end

      test 'OAuth token exchange request succeeds when supplied correct information' do
        metadata do
          id '08'
          link 'http://www.hl7.org/fhir/smart-app-launch/'
          description %(
            After obtaining an authorization code, the app trades the code for an access token via HTTP POST to the
            EHR authorization server's token endpoint URL, using content-type application/x-www-form-urlencoded,
            as described in section [4.1.3 of RFC6749](https://tools.ietf.org/html/rfc6749#section-4.1.3).          )
        end

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
          id '09'
          link 'http://www.hl7.org/fhir/smart-app-launch/'
          description %(
            The EHR authorization server shall return a JSON structure that
            includes an access token or a message indicating that the
            authorization request has been denied.
            access_token, token_type, and scope are required. access_token must be Bearer.
          )
        end

        assert @token_response.present?, NO_TOKEN

        assert_valid_json(@token_response.body)
        @token_response_body = JSON.parse(@token_response.body)

        if @token_response_body.key?('id_token')
          @instance.update(id_token: @token_response_body['id_token'])
        end

        if @token_response_body.key?('refresh_token')
          @instance.update(refresh_token: @token_response_body['refresh_token'])
        end

        assert @token_response_body['access_token'].present?, 'Token response did not contain access_token as required'

        @instance.patient_id = @token_response_body['patient'] if @token_response_body['patient'].present?

        @instance.update(token: @token_response_body['access_token'], token_retrieved_at: DateTime.now)

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

          assert @token_response_body['patient'].present?, 'No patient id provided in token exchange.'
          assert @token_response_body['encounter'].present?, 'No encounter id provided in token exchange.'
        end

        scopes = @token_response_body['scope'] || @instance.scopes

        @instance.update(scopes: scopes)
      end

      test 'Response includes correct HTTP Cache-Control and Pragma headers' do
        metadata do
          id '10'
          link 'http://www.hl7.org/fhir/smart-app-launch/'
          description %(
            The authorization servers response must include the HTTP Cache-Control response header field with a value of no-store, as well as the Pragma response header field with a value of no-cache.
          )
        end

        skip_if @token_response.blank?, NO_TOKEN

        token_response_headers = @token_response.headers

        [:cache_control, :pragma].each do |key|
          assert token_response_headers.key?(key), "Token response headers did not contain #{key} as is required in the SMART App Launch Guide."
        end

        assert token_response_headers[:cache_control].downcase.include?('no-store'), 'Token response header must have cache_control containing no-store.'
        assert token_response_headers[:pragma].downcase.include?('no-cache'), 'Token response header must have pragma containing no-cache.'
      end
    end
  end
end
