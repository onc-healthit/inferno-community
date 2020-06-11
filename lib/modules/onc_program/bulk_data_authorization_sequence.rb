# frozen_string_literal: true

module Inferno
  module Sequence
    class BulkDataAuthorizationSequence < SequenceBase
      title 'Bulk Data Authorization'
      description 'Demonstrate SMART Backend Service Authorization for Bulk Data'

      test_id_prefix 'BDA'

      requires :bulk_client_id, :bulk_jwks_url_auth, :bulk_encryption_method, :bulk_token_endpoint, :bulk_scope
      defines :bulk_access_token

      show_bulk_registration_info

      details %(
        Bulk Data servers are required to authorize clients using the
        [Backend Service Authorization](http://hl7.org/fhir/uv/bulkdata/STU1/authorization/)
        specification as defined in the [FHIR Bulk Data Authorization Guide](http://hl7.org/fhir/uv/bulkdata/STU1/).

        In this set of tests, Inferno serves as a Bulk Data client that attempts to authorize
        to the Bulk Data authorization server.  It also performs a number of negative tests
        to validate that the authorization service does not improperly authorize invalid
        requests.

        This test returns an access token.

      )

      def authorize(bulk_private_key: @instance.bulk_selected_private_key,
                    content_type: 'application/x-www-form-urlencoded',
                    scope: @instance.bulk_scope,
                    grant_type: 'client_credentials',
                    client_assertion_type: 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
                    iss: @instance.bulk_client_id,
                    sub: @instance.bulk_client_id,
                    aud: @instance.bulk_token_endpoint,
                    exp: 5.minutes.from_now,
                    jti: SecureRandom.hex(32))

        header =
          {
            content_type: content_type,
            accept: 'application/json'
          }.compact

        payload = create_post_payload(bulk_private_key,
                                      scope,
                                      grant_type,
                                      client_assertion_type,
                                      iss,
                                      sub,
                                      aud,
                                      exp,
                                      jti)
        assert_valid_http_uri(@instance.bulk_token_endpoint, "Invalid token endpoint: #{@instance.bulk_token_endpoint}")

        LoggedRestClient.post(@instance.bulk_token_endpoint, payload, header)
      end

      def create_post_payload(bulk_private_key,
                              scope,
                              grant_type,
                              client_assertion_type,
                              iss,
                              sub,
                              aud,
                              exp,
                              jti)

        jwt_token = JSON::JWT.new(
          iss: iss,
          sub: sub,
          aud: aud,
          exp: exp,
          jti: jti
        ).compact

        jwk = JSON::JWK.new(bulk_private_key)

        jwt_token.header[:kid] = jwk['kid']
        jwk_private_key = jwk.to_key
        client_assertion = jwt_token.sign(jwk_private_key, bulk_private_key['alg'])

        query_values =
          {
            'scope' => scope,
            'grant_type' => grant_type,
            'client_assertion_type' => client_assertion_type,
            'client_assertion' => client_assertion.to_s
          }.compact

        uri = Addressable::URI.new
        uri.query_values = query_values

        uri.query
      end

      def no_token_response_message
        'No token response received'
      end

      test :bulk_token_endpoint_tls do
        metadata do
          id '01'
          name 'Authorization service token endpoint secured by transport layer security'
          link 'http://hl7.org/fhir/uv/bulkdata/export/index.html#security-considerations'
          description %(
            All exchanges described herein between a client and a server SHALL be secured using Transport Layer Security (TLS) Protocol Version 1.2 (RFC5246)
          )
        end

        omit_if_tls_disabled

        assert_tls_1_2 @instance.bulk_token_endpoint
        assert_deny_previous_tls @instance.bulk_token_endpoint
      end

      test :require_content_type do
        metadata do
          id '02'
          name 'Authorization request fails when client supplies invalid content_type'
          link 'http://hl7.org/fhir/uv/bulkdata/authorization/index.html#protocol-details'
          description %(
            The client requests a new access token via HTTP POST to the FHIR authorization server’s token endpoint URL, using content-type application/x-www-form-urlencoded
          )
        end

        response = authorize(content_type: 'application/json')
        assert_response_bad(response)
      end

      test :require_system_scope do
        metadata do
          id '03'
          name 'Authorization request fails when client supplies invalid scope'
          link 'http://hl7.org/fhir/uv/bulkdata/authorization/index.html#scopes'
          description %(
            The Backend Service Authorization specification defines the required fields for the
            authorization request, made via HTTP POST to authorization token endpoint.  This
            request includes the `scope` parameter, where the value must be a system scope.
            System scopes have the format `system/(:resourceType|*).(read|write|*).

            The OAuth 2.0 Authorization Framework describes the proper response for an
            invalid request in the client credentials grant flow:

            ```
            If the request failed client authentication or is invalid, the authorization server returns an
            error response as described in [Section 5.2](https://tools.ietf.org/html/rfc6749#section-5.2).
            ```
          )
        end

        response = authorize(scope: 'user/*.read')
        assert_response_bad(response)
      end

      test :require_grant_type do
        metadata do
          id '04'
          name 'Authorization request fails when client supplies invalid grant_type'
          link 'http://hl7.org/fhir/uv/bulkdata/authorization/index.html#protocol-details'
          description %(
            The Backend Service Authorization specification defines the required fields for the
            authorization request, made via HTTP POST to authorization token endpoint.
            This includes the `grant_type` parameter, where the value must be `client_credentials`.

            The OAuth 2.0 Authorization Framework describes the proper response for an
            invalid request in the client credentials grant flow:

            ```
            If the request failed client authentication or is invalid, the authorization server returns an
            error response as described in [Section 5.2](https://tools.ietf.org/html/rfc6749#section-5.2).
            ```
          )
        end

        response = authorize(grant_type: 'not_a_grant_type')
        assert_response_bad(response)
      end

      test :require_client_assertion_type do
        metadata do
          id '05'
          name 'Authorization request fails when supplied invalid client_assertion_type'
          link 'http://hl7.org/fhir/uv/bulkdata/authorization/index.html#protocol-details'
          description %(
            The Backend Service Authorization specification defines the required fields for the
            authorization request, made via HTTP POST to authorization token endpoint.
            This includes the `client_assertion_type` parameter, where the value must be `urn:ietf:params:oauth:client-assertion-type:jwt-bearer`.

            The OAuth 2.0 Authorization Framework describes the proper response for an
            invalid request in the client credentials grant flow:

            ```
            If the request failed client authentication or is invalid, the authorization server returns an
            error response as described in [Section 5.2](https://tools.ietf.org/html/rfc6749#section-5.2).
            ```
          )
        end

        response = authorize(client_assertion_type: 'not_a_assertion_type')
        assert_response_bad(response)
      end

      test :require_jwt do
        metadata do
          id '06'
          name 'Authorization request fails when client supplies invalid JWT token'
          link 'http://hl7.org/fhir/uv/bulkdata/authorization/index.html#protocol-details'
          description %(

            The Backend Service Authorization specification defines the required fields for the
            authorization request, made via HTTP POST to authorization token endpoint.
            This includes the `client_assertion` parameter, where the value must be
            a valid JWT. The JWT SHALL include the following claims, and SHALL be signed with the client’s private key.

            | JWT Claim | Required? | Description |
            | --- | --- | --- |
            | iss | required | Issuer of the JWT -- the client's client_id, as determined during registration with the FHIR authorization server (note that this is the same as the value for the sub claim) |
            | sub | required | The service's client_id, as determined during registration with the FHIR authorization server (note that this is the same as the value for the iss claim) |
            | aud | required | The FHIR authorization server's "token URL" (the same URL to which this authentication JWT will be posted) |
            | exp | required | Expiration time integer for this authentication JWT, expressed in seconds since the "Epoch" (1970-01-01T00:00:00Z UTC). This time SHALL be no more than five minutes in the future. |
            | jti | required | A nonce string value that uniquely identifies this authentication JWT. |

            The OAuth 2.0 Authorization Framework describes the proper response for an
            invalid request in the client credentials grant flow:

            ```
            If the request failed client authentication or is invalid, the authorization server returns an
            error response as described in [Section 5.2](https://tools.ietf.org/html/rfc6749#section-5.2).
            ```
          )
        end

        response = authorize(iss: 'not_a_iss')
        assert_response_bad(response)
      end

      test :authorization_success do
        metadata do
          id '07'
          name 'Authorization request succeeds when supplied correct information'
          link 'http://hl7.org/fhir/uv/bulkdata/authorization/index.html#issuing-access-tokens'
          description %(
            If the access token request is valid and authorized, the authorization server SHALL issue an access token in response.
          )
        end

        response = authorize

        assert_response_ok(response)
        @token_response = response
      end

      test :have_access_token do
        metadata do
          id '08'
          name 'Authorization request response body contains required information encoded in JSON'
          link 'http://hl7.org/fhir/uv/bulkdata/authorization/index.html#issuing-access-tokens'
          description %(
            The access token response SHALL be a JSON object with the following properties:

            | Token Property | Required? | Description |
            | --- | --- | --- |
            | access_token | required | The access token issued by the authorization server. |
            | token_type | required | Fixed value: bearer. |
            | expires_in | required | The lifetime in seconds of the access token. The recommended value is 300, for a five-minute token lifetime. |
            | scope | required | Scope of access authorized. Note that this can be different from the scopes requested by the app. |
          )
        end

        skip_if @token_response.blank?, no_token_response_message

        assert_valid_json(@token_response.body)
        @token_response_body = JSON.parse(@token_response.body)

        access_token = @token_response_body['access_token']
        assert access_token.present?, 'Token response did not contain access_token as required'

        @instance.update(
          bulk_access_token: access_token
        )

        required_keys = ['token_type', 'expires_in', 'scope']

        required_keys.each do |key|
          assert @token_response_body[key].present?, "Token response did not contain #{key} as required"
        end
      end
    end
  end
end
