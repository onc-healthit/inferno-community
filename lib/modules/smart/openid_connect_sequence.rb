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

        OpenID Connect provides the ability to verify the identity of the authorizing user.This
        functionality is treated as *OPTIONAL* within Inferno, but is required within the [SMART App Launch Framework](http://hl7.org/fhir/smart-app-launch/).
        Applications can request an `id_token` be provided with by including the `openid fhirUser` scopes when requesting
        authorization.

        # Test Methodology

        This sequence requires an OAuth 2.0 id token to verify the user.  Inferno will inspect the id token, including
        the return payload and headers.  Inferno will request the OpenID Connect configuration information from the server
        in order to retrieve the JSON Web Token information from the provider.  The JSON Web Token is then used to decode
        and verify the id token


        For more information see:

        * [SMART App Launch Framework](http://hl7.org/fhir/smart-app-launch/)
        * [Scopes for requesting identity data](http://hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html#scopes-for-requesting-identity-data)
        * [Apps Requesting Authorization](http://hl7.org/fhir/smart-app-launch/#step-1-app-asks-for-authorization)
        * [OpenID Connect Core](https://openid.net/specs/openid-connect-core-1_0.html)
              )

      test 'ID token is valid jwt token' do
        metadata do
          id '01'
          link 'http://docs.smarthealthit.org/authorization/scopes-and-launch-context/'
          description %(
            Examine the ID token for its issuer property.
          )
        end

        begin
          @decoded_payload, @decoded_header = JWT.decode(@instance.id_token, nil, false,
                                                         # Overriding default options to parse without verification
                                                         verify_expiration: false,
                                                         verify_not_before: false,
                                                         verify_iss: false,
                                                         verify_iat: false,
                                                         verify_jti: false,
                                                         verify_aud: false,
                                                         verify_sub: false)
        rescue StandardError => e # Show parse error as failure
          assert false, e.message
        end
      end

      test 'ID token contains expected header and payload information' do
        metadata do
          id '02'
          link 'http://docs.smarthealthit.org/authorization/scopes-and-launch-context/'
          description %(
            Examine the ID token for its issuer property.
          )
        end

        assert !@decoded_payload.nil?, 'Payload could not be extracted from ID token'
        assert !@decoded_header.nil?, 'Header could not be extracted from ID token'
        @issuer = @decoded_payload['iss']
        assert !@issuer.nil?, 'ID Token does not contain issuer'
      end

      test 'Issuer provides OpenID configuration information' do
        metadata do
          id '03'
          link 'http://docs.smarthealthit.org/authorization/scopes-and-launch-context/'
          description %(
            Perform a GET {issuer}/.well-known/openid-configuration.
          )
        end

        assert !@issuer.nil?, 'no issuer available'
        @issuer = @issuer.chomp('/')
        openid_configuration_url = @issuer + '/.well-known/openid-configuration'
        @openid_configuration_response = LoggedRestClient.get(openid_configuration_url)
        assert_response_ok(@openid_configuration_response)
        @openid_configuration_response_headers = @openid_configuration_response.headers
        @openid_configuration_response_body = JSON.parse(@openid_configuration_response.body)

        # save the introspection URL while we're here, we'll need it for the next test sequence
        @instance.oauth_introspection_endpoint = @openid_configuration_response_body['introspection_endpoint']
      end

      test 'OpenID configuration includes JSON Web Key information' do
        metadata do
          id '04'
          link 'http://docs.smarthealthit.org/authorization/scopes-and-launch-context/'
          description %(
            Fetch the JSON Web Key of the server by following the "jwks_uri" property.
          )
        end

        assert !@openid_configuration_response_body.nil?, 'no openid-configuration response body available'
        jwks_uri = @openid_configuration_response_body['jwks_uri']
        assert jwks_uri, 'openid-configuration response did not contain jwks_uri as required'
        @jwk_response = LoggedRestClient.get(jwks_uri)
        assert_response_ok(@jwk_response)
        @jwk_response_headers = @jwk_response.headers
        @jwk_response_body = JSON.parse(@jwk_response.body)
        @jwk_set = JSON::JWK::Set.new(@jwk_response_body)
        assert !@jwk_set.nil?, 'JWK set not present'
        assert !@jwk_set.empty?, 'JWK set is empty'
      end

      test 'ID token can be decoded using JSON Web Key information' do
        metadata do
          id '05'
          link 'http://docs.smarthealthit.org/authorization/scopes-and-launch-context/'
          description %(
            Validate the token's signature against the public key.
          )
        end

        assert !@jwk_set.nil?, 'JWK set not present'
        assert !@jwk_set.empty?, 'JWK set is empty'

        begin
          jwt = JSON::JWT.decode(@instance.id_token, @jwk_set[0].to_key)
        rescue StandardError => e # Show validation error as failure
          assert false, e.message
        end

        assert !jwt.nil?, 'JWT could not be properly decoded'
      end

      test 'ID token signature validates using JSON Web Key information' do
        metadata do
          id '06'
          link 'http://openid.net/specs/openid-connect-core-1_0.html#IDTokenValidation'
          description %(
            Validate the ID token claims.
          )
        end

        leeway = 30 # 30 seconds clock slip allowed

        assert !@jwk_set.nil?, 'JWK set not present'
        assert !@jwk_set.empty?, 'JWK set is empty'
        begin
          JWT.decode @instance.id_token, @jwk_set[0].to_key, true,
                     leeway: leeway,
                     algorithm: 'RS256',
                     aud: @instance.client_id,
                     verify_aud: true,
                     verify_iat: true,
                     verify_expiration: true,
                     verify_not_before: true
        rescue StandardError => e # Show validation error as failure
          assert false, e.message
        end
      end

      test 'fhirUser claim in ID token is represented as a resource URI' do
        metadata do
          id '07'
          link 'http://docs.smarthealthit.org/authorization/scopes-and-launch-context/'
          description %(
            Extract the fhirUser claim and treat it as the URL of a FHIR resource.
          )
        end

        assert !@decoded_payload.nil?, 'no id_token payload available'
        assert !@decoded_header.nil?, 'no id_token header available'
        assert !@decoded_payload['fhirUser'].nil?, 'no id_token fhirUser claim'

        # How should we validate this profile id?
        # Does this have to be a URI, or is a fragment ok?
        # assert @decoded_payload['profile'] =~ URI::regexp, "id_token profile claim #{@decoded_payload['profile']} is not a valid URL"
      end
    end
  end
end
