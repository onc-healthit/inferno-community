module Inferno
  module Sequence
    class TokenIntrospectionSequence < SequenceBase

      inactive

      title 'OAuth 2.0 Token Introspection'

      description 'Verify token properties using token introspection at the authorization server.'

      test_id_prefix 'TI'

      optional

      test 'OAuth token introspection endpoint secured by transport layer security' do

        metadata {
          id '01'
          link 'https://tools.ietf.org/html/rfc7662'
          optional
          desc %(
            The server MUST support Transport Layer Security (TLS) 1.2.
          )
        }

        skip 'TLS tests have been disabled by configuration.' if @disable_tls_tests
        assert_tls_1_2 @instance.oauth_introspection_endpoint
        warning {
          assert_deny_previous_tls @instance.oauth_introspection_endpoint
        }
      end

      test 'Token introspection endpoint responds properly to introspection request for access token' do

        metadata {
          id '02'
          link 'https://tools.ietf.org/html/rfc7662'
          desc %(
            A resource server is capable of calling the introspection endpoint.
          )
        }

        headers = { 'Accept' => 'application/json', 'Content-type' => 'application/x-www-form-urlencoded' }

        params = {
            'token' => @instance.introspect_token,
            'client_id' => @instance.resource_id,
            'client_secret' => @instance.resource_secret
        }

        @introspection_response = LoggedRestClient.post(@instance.oauth_introspection_endpoint, params, headers)

        assert !@introspection_response.nil?, 'No introspection response'
        assert_response_ok(@introspection_response)
        @introspection_response_body = JSON.parse(@introspection_response.body)
        assert !@introspection_response_body.nil?, 'No introspection response body'

        FHIR.logger.debug "Introspection response: #{@introspection_response}"

        assert !(@introspection_response['error'] || @introspection_response['error_description']), 'Got an error from the introspection endpoint'

      end

      test 'Token introspection response confirms that Access token is active' do

        metadata {
          id '03'
          link 'https://tools.ietf.org/html/rfc7662'
          desc %(
            A current access token is listed as active.
          )
        }

        assert !@introspection_response_body.nil?, 'No introspection response body'

        active = @introspection_response_body['active']

        assert active, 'Token is not active, try the test again with a valid Access token'
      end

      test 'Scopes returned by token introspection request match expected scopes' do

        metadata {
          id '04'
          link 'https://tools.ietf.org/html/rfc7662'
          optional
          desc %(
            The scopes we received alongside the Access token match those from the introspection response.
          )
        }

        assert !@introspection_response_body.nil?, 'No introspection response body'

        expected_scopes = @instance.scopes.split(' ')
        actual_scopes = @introspection_response_body['scope'].split(' ')


        FHIR.logger.debug "Introspection: Expected scopes #{expected_scopes}, Actual scopes #{actual_scopes}"

        missing_scopes = (expected_scopes - actual_scopes)
        assert missing_scopes.empty?, "Introspection response did not include expected scopes: #{missing_scopes}"
        extra_scopes = (actual_scopes - expected_scopes)

        assert extra_scopes.empty?, "Introspection response included additional scopes: #{extra_scopes}"

      end

      # TODO verify timeout requirements
      test 'Token introspection response confirms Access token has appropriate lifetime' do

        metadata {
          id '05'
          link 'https://tools.ietf.org/html/rfc7662'
          desc %(
            The Access token should have a lifetime of at least 60 minutes.
          )
        }

        assert !@introspection_response_body.nil?, 'No introspection response body'

        expiration = Time.at(@introspection_response_body['exp']).to_datetime

        token_retrieved_at = @instance.token_retrieved_at
        now = DateTime.now

        max_token_seconds = 60 * 60 # one hour expiration?
        clock_slip = 5 # a few seconds of clock skew allowed

        assert (expiration - token_retrieved_at) < max_token_seconds, "Access token does not have adequate lifetime of at least #{max_token_seconds} seconds"

        assert (now + Rational(clock_slip, (24 * 60 * 60))) < expiration, "Access token has expired"

      end

      test 'Token introspection endpoint responds properly to introspection request for refresh token' do

        metadata {
          id '06'
          link 'https://tools.ietf.org/html/rfc7662'
          optional
          desc %(
            A resource server is capable of calling the introspection endpoint.
          )
        }

        assert !@instance.introspect_refresh_token.blank?, 'Refresh Token not supplied'

        headers = { 'Accept' => 'application/json', 'Content-type' => 'application/x-www-form-urlencoded' }

        params = {
            'token' => @instance.introspect_refresh_token,
            'client_id' => @instance.resource_id,
            'client_secret' => @instance.resource_secret
        }

        @introspection_response = LoggedRestClient.post(@instance.oauth_introspection_endpoint, params, headers)

        assert !@introspection_response.nil?, 'No refresh token introspection response'
        assert_response_ok(@introspection_response)
        @introspection_response_body = JSON.parse(@introspection_response.body)
        assert !@introspection_response_body.nil?, 'No refresh token introspection response body'

        FHIR.logger.debug "Refresh Token Introspection response: #{@introspection_response}"

        assert !(@introspection_response['error'] || @introspection_response['error_description']), 'Got an error from the introspection endpoint'

      end

      test 'Token introspection response confirms that Refresh token is active' do

        metadata {
          id '06'
          link 'https://tools.ietf.org/html/rfc7662'
          optional
          desc %(
            A current access token is listed as active.
          )
        }

        assert !@instance.introspect_refresh_token.blank?, 'Refresh Token not supplied'

        assert !@introspection_response_body.nil?, 'No introspection response body'

        active = @introspection_response_body['active']

        assert active, 'Refresh Token is not active, try the test again with a valid token'
      end

    end

  end
end
