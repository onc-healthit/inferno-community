# frozen_string_literal: true

require_relative 'onc_parameters.rb'

module Inferno
  module Sequence
    module SharedONCLaunchTests
      def self.included(klass)
        klass.extend(ClassMethods)
      end

      def required_scopes
        []
      end

      def skip_if_no_access_token
        skip_if @instance.token.blank?, 'No access token was received during the SMART launch'
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

      def after_save_refresh_token(refresh_token)
        # This method is used to save off the refresh token for standalone launch to be used for token
        # revocation later.  We must do this because we are overwriting our standalone refresh/access token
        # with the one used in the ehr launch.
      end

      def after_save_access_token(token)
        # This method is used to save off the access token for standalone launch to be used for token
        # revocation later.  We must do this because we are overwriting our standalone refresh/access token
        # with the one used in the ehr launch.
      end

      def validate_token_response_contents(token_response, require_expires_in:)
        skip_if token_response.blank?, no_token_response_message

        assert_valid_json(token_response.body)
        @token_response_body = JSON.parse(token_response.body)

        @instance.save
        if @token_response_body.key?('id_token') # rubocop:disable Style/IfUnlessModifier
          @instance.update(id_token: @token_response_body['id_token'])
        end

        if @token_response_body.key?('refresh_token')
          @instance.update(refresh_token: @token_response_body['refresh_token'])
          after_save_refresh_token(@token_response_body['refresh_token'])
        end

        assert @token_response_body['access_token'].present?, 'Token response did not contain access_token as required'

        expires_in = @token_response_body['expires_in']
        if expires_in.present? # rubocop:disable Style/IfUnlessModifier
          warning { assert expires_in.is_a?(Numeric), "`expires_in` field is not a number: #{expires_in.inspect}" }
        end

        @instance.update(
          token: @token_response_body['access_token'],
          token_retrieved_at: DateTime.now,
          token_expires_in: expires_in.to_i
        )

        after_save_access_token(@token_response_body['access_token'])

        @instance.patient_id = @token_response_body['patient'] if @token_response_body['patient'].present?
        @instance.update(encounter_id: @token_response_body['encounter']) if @token_response_body['encounter'].present?

        required_keys = ['token_type', 'scope']
        if require_expires_in
          required_keys << 'expires_in'
        else
          warning { assert expires_in.present?, 'Token exchange response did not contain the recommended `expires_in` field' }
        end

        required_keys.each do |key|
          assert @token_response_body[key].present?, "Token response did not contain #{key} as required"
        end

        # case insentitive per https://tools.ietf.org/html/rfc6749#section-5.1
        assert @token_response_body['token_type'].casecmp('bearer').zero?, 'Token type must be Bearer.'

        expected_scopes = instance_scopes.split(' ')
        actual_scopes = @token_response_body['scope'].split(' ')

        warning do
          missing_scopes = expected_scopes - actual_scopes
          assert missing_scopes.empty?, "Token exchange response did not include expected scopes: #{missing_scopes}"
        end

        extra_scopes = actual_scopes - expected_scopes
        assert extra_scopes.empty?, "Token response contained unrequested scopes: #{extra_scopes.join(', ')}"

        warning do
          assert @token_response_body['patient'].present?, 'No patient id provided in token exchange.'
        end

        received_scopes = @token_response_body['scope'] || scopes

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

      def skip_if_auth_failed
        skip_if @params.blank? || @params['error'].present?, oauth_redirect_failed_message
      end

      module ClassMethods
        def auth_endpoint_tls_test(index:)
          test :auth_endpoint_tls do
            metadata do
              id index
              name 'OAuth 2.0 authorize endpoint secured by transport layer security'
              link 'http://www.hl7.org/fhir/smart-app-launch/'
              description %(
                Apps MUST assure that sensitive information (authentication secrets,
                authorization codes, tokens) is transmitted ONLY to authenticated
                servers, over TLS-secured channels.
              )
            end

            @client = FHIR::Client.for_testing_instance(@instance, url_property: url_property)
            @client.set_bearer_token(@instance.token) unless @client.nil? || @instance.nil? || @instance.token.nil?
            @client&.monitor_requests

            omit_if_tls_disabled
            skip_if @instance.oauth_token_endpoint.blank?, %( No OAuth 2.0 token endpoint retrieved.
                                                              This is typically discovered by the client in the CapabilityStatement or Well-known endpoint. )
            assert_tls_1_2 @instance.oauth_authorize_endpoint
            assert_deny_previous_tls @instance.oauth_authorize_endpoint
          end
        end

        def token_endpoint_tls_test(index:)
          test :token_endpoint_tls do
            metadata do
              id index
              name 'OAuth token exchange endpoint secured by transport layer security'
              link 'http://www.hl7.org/fhir/smart-app-launch/'
              description %(
                Apps MUST assure that sensitive information (authentication secrets,
                authorization codes, tokens) is transmitted ONLY to authenticated
                servers, over TLS-secured channels.
              )
            end

            omit_if_tls_disabled
            skip_if @instance.oauth_token_endpoint.blank?, %( No OAuth 2.0 token endpoint retrieved.
                                                              This is typically discovered by the client in the CapabilityStatement or Well-known endpoint. )
            assert_tls_1_2 @instance.oauth_token_endpoint
            assert_deny_previous_tls @instance.oauth_token_endpoint
          end
        end

        def code_and_state_received_test(index:)
          test :code_and_state_received do
            metadata do
              id index
              name 'Inferno client app receives code parameter and correct state parameter from OAuth server at redirect URI'
              link 'http://www.hl7.org/fhir/smart-app-launch/'
              description %(
                Code and state are required querystring parameters. State must be
                the exact value received from the client.
              )
            end

            @client = FHIR::Client.for_testing_instance(@instance, url_property: url_property)
            @client.set_bearer_token(@instance.token) unless @client.nil? || @instance.nil? || @instance.token.nil?
            @client&.monitor_requests

            skip_if @params.blank?, oauth_redirect_failed_message

            assert @params['error'].nil?, auth_server_error_message
            assert @params['state'] == @instance.state, bad_state_error_message
            assert @params['code'].present?, 'Expected code to be submitted in request'
          end
        end

        def invalid_code_test(index:)
          test :invalid_code do
            metadata do
              id index
              name 'OAuth token exchange fails when supplied invalid code'
              link 'https://tools.ietf.org/html/rfc6749'
              description %(
                If the request failed verification or is invalid, the authorization
                server returns an error response.
              )
            end

            skip_if_auth_failed

            oauth2_headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }

            oauth2_params = {
              'grant_type' => 'authorization_code',
              'code' => 'INVALID_CODE',
              'redirect_uri' => @instance.redirect_uris
            }

            if instance_confidential_client
              client_credentials = "#{instance_client_id}:#{instance_client_secret}"
              oauth2_headers['Authorization'] = "Basic #{Base64.strict_encode64(client_credentials)}"
            else
              oauth2_params['client_id'] = instance_client_id
            end

            token_response = LoggedRestClient.post(@instance.oauth_token_endpoint, oauth2_params, oauth2_headers)
            assert_response_bad token_response
          end
        end

        def invalid_client_id_test(index:)
          test :invalid_client_id do
            metadata do
              id index
              name 'OAuth token exchange fails when supplied invalid client ID'
              link 'https://tools.ietf.org/html/rfc6749'
              description %(
                If the request failed verification or is invalid, the authorization
                server returns an error response.
              )
            end

            skip_if_auth_failed

            oauth2_headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }

            oauth2_params = {
              'grant_type' => 'authorization_code',
              'code' => @params['code'],
              'redirect_uri' => @instance.redirect_uris
            }

            client_id = 'INVALID_CLIENT_ID'

            if instance_confidential_client
              client_credentials = "#{client_id}:#{instance_client_secret}"
              oauth2_headers['Authorization'] = "Basic #{Base64.strict_encode64(client_credentials)}"
            else
              oauth2_params['client_id'] = client_id
            end

            token_response = LoggedRestClient.post(@instance.oauth_token_endpoint, oauth2_params, oauth2_headers)
            assert_response_bad_or_unauthorized token_response
          end
        end

        def successful_token_exchange_test(index:)
          test :successful_token_exchange do
            metadata do
              id index
              name 'OAuth token exchange request succeeds when supplied correct information'
              link 'http://www.hl7.org/fhir/smart-app-launch/'
              description %(
                After obtaining an authorization code, the app trades the code for
                an access token via HTTP POST to the EHR authorization server's
                token endpoint URL, using content-type
                application/x-www-form-urlencoded, as described in section [4.1.3 of
                RFC6749](https://tools.ietf.org/html/rfc6749#section-4.1.3).
              )
            end

            skip_if_auth_failed

            oauth2_headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }

            oauth2_params = {
              grant_type: 'authorization_code',
              code: @params['code'],
              redirect_uri: @instance.redirect_uris
            }

            if instance_confidential_client
              client_credentials = "#{instance_client_id}:#{instance_client_secret}"
              oauth2_headers['Authorization'] = "Basic #{Base64.strict_encode64(client_credentials)}"
            else
              oauth2_params[:client_id] = instance_client_id
            end

            @token_response = LoggedRestClient.post(@instance.oauth_token_endpoint, oauth2_params, oauth2_headers)
            assert_response_ok(@token_response)
          end
        end

        def token_response_contents_test(index:, require_expires_in: false)
          test :token_response_contents do
            metadata do
              id index
              name 'OAuth token exchange response body contains required information encoded in JSON'
              link 'http://www.hl7.org/fhir/smart-app-launch/'
              description %(
                The EHR authorization server shall return a JSON structure that
                includes an access token or a message indicating that the
                authorization request has been denied.
                `access_token`, `token_type`, and `scope` are required. `token_type` must
                be Bearer. `expires_in` is required for token refreshes. `scope`
                must be a strict subset of the requested scopes, or empty.
              )
            end

            skip_if_auth_failed

            validate_token_response_contents(@token_response, require_expires_in: require_expires_in)
          end
        end

        def token_response_headers_test(index:)
          test :token_response_headers do
            metadata do
              id index
              name 'OAuth token exchange response includes correct HTTP Cache-Control and Pragma headers'
              link 'http://www.hl7.org/fhir/smart-app-launch/'
              description %(
                The authorization servers response must include the HTTP
                Cache-Control response header field with a value of no-store, as
                well as the Pragma response header field with a value of no-cache.
              )
            end

            skip_if_auth_failed

            skip_if @token_response.blank?, no_token_response_message

            validate_token_response_headers(@token_response)
          end
        end

        def required_scope_test(index:, patient_or_user:)
          test :onc_scopes do
            metadata do
              id index
              name "#{patient_or_user.capitalize}-level access with OpenID Connect and Refresh Token scopes used."
              link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html#quick-start'
              description %(
                The scopes being input must follow the guidelines specified in the smart-app-launch guide.
                All scopes requested are expected to be granted.
              )
            end

            skip_if_auth_failed

            [
              {
                scopes: instance_scopes || '',
                received_or_requested: 'requested'
              },
              {
                scopes: @instance.received_scopes || '',
                received_or_requested: 'received'
              }
            ].each do |metadata|
              scopes = metadata[:scopes].split(' ')
              received_or_requested = metadata[:received_or_requested]

              missing_scopes = required_scopes - scopes
              assert missing_scopes.empty?, "Required scopes were not #{received_or_requested}: #{missing_scopes.join(', ')}"

              scopes -= required_scopes
              # Other 'okay' scopes
              scopes.delete('online_access')

              patient_scope_found = false

              scopes.each do |scope|
                bad_format_message = "#{received_or_requested.capitalize} scope '#{scope}' does not follow the format: #{patient_or_user}/[ resource | * ].[ read | * ]"
                scope_pieces = scope.split('/')

                assert scope_pieces.count == 2, bad_format_message
                assert scope_pieces[0] == patient_or_user, bad_format_message

                resource_access = scope_pieces[1].split('.')
                bad_resource_message = "'#{resource_access[0]}' must be either a valid resource type or '*'"

                assert resource_access.count == 2, bad_format_message
                assert valid_resource_types.include?(resource_access[0]), bad_resource_message
                assert resource_access[1] =~ /^(\*|read)/, bad_format_message

                patient_scope_found = true
              end

              assert patient_scope_found, "#{patient_or_user.capitalize}-level scope in the format: #{patient_or_user}/[ resource | * ].[ read | *] was not #{received_or_requested}."
            end
          end
        end

        def patient_context_test(index:, refresh: false)
          test :patient_context do
            metadata do
              id index
              name 'OAuth token exchange response body contains patient context and patient resource can be retrieved'
              link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html#scopes-for-requesting-context-data'
              description %(
                The `patient` field is a String value with a patient id,
                indicating that the app was launched in the context of this FHIR
                Patient
              )
            end

            if refresh
              skip_if_no_refresh_token
              skip_unless @refresh_successful, 'Token was not successfully refreshed'
            else
              skip_if_auth_failed
            end

            skip_if_no_access_token

            skip_if @instance.patient_id.blank?, 'Token response did not contain `patient` field'

            @client.set_bearer_token(@instance.token)
            patient_read_response = @client.read(versioned_resource_class('Patient'), @instance.patient_id)
            assert_response_ok patient_read_response

            patient = patient_read_response.resource
            assert patient.is_a?(versioned_resource_class('Patient')), 'Expected response to be a Patient resource'
          end
        end

        def encounter_context_test(index:, refresh: false)
          test :encounter_context do
            metadata do
              id index
              name 'Encounter context provided during token exchange and encounter resource can be retrieved'
              link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html#scopes-for-requesting-context-data'
              description %(
                The `encounter` field is a String value with a encounter id,
                indicating that the app was launched in the context of this FHIR
                Encounter
              )
            end

            if refresh
              skip_if_no_refresh_token
              skip_unless @refresh_successful, 'Token was not successfully refreshed'
            else
              skip_if_auth_failed
            end

            skip_if_no_access_token

            skip_if @instance.encounter_id.blank?, 'Token response did not contain `encounter` field'

            @client.set_bearer_token(@instance.token)
            encounter_read_response = @client.read(versioned_resource_class('Encounter'), @instance.encounter_id)
            assert_response_ok encounter_read_response

            encounter = encounter_read_response.resource
            assert encounter.is_a?(versioned_resource_class('Encounter')), 'Expected response to be an Encounter resource'

            encounter_matches_patient = encounter&.subject&.reference&.split('/')&.last == @instance.patient_id
            assert encounter_matches_patient, "Encounter subject (#{encounter&.subject&.reference}) does not match patient id (#{@instance.patient_id})"
          end
        end
      end
    end
  end
end
