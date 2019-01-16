module Inferno
  module Sequence
    class OpenIDConnectSequence < SequenceBase

      title 'OpenID Connect (Optional)'
      description 'Authenticate users with OpenID Connect for OAuth 2.0.'

      test_id_prefix 'OIDC'

      requires :id_token, :client_id
      defines :oauth_introspection_endpoint

      test 'ID token is valid jwt token' do

        metadata {
          id '01'
          link 'http://docs.smarthealthit.org/authorization/scopes-and-launch-context/'
          desc %(
            Examine the ID token for its issuer property.
          )
        }


        begin
          @decoded_payload, @decoded_header = JWT.decode(@instance.id_token, nil, false,
                                                         # Overriding default options to parse without verification
                                                         {
                                                             verify_expiration: false,
                                                             verify_not_before: false,
                                                             verify_iss: false,
                                                             verify_iat: false,
                                                             verify_jti: false,
                                                             verify_aud: false,
                                                             verify_sub: false
                                                         }
          )
        rescue => e # Show parse error as failure
          assert false, e.message
        end
      end

      test 'ID token contains expected header and payload information' do

        metadata {
          id '02'
          link 'http://docs.smarthealthit.org/authorization/scopes-and-launch-context/'
          desc %(
            Examine the ID token for its issuer property.
          )
        }

        assert !@decoded_payload.nil?, 'Payload could not be extracted from ID token'
        assert !@decoded_header.nil?, 'Header could not be extracted from ID token'
        @issuer = @decoded_payload['iss']
        assert !@issuer.nil?, 'ID Token does not contain issuer'

      end

      test 'Issuer provides OpenID configuration information' do

        metadata {
          id '03'
          link 'http://docs.smarthealthit.org/authorization/scopes-and-launch-context/'
          desc %(
            Perform a GET {issuer}/.well-known/openid-configuration.
          )
        }

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

        metadata {
          id '04'
          link 'http://docs.smarthealthit.org/authorization/scopes-and-launch-context/'
          desc %(
            Fetch the JSON Web Key of the server by following the "jwks_uri" property.
          )
        }

        assert !@openid_configuration_response_body.nil?, 'no openid-configuration response body available'
        jwks_uri = @openid_configuration_response_body['jwks_uri']
        assert jwks_uri, 'openid-configuration response did not contain jwks_uri as required'
        @jwk_response = LoggedRestClient.get(jwks_uri)
        assert_response_ok(@jwk_response)
        @jwk_response_headers = @jwk_response.headers
        @jwk_response_body = JSON.parse(@jwk_response.body)
        @jwk_set = JSON::JWK::Set.new(@jwk_response_body)
        assert !@jwk_set.nil?, 'JWK set not present'
        assert @jwk_set.length > 0, 'JWK set is empty'

      end

      test 'ID token can be decoded using JSON Web Key information' do

        metadata {
          id '05'
          link 'http://docs.smarthealthit.org/authorization/scopes-and-launch-context/'
          desc %(
            Validate the token's signature against the public key.
          )
        }

        assert !@jwk_set.nil?, 'JWK set not present'
        assert @jwk_set.length > 0, 'JWK set is empty'

        begin
          jwt = JSON::JWT.decode(@instance.id_token, @jwk_set)
        rescue => e # Show validation error as failure
          assert false, e.message
        end

        assert !jwt.nil?, 'JWT could not be properly decoded'

      end

      test 'ID token signature validates using JSON Web Key information' do

        metadata {
          id '06'
          link 'http://openid.net/specs/openid-connect-core-1_0.html#IDTokenValidation'
          desc %(
            Validate the ID token claims.
          )
        }

        leeway = 30 # 30 seconds clock slip allowed

        begin
          JWT.decode @instance.id_token, @jwk_set[0].to_key, true, {
              leeway: leeway,
              algorithm: 'RS256',
              aud: @instance.client_id,
              verify_aud: true,
              verify_iat: true,
              verify_expiration: true,
              verify_not_before: true
          }

        rescue => e # Show validation error as failure
          assert false, e.message
        end

      end

      test 'Profile claim in ID token is represented as a resource URI' do

        metadata {
          id '07'
          link 'http://docs.smarthealthit.org/authorization/scopes-and-launch-context/'
          desc %(
            Extract the profile claim and treat it as the URL of a FHIR resource.
          )
        }

        assert !@decoded_payload.nil?, 'no id_token payload available'
        assert !@decoded_header.nil?, 'no id_token header available'
        assert !@decoded_payload['profile'].nil?, 'no id_token profile claim'

        # How should we validate this profile id?
        # Does this have to be a URI, or is a fragment ok?
        # assert @decoded_payload['profile'] =~ URI::regexp, "id_token profile claim #{@decoded_payload['profile']} is not a valid URL"

      end

    end

  end
end
