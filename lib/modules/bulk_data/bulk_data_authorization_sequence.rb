# frozen_string_literal: true

module Inferno
  module Sequence
    class BulkDataAuthorizationSequence < SequenceBase
      title 'Bulk Data Authentication'

      test_id_prefix 'BDA'

      requires :client_id, :bulk_private_key, :oauth_token_endpoint

      description 'Test Bulk Data Authorization Token Endpoint'

      def authorize(bulk_private_key: @instance.bulk_private_key,
                    content_type: 'application/x-www-form-urlencoded',
                    scope: 'system/*.read',
                    grant_type: 'client_credentials',
                    client_assertion_type: 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
                    iss: @instance.client_id,
                    sub: @instance.client_id,
                    aud: @instance.oauth_token_endpoint,
                    exp: 5.minutes.from_now,
                    jti: SecureRandom.hex(32))
        id_token = JSON::JWT.new(
          iss: iss,
          sub: sub,
          aud: aud,
          exp: exp,
          jti: jti
        ).compact

        jwk = JSON::JWK.new(JSON.parse(bulk_private_key))

        id_token.header[:kid] = jwk['kid']
        jwk_private_key = jwk.to_key
        client_assertion = id_token.sign(jwk_private_key, 'RS384')

        payload =
          {
            'scope' => scope,
            'grant_type' => grant_type,
            'client_assertion_type' => client_assertion_type,
            'client_assertion' => client_assertion.to_s
          }.compact

        header =
          {
            content_type: content_type,
            accept: 'application/json'
          }.compact

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
            * grant_type	required	Fixed value: client_credentials
          )
        end

        response = authorize(grant_type: 'not_a_grant_type')
        assert_response_bad_or_unauthorized(response)
      end

      test :require_client_assertion_type do
        metadata do
          id '04'
          name 'Bulk Data authorization request shall use client_assertion_type "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"'
          link 'https://build.fhir.org/ig/HL7/bulk-data/authorization/index.html#protocol-details'
          description %(
            * client_assertion_type	required	Fixed value: urn:ietf:params:oauth:client-assertion-type:jwt-bearer
          )
        end

        response = authorize(client_assertion_type: 'not_a_assertion_type')
        assert_response_bad_or_unauthorized(response)
      end

      test :require_jwt_iss do
        metadata do
          id '05'
          name 'Bulk Data authorization request shall use client_id as JWT issuer '
          link 'https://build.fhir.org/ig/HL7/bulk-data/authorization/index.html#protocol-details'
          description %(
            * iss	required	Issuer of the JWT -- the client's client_id, as determined during registration with the FHIR authorization server (note that this is the same as the value for the sub claim)
          )
        end

        response = authorize(iss: 'not_a_iss')
        assert_response_bad_or_unauthorized(response)
      end

      test :require_jwt_sub do
        metadata do
          id '06'
          name 'Bulk Data authorization request shall use client_id as JWT subject '
          link 'https://build.fhir.org/ig/HL7/bulk-data/authorization/index.html#protocol-details'
          description %(
            * sub	required	The service's client_id, as determined during registration with the FHIR authorization server (note that this is the same as the value for the iss claim)
          )
        end

        response = authorize(sub: 'not_a_sub')
        assert_response_bad_or_unauthorized(response)
      end

      test :require_jwt_aud do
        metadata do
          id '07'
          name 'Bulk Data authorization request shall use token url as JWT audience '
          link 'https://build.fhir.org/ig/HL7/bulk-data/authorization/index.html#protocol-details'
          description %(
            * aud	required	The FHIR authorization server's "token URL" (the same URL to which this authentication JWT will be posted )
          )
        end

        response = authorize(aud: 'not_a_token_url')
        assert_response_bad_or_unauthorized(response)
      end

      test :require_jwt_exp do
        metadata do
          id '08'
          name 'Bulk Data authorization request shall have JWT expiration time'
          link 'https://build.fhir.org/ig/HL7/bulk-data/authorization/index.html#protocol-details'
          description %(
            * exp	required	Expiration time integer for this authentication JWT, expressed in seconds since the "Epoch" (1970-01-01T00:00:00Z UTC). This time SHALL be no more than five minutes in the future.
          )
        end

        response = authorize(exp: nil)
        assert_response_bad_or_unauthorized(response)
      end

      test :require_jwt_exp_value do
        metadata do
          id '09'
          name 'Bulk Data authorization request shall have JWT expiration time no more than 5 minutes in the future'
          link 'https://build.fhir.org/ig/HL7/bulk-data/authorization/index.html#protocol-details'
          description %(
            * exp	required	Expiration time integer for this authentication JWT, expressed in seconds since the "Epoch" (1970-01-01T00:00:00Z UTC). This time SHALL be no more than five minutes in the future.
          )
        end

        response = authorize(exp: 10.minutes.from_now)
        assert_response_bad_or_unauthorized(response)
      end

      test :require_jwt_jti do
        metadata do
          id '10'
          name 'Bulk Data authorization request shall have JWT ID'
          link 'https://build.fhir.org/ig/HL7/bulk-data/authorization/index.html#protocol-details'
          description %(
            * jti	required	A nonce string value that uniquely identifies this authentication JWT.
          )
        end

        response = authorize(jti: nil)
        assert_response_bad_or_unauthorized(response)
      end

      test :correct_signature do
        metadata do
          id '10'
          name 'Bulk Data authorization request shall be signed by client private key'
          link 'https://build.fhir.org/ig/HL7/bulk-data/authorization/index.html#protocol-details'
          description %(
            The authentication JWT SHALL include the following claims, and SHALL be signed with the client’s private key

            The EHR’s authorization server SHALL validate the JWT according to the processing requirements defined in Section 3 of RFC7523 including validation of the signature on the JWT.
          )
        end

        invalid_private_key = {
          "kty": 'RSA',
          "alg": 'RS384',
          "n": 'yh9VjpVXyYWKEg8pwCLWtvIcqxCFn5-6iTmm_ocqmfmJ7hb2S_RWIHNyTea6LlnWP_FaL46WQYI0SgSIaos3C8pxxskrMWJQkqra0w8rjJhL3D-avvVf5Mugv6rUYboFbRlTmqGmwQl1lCm5wJEcwFwFis2phf8Xydjdoo2HxP8q94zfCrZt1zXrHpqMLMaN8Hc-Zuuq2vZmqEfsiwxdCBPvfHJTj3ht10MC7HPrJc9T5LiAaaxaQUVzM91Q85z7wQcdIGSjr3MJJuyWhD-z878AXH49K_eft_S-B8Uotu9jwLZqNyk7_in1PeJYBVB-SyKRNa9dBuQc5TvFNqVT2Q',
          "e": 'AQAB',
          "d": 'x88wEhMaxJIpyu6IdHM8VYCEzKs5nXIWwl9m8YmHmM1yCBdVBgMWPWBDKDWl6fpPbcjXQdowObRQordWcBUNpq9LyJrIAzrQsh0K08jUYVmQ7LtH6-zADnsqfy-OYsm1YYO-_Uc-hOgn_v88rNwHUzXlGLF1G4zw5E5p068b_6YKtVFhmQpdvbvrAg55pAlCpQzOKYwqepJgG1BPQz0ta6ymYWIiPsDpr02VkkfEeIOV24ymCPfu9vayEfxGdHyN4NWE3xRujBXONVBemsAMU0tFxuN-vBZklM9Pqv803kILpHTC9L9OFkzisY-7P5bahErhIiLJUeHeeZnGTi0cXQ',
          "p": '6_Lg8H29uGVQjmhRgmwzQ-Q__ybRbKIlIf7ieyHrAmIIbT8LtQlPCEzCFnflz_j5hoRq0DbvpLEZYcMjiJnGXrDxhInwOWPf-2eo5jGJtm64bkT8xBEZ5A6SWadAO9Dmy9KMoB136mQpiEHqYvLLg7E-RVAUKkw2LspYcZB6-r8',
          "q": '20yOKIYq1lQBP48DqA88iIm9DINNhz66tfxEfWu4fjAsku0wbFRqsidw0XW1I6BHgrCnRLSev_m9Rj-MjpcUyZsEsGqSuVhXDOWocS_eZapkTD79ugU2P_lMT0qErlF5Bfmg7kUByTJODyDrpT2hAX7q-wb77029ANlCDugWz2c',
          "dp": 'k1x-tlSiAB9uv3JRrfYr0nQksBOraoCeVmwdQS_-2d8mSiy9ABVPQezGr0e0xT5HgYcEOwSEiUR-iLtaXv9DkHJMdS29VeqVwiuMpjA8RS9DisMVZtMTa4baSpoVmQYwjw3x_DJLaZ2i_tHENIZVKuuw65NG9N_iWzjPIiZNWHs',
          "dq": 'LFSNaCO3BRx2JCME2jQ6SF-Pl7fzNCO6Go-kSLY91URnvku0PjHSX7EZXT4uH8WGrySGq5zXendBi7HM-AYSba6ohAEHJ_BzqGfEZR0IGAUZwU_6emATV1tN0bl-mL5feJW9smzAr6s7nFNLT1vl8Cd32MbQps9QJZvFfr3r3oE',
          "qi": 'H45gESn1kzqIjLqf1iiESlXb-04s_rLO43BCN-57LMIPckAW4AQPx4bq4-58Jig_U3h6eJX7-2W4QP3UyyGHPIBQH7HaCxnqUZ7ilRzLQBneBZCrtPtlIxExdD_a2Aqzgb5JdND92ZutlPdCUKxZSBVQtmLVg4wh8O-GCA3bSqI',
          "key_ops": [
            'sign'
          ],
          "ext": true,
          "kid": '510c84dd7c5a7c285911d0f405522c5a'
        }

        response = authorize(bulk_private_key: invalid_private_key.to_json)
        assert_response_bad_or_unauthorized(response)
      end

      test :return_access_token do
        metadata do
          id '11'
          name 'Bulk Data Token Endpoint shall return access token'
          link 'https://build.fhir.org/ig/HL7/bulk-data/authorization/index.html#issuing-access-tokens'
          description %(
            If the access token request is valid and authorized, the authorization server SHALL issue an access token in response.

            The access token response SHALL be a JSON object with the following properties:

            * access_token	required	The access token issued by the authorization server.
            * token_type	required	Fixed value: bearer.
            * expires_in	required	The lifetime in seconds of the access token. The recommended value is 300, for a five-minute token lifetime.
            * scope	required	Scope of access authorized. Note that this can be different from the scopes requested by the app.
          )
        end

        response = authorize

        assert_response_ok(response)
        response_body = JSON.parse(response.body)
        @access_token = response_body['access_token']
        assert @access_token.present?, 'access_token is empty'
        assert response_body['token_type'] == 'bearer', 'token_type expected to be "bearer"'
        assert response_body['expires_in'].present?, 'expires_in is empty'
        assert response_body['scope'].present?, 'scope is empty'
      end
    end
  end
end
