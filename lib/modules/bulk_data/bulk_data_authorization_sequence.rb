# frozen_string_literal: true

module Inferno
  module Sequence
    class BulkDataAuthorizationSequence < SequenceBase
      title 'Bulk Data Authentication'

      test_id_prefix 'BDA'

      requires :client_id, :bulk_private_key, :oauth_token_endpoint

      description 'Test Bulk Data Authorization Token Endpoint'

      def authorize
        id_token = JSON::JWT.new(
          iss: @instance.client_id,
          sub: @instance.client_id,
          aud: @instance.oauth_token_endpoint,
          exp: 1.hour.from_now,
          jti: SecureRandom.hex(32)
        )

        jwk = JSON::JWK.new(JSON.parse(@instance.bulk_private_key))

        id_token.header[:kid] = jwk['kid']
        private_key = jwk.to_key
        client_assertion = id_token.sign(private_key, 'RS384')

        payload =
          {
            'scope' => 'system/*.read',
            'grant_type' => 'client_credentials',
            'client_assertion_type' => 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
            'client_assertion' => client_assertion.to_s
          }

        header =
          {
            content_type: 'application/x-www-form-urlencoded',
            accept: 'application/json'
          }

        uri = Addressable::URI.new
        uri.query_values = payload

        response = LoggedRestClient.post(@instance.oauth_token_endpoint, uri.query, header)
        response
      end

      test :return_access_token do
        metadata do
          id '01'
          name 'Bulk Data Token Endpoint shall return access token'
          link 'https://build.fhir.org/ig/HL7/bulk-data/authorization/index.html#issuing-access-tokens'
          description %(
            With valid token request from Bulk Data client, Token endpoint shall return access token.
          )
        end

        response = authorize

        assert_response_ok(response)
        @access_token = response.body['access_token']
        assert !@access_token.nil?, 'access_token is empty'
      end
    end
  end
end
