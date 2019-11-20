# frozen_string_literal: true

module Inferno
  module Sequence
    class BulkDataAuthorizationSequence < SequenceBase
      title 'Bulk Data Authentication'

      test_id_prefix 'BDA'

      requires :client_id, :bulk_private_key, :oauth_token_endpoint

      description 'Test Bulk Data Authorization Token Endpoint'

      def authorize(content_type: 'application/x-www-form-urlencoded',
                    scope: 'system/*.read',
                    grant_type: 'client_credentials')
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
            'scope' => scope,
            'grant_type' => grant_type,
            'client_assertion_type' => 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
            'client_assertion' => client_assertion.to_s
          }

        header =
          {
            content_type: content_type,
            accept: 'application/json'
          }

        uri = Addressable::URI.new
        uri.query_values = payload

        response = LoggedRestClient.post(@instance.oauth_token_endpoint, uri.query, header)
        response
      end

      test :require_content_type do
        metadata do
          id '01'
          name 'Bulk Data authorization request shall use content_type "application/x-www-form-urlencoded"'
          link 'https://build.fhir.org/ig/HL7/bulk-data/authorization/index.html#protocol-details'
          description %(
            After generating an authentication JWT, the client requests a new access token via HTTP POST to the FHIR authorization server’s token endpoint URL, using content-type application/x-www-form-urlencoded
          )
        end

        response = authorize(content_type: 'application/json')
        assert_response_bad_or_unauthorized(response)
      end

      test :require_system_scope do
        metadata do
          id '02'
          name 'Bulk Data authorization request shall use "system" scope'
          link 'https://build.fhir.org/ig/HL7/bulk-data/authorization/index.html#scopes'
          description %(
            clients SHALL use “system” scopes.
            System scopes have the format system/(:resourceType|*).(read|write|*)
          )
        end

        response = authorize(scope: 'user/*.read')
        assert_response_bad_or_unauthorized(response)
      end

      test :require_grant_type do
        metadata do
          id '03'
          name 'Bulk Data authorization request shall use grand_type "client_credentials"'
          link 'https://build.fhir.org/ig/HL7/bulk-data/authorization/index.html#protocol-details'
          description %(
            grant_type	required	Fixed value: client_credentials
          )
        end

        response = authorize(grant_type: 'invalid_grant_type')
        assert_response_bad_or_unauthorized(response)
      end

      test :return_access_token do
        metadata do
          id '04'
          name 'Bulk Data Token Endpoint shall return access token'
          link 'https://build.fhir.org/ig/HL7/bulk-data/authorization/index.html#issuing-access-tokens'
          description %(
            With valid token request from Bulk Data client, Token endpoint shall return access token.
          )
        end

        response = authorize

        assert_response_ok(response)
        response_body = JSON.parse(response.body)
        @access_token = response_body['access_token']
        assert !@access_token.nil?, 'access_token is empty'
      end
    end
  end
end
