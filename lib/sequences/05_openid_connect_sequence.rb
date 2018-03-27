class OpenIDConnectSequence < SequenceBase

  title 'OpenID Connect'
  description 'Verify OpenID Connect functionality of server.'

  preconditions 'Client must have ID token.' do
    !@instance.id_token.nil?
  end

  test 'ID token has issuer property.',
    'http://docs.smarthealthit.org/authorization/scopes-and-launch-context/',
    '1. Examine the ID token for its issuer property' do

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

    assert !@decoded_payload.nil?, 'Missing id_token payload'
    assert !@decoded_header.nil?, 'Missing id_token header'
    @issuer = @decoded_payload['iss']
    assert !@issuer.nil?, 'id_token did not contain iss as required'

  end

  test 'OpenID configuration response properly returned.',
    'http://docs.smarthealthit.org/authorization/scopes-and-launch-context/',
    '2. Perform a GET {issuer}/.well-known/openid-configuration' do

    assert !@issuer.nil?, 'no issuer available'
    @issuer = @issuer.chomp('/')
    openid_configuration_url = @issuer + '/.well-known/openid-configuration'
    @openid_configuration_response = LoggedRestClient.get(openid_configuration_url)
    assert_response_ok(@openid_configuration_response)
    @openid_configuration_response_headers = @openid_configuration_response.headers
    @openid_configuration_response_body = JSON.parse(@openid_configuration_response.body)

  end

  test 'JSON Web Key information properly returned.',
    'http://docs.smarthealthit.org/authorization/scopes-and-launch-context/',
    '3. Fetch the server’s JSON Web Key by following the “jwks_uri” property' do

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

  test 'ID token signature validated.',
    'http://docs.smarthealthit.org/authorization/scopes-and-launch-context/',
    '4. Validate the token’s signature against the public key from step #3' do

    assert !@jwk_set.nil?, 'JWK set not present'
    assert @jwk_set.length > 0, 'JWK set is empty'

    begin
      jwt = JSON::JWT.decode(@instance.id_token, @jwk_set)
    rescue => e # Show validation error as failure
      assert false, e.message
    end

    assert !jwt.nil?, 'JWT could not be properly decoded'

  end

  test 'ID token claims validated.',
    'http://openid.net/specs/openid-connect-core-1_0.html#IDTokenValidation',
    'Validate the ID token claims' do

    leeway = 30 # 30 seconds clock slip allowed

    begin
      decoder = JWT::Decode.new(@instance.id_token, nil, false,
        {
          leeway: leeway,
          aud: @instance.client_id,
          verify_aud: true,
          verify_iat: true,
          verify_expiration: true,
          verify_not_before: true
          # If we gain information about iss or sub, this information
          # should go here, as below
          # iss: 'foo', #issuer goes here
          # verify_iss: true
          #sub: subject goes here
          #verify_sub: true
        }
      )
      decoder.decode_segments
      decoder.verify
    rescue => e # Show validation error as failure
      assert false, e.message
    end

  end

  test 'ID token has profile claim as resource URL.',
    'http://docs.smarthealthit.org/authorization/scopes-and-launch-context/',
    '5. Extract the profile claim and treat it as the URL of a FHIR resource' do

    assert !@decoded_payload.nil?, 'no id_token payload available'
    assert !@decoded_header.nil?, 'no id_token header available'
    assert !@decoded_payload['profile'].nil?, 'no id_token profile claim'
    assert @decoded_payload['profile'] =~ URI::regexp, "id_token profile claim #{@decoded_payload['profile']} is not a valid URL"

  end

end
