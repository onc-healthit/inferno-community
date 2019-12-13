# frozen_string_literal: true

module Inferno
  module Sequence
    class OpenIDConnectSequence < SequenceBase
      title 'OpenID Connect'
      description 'Authenticate users with OpenID Connect for OAuth 2.0.'

      test_id_prefix 'OIDC'

      requires :id_token, :client_id
      defines :oauth_introspection_endpoint

      details %(
        # Background

        OpenID Connect (OIDC) provides the ability to verify the identity of the
        authorizing user. Within the [SMART App Launch
        Framework](http://hl7.org/fhir/smart-app-launch/), Applications can
        request an `id_token` be provided with by including the `openid
        fhirUser` scopes when requesting authorization.

        # Test Methodology

        This sequence validates the id token returned as part of the OAuth 2.0
        token response. Once the token is decoded, the server's OIDC
        configuration is retrieved from its well-known configuration endpoint.
        This configuration is checked to ensure that all required fields are
        present. Next the keys used to cryptographically sign the id token are
        retrieved from the url contained in the OIDC configuration. Then the
        header, payload, and signature of the id token are validated. Finally,
        the FHIR resource from the `fhirUser` claim in the id token is fetched
        from the FHIR server.

        For more information see:

        * [SMART App Launch Framework](http://hl7.org/fhir/smart-app-launch/)
        * [Scopes for requesting identity data](http://hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html#scopes-for-requesting-identity-data)
        * [Apps Requesting Authorization](http://hl7.org/fhir/smart-app-launch/#step-1-app-asks-for-authorization)
        * [OpenID Connect Core](https://openid.net/specs/openid-connect-core-1_0.html)
      )

      def skip_if_id_token_not_requested
        skip_unless id_token_requested?, '"openid" and "fhirUser" scopes not requested'
      end

      def id_token_requested?
        @instance.scopes.include?('openid') && @instance.scopes.include?('fhirUser')
      end

      def skip_if_id_token_could_not_be_decoded
        skip_if @decoded_payload.blank?, 'ID token could not be decoded'
      end

      def skip_if_configuration_could_not_be_retrieved
        skip_if @oidc_configuration.blank?, 'OpenID Connect well-known configuration could not be retrieved'
      end

      def required_configuration_fields
        [
          'issuer',
          'authorization_endpoint',
          'token_endpoint',
          'jwks_uri',
          'response_types_supported',
          'subject_types_supported',
          'id_token_signing_alg_values_supported'
        ]
      end

      def discouraged_header_fields
        ['x5u', 'x5c', 'jku', 'jwk']
      end

      def required_payload_claims
        ['iss', 'sub', 'aud', 'exp', 'iat']
      end

      def valid_fhir_user_resource_types
        ['Patient', 'Practitioner', 'RelatedPerson', 'Person']
      end

      test :decode_token do
        metadata do
          id '01'
          link 'https://tools.ietf.org/html/rfc7519'
          name 'ID token can be decoded'
          description %(
            Verify that the ID token is a properly constructed JWT.
          )
        end

        skip_if_id_token_not_requested

        assert @instance.id_token.present?, 'Launch context did not contain an id token'

        begin
          decoded_token =
            JWT.decode(
              @instance.id_token,
              nil,
              false
            )
          @decoded_payload, @decoded_header = decoded_token
        rescue StandardError => e # Show parse error as failure
          assert false, "ID token is not a properly constructed JWT: #{e.message}"
        end
      end

      test :retrieve_configuration do
        metadata do
          id '02'
          link 'https://openid.net/specs/openid-connect-discovery-1_0.html#ProviderConfig'
          name 'OpenID Connect well-known configuration can be retrieved'
          description %(
            Verify that the OpenId Connect configuration can be retrieved as
            described in the OpenID Connect Discovery 1.0 documentation
          )
        end

        skip_if_id_token_not_requested
        skip_if_id_token_could_not_be_decoded
        issuer = @decoded_payload['iss']

        configuration_url = issuer.chomp('/') + '/.well-known/openid-configuration'
        configuration_response = LoggedRestClient.get(configuration_url)

        assert_response_ok(configuration_response)
        assert_response_content_type(configuration_response, 'application/json')
        assert_valid_json(configuration_response.body)

        @oidc_configuration = JSON.parse(configuration_response.body)
      end

      test :required_configuration_fields do
        metadata do
          id '03'
          link 'https://openid.net/specs/openid-connect-discovery-1_0.html#ProviderMetadata'
          name 'OpenID Connect well-known configuration contains all required fields'
          description %(
            Verify that the OpenId Connect configuration contains the following
            required fields: `issuer`, `authorization_endpoint`,
            `token_endpoint`, `jwks_uri`, `response_types_supported`,
            `subject_types_supported`, and
            `id_token_signing_alg_values_supported`.

            Additionally, the [SMART App Launch
            Framework](http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html#scopes-for-requesting-identity-data)
            requires that the RSA SHA-256 signing algorithm be supported.
          )
        end

        skip_if_id_token_not_requested
        skip_if_id_token_could_not_be_decoded
        skip_if_configuration_could_not_be_retrieved

        configuration_fields = @oidc_configuration.keys
        missing_fields = required_configuration_fields - configuration_fields
        assert missing_fields.empty?, "OpenID Connect well-known configuration missing required fields: #{missing_fields.join(', ')}"

        assert @oidc_configuration['id_token_signing_alg_values_supported'].include?('RS256'), 'Signing tokens with RSA SHA-256 not supported'
      end

      test :retrieve_jwks do
        metadata do
          id '04'
          link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html#steps-for-using-an-id-token'
          name 'JWKS can be retrieved'
          description %(
            Verify that the JWKS can be retrieved from the `jwks_uri` from the
            OpenID Connect well-known configuration.
          )
        end

        skip_if_id_token_not_requested
        skip_if_id_token_could_not_be_decoded
        skip_if_configuration_could_not_be_retrieved

        jwks_uri = @oidc_configuration['jwks_uri']

        skip_if jwks_uri.blank?, 'OpenID Connect well-known configuration did not contain a jwks_uri'

        jwks_response = LoggedRestClient.get(jwks_uri)

        assert_response_ok(jwks_response)
        assert_valid_json(jwks_response.body)

        @raw_jwks = JSON.parse(jwks_response.body).deep_symbolize_keys
        assert @raw_jwks[:keys].is_a?(Array), 'JWKS "keys" field must be an array'

        @raw_jwks[:keys].each do |jwk|
          # https://tools.ietf.org/html/rfc7517#section-5
          # Implementations SHOULD ignore JWKs within a JWK Set that use "kty"
          # (key type) values that are not understood by them
          next unless jwk[:kty] == 'RSA' # SMART only requires support of RSA SHA-256 keys

          begin
            JWT::JWK.import(jwk)
          rescue StandardError
            assert false, "Invalid JWK: #{jwk.to_json}"
          end
        end

        @jwks = @raw_jwks[:keys].select { |jwk| jwk[:kty] == 'RSA' }
        assert @jwks.present?, 'JWKS contains no RSA keys'
      end

      test :token_header do
        metadata do
          id '05'
          link 'https://openid.net/specs/openid-connect-core-1_0.html#IDToken'
          name 'ID token header contains required information'
          description %(
            Verify that the id token is signed using RSA SHA-256 [as required by
            the SMART app launch
            framework](http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html#scopes-for-requesting-identity-data)
            and that the key used to sign the token can be identified in the
            JWKS.
          )
        end

        skip_if_id_token_not_requested
        skip_if_id_token_could_not_be_decoded
        skip_if_configuration_could_not_be_retrieved
        skip_unless @jwks.present?, 'RSA keys could not be retrieved from JWKS'

        warning do
          discouraged_fields = discouraged_header_fields & @decoded_header.keys
          assert discouraged_fields.blank?, "ID token header contains fields that should not be used: #{discouraged_fields.join(', ')}"
        end

        algorithm = @decoded_header['alg']
        assert algorithm == 'RS256', "ID Token signed with #{algorithm} rather than RS256"

        kid = @decoded_header['kid']

        if @raw_jwks[:keys].length > 1
          assert kid.present?, '"kid" field must be present if JWKS contains multiple keys'
          @jwk = @jwks.find { |jwk| jwk[:kid] == kid }
          assert @jwk.present?, "JWKS did not contain an RS256 key with an id of #{kid}"
        else
          @jwk = @jwks.first
          assert @jwk[:kid] == kid, "JWKS did not contain an RS256 key with an id of #{kid}" if kid.present?
        end
      end

      test :token_payload do
        metadata do
          id '06'
          link 'https://openid.net/specs/openid-connect-core-1_0.html#IDTokenValidation'
          name 'ID token payload has required claims and a valid signature'
          description %(
            The `iss`, `sub`, `aud`, `exp`, and `iat` claims are required.
            Additionally:

            - `iss` must match the `issuer` from the OpenID Connect well-known
              configuration
            - `aud` must match the client ID
            - `exp` must represent a time in the future
          )
        end

        skip_if_id_token_not_requested
        skip_if_id_token_could_not_be_decoded
        skip_if_configuration_could_not_be_retrieved

        missing_claims = required_payload_claims - @decoded_payload.keys
        assert missing_claims.empty?, "ID token missing required claims: #{missing_claims.join(', ')}"

        skip_if @jwk.blank?, 'No JWK was found'

        begin
          JWT.decode(
            @instance.id_token,
            JWT::JWK.import(@jwk).public_key,
            true,
            algorithms: ['RS256'],
            exp_leeway: 60,
            iss: @oidc_configuration['issuer'],
            aud: @instance.client_id,
            verify_not_before: false,
            verify_iat: false,
            verify_jti: false,
            verify_sub: false,
            verify_iss: true,
            verify_aud: true
          )
        rescue StandardError => e
          assert false, "Token validation error: #{e.message}"
        end
      end

      test :fhir_user_claim do
        metadata do
          id '07'
          link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html#scopes-for-requesting-identity-data'
          name 'FHIR resource representing the current user can be retrieved'
          description %(
            Verify that the `fhirUser` claim is present in the ID token and that
            the FHIR resource it refers to can be retrieved. The `fhirUser`
            claim must be the url for a Patient, Practitioner, RelatedPerson, or
            Person resource
          )
        end

        skip_if_id_token_not_requested
        skip_if_id_token_could_not_be_decoded
        skip_if_configuration_could_not_be_retrieved

        fhir_user = @decoded_payload['fhirUser']
        assert fhir_user.present?, 'ID token does not contain `fhirUser` claim'

        assert valid_fhir_user_resource_types.any? { |type| fhir_user.include? type },
               "ID token `fhirUser` claim does not refer to a valid resource type (#{valid_fhir_user_resource_types.join(', ')}): #{fhir_user}"

        fhir_user_response = @client.get(fhir_user, @client.fhir_headers)
        assert_response_ok fhir_user_response
        assert_valid_json fhir_user_response.body

        response_resource_type = JSON.parse(fhir_user_response.body)['resourceType']

        assert valid_fhir_user_resource_types.include?(response_resource_type), "Resource from `fhirUser` claim was not an allowed resource type: #{response_resource_type}"
      end
    end
  end
end
