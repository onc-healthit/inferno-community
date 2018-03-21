class OpenIDConnectSequence < SequenceBase

  title 'OpenID Connect Sequence'
  description 'Verify OpenID Connect functionality of server.'

  preconditions 'Client must have ID token.' do
    !@instance.id_token.nil?
  end

  test 'ID token has issuer property.',
    'http://docs.smarthealthit.org/authorization/scopes-and-launch-context/',
    '1. Examine the ID token for its issuer property' do

    @decoded_token = JWT.decode(@instance.id_token, @public_key, false, { algorithm: @alg }).reduce({}, :merge)
    assert !@decoded_token.nil?, 'id_token could not be parsed as JWT'
    @issuer = @decoded_token['iss']
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
    assert @jwk_response_body.has_key?('keys') && @jwk_response_body['keys'].length > 0, 'JWK response does not have keys as required'
    key_info = @jwk_response_body['keys'][0]
    assert key_info.has_key?('n'), "JWK response does not have public key as required"
    @public_key = key_info['n']
    assert key_info.has_key?('alg'), "JWK response does not have alg as required"
    @alg = key_info['alg']

  end

  test 'ID token signature validated.',
    'http://docs.smarthealthit.org/authorization/scopes-and-launch-context/',
    '4. Validate the token’s signature against the public key from step #3' do

    assert !@issuer.nil?, 'no issuer available'
    assert !@public_key.nil?, 'no public key available'
    assert !@alg.nil?, 'no decryption algorithm available'
    @validated_token = JWT.decode(@instance.id_token, @public_key, false, { algorithm: @alg }).reduce({}, :merge)
    assert !@validated_token.nil?, 'id_token signature was not properly validated'
    assert @validated_token['iss'].chomp('/') == @issuer.chomp('/'), 'id_token iss does not match issuer claim'
    assert @validated_token['alg'] == @alg, 'id_token alg does not match JWK alg'

  end

  test 'ID token has profile claim as resource URL.',
    'http://docs.smarthealthit.org/authorization/scopes-and-launch-context/',
    '5. Extract the profile claim and treat it as the URL of a FHIR resource' do

    assert !@decoded_token.nil?, 'id_token was not properly parsed as JWT'
    assert @decoded_token['profile'] =~ URI::regexp, 'id_token profile is not a valid URL'

  end

end
