# frozen_string_literal: true

module Inferno
  module Sequence
    module SharedLaunchTests
      def self.included(klass)
        klass.extend(ClassMethods)
      end

      def oauth_redirect_failed_message
        'Redirect to OAuth server failed'
      end

      def no_token_response_message
        'No token response received'
      end

      def auth_server_error_message
        "Error returned from authorization server: code #{@params['error']}, description: #{@params['error_description']}"
      end

      def bad_state_error_message
        "State provided in redirect (#{@params[:state]}) does not match expected state (#{@instance.state})."
      end

      def validate_token_response_contents(token_response)
        assert token_response.present?, no_token_response_message

        assert_valid_json(token_response.body)
        token_response_body = JSON.parse(token_response.body)

        @instance.save
        if token_response_body.key?('id_token') # rubocop:disable Style/IfUnlessModifier
          @instance.update(id_token: token_response_body['id_token'])
        end

        if token_response_body.key?('refresh_token') # rubocop:disable Style/IfUnlessModifier
          @instance.update(refresh_token: token_response_body['refresh_token'])
        end

        assert token_response_body['access_token'].present?, 'Token response did not contain access_token as required'

        @instance.update(token: token_response_body['access_token'], token_retrieved_at: DateTime.now)

        @instance.patient_id = token_response_body['patient'] if token_response_body['patient'].present?

        ['token_type', 'scope'].each do |key|
          assert token_response_body[key].present?, "Token response did not contain #{key} as required"
        end

        # case insentitive per https://tools.ietf.org/html/rfc6749#section-5.1
        assert token_response_body['token_type'].casecmp('bearer').zero?, 'Token type must be Bearer.'

        expected_scopes = @instance.scopes.split(' ')
        actual_scopes = token_response_body['scope'].split(' ')

        warning do
          missing_scopes = (expected_scopes - actual_scopes)
          assert missing_scopes.empty?, "Token exchange response did not include expected scopes: #{missing_scopes}"
        end

        warning do
          assert token_response_body['patient'].present?, 'No patient id provided in token exchange.'
        end

        warning do
          assert token_response_body['encounter'].present?, 'No encounter id provided in token exchange.'
        end

        received_scopes = token_response_body['scope'] || @instance.scopes

        @instance.update(received_scopes: received_scopes)
      end

      def validate_token_response_headers(token_response)
        token_response_headers = token_response.headers

        [:cache_control, :pragma].each do |key|
          assert token_response_headers.key?(key), "Token response headers did not contain #{key} as is required in the SMART App Launch Guide."
        end

        assert token_response_headers[:cache_control].downcase.include?('no-store'), 'Token response header must have cache_control containing no-store.'
        assert token_response_headers[:pragma].downcase.include?('no-cache'), 'Token response header must have pragma containing no-cache.'
      end

      module ClassMethods
        def auth_endpoint_tls_test(index:)
          test 'OAuth 2.0 authorize endpoint secured by transport layer security' do
            metadata do
              id index
              link 'http://www.hl7.org/fhir/smart-app-launch/'
              description %(
                Apps MUST assure that sensitive information (authentication secrets,
                authorization codes, tokens) is transmitted ONLY to authenticated
                servers, over TLS-secured channels.
              )
            end

            omit_if_tls_disabled
            assert_tls_1_2 @instance.oauth_authorize_endpoint
            warning do
              assert_deny_previous_tls @instance.oauth_authorize_endpoint
            end
          end
        end

        def token_endpoint_tls_test(index:)
          test 'OAuth token exchange endpoint secured by transport layer security' do
            metadata do
              id index
              link 'http://www.hl7.org/fhir/smart-app-launch/'
              description %(
                Apps MUST assure that sensitive information (authentication secrets,
                authorization codes, tokens) is transmitted ONLY to authenticated
                servers, over TLS-secured channels.
              )
            end

            omit_if_tls_disabled
            assert_tls_1_2 @instance.oauth_token_endpoint
            warning do
              assert_deny_previous_tls @instance.oauth_token_endpoint
            end
          end
        end

        def code_and_state_received_test(index:)
          test 'Client app receives code parameter and correct state parameter from OAuth server at redirect URI' do
            metadata do
              id index
              link 'http://www.hl7.org/fhir/smart-app-launch/'
              description %(
                Code and state are required querystring parameters. State must be
                the exact value received from the client.
              )
            end

            skip_if @params.blank?, oauth_redirect_failed_message

            assert @params['error'].nil?, auth_server_error_message
            assert @params['state'] == @instance.state, bad_state_error_message
            assert @params['code'].present?, 'Expected code to be submitted in request'
          end
        end

        def invalid_code_test(index:)
          test 'OAuth token exchange fails when supplied invalid code' do
            metadata do
              id index
              link 'https://tools.ietf.org/html/rfc6749'
              description %(
                If the request failed verification or is invalid, the authorization
                server returns an error response.
              )
            end

            skip_if @params.blank?, oauth_redirect_failed_message

            headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }

            oauth2_params = {
              'grant_type' => 'authorization_code',
              'code' => 'INVALID_CODE',
              'redirect_uri' => @instance.redirect_uris,
              'client_id' => @instance.client_id
            }

            token_response = LoggedRestClient.post(@instance.oauth_token_endpoint, oauth2_params.to_json, headers)
            assert_response_bad token_response
          end
        end

        def invalid_client_id_test(index:)
          test 'OAuth token exchange fails when supplied invalid client ID' do
            metadata do
              id index
              link 'https://tools.ietf.org/html/rfc6749'
              description %(
                If the request failed verification or is invalid, the authorization
                server returns an error response.
              )
            end

            skip_if @params.blank?, oauth_redirect_failed_message

            headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }

            oauth2_params = {
              'grant_type' => 'authorization_code',
              'code' => @params['code'],
              'redirect_uri' => @instance.redirect_uris,
              'client_id' => 'INVALID_CLIENT_ID'
            }

            token_response = LoggedRestClient.post(@instance.oauth_token_endpoint, oauth2_params.to_json, headers)
            assert_response_bad_or_unauthorized token_response
          end
        end

        def successful_token_exchange_test(index:)
          test 'OAuth token exchange request succeeds when supplied correct information' do
            metadata do
              id index
              link 'http://www.hl7.org/fhir/smart-app-launch/'
              description %(
                After obtaining an authorization code, the app trades the code for
                an access token via HTTP POST to the EHR authorization server's
                token endpoint URL, using content-type
                application/x-www-form-urlencoded, as described in section [4.1.3 of
                RFC6749](https://tools.ietf.org/html/rfc6749#section-4.1.3).
              )
            end

            skip_if @params.blank?, oauth_redirect_failed_message

            oauth2_headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }

            oauth2_params = {
              'grant_type' => 'authorization_code',
              'code' => @params['code'],
              'redirect_uri' => @instance.redirect_uris
            }

            if @instance.confidential_client
              client_credentials = "#{@instance.client_id}:#{@instance.client_secret}"
              oauth2_headers['Authorization'] = "Basic #{Base64.strict_encode64(client_credentials)}"
            else
              oauth2_params['client_id'] = @instance.client_id
            end

            @token_response = LoggedRestClient.post(@instance.oauth_token_endpoint, oauth2_params, oauth2_headers)
            assert_response_ok(@token_response)
          end
        end

        def token_exchange_response_contents_test(index:)
          test 'Token exchange response contains required information encoded in JSON' do
            metadata do
              id index
              link 'http://www.hl7.org/fhir/smart-app-launch/'
              description %(
                The EHR authorization server shall return a JSON structure that
                includes an access token or a message indicating that the
                authorization request has been denied.
                access_token, token_type, and scope are required. access_token must
                be Bearer.
              )
            end

            validate_token_response_contents(@token_response)
          end
        end

        def token_exchange_response_headers_test(index:)
          test 'Response includes correct HTTP Cache-Control and Pragma headers' do
            metadata do
              id index
              link 'http://www.hl7.org/fhir/smart-app-launch/'
              description %(
                The authorization servers response must include the HTTP
                Cache-Control response header field with a value of no-store, as
                well as the Pragma response header field with a value of no-cache.
              )
            end

            skip_if @token_response.blank?, no_token_response_message

            validate_token_response_headers(@token_response)
          end
        end
      end
    end
  end
end
